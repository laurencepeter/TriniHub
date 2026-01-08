import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/qr_scannerpage.dart';
import 'package:local_app_tt/widgets/loginpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDrawer extends StatelessWidget {
  final void Function(bool) onThemeToggle;

  const AppDrawer({
    super.key,
    required this.onThemeToggle,
  });

  Route<T> _buildSmoothRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation);
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.04),
          end: Offset.zero,
        ).animate(curvedAnimation);
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            onChanged: (value) {
              onThemeToggle(value);
            },
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Home'),
            leading: const Icon(Icons.home),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            title: const Text('Profile'),
            leading: const Icon(Icons.account_circle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/profile');
            },
          ),
          ListTile(
            title: const Text('Settings'),
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
          ListTile(
            title: const Text('About'),
            leading: const Icon(Icons.info),
            onTap: () {
              Navigator.pop(context);
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
              Navigator.pop(context);
              Navigator.push(
                context,
                _buildSmoothRoute(InternalServices()),
              );
            },
          ),
          ListTile(
            title: const Text('External'),
            leading: const Icon(Icons.outdoor_grill_sharp),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                _buildSmoothRoute(
                  const QRScannerPage(
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
                      builder: (_) => LoginPage(
                        onThemeToggle: onThemeToggle,
                      ),
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
