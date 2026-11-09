import 'package:daalsetu/modules/nav_bar/view/nav_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestNavBar({
    EdgeInsets padding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          padding: padding,
          viewInsets: viewInsets,
          size: const Size(400, 800),
        ),
        child: Scaffold(
          bottomNavigationBar: GlassNavBar(
            currentIndex: 0,
            role: 'buyer',
            onTap: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('GlassNavBar adjusts bottom margin to 64px on Android 3-button navigation (bottom: 48)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestNavBar(padding: const EdgeInsets.only(bottom: 48)),
    );
    await tester.pumpAndSettle();

    final containerFinder =
        find.byKey(const Key('floating_glass_nav_bar_container'));
    expect(containerFinder, findsOneWidget);

    final container = tester.widget<Container>(containerFinder);
    expect(container.margin, const EdgeInsets.fromLTRB(16, 0, 16, 64));
  });

  testWidgets('GlassNavBar adjusts bottom margin to 32px on gesture navigation (bottom: 16)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestNavBar(padding: const EdgeInsets.only(bottom: 16)),
    );
    await tester.pumpAndSettle();

    final containerFinder =
        find.byKey(const Key('floating_glass_nav_bar_container'));
    expect(containerFinder, findsOneWidget);

    final container = tester.widget<Container>(containerFinder);
    expect(container.margin, const EdgeInsets.fromLTRB(16, 0, 16, 32));
  });

  testWidgets('GlassNavBar preserves standard 16px bottom margin on desktop/web (bottom: 0)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestNavBar(padding: EdgeInsets.zero),
    );
    await tester.pumpAndSettle();

    final containerFinder =
        find.byKey(const Key('floating_glass_nav_bar_container'));
    expect(containerFinder, findsOneWidget);

    final container = tester.widget<Container>(containerFinder);
    expect(container.margin, const EdgeInsets.fromLTRB(16, 0, 16, 16));
  });

  testWidgets('GlassNavBar does not jump when keyboard opens (viewInsets: 300)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestNavBar(
        padding: const EdgeInsets.only(bottom: 48),
        viewInsets: const EdgeInsets.only(bottom: 300),
      ),
    );
    await tester.pumpAndSettle();

    final containerFinder =
        find.byKey(const Key('floating_glass_nav_bar_container'));
    expect(containerFinder, findsOneWidget);

    final container = tester.widget<Container>(containerFinder);
    expect(container.margin, const EdgeInsets.fromLTRB(16, 0, 16, 16));
  });
}

