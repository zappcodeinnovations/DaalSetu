import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_form_screen.dart';
import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:daalsetu/modules/contracts/services/contract_pdf.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Bug 1 & Bug 3: Registered Vehicles Form - RC Number & Document Upload', () {
    testWidgets('RC number field has placeholder e.g., MH31 AB 1234, maxLength 10, and validation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final vehiclesConfig = AdminModules.byKey('vehicles');

      await tester.pumpWidget(
        GetMaterialApp(
          home: AdminRecordFormScreen(config: vehiclesConfig),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Find the RC number TextFormField
      final rcFieldFinder = find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          final decoration = widget.decoration;
          return decoration?.labelText?.contains('RC number') == true;
        }
        return false;
      });

      // Scroll to RC number field if needed
      final scrollableFinder = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(rcFieldFinder, 200, scrollable: scrollableFinder);
      expect(rcFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(rcFieldFinder);

      // Verify hintText placeholder
      expect(textField.decoration?.hintText, equals('e.g., MH31 AB 1234'),
          reason: 'RC number field must show placeholder guidance e.g., MH31 AB 1234');

      // Verify maxLength 10
      expect(textField.maxLength, equals(10),
          reason: 'RC number field must enforce 10-character standard format');
    });

    testWidgets('RC document field shows remove (x) icon when a file is selected and clears on tap',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final vehiclesConfig = AdminModules.byKey('vehicles');

      await tester.pumpWidget(
        GetMaterialApp(
          home: AdminRecordFormScreen(
            config: vehiclesConfig,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final state = tester.state<State>(find.byType(AdminRecordFormScreen));
      // Simulate file selection
      (state as dynamic).setState(() {
        (state as dynamic).filePaths['rc_upload'] = '/path/to/scaled_c03bff0.jpg';
      });
      await tester.pump();

      // Scroll to remove button into viewport
      final removeIconFinder = find.byWidgetPredicate((widget) =>
          widget is IconButton &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.close_rounded);
      await tester.ensureVisible(removeIconFinder);
      await tester.pump(const Duration(milliseconds: 300));
      expect(removeIconFinder, findsOneWidget,
          reason: 'Remove (x) icon must appear when RC document is uploaded');

      // Tap the remove icon button
      await tester.tap(removeIconFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify file is cleared
      expect((state as dynamic).filePaths.containsKey('rc_upload'), isFalse);
    });
  });

  group('Bug 2 & Bug 4: Downloaded Contract PDF Parity', () {
    test('buildContractPdf includes Admin Remark, Buyer GST No., and Seller GST No.', () async {
      final sampleContract = ContractDetailModel.fromJson({
        'id': 101,
        'contract_id': 'CON-20261123-001',
        'product_title': 'YELLOW DAAL',
        'product_category': 'Pulse',
        'interest_id': 'INT-45',
        'deal_quantity': '20',
        'quantity_unit': 'TON',
        'deal_amount': '80000',
        'amount_unit': 'TON',
        'trade_value': '1600000',
        'status': 'confirmed',
        'buyer_id': 'BUY-166',
        'buyer_name': 'rajesh kumar',
        'buyer_company': 'Test company',
        'buyer_mobile': '1234567891',
        'buyer_email': 'athawalehiral@gmail.com',
        'buyer_gst': '22ABCDE1234E1ZA',
        'seller_id': 'SEL-165',
        'seller_name': 'Umesh Rathor',
        'seller_company': 'Agrotech',
        'seller_mobile': '1234567890',
        'seller_email': 'hiral4nov2004@gmail.com',
        'seller_gst': '22ABCDE1234U1ZF',
        'loading_from': 'nagpur',
        'loading_to': 'nagpur',
        'admin_remark': 'Priority fulfillment approved',
        'confirmed_by_admin_name': 'FARMLAND',
        'confirmed_branch_name': 'AMR158M',
        'created_by_user_name': 'FARMLAND',
        'assigned_sub_admin_name': 'FARMLAND',
        'created_at': '2026-11-23 19:43',
        'confirmed_at': '2026-11-23 14:13',
        'ready_for_loading_at': '2026-11-26 11:32',
        'updated_at': '2026-11-26 11:32',
      });

      final doc = buildContractPdf(
        sampleContract,
        'CON-20261123-001',
        deflate: (bytes) => bytes,
      );
      expect(doc, isNotNull);

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);

      final pdfString = String.fromCharCodes(bytes);

      // Verify Buyer GST is in PDF stream
      expect(pdfString.contains('22ABCDE1234E1ZA'), isTrue,
          reason: 'Downloaded PDF must contain Buyer GST No.');

      // Verify Seller GST is in PDF stream
      expect(pdfString.contains('22ABCDE1234U1ZF'), isTrue,
          reason: 'Downloaded PDF must contain Seller GST No.');

      // Verify Administration section & Admin Remark label & text is in PDF stream
      expect(pdfString.contains('Administration'), isTrue,
          reason: 'Downloaded PDF must contain Administration section');
      expect(pdfString.contains('Admin'), isTrue,
          reason: 'Downloaded PDF must contain Admin in Administration section');
      expect(pdfString.contains('Remark'), isTrue,
          reason: 'Downloaded PDF must contain Remark in Administration section');
      expect(pdfString.contains('Priority'), isTrue,
          reason: 'Downloaded PDF must contain Admin Remark value');
    });

    test('buildContractPdf safely handles special characters and em-dash without throwing', () async {
      final contractWithSpecialChars = ContractDetailModel.fromJson({
        'id': 193,
        'contract_id': 'JBC2611239663',
        'product_title': 'toor daal',
        'product_category': 'pukhraj',
        'deal_amount': '₹45.00',
        'amount_unit': 'qtl',
        'trade_value': '₹4509.00000',
        'status': 'confirmed',
        'buyer_id': 'BUY-166',
        'buyer_name': 'rajesh kumar',
        'buyer_company': '“Test” company',
        'seller_id': 'SEL-165',
        'seller_name': 'Umesh Rathor',
        'seller_company': 'Agrotech',
        'admin_remark': 'Order approved — delivery expedited',
        'bag_count': 334,
        'packing_weight_kg': '30.000',
        'deal_quantity': '100.200',
        'quantity_unit': 'qtl',
      });

      final doc = buildContractPdf(
        contractWithSpecialChars,
        'JBC2611239663',
        deflate: (bytes) => bytes,
      );

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);

      final pdfString = String.fromCharCodes(bytes);
      // Words from the remark are rendered in the PDF stream
      expect(pdfString.contains('Order'), isTrue);
      expect(pdfString.contains('expedited'), isTrue);
      // Rupee converted to 'Rs.'
      expect(pdfString.contains('Rs.'), isTrue);
    });
  });
}
