import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/externalservices.dart';
import 'package:local_app_tt/screens/home.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/services.dart';
import 'package:local_app_tt/services/theme_settings.dart';
import 'package:local_app_tt/services/user_role_service.dart';
import 'package:local_app_tt/widgets/bottom_tab_nav.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';

class SettingsPage extends StatefulWidget {
  final String device;

  const SettingsPage({
    super.key,
    required this.device,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UserRoleService _roleService = UserRoleService();
  bool _compactLayout = true;
  bool _priorityAlerts = true;
  bool _dailySummary = false;
  bool _syncOverWifi = true;
  bool _offlineAccess = true;
  bool _biometrics = true;
  bool _autoLock = true;
  bool _shareUsageData = false;
  bool _reduceMotion = false;
  late Future<UserRoleAssignment?> _assignmentFuture;

  @override
  void initState() {
    super.initState();
    _assignmentFuture = _roleService.fetchCurrentAssignment();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    if (index == 4) {
      return;
    }
    Widget destination;
    switch (index) {
      case 0:
        destination = ResponsiveScaffold(
          childBuilder: (device) => HomePage(device: device),
        );
        break;
      case 1:
        destination = ResponsiveScaffold(
          childBuilder: (device) => ServicesPage(device: device),
        );
        break;
      case 2:
        destination = ResponsiveScaffold(
          childBuilder: (device) => InternalServices(),
        );
        break;
      case 3:
        destination = ResponsiveScaffold(
          childBuilder: (device) => ExternalServices(),
        );
        break;
      default:
        destination = ResponsiveScaffold(
          childBuilder: (device) => HomePage(device: device),
        );
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final showBottomNav = MediaQuery.of(context).size.width < 1200;
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
              Breadcrumbs(
                items: [
                  BreadcrumbItem(
                    'Home',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResponsiveScaffold(
                            childBuilder: (device) => HomePage(device: device),
                          ),
                        ),
                      );
                    },
                  ),
                  const BreadcrumbItem('Settings'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Settings',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Tune the app experience for ${widget.device} and keep workflows consistent.',
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
                      value: isDarkMode,
                      onChanged: (value) => ThemeSettings.instance.setThemeMode(value),
                      secondary: const Icon(Icons.palette_outlined),
                      title: const Text('Appearance'),
                      subtitle: Text(
                        isDarkMode ? 'Dark mode enabled' : 'Light mode enabled',
                      ),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      value: _compactLayout,
                      onChanged: (value) => setState(() => _compactLayout = value),
                      secondary: const Icon(Icons.grid_view_rounded),
                      title: const Text('Compact layout'),
                      subtitle: const Text('Show more data tiles on dashboards.'),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      value: _reduceMotion,
                      onChanged: (value) => setState(() => _reduceMotion = value),
                      secondary: const Icon(Icons.motion_photos_off_outlined),
                      title: const Text('Reduce motion'),
                      subtitle: const Text('Tone down animation and transitions.'),
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
                      value: _priorityAlerts,
                      onChanged: (value) => setState(() => _priorityAlerts = value),
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Priority alerts'),
                      subtitle: const Text('Send push alerts for high-impact requests.'),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      value: _dailySummary,
                      onChanged: (value) => setState(() => _dailySummary = value),
                      secondary: const Icon(Icons.email_outlined),
                      title: const Text('Daily summary email'),
                      subtitle: const Text('Receive a report at 6:00 AM.'),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.language_outlined),
                      title: const Text('Language'),
                      subtitle: const Text('English (Trinidad & Tobago)'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSnack('Language settings opened.'),
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
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Profile details'),
                      subtitle: const Text('Name, role, and contact details.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSnack('Profile details opened.'),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Password & sign-in'),
                      subtitle: const Text('Change password and recovery options.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSnack('Password settings opened.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: FutureBuilder<UserRoleAssignment?>(
                  future: _assignmentFuture,
                  builder: (context, snapshot) {
                    final assignment = snapshot.data;
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: Icon(Icons.admin_panel_settings_outlined),
                        title: Text('Access roles'),
                        subtitle: Text('Loading assigned roles...'),
                        trailing: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (assignment == null) {
                      return const ListTile(
                        leading: Icon(Icons.admin_panel_settings_outlined),
                        title: Text('Access roles'),
                        subtitle: Text('Public access · No role assignments found'),
                      );
                    }
                    final roleLabel = assignment.role.label;
                    final organization = assignment.organization?.trim();
                    final email = assignment.email?.trim();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.admin_panel_settings_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Access roles',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Refresh roles',
                                onPressed: () {
                                  setState(() {
                                    _assignmentFuture = _roleService.fetchCurrentAssignment();
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            assignment.displayName ?? 'Signed-in user',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              roleLabel,
                              if (organization != null && organization.isNotEmpty) organization,
                            ].join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                          ),
                          if (email != null && email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
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
                      value: _syncOverWifi,
                      onChanged: (value) => setState(() => _syncOverWifi = value),
                      secondary: const Icon(Icons.sync_outlined),
                      title: const Text('Sync over Wi-Fi only'),
                      subtitle: const Text('Prevent mobile data from syncing uploads.'),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      value: _offlineAccess,
                      onChanged: (value) => setState(() => _offlineAccess = value),
                      secondary: const Icon(Icons.storage_outlined),
                      title: const Text('Offline access'),
                      subtitle: const Text('Store forms for up to 30 days.'),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.cloud_done_outlined),
                      title: const Text('Last sync'),
                      subtitle: const Text('4 minutes ago · 32 items uploaded'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSnack('Sync activity opened.'),
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
                      value: _biometrics,
                      onChanged: (value) => setState(() => _biometrics = value),
                      secondary: const Icon(Icons.fingerprint),
                      title: const Text('Biometric unlock'),
                      subtitle: const Text('Use fingerprint or Face ID to sign in.'),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      value: _autoLock,
                      onChanged: (value) => setState(() => _autoLock = value),
                      secondary: const Icon(Icons.timer_outlined),
                      title: const Text('Auto-lock'),
                      subtitle: const Text('Lock the app after 5 minutes idle.'),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      value: _shareUsageData,
                      onChanged: (value) => setState(() => _shareUsageData = value),
                      secondary: const Icon(Icons.analytics_outlined),
                      title: const Text('Share usage analytics'),
                      subtitle: const Text('Help improve performance and stability.'),
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
                    ListTile(
                      leading: const Icon(Icons.integration_instructions_outlined),
                      title: const Text('Integrations'),
                      subtitle: const Text('Connect GIS, payroll, and asset systems.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSnack('Integrations opened.'),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('System status'),
                      subtitle: const Text('All systems operational · Next maintenance Fri 9 PM.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSnack('System status opened.'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? BottomNavBar(
              currentIndex: 4,
              onTap: (index) => _handleBottomNavTap(context, index),
            )
          : null,
    );
  }
}
