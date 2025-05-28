// responsive_wrapper.dart
import 'package:flutter/material.dart';
import 'responsive_scaffold.dart';
import 'package:local_app_tt/screens/home.dart';

class ResponsiveWrapper extends StatelessWidget {
  final bool isDarkMode;
  final void Function(bool) onThemeToggle;

  const ResponsiveWrapper({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      isDarkMode: isDarkMode,
      onThemeToggle: onThemeToggle,
      childBuilder: (device) => HomePage(
        device: device,
        onThemeToggle: () {}, // or pass actual callback
      ),
    );
  }
}
