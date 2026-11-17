import 'dart:convert';
import 'package:daalsetu/modules/buyer/offers/view/add_buyer_offer_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({'access_token': 'test'}),
  );
  tearDown(Get.reset);

  testWidgets(
    'create form submits description delivery terms remark and selected validity',
    (tester) async {
      Map<String, dynamic>? submitted;
      Finder field(String hint) => find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.hintText == hint,
      );
      Future<void> fill(String hint, String value) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          field(hint),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(field(hint), value);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }

      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            GetMaterialApp(
              home: Scaffold(
                body: TextButton(
                  onPressed: () => Get.to(() => const AddBuyerOfferScreen()),
                  child: const Text('Create'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Create'));
          await tester.pumpAndSettle();
          await fill('Requirement Title (e.g. Need Toor Dal)', 'Need chana');
          await fill('Description (Optional)', 'Detailed requirement');
          await tester.tap(find.text('Select Category'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Chana').last);
          await tester.pumpAndSettle();
          await fill('Quantity', '50');
          await fill('Target Price', '50');
          await fill('Packing (kg)', '50');
          await fill('Delivery Terms (Optional)', 'Deliver next week');
          await fill('Remark (Optional)', 'Call before dispatch');
          await tester.scrollUntilVisible(
            find.text('7 days'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.text('7 days'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('14 days').last);
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('POST REQUIREMENT'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(find.text('POST REQUIREMENT'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('POST REQUIREMENT'));
          await tester.pumpAndSettle();
          expect(submitted?['description'], 'Detailed requirement');
          expect(submitted?['delivery_terms'], 'Deliver next week');
          expect(submitted?['buyer_remark'], 'Call before dispatch');
          expect(submitted?['expiry_days'], '14');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        () => MockClient((request) async {
          if (request.method == 'POST') {
            expect(request.url.path, '/api/rfqs/create/');
            submitted = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(jsonEncode({'success': true}), 201);
          }
          if (request.url.path.contains('parent-dropdown')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {'id': 1, 'category_name': 'Chana'},
                ],
              }),
              200,
            );
          }
          if (request.url.path == '/api/seller/branches/') {
            return http.Response(
              jsonEncode({
                'data': {
                  'my_branches': [
                    {
                      'id': 1,
                      'branch_code': 'TEST',
                      'location_name': 'Test branch',
                    },
                  ],
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({'success': true, 'results': [], 'data': []}),
            200,
          );
        }),
      );
    },
  );
}
