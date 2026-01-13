import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/about.dart';
import 'package:local_app_tt/screens/home.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/profile.dart';
import 'package:local_app_tt/screens/services.dart';
import 'package:local_app_tt/screens/settings.dart';
import 'package:local_app_tt/screens/qr_scannerpage.dart';
import 'package:local_app_tt/widgets/loginpage.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDrawer extends StatelessWidget {
  final bool isPersistent;

  const AppDrawer({
    super.key,
    this.isPersistent = false,
  });

  @override
  Widget build(BuildContext context) {
    void closeDrawer() {
      if (!isPersistent) {
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
                  'RDLG',
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
          const Divider(),
          ListTile(
            title: const Text('Internal'),
            leading: const Icon(Icons.apartment_rounded),
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
          ListTile(
            title: const Text('External'),
            leading: const Icon(Icons.public_rounded),
            onTap: () {
              closeDrawer();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResponsiveScaffold(
                    childBuilder: (device) => const QRScannerPage(
                      departmentId: 'internal-services',
                      eventType: 'internal',
                    ),
                  ),
                ),
              );
            },
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
