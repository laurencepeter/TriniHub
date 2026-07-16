import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:local_app_tt/services/theme_settings.dart';

/// A compact status pill that reassures users every service lane is online.
///
/// A soft green glow orbits the pill while a status dot gently pulses, so the
/// "live" state reads as something actively running rather than a static
/// label. Honors the OS "disable animations" flag and the in-app
/// "Reduce motion" preference by settling into a calm, steady glow.
class LiveServicesIndicator extends StatefulWidget {
  const LiveServicesIndicator({
    super.key,
    this.label = 'All services live',
    this.sublabel = 'Systems operational',
  });

  final String label;
  final String sublabel;

  @override
  State<LiveServicesIndicator> createState() => _LiveServicesIndicatorState();
}

class _LiveServicesIndicatorState extends State<LiveServicesIndicator>
    with SingleTickerProviderStateMixin {
  static const Color _live = Color(0xFF22C55E);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _motionDisabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations ||
        ThemeSettings.instance.reduceMotion.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = _motionDisabled(context);

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _live.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: _live.withOpacity(0.12),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(controller: _controller, color: _live, animate: !reduceMotion),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                widget.sublabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return IntrinsicWidth(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final angle = reduceMotion ? -math.pi / 3 : _controller.value * 2 * math.pi;
                  return Align(
                    alignment: Alignment(math.cos(angle), math.sin(angle)),
                    child: _GlowBubble(color: _live, dim: reduceMotion),
                  );
                },
              ),
            ),
          ),
          pill,
        ],
      ),
    );
  }
}

class _GlowBubble extends StatelessWidget {
  const _GlowBubble({required this.color, required this.dim});

  final Color color;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(dim ? 0.35 : 0.6),
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  const _PulsingDot({
    required this.controller,
    required this.color,
    required this.animate,
  });

  final AnimationController controller;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = animate ? (math.sin(controller.value * 2 * math.pi) + 1) / 2 : 0.5;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Expanding halo behind the core dot.
              Container(
                width: 8 + t * 6,
                height: 8 + t * 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15 + (1 - t) * 0.2),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.7),
                      blurRadius: 6 + t * 4,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
