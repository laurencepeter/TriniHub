import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:local_app_tt/services/audit_log_service.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final AuditLogService _service = AuditLogService.instance;
  late Future<List<AuditLogEntry>> _logsFuture;
  Future<List<String>>? _actionsFuture;
  String _actionFilter = 'All';
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _since;

  @override
  void initState() {
    super.initState();
    _logsFuture = _service.fetchLogs();
    _actionsFuture = _service.fetchActions();
  }

  void _refresh() {
    setState(() {
      _logsFuture = _service.fetchLogs(
        action: _actionFilter == 'All' ? null : _actionFilter,
        since: _since,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AuditLogEntry> _applySearch(List<AuditLogEntry> entries) {
    if (_query.trim().isEmpty) return entries;
    final q = _query.toLowerCase();
    return entries.where((entry) {
      return [
        entry.action,
        entry.actorEmail ?? '',
        entry.entityType ?? '',
        entry.entityId ?? '',
        entry.summary ?? '',
      ].join(' ').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Breadcrumbs(items: [
              BreadcrumbItem('Admin'),
              BreadcrumbItem('Audit logs'),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.tertiary.withOpacity(0.15),
                  child: Icon(Icons.fact_check_outlined, color: theme.colorScheme.tertiary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audit logs',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Every change made by admins, corporations, and the system.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search action, actor, entity, summary',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FutureBuilder<List<String>>(
                  future: _actionsFuture,
                  builder: (context, snapshot) {
                    final actions = ['All', ...?snapshot.data];
                    return SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        value: actions.contains(_actionFilter) ? _actionFilter : 'All',
                        decoration: const InputDecoration(
                          labelText: 'Action',
                          border: OutlineInputBorder(),
                        ),
                        items: actions
                            .map((action) => DropdownMenuItem(value: action, child: Text(action)))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _actionFilter = value);
                          _refresh();
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _sinceLabel(),
                    decoration: const InputDecoration(
                      labelText: 'Timeframe',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All time', child: Text('All time')),
                      DropdownMenuItem(value: '24h', child: Text('Last 24 hours')),
                      DropdownMenuItem(value: '7d', child: Text('Last 7 days')),
                      DropdownMenuItem(value: '30d', child: Text('Last 30 days')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        switch (value) {
                          case '24h':
                            _since = DateTime.now().subtract(const Duration(hours: 24));
                            break;
                          case '7d':
                            _since = DateTime.now().subtract(const Duration(days: 7));
                            break;
                          case '30d':
                            _since = DateTime.now().subtract(const Duration(days: 30));
                            break;
                          default:
                            _since = null;
                        }
                      });
                      _refresh();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<AuditLogEntry>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: 'Audit logs unavailable: ${snapshot.error}',
                    onRetry: _refresh,
                  );
                }
                final entries = _applySearch(snapshot.data ?? []);
                if (entries.isEmpty) {
                  return _EmptyState(onRetry: _refresh);
                }
                return Column(
                  children: entries.map((entry) => _AuditLogTile(entry: entry)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _sinceLabel() {
    if (_since == null) return 'All time';
    final diff = DateTime.now().difference(_since!);
    if (diff.inHours <= 25) return '24h';
    if (diff.inDays <= 8) return '7d';
    return '30d';
  }
}

class _AuditLogTile extends StatelessWidget {
  final AuditLogEntry entry;

  const _AuditLogTile({required this.entry});

  Color _accentColor(ThemeData theme) {
    if (entry.action.startsWith('form.')) return theme.colorScheme.primary;
    if (entry.action.startsWith('civsnap.')) return Colors.orange.shade700;
    if (entry.action.startsWith('user.') || entry.action.startsWith('auth.')) {
      return theme.colorScheme.secondary;
    }
    return theme.colorScheme.tertiary;
  }

  IconData _iconFor() {
    if (entry.action.startsWith('form.')) return Icons.description_outlined;
    if (entry.action.startsWith('civsnap.')) return Icons.report_gmailerrorred_outlined;
    if (entry.action.startsWith('user.') || entry.action.startsWith('auth.')) {
      return Icons.person_outline;
    }
    return Icons.fact_check_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentColor(theme);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withOpacity(0.15),
            child: Icon(_iconFor(), color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.action,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(entry.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
                if (entry.summary != null && entry.summary!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(entry.summary!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (entry.actorEmail != null)
                      _Chip(label: entry.actorEmail!, icon: Icons.person_outline),
                    if (entry.actorRole != null)
                      _Chip(label: entry.actorRole!, icon: Icons.badge_outlined),
                    if (entry.entityType != null)
                      _Chip(label: '${entry.entityType}${entry.entityId != null ? ' · ${entry.entityId}' : ''}', icon: Icons.tag),
                  ],
                ),
                if (entry.beforeData != null || entry.afterData != null || entry.metadata != null) ...[
                  const SizedBox(height: 6),
                  _ExpandableJson(
                    before: entry.beforeData,
                    after: entry.afterData,
                    metadata: entry.metadata,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final yyyy = local.year.toString().padLeft(4, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$mi';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.hintColor),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ExpandableJson extends StatefulWidget {
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final Map<String, dynamic>? metadata;

  const _ExpandableJson({this.before, this.after, this.metadata});

  @override
  State<_ExpandableJson> createState() => _ExpandableJsonState();
}

class _ExpandableJsonState extends State<_ExpandableJson> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16),
          label: Text(_expanded ? 'Hide details' : 'Show details'),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24)),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.before != null) ...[
                  Text('Before', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SelectableText(
                    const JsonEncoder.withIndent('  ').convert(widget.before),
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 6),
                ],
                if (widget.after != null) ...[
                  Text('After', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SelectableText(
                    const JsonEncoder.withIndent('  ').convert(widget.after),
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 6),
                ],
                if (widget.metadata != null) ...[
                  Text('Metadata', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SelectableText(
                    const JsonEncoder.withIndent('  ').convert(widget.metadata),
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 36, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'No audit entries match the current filters.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
