import 'package:flutter/material.dart';

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
              mainAxisAlignment: MainAxisAlignment.start,  // Align children to the start
              children: [
                Image.asset(
                  'lib/assets/images/RDLG2.1.png',// Path to your logo image (ensure the logo is in your assets folder)
                  height: 40,           // You can adjust the size as needed
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
              Navigator.pushReplacementNamed(context, '/');
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
            title: const Text('Log Out'),
            leading: const Icon(Icons.logout),
            onTap: () {
              // Handle log out logic here
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
