import 'package:flutter/material.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';

class SettingsPage extends StatelessWidget {
  final String device;

  const SettingsPage({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.secondary.withOpacity(0.08),
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
              const Breadcrumbs(items: ['Home', 'Settings']),
              const SizedBox(height: 12),
              Text(
                'Settings',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Tune the app experience for $device and keep workflows consistent.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: true,
                      onChanged: (_) {},
                      secondary: const Icon(Icons.palette_outlined),
                      title: const Text('Appearance'),
                      subtitle: const Text('Use the standard light/dark theme pairing.'),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      value: true,
                      onChanged: (_) {},
                      secondary: const Icon(Icons.grid_view_rounded),
                      title: const Text('Compact layout'),
                      subtitle: const Text('Show more data tiles on dashboards.'),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.language_outlined),
                      title: const Text('Language'),
                      subtitle: const Text('English (Trinidad & Tobago)'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: true,
                      onChanged: (_) {},
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Priority alerts'),
                      subtitle: const Text('Send push alerts for high-impact requests.'),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      value: false,
                      onChanged: (_) {},
                      secondary: const Icon(Icons.email_outlined),
                      title: const Text('Daily summary email'),
                      subtitle: const Text('Receive a report at 6:00 AM.'),
                    ),
                  ],
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
                      leading: Icon(Icons.sync_outlined),
                      title: Text('Sync'),
                      subtitle: Text('Last updated 4 minutes ago.'),
                      trailing: Icon(Icons.chevron_right),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.storage_outlined),
                      title: Text('Offline access'),
                      subtitle: Text('Store forms for up to 30 days.'),
                      trailing: Icon(Icons.chevron_right),
                    ),
                  ],
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
                      leading: Icon(Icons.lock_outline),
                      title: Text('Security controls'),
                      subtitle: Text('Review device trust and login sessions.'),
                      trailing: Icon(Icons.chevron_right),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.integration_instructions_outlined),
                      title: Text('Integrations'),
                      subtitle: Text('Connect GIS, payroll, and asset systems.'),
                      trailing: Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('System status'),
                  subtitle: Text('All systems operational · Next maintenance Fri 9 PM.'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
