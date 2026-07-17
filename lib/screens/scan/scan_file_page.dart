import 'package:flutter/material.dart';
import 'package:local_app_tt/navigation/app_navigation.dart';
import 'package:local_app_tt/screens/scan/file_history_page.dart';
import 'package:local_app_tt/services/file_scan_service.dart';
import 'package:local_app_tt/services/staff_badge_token.dart';
import 'package:local_app_tt/utils/error_mapper.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scan a file's QR to log a custody event.
///
/// * "Receive" — the signed-in staffer takes the file; only the file is scanned.
/// * "Hand over" — the file is passed to a colleague, who is identified by
///   scanning their personal badge QR (see StaffBadgePage).
class ScanFilePage extends StatefulWidget {
  const ScanFilePage({super.key});

  @override
  State<ScanFilePage> createState() => _ScanFilePageState();
}

class _ScanFilePageState extends State<ScanFilePage> {
  final FileScanService _service = FileScanService.instance;
  late final MobileScannerController _controller;

  String _mode = FileEventType.received;
  List<Department> _departments = [];
  String? _departmentId;

  String? _fileId;
  StaffBadgeToken? _custodian;
  bool _saving = false;

  bool get _needsCustodian => _mode == FileEventType.checkedOut;

  bool get _readyToLog =>
      _fileId != null && (!_needsCustodian || (_custodian != null && !_custodian!.isExpired));

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
    _controller.start();
    _loadDepartments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _service.fetchDepartments();
      if (!mounted) return;
      setState(() => _departments = departments);
    } catch (_) {
      // Departments are optional; ignore load failures.
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_saving || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    final badge = StaffBadgeToken.tryDecode(code);
    if (badge != null) {
      if (!_needsCustodian) {
        _toast('Switch to "Hand over" to assign a file to a colleague.');
        return;
      }
      if (badge.isExpired) {
        _toast('That badge has expired — ask them to refresh it.');
        return;
      }
      if (_custodian?.userId == badge.userId && !_custodian!.isExpired) return;
      setState(() => _custodian = badge);
      _toast('Recipient: ${badge.label}');
      return;
    }

    // Otherwise treat the code as a file identifier.
    if (_fileId == code) return;
    setState(() => _fileId = code);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _confirm() async {
    final fileId = _fileId;
    if (fileId == null || _saving) return;
    if (_needsCustodian && (_custodian == null || _custodian!.isExpired)) {
      _toast('Scan the recipient\'s badge — it may have expired.');
      setState(() => _custodian = null);
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.recordCustodyEvent(
        fileId: fileId,
        eventType: _mode,
        departmentId: _departmentId,
        custodianId: _needsCustodian ? _custodian!.userId : null,
        custodianLabel: _needsCustodian ? _custodian!.label : null,
      );
      if (!mounted) return;
      await _showSuccess(fileId);
    } catch (error) {
      if (!mounted) return;
      _toast('Could not log scan: ${mapSupabaseError(error)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showSuccess(String fileId) async {
    final custodian = _needsCustodian ? _custodian!.label : 'you';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Custody logged'),
        content: Text(
          '${FileEventType.label(_mode)} · file now with $custodian.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FileHistoryPage(fileId: fileId),
                ),
              );
            },
            child: const Text('View history'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() {
                _fileId = null;
                _custodian = null;
              });
            },
            child: const Text('Scan another'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Breadcrumbs(
                    items: [
                      BreadcrumbItem('Home', onTap: () => AppNavigation.goHome(context)),
                      BreadcrumbItem('Scan File', onTap: () => AppNavigation.backOrHome(context)),
                      const BreadcrumbItem('Scan'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        tooltip: 'Back',
                        onPressed: () => AppNavigation.backOrHome(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Scan a File',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Toggle torch',
                        onPressed: () async {
                          await _controller.toggleTorch();
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.flashlight_on_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Receive'),
                        selected: _mode == FileEventType.received,
                        onSelected: (_) => setState(() {
                          _mode = FileEventType.received;
                          _custodian = null;
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('Hand over'),
                        selected: _mode == FileEventType.checkedOut,
                        onSelected: (_) => setState(() => _mode = FileEventType.checkedOut),
                      ),
                    ],
                  ),
                  if (_departments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String?>(
                      value: _departmentId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Department (optional)',
                        prefixIcon: Icon(Icons.apartment_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No department'),
                        ),
                        ..._departments.map(
                          (dept) => DropdownMenuItem<String?>(
                            value: dept.id,
                            child: Text(dept.name),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _departmentId = value),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(controller: _controller, onDetect: _onDetect),
                      Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.primary, width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _fileId == null
                                ? 'Point at the file QR'
                                : _needsCustodian && _custodian == null
                                    ? 'Now scan the recipient\'s badge'
                                    : 'Ready to log',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _StatusRow(
                    icon: Icons.description_outlined,
                    label: 'File',
                    value: _fileId == null ? 'Not scanned' : _shorten(_fileId!),
                    done: _fileId != null,
                  ),
                  if (_needsCustodian) ...[
                    const SizedBox(height: 8),
                    _StatusRow(
                      icon: Icons.badge_outlined,
                      label: 'Recipient',
                      value: _custodian == null ? 'Scan badge' : _custodian!.label,
                      done: _custodian != null && !_custodian!.isExpired,
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _readyToLog && !_saving ? _confirm : null,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label: Text(_saving ? 'Logging…' : 'Log ${FileEventType.label(_mode).toLowerCase()}'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shorten(String value) {
    if (value.length <= 12) return value;
    return '${value.substring(0, 6)}…${value.substring(value.length - 4)}';
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool done;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = done ? Colors.green : theme.hintColor;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text('$label:', style: theme.textTheme.labelLarge?.copyWith(color: theme.hintColor)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: color),
      ],
    );
  }
}
