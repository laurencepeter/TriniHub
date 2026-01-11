import 'package:flutter/material.dart';
import 'app_drawer.dart';

class ResponsiveScaffold extends StatelessWidget {
  final void Function(bool) onThemeToggle;
  final Widget Function(String device) childBuilder;

  const ResponsiveScaffold({
    super.key,
    required this.onThemeToggle,
    required this.childBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isDesktop = width >= 1200;

        String deviceType = 'Mobile';
        if (isDesktop) {
          deviceType = 'Desktop';
        } else if (width >= 600) {
          deviceType = 'Tablet';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('$deviceType Layout'),
            automaticallyImplyLeading: !isDesktop,
          ),
          drawer: isDesktop
              ? null
              : AppDrawer(
                  onThemeToggle: onThemeToggle,
                ),
          body: isDesktop
              ? Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: AppDrawer(
                        onThemeToggle: onThemeToggle,
                        isPersistent: true,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: childBuilder(deviceType)),
                  ],
                )
              : childBuilder(deviceType),
        );
      },
    );
  }
}
