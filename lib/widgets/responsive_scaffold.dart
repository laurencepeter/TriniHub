import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/settings.dart';
import 'package:local_app_tt/widgets/loginpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_drawer.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget Function(String device) childBuilder;

  const ResponsiveScaffold({
    super.key,
    required this.childBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isDesktop = width >= 1200;

        String deviceType = 'Mobile';
        if (isDesktop) {
          deviceType = 'Desktop';
        } else if (width >= 600) {
          deviceType = 'Tablet';
        }

        return Scaffold(
          drawer: isDesktop
              ? null
              : AppDrawer(
                  isPersistent: false,
                ),
          floatingActionButton: isDesktop
              ? null
              : Builder(
                  builder: (context) => FloatingActionButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    child: const Icon(Icons.menu),
                  ),
                ),
          body: isDesktop
              ? Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: ExcludeFocus(
                        child: FocusTraversalGroup(
                          descendantsAreFocusable: false,
                          child: AppDrawer(
                            isPersistent: true,
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          const _DesktopAccountMenu(),
                          const Divider(height: 1),
                          Expanded(child: childBuilder(deviceType)),
                        ],
                      ),
                    ),
                  ],
                )
              : childBuilder(deviceType),
        );
      },
    );
  }
}

enum _DesktopMenuAction { accountSettings, logout }

class _DesktopAccountMenu extends StatelessWidget {
  const _DesktopAccountMenu();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          PopupMenuButton<_DesktopMenuAction>(
            tooltip: 'Account menu',
            onSelected: (action) async {
              switch (action) {
                case _DesktopMenuAction.accountSettings:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResponsiveScaffold(
                        childBuilder: (device) => SettingsPage(device: device),
                      ),
                    ),
                  );
                  return;
                case _DesktopMenuAction.logout:
                  try {
                    final authClient = Supabase.instance.client.auth;
                    final session = authClient.currentSession;

                    if (session == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No active session. Please log in.'),
                        ),
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
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: $error')),
                    );
                  }
                  return;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _DesktopMenuAction.accountSettings,
                child: Text('Account settings'),
              ),
              PopupMenuItem(
                value: _DesktopMenuAction.logout,
                child: Text('Log out'),
              ),
            ],
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                      child: Icon(
                        Icons.person,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Account',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_more, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
