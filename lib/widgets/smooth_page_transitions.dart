import 'package:flutter/material.dart';
import 'package:local_app_tt/services/theme_settings.dart';

/// A gentle cross-fade page transition with no white flash.
///
/// The incoming screen dissolves in over the whole duration while the outgoing
/// screen stays painted directly beneath it. Because the two overlap — the old
/// page is still on screen while the new one materialises on top — you actually
/// see one page melt into the next instead of the content snapping over from a
/// blank canvas. That blank-canvas swap is what used to make navigation feel
/// like a browser "refresh" rather than a smooth in-app transition.
///
/// The theme surface colour is painted *inside* the fade (as the incoming
/// page's own backdrop) rather than behind it. Keeping it inside the fade is
/// what makes the cross-fade real: an opaque backdrop drawn *behind* the fade
/// would hide the outgoing page entirely, collapsing the dissolve back into an
/// instant swap. Because the backdrop fades in together with the page, the
/// outgoing screen shows through the whole time, yet the incoming page is still
/// always backed by the app's own dark (or light) surface, so no single frame
/// can ever reveal white.
///
/// The incoming page is never scaled below full-screen size, so its edges
/// never pull in to reveal a rectangular border. The whole effect is a quiet
/// dissolve the user is unlikely to consciously notice.
///
/// For this to read as a cross-fade the outgoing page must still be on the
/// stack while the incoming one animates in — see [AppNavigation.goToSectionPage],
/// which swaps sections with `pushReplacement` (keeping the outgoing page alive
/// for the transition) instead of tearing it down up front.
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
/// popped (1 -> 0). The entering page (surface backdrop included) fades in over
/// the page still painted beneath it, so the two genuinely overlap: at the
/// mid-point you see roughly half of each, which is what makes the change read
/// as a smooth dissolve rather than an instant swap.
class _CrossFadeTransition extends StatelessWidget {
  const _CrossFadeTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Paint the page over the theme surface colour rather than the default
    // (white) canvas. The backdrop lives *inside* the FadeTransition so it
    // fades in with the page instead of masking the outgoing screen: the old
    // page stays visible through the dissolve, yet the incoming page is never
    // backed by white on any single frame.
    final Color surface = Theme.of(context).colorScheme.surface;

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: ColoredBox(
        color: surface,
        child: child,
      ),
    );
  }
}
