import 'package:flutter/material.dart';
import 'package:local_app_tt/services/notification_service.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';

class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key});

  @override
  State<NotificationsInboxScreen> createState() => _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  final NotificationService _service = NotificationService.instance;
  late Future<List<AppNotification>> _future;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchInbox(unreadOnly: _unreadOnly);
  }

  void _refresh() {
    setState(() {
      _future = _service.fetchInbox(unreadOnly: _unreadOnly);
    });
  }

  Future<void> _markAll() async {
    await _service.markAllRead();
    _refresh();
  }

  Future<void> _markOne(AppNotification n) async {
    if (n.isRead) return;
    await _service.markRead(n.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Breadcrumbs(items: [BreadcrumbItem('Inbox'), BreadcrumbItem('Notifications')]),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  child: Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Reports assigned to your municipality, status updates, and alerts.',
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
            const SizedBox(height: 12),
            Row(
              children: [
                FilterChip(
                  selected: _unreadOnly,
                  label: const Text('Unread only'),
                  onSelected: (value) {
                    setState(() => _unreadOnly = value);
                    _refresh();
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _markAll,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Mark all read'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<AppNotification>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: 'Notifications unavailable: ${snapshot.error}',
                    onRetry: _refresh,
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return _EmptyState(onRetry: _refresh);
                }
                return Column(
                  children: items
                      .map((n) => _NotificationTile(notification: n, onTap: () => _markOne(n)))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  Color _accent(ThemeData theme) {
    switch (notification.category) {
      case 'civsnap':
        return Colors.orange.shade700;
      case 'form':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.tertiary;
    }
  }

  IconData _icon() {
    switch (notification.category) {
      case 'civsnap':
        return Icons.report_gmailerrorred_outlined;
      case 'form':
        return Icons.description_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accent(theme);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? theme.colorScheme.surface
              : accent.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? theme.dividerColor.withOpacity(0.3)
                : accent.withOpacity(0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accent.withOpacity(0.15),
              child: Icon(_icon(), color: accent, size: 18),
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
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _relativeTime(notification.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                  if (notification.body != null && notification.body!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(notification.body!, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
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
          Icon(Icons.notifications_none, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text('You are all caught up.', style: theme.textTheme.titleSmall),
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
