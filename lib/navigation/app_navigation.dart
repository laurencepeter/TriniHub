import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/externalservices.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/services.dart';
import 'package:local_app_tt/screens/settings.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';

/// Tracks the live page-route stack for the root navigator.
///
/// [AppNavigation.goToSectionPage] needs to know which routes currently sit
/// between the signed-in root and the page the user is looking at so it can
/// collapse the detail pages while leaving the outgoing section on screen for
/// the cross-fade. The framework doesn't expose the route list, so we mirror it
/// here by observing pushes, pops, removals and replacements.
///
/// Only [PageRoute]s are tracked; transient routes like dialogs and popup
/// menus are ignored so an open menu never looks like a page on the stack.
class SectionRouteObserver extends NavigatorObserver {
  SectionRouteObserver._();

  /// Shared instance wired into `MaterialApp.navigatorObservers`.
  static final SectionRouteObserver instance = SectionRouteObserver._();

  final List<PageRoute<dynamic>> _stack = <PageRoute<dynamic>>[];

  /// Page routes currently sitting above the signed-in root, ordered
  /// bottom-to-top. Empty when only the root is on screen.
  List<PageRoute<dynamic>> get routesAboveRoot =>
      _stack.length <= 1 ? const [] : _stack.sublist(1);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _stack.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _stack.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _stack.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute is! PageRoute) return;
    final index = _stack.indexOf(oldRoute);
    if (index < 0) return;
    if (newRoute is PageRoute) {
      _stack[index] = newRoute;
    } else {
      _stack.removeAt(index);
    }
  }
}

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
  ///
  /// The stack always ends up as `[root, section]`, but *how* we get there is
  /// what makes the switch feel smooth. Rather than `pushAndRemoveUntil`, which
  /// tears the outgoing section down before the new one animates in (leaving
  /// the incoming page to dissolve in from the bare root — the "refresh" look),
  /// we keep the outgoing page painted for the whole transition:
  ///
  /// * From the root itself, we `push` so the root stays underneath.
  /// * From a section (possibly with detail pages stacked on top), we silently
  ///   drop the hidden detail pages, then `pushReplacement` the still-visible
  ///   section. `pushReplacement` keeps that outgoing page alive until the new
  ///   one has finished animating in, so the two genuinely cross-fade.
  static void goToSectionPage(BuildContext context, Widget page) {
    final navigator = Navigator.of(context);
    final route = MaterialPageRoute<void>(builder: (_) => page);

    if (!navigator.canPop()) {
      // Only the root is on screen — push so it stays beneath the new section
      // and the back button still returns home.
      navigator.push(route);
      return;
    }

    // Collapse any detail pages sitting between the root and the current top,
    // keeping the top (the visible outgoing page) so it can cross-fade. These
    // intermediate routes are hidden beneath the opaque top, so removing them
    // now is invisible.
    final aboveRoot = SectionRouteObserver.instance.routesAboveRoot;
    if (aboveRoot.length > 1) {
      for (final hidden in aboveRoot.sublist(0, aboveRoot.length - 1)) {
        if (hidden.isActive) navigator.removeRoute(hidden);
      }
    }

    navigator.pushReplacement(route);
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
