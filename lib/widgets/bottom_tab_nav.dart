import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withOpacity(0.7),
      showUnselectedLabels: true,
      selectedLabelStyle: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.design_services_rounded),
          label: 'Services',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.apartment_rounded),
          label: 'Internal',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.public_rounded),
          label: 'External',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }
}
