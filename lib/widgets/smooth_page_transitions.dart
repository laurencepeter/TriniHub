import 'package:flutter/material.dart';
import 'package:local_app_tt/services/theme_settings.dart';

/// A Material "fade through" page transition.
///
/// Peer screens (the top-level sections such as Internal Services and
/// External Services) and detail pages cross-dissolve into place: the
/// outgoing screen simply fades out — it never shrinks, dims into a card,
/// or looks like a "minimized" page with a fresh page dropped on top — while
/// the incoming screen fades in at full size. The two phases are staggered so
/// there is no muddy double-exposure in the middle: the old page is gone
/// before the new one arrives, which is what makes the change feel silky
/// rather than layered.
///
/// Crucially the incoming page is never scaled below full-screen size. A
/// scaled-down page pulls its edges in from the screen border and exposes the
/// route beneath it, which reads as a rectangular "border" — as if a smaller
/// page had been dropped on top of another. Keeping the page at full size
/// throughout means the change is a clean dissolve with no visible seam.
///
/// Honors both the OS-level "disable animations" accessibility setting and
/// the in-app "Reduce motion" preference by falling back to a plain fade.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations ||
        ThemeSettings.instance.reduceMotion.value) {
      return FadeTransition(opacity: animation, child: child);
    }

    return _FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

/// Implements the two-phase fade-through described above.
///
/// * `animation` drives the page while it is entering (0 -> 1).
/// * `secondaryAnimation` drives the same page while a newer route is being
///   pushed on top of it (0 -> 1), so it must fade this page back out.
class _FadeThroughTransition extends StatelessWidget {
  const _FadeThroughTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Incoming: hold transparent for the first ~35% (while the previous page
    // finishes fading out) then ease in at full size. No scaling — the page
    // always fills the screen, so its edges never pull in to reveal a border.
    final CurvedAnimation enter = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );

    // Outgoing (covered by a newer route): fade out over the first ~35% and
    // stay hidden, with no scaling so it never reads as a shrinking card.
    final Animation<double> exit = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0, 0.35, curve: Curves.easeIn),
      ),
    );

    return FadeTransition(
      opacity: exit,
      child: FadeTransition(
        opacity: enter,
        child: child,
      ),
    );
  }
}
