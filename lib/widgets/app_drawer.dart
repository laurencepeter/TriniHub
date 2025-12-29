import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/qr_scannerpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDrawer extends StatelessWidget {
  final bool isDarkMode;
  final void Function(bool) onThemeToggle;

  const AppDrawer({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
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

          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: onThemeToggle,
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
          ),
          const Divider(),
          ListTile(
            title: const Text('Home'),
            leading: const Icon(Icons.home),
            onTap: () {
              // Navigate to Home Screen
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            title: const Text('Profile'),
            leading: const Icon(Icons.account_circle),
            onTap: () {
              // Navigate to Profile Screen
              Navigator.pushReplacementNamed(context, '/profile');
            },
          ),
          ListTile(
            title: const Text('Settings'),
            leading: const Icon(Icons.settings),
            onTap: () {
              // Navigate to Settings Screen
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
          ListTile(
            title: const Text('About'),
            leading: const Icon(Icons.info),
            onTap: () {
              // Navigate to About Screen
              Navigator.pushReplacementNamed(context, '/about');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Services'),
            leading: const Icon(Icons.info),
            onTap: () {
              // Navigate to Settings Screen
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Internal'),
            leading: const Icon(Icons.integration_instructions),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InternalServices()),
              );
            },
          ),
          ListTile(
            title: const Text('External'),
            leading: const Icon(Icons.outdoor_grill_sharp),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => const QRScannerPage(
                        departmentId: 'default-dept',
                        eventType: 'out',
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
                await Supabase.instance.client.auth.signOut(
                  scope: SignOutScope.global,
                );
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
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
