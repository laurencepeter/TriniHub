import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/about.dart';
import 'package:local_app_tt/screens/admin_dashboard.dart';
import 'package:local_app_tt/screens/audit_logs.dart';
import 'package:local_app_tt/screens/externalservices.dart';
import 'package:local_app_tt/screens/home.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/notifications_inbox.dart';
import 'package:local_app_tt/screens/profile.dart';
import 'package:local_app_tt/screens/services.dart';
import 'package:local_app_tt/screens/settings.dart';
import 'package:local_app_tt/screens/user_support_hub.dart';
import 'package:local_app_tt/data/service_catalog.dart';
import 'package:local_app_tt/services/user_role_service.dart';
import 'package:local_app_tt/widgets/admin_gate.dart';
import 'package:local_app_tt/widgets/loginpage.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDrawer extends StatefulWidget {
  final bool isPersistent;

  const AppDrawer({
    super.key,
    this.isPersistent = false,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final UserRoleService _roleService = UserRoleService();
  late Future<AppRole> _roleFuture;
  late AppRole _cachedRole;

  @override
  void initState() {
    super.initState();
    _cachedRole = _roleService.cachedRole();
    _roleFuture = _roleService.fetchCurrentRole();
  }

  @override
  Widget build(BuildContext context) {
    void closeDrawer() {
      if (!widget.isPersistent) {
        Navigator.pop(context);
      }
    }

    void navigateTo(Widget page) {
      closeDrawer();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    }

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Align children to the start
              children: [
                Image.asset(
                  'lib/assets/images/TriniHub.png', // Path to your logo image (ensure the logo is in your assets folder)
                  height: 40, // You can adjust the size as needed
                  width: 40,
                ),
                const SizedBox(width: 10), // Spacing between the logo and text
                const Text(
                  'Trini Hub',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    //color: Colors.white,  // You can adjust the text color
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            title: const Text('Home'),
            leading: const Icon(Icons.home_rounded),
            onTap: () {
              navigateTo(
                ResponsiveScaffold(
                  childBuilder: (device) => HomePage(device: device),
                ),
              );
            },
          ),
          FutureBuilder<AppRole>(
            future: _roleFuture,
            initialData: _cachedRole,
            builder: (context, snapshot) {
              final role = snapshot.data ?? AppRole.public;
              final showNotifications = role != AppRole.public;
              final adminSection = role == AppRole.admin
                  ? Column(
                      key: const ValueKey('admin-section'),
                      children: [
                        ListTile(
                          title: const Text('Admin Dashboard'),
                          leading: const Icon(Icons.admin_panel_settings_outlined),
                          onTap: () {
                            navigateTo(
                              AdminGate(
                                child: ResponsiveScaffold(
                                  childBuilder: (device) => AdminDashboardScreen(device: device),
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('User Support Hub'),
                          leading: const Icon(Icons.support_agent_outlined),
                          onTap: () {
                            navigateTo(
                              AdminGate(
                                child: ResponsiveScaffold(
                                  childBuilder: (device) => const UserSupportHubScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Audit Logs'),
                          leading: const Icon(Icons.fact_check_outlined),
                          onTap: () {
                            navigateTo(
                              AdminGate(
                                child: ResponsiveScaffold(
                                  childBuilder: (device) => const AuditLogsScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                      ],
                    )
                  : const SizedBox(
                      key: ValueKey('no-admin-section'),
                    );
              final notificationsTile = showNotifications
                  ? ListTile(
                      key: const ValueKey('notifications-tile'),
                      title: const Text('Notifications'),
                      leading: const Icon(Icons.notifications_outlined),
                      onTap: () {
                        navigateTo(
                          ResponsiveScaffold(
                            childBuilder: (device) => const NotificationsInboxScreen(),
                          ),
                        );
                      },
                    )
                  : const SizedBox(key: ValueKey('no-notifications-tile'));
              return Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: adminSection,
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: notificationsTile,
                  ),
                ],
              );
            },
          ),
          ListTile(
            title: const Text('Profile'),
            leading: const Icon(Icons.person_rounded),
            onTap: () {
              navigateTo(
                ResponsiveScaffold(
                  childBuilder: (device) => ProfilePage(device: device),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Settings'),
            leading: const Icon(Icons.settings_rounded),
            onTap: () {
              navigateTo(
                ResponsiveScaffold(
                  childBuilder: (device) => SettingsPage(device: device),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('About'),
            leading: const Icon(Icons.info_outline_rounded),
            onTap: () {
              navigateTo(
                ResponsiveScaffold(
                  childBuilder: (device) => AboutPage(device: device),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Services'),
            leading: const Icon(Icons.design_services_rounded),
            onTap: () {
              navigateTo(
                ResponsiveScaffold(
                  childBuilder: (device) => ServicesPage(device: device),
                ),
              );
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.apartment_rounded),
            title: const Text('Internal services'),
            children: [
              ListTile(
                title: const Text('All internal services'),
                leading: const Icon(Icons.dashboard_customize_outlined),
                onTap: () {
                  closeDrawer();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResponsiveScaffold(
                        childBuilder: (device) => InternalServices(),
                      ),
                    ),
                  );
                },
              ),
              for (final option in internalServiceOptions)
                ListTile(
                  title: Text(option.label),
                  leading: Icon(option.icon),
                  onTap: () {
                    closeDrawer();
                    handleInternalServiceTap(context, option);
                  },
                ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.public_rounded),
            title: const Text('External services'),
            children: [
              ListTile(
                title: const Text('All external services'),
                leading: const Icon(Icons.dashboard_customize_outlined),
                onTap: () {
                  closeDrawer();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResponsiveScaffold(
                        childBuilder: (device) => ExternalServices(),
                      ),
                    ),
                  );
                },
              ),
              for (final option in externalServiceOptions)
                ListTile(
                  title: Text(option.label),
                  leading: Icon(option.icon),
                  onTap: () {
                    closeDrawer();
                    handleExternalServiceTap(context, option);
                  },
                ),
            ],
          ),
          const Divider(),
          const Divider(),
          ListTile(
            title: const Text('Log Out'),
            leading: const Icon(Icons.logout),
            onTap: () async {
              try {
                final authClient = Supabase.instance.client.auth;
                final session = authClient.currentSession;

                if (session == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No active session. Please log in.')),
                  );
                  return;
                }

                await authClient.signOut(
                  scope: SignOutScope.global,
                );

                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
              }
            },
          ),
        ],
      ),
    );
  }
}
