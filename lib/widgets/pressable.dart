import 'package:flutter/material.dart';
import 'package:local_app_tt/services/theme_settings.dart';

/// Adds an Apple-style springy press response to any tappable child:
/// the widget eases down to [pressedScale] while the pointer is down and
/// springs back on release. Uses raw pointer events so it composes cleanly
/// with an inner InkWell (ripple, focus, and semantics stay intact).
class Pressable extends StatefulWidget {
  final Widget child;
  final double pressedScale;

  const Pressable({
    super.key,
    required this.child,
    this.pressedScale = 0.975,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) {
      setState(() => _pressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final motionDisabled = MediaQuery.of(context).disableAnimations ||
        ThemeSettings.instance.reduceMotion.value;
    if (motionDisabled) {
      return widget.child;
    }
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
