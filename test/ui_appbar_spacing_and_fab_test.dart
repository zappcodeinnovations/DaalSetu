import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'package:daalsetu/theme/theme_controller.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_activity_view.dart';
import 'package:daalsetu/modules/settings/view/settings_page.dart';
import 'package:daalsetu/modules/category/view/category_page.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    Get.put(ThemeController());
  });

  tearDown(() {
    Get.reset();
  });

  group('AppBar Top Spacing & Leading Width Tests', () {
    testWidgets('AppBarLeading widthFor on unpoppable tab screen returns tight width (46)',
        (WidgetTester tester) async {
      double calculatedWidth = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              calculatedWidth = AppBarLeading.widthFor(context, hasChild: false);
              return Scaffold(
                appBar: AppBar(
                  leading: const AppBarLeading(),
                  leadingWidth: calculatedWidth,
                  title: const Text('My Activity'),
                ),
                body: const SizedBox(),
              );
            },
          ),
        ),
      );

      expect(calculatedWidth, equals(46.0));
      final titleFinder = find.text('My Activity');
      expect(titleFinder, findsOneWidget);

      final titleTopLeft = tester.getTopLeft(titleFinder);
      // Leading width is 46, titleSpacing is 0, so title begins at x = 46.0!
      expect(titleTopLeft.dx, equals(46.0));
    });

    testWidgets('AppBarLeading widthFor guards against hasChild=true when route cannot pop',
        (WidgetTester tester) async {
      double calculatedWidth = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              // Even if caller erroneously passed hasChild: true on a tab root screen:
              calculatedWidth = AppBarLeading.widthFor(context, hasChild: true);
              return Scaffold(
                appBar: AppBar(
                  leading: const AppBarLeading(),
                  leadingWidth: calculatedWidth,
                  title: const Text('Tab Title'),
                ),
                body: const SizedBox(),
              );
            },
          ),
        ),
      );

      // Route cannot pop, so it must not falsely allocate 2 slots (which was 92.0 previously)
      expect(calculatedWidth, equals(46.0));
      final titleTopLeft = tester.getTopLeft(find.text('Tab Title'));
      expect(titleTopLeft.dx, equals(46.0));
    });
  });

  group('Buyer Activity Post Requirement Button Tests', () {
    testWidgets('BuyerActivityView renders Post Requirement FAB with bottom clearance above nav bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            bottomNavigationBar: SizedBox(height: 72),
            body: BuyerActivityView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final fabFinder = find.byKey(const Key('buyer_activity_post_requirement_fab'));
      expect(fabFinder, findsOneWidget);
      expect(find.text('Post Requirement'), findsOneWidget);

      // Verify FAB has bottom padding reserving space for navigation bar
      final paddingFinder = find.ancestor(
        of: find.text('Post Requirement'),
        matching: find.byType(Padding),
      );
      expect(paddingFinder, findsWidgets);

      bool foundNavClearance = false;
      for (final element in tester.widgetList<Padding>(paddingFinder)) {
        if (element.padding is EdgeInsets) {
          final insets = element.padding as EdgeInsets;
          if (insets.bottom >= 104.0) {
            foundNavClearance = true;
            break;
          }
        }
      }
      expect(foundNavClearance, isTrue);
    });
  });

  group('Settings Screen Bottom Spacing Tests', () {
    testWidgets('SettingsScreen has reduced bottom spacing below Version text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: SettingsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final versionFinder = find.text('Version 1.0.0');
      await tester.scrollUntilVisible(versionFinder, 300);
      expect(versionFinder, findsOneWidget);

      // Verify the trailing SizedBox height is 16.0 instead of 80.0
      final listView = tester.widget<ListView>(find.byType(ListView));
      final childrenDelegate = listView.childrenDelegate as SliverChildListDelegate;
      final lastWidget = childrenDelegate.children.last;
      expect(lastWidget, isA<SizedBox>());
      final sizedBox = lastWidget as SizedBox;
      expect(sizedBox.height, equals(16.0));
    });
  });

  group('Category Page Bottom Button Insets Tests', () {
    testWidgets('CategoryPage Send for Approval button has SafeArea wrapping to avoid mobile navigation button overlap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const CategoryPageView(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SEND FOR APPROVAL'), findsOneWidget);
      final safeAreaFinder = find.byType(SafeArea);
      expect(safeAreaFinder, findsWidgets);

      // Find the SafeArea wrapping the bottomNavigationBar button
      final btnFinder = find.text('SEND FOR APPROVAL');
      final btnSafeAreaFinder = find.ancestor(of: btnFinder, matching: find.byType(SafeArea));
      expect(btnSafeAreaFinder, findsOneWidget);
      final safeArea = tester.widget<SafeArea>(btnSafeAreaFinder);
      expect(safeArea.top, isFalse);
      expect(safeArea.bottom, isTrue);
    });
  });
}
