import 'package:flutter/material.dart';
import 'package:local_app_tt/navigation/app_navigation.dart';
import 'package:local_app_tt/services/file_scan_service.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';

/// Chronological custody trail for a single file.
class FileHistoryPage extends StatefulWidget {
  final String fileId;

  const FileHistoryPage({super.key, required this.fileId});

  @override
  State<FileHistoryPage> createState() => _FileHistoryPageState();
}

class _FileHistoryPageState extends State<FileHistoryPage> {
  final FileScanService _service = FileScanService.instance;
  late Future<List<FileScanEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchFileHistory(widget.fileId);
  }

  void _refresh() {
    setState(() {
      _future = _service.fetchFileHistory(widget.fileId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Breadcrumbs(
              items: [
                BreadcrumbItem('Home', onTap: () => AppNavigation.goHome(context)),
                const BreadcrumbItem('File history'),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File custody trail',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'ID ${widget.fileId}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<FileScanEvent>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _Empty(
                    icon: Icons.error_outline,
                    text: 'Unable to load this file\'s history.',
                  );
                }
                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return _Empty(
                    icon: Icons.history_toggle_off,
                    text: 'No custody events logged for this file yet.',
                  );
                }
                return Column(
                  children: [
                    for (int i = 0; i < events.length; i++)
                      _EventTile(event: events[i], isLatest: i == 0),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final FileScanEvent event;
  final bool isLatest;

  const _EventTile({required this.event, required this.isLatest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isLatest ? theme.colorScheme.primary : theme.hintColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest ? accent.withOpacity(0.4) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withOpacity(0.12),
            child: Icon(_iconFor(event.eventType), color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      FileEventType.label(event.eventType),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Current',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Held by ${event.custodianLabel ?? 'Unknown'}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (event.actorLabel != null && event.actorLabel != event.custodianLabel)
                  Text(
                    'Logged by ${event.actorLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(event.scanTime),
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case FileEventType.received:
      case 'in':
        return Icons.call_received;
      case FileEventType.checkedOut:
      case 'out':
        return Icons.call_made;
      case FileEventType.transferred:
        return Icons.swap_horiz;
      default:
        return Icons.qr_code_scanner;
    }
  }

  String _formatTime(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Empty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.hintColor, size: 32),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
