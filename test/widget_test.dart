// Tests for the navigation stack model and motion primitives.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_app_tt/navigation/app_navigation.dart';
import 'package:local_app_tt/widgets/pressable.dart';
import 'package:local_app_tt/widgets/smooth_page_transitions.dart';

void main() {
  Widget wrap(Widget home) => MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: SmoothPageTransitionsBuilder(),
            },
          ),
        ),
        home: home,
      );

  testWidgets('sections replace each other and keep the root underneath',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                AppNavigation.goToSectionPage(context, const Text('Section A')),
            child: const Text('Root'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Root'));
    await tester.pumpAndSettle();
    expect(find.text('Section A'), findsOneWidget);

    // Opening a second section replaces the first instead of stacking.
    AppNavigation.goToSectionPage(
      tester.element(find.text('Section A')),
      const Text('Section B'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Section B'), findsOneWidget);
    expect(find.text('Section A'), findsNothing);

    // Back from any section lands on the root, never a dead end.
    AppNavigation.backOrHome(tester.element(find.text('Section B')));
    await tester.pumpAndSettle();
    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('backOrHome on the root route is a safe no-op', (tester) async {
    await tester.pumpWidget(wrap(const Text('Root')));
    AppNavigation.backOrHome(tester.element(find.text('Root')));
    await tester.pumpAndSettle();
    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('goHome pops every route above the root', (tester) async {
    await tester.pumpWidget(wrap(const Text('Root')));
    final rootContext = tester.element(find.text('Root'));
    AppNavigation.goToSectionPage(rootContext, const Text('Section'));
    await tester.pumpAndSettle();
    AppNavigation.goToDetail(
      tester.element(find.text('Section')),
      const Text('Detail'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);

    AppNavigation.goHome(tester.element(find.text('Detail')));
    await tester.pumpAndSettle();
    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('Pressable scales down while pressed and springs back',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const Scaffold(
          body: Center(
            child: Pressable(
              child: ColoredBox(
                color: Colors.blue,
                child: SizedBox(width: 100, height: 40),
              ),
            ),
          ),
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Pressable)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      lessThan(1),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });
}
