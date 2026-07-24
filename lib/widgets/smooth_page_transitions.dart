import 'package:flutter/material.dart';
import 'package:local_app_tt/services/theme_settings.dart';

/// A gentle cross-fade page transition with no white flash.
///
/// The incoming screen simply fades in at full size over the whole duration
/// while the outgoing screen stays fully opaque beneath it. Because the two
/// phases overlap — the old page never disappears before the new one has
/// arrived — the app's canvas colour is never exposed between them. That gap
/// is what used to read as a bright "camera flash" blink, which is especially
/// jarring on a dark theme.
///
/// As extra insurance the fade is painted over the theme's surface colour, so
/// even a single frame can never reveal white: any sliver of background shows
/// the same dark (or light) surface the screens themselves use.
///
/// The incoming page is never scaled below full-screen size, so its edges
/// never pull in to reveal a rectangular border. The whole effect is a quiet
/// dissolve the user is unlikely to consciously notice.
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

    return _CrossFadeTransition(
      animation: animation,
      child: child,
    );
  }
}

/// Implements the overlapping cross-fade described above.
///
/// `animation` drives the page as it enters (0 -> 1) and, in reverse, as it is
/// popped (1 -> 0). Fading only the entering page — and leaving the page below
/// fully opaque — means there is never a moment where both are transparent, so
/// the background is never exposed and there is no flash.
class _CrossFadeTransition extends StatelessWidget {
  const _CrossFadeTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Paint the fade over the theme surface colour rather than the default
    // (white) canvas, so any partially-transparent frame dissolves through the
    // app's own dark/light surface instead of flashing white.
    final Color surface = Theme.of(context).colorScheme.surface;

    return ColoredBox(
      color: surface,
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      ),
    );
  }
}
