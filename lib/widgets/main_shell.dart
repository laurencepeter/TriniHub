import 'package:flutter/material.dart';
import 'package:local_app_tt/navigation/main_shell_controller.dart';
import 'package:local_app_tt/screens/externalservices.dart';
import 'package:local_app_tt/screens/home.dart';
import 'package:local_app_tt/screens/internalservices.dart';
import 'package:local_app_tt/screens/services.dart';
import 'package:local_app_tt/screens/settings.dart';
import 'package:local_app_tt/services/theme_settings.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';

/// The persistent home for a signed-in public user.
///
/// Rather than pushing a fresh route every time the user taps a bottom-nav tab
/// or a drawer section — which rebuilds the whole page and throws its state
/// away, the "refresh" the change used to feel like — all five sections live
/// here together and only their visibility changes. Tapping a tab flips
/// [MainShellController.index]; the shell keeps every visited section alive and
/// cross-fades to the new one, so switching sections feels like the content
/// quietly dissolving in place rather than a page load.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final MainShellController _controller = MainShellController.instance;
  Route<dynamic>? _route;

  // Built once and reused for the life of the shell so each section keeps a
  // stable element (and therefore its state) across tab switches.
  late final List<Widget> _tabs = <Widget>[
    ResponsiveScaffold(childBuilder: (device) => HomePage(device: device)),
    ResponsiveScaffold(childBuilder: (device) => ServicesPage(device: device)),
    ResponsiveScaffold(childBuilder: (device) => InternalServices()),
    ResponsiveScaffold(childBuilder: (device) => ExternalServices()),
    ResponsiveScaffold(childBuilder: (device) => SettingsPage(device: device)),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Remember the route hosting the shell so navigation helpers can pop back
    // to it. Captured here (not in initState) because ModalRoute isn't
    // available until the widget is in the tree.
    final route = ModalRoute.of(context);
    if (route != null && !identical(route, _route)) {
      _route = route;
      _controller.attach(route);
    }
  }

  @override
  void dispose() {
    final route = _route;
    if (route != null) {
      _controller.detach(route);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Honour the OS "disable animations" setting and the in-app "Reduce
    // motion" preference by collapsing the cross-fade to an instant swap. The
    // state-preserving behaviour is unchanged either way.
    final bool reduceMotion = MediaQuery.of(context).disableAnimations ||
        ThemeSettings.instance.reduceMotion.value;

    return ValueListenableBuilder<int>(
      valueListenable: _controller.index,
      builder: (context, index, _) {
        final safeIndex = index.clamp(0, _tabs.length - 1);
        return LazyCrossFadeStack(
          index: safeIndex,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 280),
          children: _tabs,
        );
      },
    );
  }
}

/// Shows one of [children] at a time, cross-fading between them while keeping
/// every page that has been visited alive.
///
/// * **Lazy:** a page's subtree — and so its `initState`, network calls and
///   animations — is created only the first time it is shown, then retained.
/// * **Stateful:** hidden pages stay laid out (scroll offsets, open menus and
///   form input are preserved) but are not painted, and their tickers are
///   muted so background tabs don't animate or consume pointer events.
/// * **Seamless:** the incoming page fades in over the outgoing one, which
///   holds full opacity beneath it until the new page has completely arrived,
///   so no blank or white frame is ever exposed between them.
class LazyCrossFadeStack extends StatefulWidget {
  const LazyCrossFadeStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 280),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<LazyCrossFadeStack> createState() => _LazyCrossFadeStackState();
}

class _LazyCrossFadeStackState extends State<LazyCrossFadeStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<bool> _activated;
  late int _currentIndex;
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _activated = List<bool>.filled(widget.children.length, false);
    _activated[_currentIndex] = true;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1, // the first page is already fully shown
    )
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
  }

  void _onTick() {
    // Repaint as the fade progresses.
    setState(() {});
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _previousIndex != null) {
      // The incoming page fully covers the outgoing one now, so stop painting
      // the outgoing page (it stays alive, just hidden).
      setState(() => _previousIndex = null);
    }
  }

  @override
  void didUpdateWidget(covariant LazyCrossFadeStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = widget.index;
        _activated[_currentIndex] = true;
      });
      _controller
        ..duration = widget.duration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTick)
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color surface = Theme.of(context).colorScheme.surface;
    final bool animating = _previousIndex != null;

    // Paint the current page last (on top) so it fades in over the outgoing
    // page. Keys bind each layer to its page's element, so reordering the list
    // for paint priority never disturbs the pages' state.
    final List<int> order = <int>[
      for (int i = 0; i < widget.children.length; i++)
        if (i != _currentIndex && _activated[i]) i,
      _currentIndex,
    ];

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        for (final i in order) _buildLayer(i, surface, animating),
      ],
    );
  }

  Widget _buildLayer(int i, Color surface, bool animating) {
    final bool isCurrent = i == _currentIndex;
    final bool isPrevious = i == _previousIndex;

    // Incoming page fades 0 -> 1; the outgoing page holds full opacity beneath
    // it until the fade completes; every other kept-alive page stays fully
    // transparent (laid out for state, but never painted).
    final double opacity = isCurrent
        ? (animating ? _controller.value : 1.0)
        : (isPrevious ? 1.0 : 0.0);

    // The wrapper structure is identical for every page (only the flags and
    // opacity differ). This is deliberate: inserting or removing a wrapper for
    // some states would change the subtree shape and make Flutter rebuild the
    // page, throwing away the very state we are trying to keep alive. The
    // ColoredBox surface backing therefore always wraps the page — it is
    // invisible except on a partially faded incoming page, where it stops a
    // half-transparent frame from flashing white.
    return Positioned.fill(
      key: ValueKey<int>(i),
      child: IgnorePointer(
        ignoring: !isCurrent,
        child: TickerMode(
          enabled: isCurrent,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: ColoredBox(
              color: surface,
              child: widget.children[i],
            ),
          ),
        ),
      ),
    );
  }
}
