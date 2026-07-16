import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/externalservices.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/services.dart';
import 'package:local_app_tt/screens/settings.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';

/// Central navigation helpers that keep the back stack predictable.
///
/// Stack model:
///   [role home (root)] -> [one section] -> [detail pages...]
///
/// * The signed-in root (public home, admin dashboard, or corp portal)
///   always stays at the bottom of the stack, so the browser/system back
///   button and in-app back arrows always have somewhere sensible to go.
/// * Top-level sections replace each other instead of piling up.
/// * Detail pages stack normally on top of a section.
class AppNavigation {
  AppNavigation._();

  /// Pop everything back to the signed-in root.
  static void goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Open a top-level section wrapped in the responsive shell. Any section
  /// currently on the stack is replaced; the root stays underneath so the
  /// back button returns home instead of dead-ending.
  static void goToSection(
    BuildContext context,
    Widget Function(String device) childBuilder,
  ) {
    goToSectionPage(context, ResponsiveScaffold(childBuilder: childBuilder));
  }

  /// Same as [goToSection] for pages that bring their own shell
  /// (for example gated admin pages).
  static void goToSectionPage(BuildContext context, Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => route.isFirst,
    );
  }

  /// Push a detail page on top of the current stack.
  static void goToDetail(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Pop when possible, otherwise fall back to the root so a back arrow
  /// never turns into a dead tap.
  static void backOrHome(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      goHome(context);
    }
  }

  /// Shared handler for the bottom tab bar. Tabs never stack on each
  /// other: Home pops to the root and every other tab swaps the current
  /// section, keeping the root underneath for back navigation.
  static void handleBottomNavTap(
    BuildContext context,
    int index,
    int currentIndex,
  ) {
    if (index == currentIndex) {
      return;
    }
    switch (index) {
      case 1:
        goToSection(context, (device) => ServicesPage(device: device));
      case 2:
        goToSection(context, (device) => InternalServices());
      case 3:
        goToSection(context, (device) => ExternalServices());
      case 4:
        goToSection(context, (device) => SettingsPage(device: device));
      case 0:
      default:
        goHome(context);
    }
  }
}
