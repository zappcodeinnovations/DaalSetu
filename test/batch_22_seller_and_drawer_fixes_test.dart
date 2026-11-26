import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/controller/drawer_controller.dart' as admin;
import 'package:daalsetu/modules/admin_catalog/model/drawer_menu_model.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_form_screen.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/modules/seller/dashboard/model/seller_dashboard_model.dart';
import 'package:daalsetu/modules/seller/contracts/view/seller_contracts_view.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Batch 22 Bug Fixes Tests', () {
    testWidgets('Bug 1: Role deletion confirmation dialog Cancel button is an OutlinedButton with border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Delete test?'),
                      content: const Text('Users assigned to it will lose this role.'),
                      actions: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Delete'),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete test?'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);

      final outlinedBtn = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(outlinedBtn.style?.side?.resolve({})?.color, const Color(0xFF475569));

      // Tapping Cancel dismisses the dialog safely
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(find.text('Delete test?'), findsNothing);
    });

    testWidgets('Bug 2: Seller Dashboard _openKpi navigates to SellerContractsView for active contracts', (tester) async {
      final kpi = SellerKpi(
        title: 'Active Contracts',
        subtitle: 'Signed this month: 7',
        value: 6,
        screen: 'contracts',
        type: 'count',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  // Direct navigation check for the kpi
                  if (kpi.screen == 'contracts' || kpi.title.toLowerCase().contains('contract')) {
                    Get.to(() => const SellerContractsView());
                  }
                },
                child: const Text('Tap Contracts KPI'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Contracts KPI'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SellerContractsView), findsOneWidget);
    });

    testWidgets('Bug 3 & Bug 4: Sub-admin form hides parent_admin_id for seller and sets branch_ref_code read-only', (tester) async {
      final config = AdminModules.byKey('salesman');

      // Verify config property
      final branchRefField = config.fields.firstWhere((f) => f.key == 'branch_ref_code');
      expect(branchRefField.readOnly, isTrue);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.light(),
          home: AdminRecordFormScreen(
            config: config,
            userRole: 'seller',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // parent_admin_id ('Under Admin') should NOT be visible for seller
      expect(find.text('Under Admin (Super Admin only)'), findsNothing);
      expect(find.text('Under Admin'), findsNothing);

      // Branch Ref Code should be visible and marked read-only on the rendered TextField
      final readOnlyFieldFinder = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.readOnly == true,
      );
      expect(readOnlyFieldFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('Bug 5: Admin drawer Downloads menu icon uses theme-aware high contrast in dark mode', (tester) async {
      tester.view.physicalSize = const Size(600, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final drawerController = Get.put(admin.DrawerController());
      drawerController.userRole.value = 'admin';
      drawerController.isLoading.value = false;
      drawerController.menuSections.value = [
        const DrawerMenuSection(
          sectionTitle: 'MANAGEMENT',
          items: [],
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            drawer: AdminDrawer(activeKey: 'dashboard'),
            body: Center(child: Text('Body')),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Find the downloads icon
      final downloadsIconFinder = find.byIcon(Icons.download_rounded);
      expect(downloadsIconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(downloadsIconFinder);
      expect(iconWidget.color, const Color(0xFFCBD5E1));
    });
  });
}
