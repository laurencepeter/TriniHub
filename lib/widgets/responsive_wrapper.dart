// responsive_wrapper.dart
import 'package:flutter/material.dart';
import 'responsive_scaffold.dart';
import 'package:local_app_tt/screens/home.dart';

class ResponsiveWrapper extends StatelessWidget {
  final void Function(bool) onThemeToggle;

  ResponsiveWrapper({
    super.key,
    void Function(bool)? onThemeToggle,
  }) : onThemeToggle = onThemeToggle ?? _noopThemeToggle;

  static void _noopThemeToggle(bool _) {}

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      onThemeToggle: onThemeToggle,
      childBuilder: (device) => HomePage(
        device: device,
      ),
    );
  }
}
