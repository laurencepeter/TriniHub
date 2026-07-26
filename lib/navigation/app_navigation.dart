import 'package:flutter/material.dart';
import 'package:local_app_tt/navigation/main_shell_controller.dart';
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

  // Tab indices for the five top-level sections. These line up with the
  // bottom navigation bar items and each section's hard-coded `currentIndex`.
  static const int tabHome = 0;
  static const int tabServices = 1;
  static const int tabInternal = 2;
  static const int tabExternal = 3;
  static const int tabSettings = 4;

  /// Go to the Home tab.
  ///
  /// Inside the public shell this simply selects the Home tab (popping any
  /// detail pages stacked above it first), so no section is rebuilt. Outside
  /// the shell — the admin and corporate portals — it falls back to popping
  /// the navigator back to the signed-in root.
  static void goHome(BuildContext context) {
    if (MainShellController.instance.openTab(context, tabHome)) {
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Reveal one of the five top-level sections by its tab index
  /// (Home = 0 ... Settings = 4).
  ///
  /// When the persistent shell is on screen the section is shown in place —
  /// its state is kept alive and the change cross-fades — instead of pushing a
  /// new route. When it isn't (admin / corporate portals) we fall back to the
  /// route-based section navigation so those flows keep working unchanged.
  static void goToTab(BuildContext context, int tabIndex) {
    if (MainShellController.instance.openTab(context, tabIndex)) {
      return;
    }
    switch (tabIndex) {
      case tabServices:
        goToSection(context, (device) => ServicesPage(device: device));
      case tabInternal:
        goToSection(context, (device) => InternalServices());
      case tabExternal:
        goToSection(context, (device) => ExternalServices());
      case tabSettings:
        goToSection(context, (device) => SettingsPage(device: device));
      case tabHome:
      default:
        Navigator.of(context).popUntil((route) => route.isFirst);
    }
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

  /// Push a page that brings its own shell (gated admin pages, Profile,
  /// Notifications, About, …) so the stack stays shallow — `[root, page]` — and
  /// the change reads as a smooth cross-fade rather than a "refresh".
  ///
  /// Rather than `pushAndRemoveUntil` (which tears the outgoing page down before
  /// the new one animates in, so it dissolves in from the bare root), we keep
  /// the outgoing page painted for the whole transition:
  ///
  /// * On the root, or on the persistent public shell, we `push` so it stays
  ///   mounted underneath. The shell is never replaced — it holds every tab's
  ///   live state — so back returns straight to it.
  /// * On a detail page, we silently drop any pages between the root and the
  ///   current top (never the shell), then `pushReplacement` the still-visible
  ///   top so the two genuinely cross-fade.
  static void goToSectionPage(BuildContext context, Widget page) {
    final navigator = Navigator.of(context);
    final route = MaterialPageRoute<void>(builder: (_) => page);
    final shell = MainShellController.instance;

    final aboveRoot = SectionRouteObserver.instance.routesAboveRoot;
    final PageRoute<dynamic>? top = aboveRoot.isEmpty ? null : aboveRoot.last;
    final bool topIsShell = top != null && shell.ownsRoute(top);

    if (top == null || topIsShell) {
      // Nothing to replace, or the page underneath is the persistent shell —
      // push so the root / shell stays mounted beneath (the shell must never
      // be replaced; it holds every tab's live state). Back returns to it.
      navigator.push(route);
      return;
    }

    // Collapse any pages sitting between the root and the current top — but
    // never the shell — keeping the top (the visible outgoing page) so it can
    // cross-fade. These hidden intermediates are removed invisibly, then the
    // top is replaced, leaving a shallow `[root, page]` stack.
    for (final hidden in aboveRoot.sublist(0, aboveRoot.length - 1)) {
      if (hidden.isActive && !shell.ownsRoute(hidden)) {
        navigator.removeRoute(hidden);
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

  /// Pop when possible, otherwise fall back to the Home tab / root so a back
  /// arrow never turns into a dead tap.
  static void backOrHome(BuildContext context) {
    // When a top-level tab is in the foreground it is not a pushed route, so
    // "back" must return to the Home tab rather than popping the shell (which
    // would drop the user back to the login screen).
    if (MainShellController.instance.isForeground) {
      goHome(context);
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      goHome(context);
    }
  }

  /// Shared handler for the bottom tab bar. Inside the shell each tap simply
  /// selects that tab in place (keeping every section's state alive); outside
  /// it, [goToTab] falls back to route navigation.
  static void handleBottomNavTap(
    BuildContext context,
    int index,
    int currentIndex,
  ) {
    if (index == currentIndex) {
      return;
    }
    goToTab(context, index);
  }
}
