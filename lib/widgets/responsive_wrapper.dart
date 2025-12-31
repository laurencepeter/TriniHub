// responsive_wrapper.dart
import 'package:flutter/material.dart';
import 'responsive_scaffold.dart';
import 'package:local_app_tt/screens/home.dart';

class ResponsiveWrapper extends StatelessWidget {
  final void Function(bool) onThemeToggle;
  final bool isDarkMode;

  const ResponsiveWrapper({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      onThemeToggle: onThemeToggle,
      isDarkMode: isDarkMode,
      childBuilder: (device) => HomePage(
        device: device,
      ),
    );
  }
}
