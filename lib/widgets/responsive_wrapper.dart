// responsive_wrapper.dart
import 'package:flutter/material.dart';
import 'package:local_app_tt/widgets/main_shell.dart';

/// Entry point for the signed-in public experience.
///
/// The five top-level sections now live inside a single persistent
/// [MainShell] that keeps their state alive and cross-fades between them, so
/// this wrapper simply hands off to the shell. [onThemeToggle] is retained for
/// call-site compatibility; theming is driven through `ThemeSettings` inside
/// the shell's chrome.
class ResponsiveWrapper extends StatelessWidget {
  final void Function(bool)? onThemeToggle;

  const ResponsiveWrapper({
    super.key,
    this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return const MainShell();
  }
}
