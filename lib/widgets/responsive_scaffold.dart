import 'package:flutter/material.dart';
import 'app_drawer.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget Function(String device) childBuilder;

  const ResponsiveScaffold({
    super.key,
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
          drawer: isDesktop
              ? null
              : AppDrawer(
                  isPersistent: false,
                ),
          floatingActionButton: isDesktop
              ? null
              : Builder(
                  builder: (context) => FloatingActionButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    child: const Icon(Icons.menu),
                  ),
                ),
          body: isDesktop
              ? Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: AppDrawer(
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
