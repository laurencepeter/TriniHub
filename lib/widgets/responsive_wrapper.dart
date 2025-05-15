import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home.dart';
import 'responsive_scaffold.dart';

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
      childBuilder: (device) => HomePage(device: device),
    );
  }
}
