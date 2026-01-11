import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String device;

  const ProfilePage({
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
              theme.colorScheme.primary.withOpacity(0.08),
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
                'Profile',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your personal details and access preferences for $device.',
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
                    children: [
                      ListTile(
                        leading: const Icon(Icons.account_circle_outlined),
                        title: const Text('Account details'),
                        subtitle: const Text('View your name, role, and contact info.'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                      const Divider(height: 24),
                      ListTile(
                        leading: const Icon(Icons.security_outlined),
                        title: const Text('Security'),
                        subtitle: const Text('Update your password and MFA settings.'),
                        trailing: const Icon(Icons.chevron_right),
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
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text('Choose what updates you receive.'),
                  trailing: const Icon(Icons.tune),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
