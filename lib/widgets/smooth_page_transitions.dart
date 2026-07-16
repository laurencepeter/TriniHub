import 'package:flutter/material.dart';
import 'package:local_app_tt/services/theme_settings.dart';

/// Depth-style page transition inspired by iOS navigation:
/// the incoming page fades in while drifting up a few points, and the
/// outgoing page recedes with a subtle scale-down and dim, so screens feel
/// layered instead of swapped.
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

    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final exit = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInOutCubic,
    );

    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(enter),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1, end: 0.96).animate(exit),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0.65).animate(exit),
            child: child,
          ),
        ),
      ),
    );
  }
}
