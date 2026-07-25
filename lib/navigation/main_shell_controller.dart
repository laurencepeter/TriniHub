import 'package:flutter/material.dart';

/// Drives the persistent public shell (see `MainShell`).
///
/// The five top-level sections — Home, Services, Internal, External and
/// Settings — live inside a single long-lived shell instead of being separate
/// routes. Switching between them is therefore a change of [index] on this
/// controller rather than a navigation, which is what keeps every section's
/// state (scroll position, open menus, half-filled forms) alive and makes the
/// change a seamless cross-fade instead of a page reload.
///
/// A single shell is ever mounted at a time, so a plain singleton is enough.
/// The controller also remembers the shell's own route, so navigation helpers
/// can pop any detail pages stacked on top of the shell and reveal the chosen
/// tab in one gesture.
class MainShellController {
  MainShellController._();

  /// Shared instance used by both the shell and the navigation helpers.
  static final MainShellController instance = MainShellController._();

  /// The currently visible tab. Section widgets keep their own hard-coded
  /// index (Home = 0 ... Settings = 4); those match these values.
  final ValueNotifier<int> index = ValueNotifier<int>(0);

  Route<dynamic>? _shellRoute;

  /// Whether a public shell is currently on screen. False for the admin and
  /// corporate portals, which don't use the tabbed shell — callers fall back
  /// to ordinary route navigation in that case.
  bool get isActive => _shellRoute != null && _shellRoute!.isActive;

  /// Whether the shell itself is the topmost route (no detail pages stacked on
  /// top of it). Used so an in-section "back" resolves to the Home tab instead
  /// of popping the whole shell off the navigator.
  bool get isForeground => isActive && _shellRoute!.isCurrent;

  /// Whether [route] is the shell's own route. Navigation helpers use this to
  /// make sure the shell is never replaced or removed while collapsing the
  /// stack — doing so would tear down every tab's live state.
  bool ownsRoute(Route<dynamic> route) => identical(_shellRoute, route);

  /// Called by the shell when it mounts so we can pop back to it later.
  void attach(Route<dynamic> route) {
    _shellRoute = route;
  }

  /// Called by the shell when it is torn down (for example on sign-out).
  void detach(Route<dynamic> route) {
    if (identical(_shellRoute, route)) {
      _shellRoute = null;
      index.value = 0;
    }
  }

  /// Reveal [tabIndex] inside the shell, popping any detail pages that sit on
  /// top of it first. Returns false when no shell is mounted so the caller can
  /// fall back to route-based navigation.
  bool openTab(BuildContext context, int tabIndex) {
    final route = _shellRoute;
    if (route == null || !route.isActive) {
      return false;
    }
    if (!route.isCurrent) {
      // Detail pages are stacked above the shell — peel them off so the tab
      // the user asked for is actually visible.
      Navigator.of(context).popUntil((r) => identical(r, route));
    }
    index.value = tabIndex;
    return true;
  }
}
