import 'package:flutter/material.dart';

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
                  children: const [
                    ListTile(
                      leading: Icon(Icons.palette_outlined),
                      title: Text('Appearance'),
                      subtitle: Text('Adjust theme and layout preferences.'),
                      trailing: Icon(Icons.chevron_right),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.language_outlined),
                      title: Text('Language'),
                      subtitle: Text('Choose your default locale.'),
                      trailing: Icon(Icons.chevron_right),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.sync_outlined),
                      title: Text('Sync'),
                      subtitle: Text('Manage offline access and data refresh.'),
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
                  subtitle: Text('Review uptime and maintenance windows.'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
