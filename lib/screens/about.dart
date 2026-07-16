import 'package:flutter/material.dart';
import 'package:local_app_tt/navigation/app_navigation.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatelessWidget {
  final String device;

  const AboutPage({
    super.key,
    required this.device,
  });

  Future<String> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    if (version.isEmpty) {
      return '';
    }
    return 'Trini Hub · Version $version';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.06),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Breadcrumbs(
                items: [
                  BreadcrumbItem(
                    'Home',
                    onTap: () => AppNavigation.goHome(context),
                  ),
                  const BreadcrumbItem('About'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'About',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Trini Hub aligns internal and external services in one view on $device.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: _loadVersion(),
                        builder: (context, snapshot) {
                          final label = snapshot.data ?? '';
                          return Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A unified dashboard for municipal teams to coordinate requests, scan assets, '
                        'and keep public services moving.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(label: 'Live service intake'),
                          _InfoChip(label: 'Offline-ready forms'),
                          _InfoChip(label: 'Secure role access'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mission',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deliver a calm, accessible workspace for tracking requests, scanning assets, and '
                        'launching service workflows.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Support',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reach the operations team for guidance on service policies and data security.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'What\'s inside',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Internal service tooling, external request intake, live status dashboards, and '
                        'auditable approval workflows.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.shield_outlined),
                      title: Text('Compliance-first'),
                      subtitle: Text('Built to keep operational data secure and readable.'),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.groups_outlined),
                      title: Text('Designed for teams'),
                      subtitle: Text('Role-based access for operations, field staff, and leadership.'),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.support_agent_outlined),
                      title: Text('Support coverage'),
                      subtitle: Text('Mon-Sat · 7:00 AM - 7:00 PM'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
