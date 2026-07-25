import 'package:flutter/material.dart';
import 'package:local_app_tt/navigation/app_navigation.dart';
import 'package:local_app_tt/screens/scan/file_history_page.dart';
import 'package:local_app_tt/screens/scan/scan_file_page.dart';
import 'package:local_app_tt/screens/scan/staff_badge_page.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';

/// Landing screen for the file custody / "Scan File" workflow.
class FileCustodyHub extends StatefulWidget {
  const FileCustodyHub({super.key});

  @override
  State<FileCustodyHub> createState() => _FileCustodyHubState();
}

class _FileCustodyHubState extends State<FileCustodyHub> {
  final TextEditingController _lookupController = TextEditingController();

  @override
  void dispose() {
    _lookupController.dispose();
    super.dispose();
  }

  void _openBadge() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StaffBadgePage()),
    );
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanFilePage()),
    );
  }

  void _lookup() {
    final id = _lookupController.text.trim();
    if (id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FileHistoryPage(fileId: id)),
    );
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
                BreadcrumbItem(
                  'Services',
                  onTap: () => AppNavigation.goToTab(
                    context,
                    AppNavigation.tabServices,
                  ),
                ),
                const BreadcrumbItem('Scan File'),
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
                        'Scan File',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Track who is holding each physical file',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _HowItWorksCard(),
            const SizedBox(height: 16),
            _ActionCard(
              icon: Icons.qr_code_scanner,
              color: theme.colorScheme.primary,
              title: 'Scan a File',
              subtitle: 'Log a file as received by you, or hand it to a colleague.',
              onTap: _openScanner,
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.badge_outlined,
              color: theme.colorScheme.secondary,
              title: 'My Staff Badge',
              subtitle: 'Show your rotating QR so a colleague can pass a file to you.',
              onTap: _openBadge,
            ),
            const SizedBox(height: 20),
            Text(
              'Look up a file',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lookupController,
                    onSubmitted: (_) => _lookup(),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Paste a file ID to view its custody trail',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _lookup,
                  child: const Text('View'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const steps = [
      'Each physical file carries a QR sticker; each staff member has a rotating badge QR.',
      'To take a file, open "Scan a File", pick Receive, and scan the file.',
      'To hand a file over, pick Hand over, scan the file, then scan the recipient\'s badge.',
      'Every scan is logged with who holds the file and who recorded it.',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'How it works',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withOpacity(0.14),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
