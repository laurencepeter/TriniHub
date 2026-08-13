import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:local_app_tt/data/service_catalog.dart';
import 'package:local_app_tt/services/bug_report_service.dart';
import 'package:local_app_tt/utils/error_mapper.dart';
import 'package:local_app_tt/utils/validators.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';

/// Real, database-backed "Report a Bug" form shared by the Internal and
/// External service catalogs. Replaces the previous UI-only mock in
/// [ServiceDetailScreen] that discarded whatever the user typed.
class ReportBugScreen extends StatefulWidget {
  final ServiceOption option;

  const ReportBugScreen({super.key, required this.option});

  /// `'internal'` or `'external'`, derived from the catalog category.
  String get scope => option.category.toLowerCase().contains('internal') ? 'internal' : 'external';

  static Route<void> route(ServiceOption option) {
    return MaterialPageRoute(
      builder: (_) => ResponsiveScaffold(
        childBuilder: (device) => ReportBugScreen(option: option),
      ),
    );
  }

  @override
  State<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _moduleController = TextEditingController();
  final _stepsController = TextEditingController();
  final _contactController = TextEditingController();

  BugSeverity _severity = BugSeverity.medium;
  bool _submitting = false;
  bool _submitted = false;
  String? _referenceId;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version}+${info.buildNumber}');
      }
    } catch (_) {
      // Version is best-effort diagnostic context; ignore failures.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _moduleController.dispose();
    _stepsController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // The catalog lists "Module" for internal bugs and "Steps to reproduce" for
  // external ones; surface both labels correctly per scope.
  bool get _isInternal => widget.scope == 'internal';
  String get _moduleLabel => _isInternal ? 'Module' : 'Category';

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final report = await BugReportService.instance.submit(
        scope: widget.scope,
        title: _titleController.text,
        description: _stepsController.text,
        module: _moduleController.text,
        severity: _severity,
        contactEmail: _contactController.text,
        appVersion: _appVersion,
      );
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _referenceId = report.id;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit the bug report: ${mapSupabaseError(error)}')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _moduleController.clear();
    _stepsController.clear();
    _contactController.clear();
    setState(() {
      _severity = BugSeverity.medium;
      _submitted = false;
      _referenceId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final option = widget.option;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              option.accentColor.withOpacity(0.12),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(option: option)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _submitted ? _buildSuccess(theme, option) : _buildForm(theme, option),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, ServiceOption option) {
    return Container(
      key: const ValueKey('bug-form'),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(theme),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bug details',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Your account, device platform and app version are attached automatically.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(theme, 'Bug title'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Please enter a short title.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _moduleController,
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(
                theme,
                _isInternal ? 'Module (e.g. Forms, Scan File)' : 'Category (which service?)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BugSeverity>(
              value: _severity,
              decoration: _fieldDecoration(theme, 'Impact level'),
              items: BugSeverity.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _severity = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stepsController,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: _fieldDecoration(
                theme,
                'Steps to reproduce / what happened',
              ).copyWith(alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactController,
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDecoration(theme, 'Contact email (optional)'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return Validators.email(value);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Please do not include passwords or other sensitive information.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(_submitting ? 'Submitting…' : 'Submit bug report'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: option.accentColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(ThemeData theme, ServiceOption option) {
    return Container(
      key: const ValueKey('bug-success'),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: option.accentColor.withOpacity(0.18),
                child: Icon(Icons.check_rounded, color: option.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bug report logged',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Thanks — your report has been saved and our team has been notified. '
            'You can track it from your reports, and we may follow up by email.',
            style: theme.textTheme.bodyMedium,
          ),
          if (_referenceId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: option.accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 18, color: option.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      'Reference: $_referenceId',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Report another'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(backgroundColor: option.accentColor),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) => BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      );

  InputDecoration _fieldDecoration(ThemeData theme, String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      );
}

class _Header extends StatelessWidget {
  final ServiceOption option;

  const _Header({required this.option});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseAccent = Color.alphaBlend(Colors.black.withOpacity(0.35), option.accentColor);
    final highlightAccent = Color.alphaBlend(Colors.black.withOpacity(0.15), option.accentColor);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: [baseAccent, highlightAccent]),
          boxShadow: [
            BoxShadow(
              color: baseAccent.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    option.category,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(option.icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        option.heroSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
