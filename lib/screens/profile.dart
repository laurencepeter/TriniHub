import 'package:flutter/material.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';

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
              const Breadcrumbs(items: ['Home', 'Profile']),
              const SizedBox(height: 12),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                        child: Icon(Icons.person, color: theme.colorScheme.primary, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jordan Fraser',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Operations Lead · Regional Support',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.verified, color: theme.colorScheme.primary),
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
                      const Divider(height: 24),
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('Role & access'),
                        subtitle: const Text('View assigned departments and permissions.'),
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
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.phone_outlined),
                      title: Text('Primary contact'),
                      subtitle: Text('+1 (868) 555-0198 · jordan.fraser@trinihub.gov'),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.location_on_outlined),
                      title: Text('Base location'),
                      subtitle: Text('Port of Spain Operations Center'),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.emergency_outlined),
                      title: Text('Emergency contact'),
                      subtitle: Text('Sasha Fraser · +1 (868) 555-0110'),
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
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      subtitle: const Text('Choose what updates you receive.'),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      value: false,
                      onChanged: (_) {},
                      secondary: const Icon(Icons.language_outlined),
                      title: const Text('Status visibility'),
                      subtitle: const Text('Let teammates see when you are online.'),
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
                      leading: Icon(Icons.badge_outlined),
                      title: Text('Supervisor'),
                      subtitle: Text('Asha Singh · Director of Operations'),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.groups_outlined),
                      title: Text('Team'),
                      subtitle: Text('Field Ops Alpha · 12 members'),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.event_available_outlined),
                      title: Text('Schedule'),
                      subtitle: Text('Mon-Fri · 8:00 AM - 4:00 PM'),
                    ),
                  ],
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
                        'Assigned departments',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DepartmentChip(label: 'Public Safety'),
                          _DepartmentChip(label: 'Licensing'),
                          _DepartmentChip(label: 'Field Operations'),
                          _DepartmentChip(label: 'Customer Care'),
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
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.devices_outlined),
                      title: Text('Registered devices'),
                      subtitle: Text('2 active devices · Last login 14 minutes ago'),
                      trailing: Icon(Icons.chevron_right),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.shield_outlined),
                      title: Text('Security score'),
                      subtitle: Text('Strong · MFA enabled · Recovery email verified'),
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
                      leading: Icon(Icons.history_toggle_off),
                      title: Text('Recent activity'),
                      subtitle: Text('Reviewed 12 service requests today.'),
                    ),
                    Divider(height: 24),
                    ListTile(
                      leading: Icon(Icons.schedule_outlined),
                      title: Text('Upcoming shift'),
                      subtitle: Text('Wed · 8:00 AM - 4:00 PM (Operations Center)'),
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

class _DepartmentChip extends StatelessWidget {
  final String label;

  const _DepartmentChip({required this.label});

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
