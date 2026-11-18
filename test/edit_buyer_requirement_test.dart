import 'dart:convert';
import 'package:daalsetu/modules/buyer/offers/view/edit_buyer_requirement_view.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_request_management_view.dart';
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
  const requirement = {
    'id': 101,
    'title': 'My expired requirement',
    'status': 'expired',
    'required_quantity': '10',
    'quantity_unit': 'qtl',
    'target_price': '50',
    'price_unit': 'qtl',
  };

  testWidgets('edit form sends updates to the existing requirement API', (
    tester,
  ) async {
    Map<String, dynamic>? submitted;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          const GetMaterialApp(
            home: EditBuyerRequirementView(requirement: requirement),
          ),
        );
        expect(find.text('My expired requirement'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField).first,
          'Updated requirement',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Save Changes'), 300, scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(find.text('Save Changes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();
        expect(submitted?['action'], 'update');
        expect(submitted?['title'], 'Updated requirement');
        expect(submitted?['expiry_days'], 7);
        expect(submitted?['required_quantity'], '10');
        await tester.pumpWidget(const SizedBox.shrink());
      },
      () => MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/buyer-requirements/101/');
        submitted = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'success': true}), 200);
      }),
    );
  });

  for (final canEdit in [true, false]) {
    testWidgets('requirement card respects backend edit permission $canEdit', (
      tester,
    ) async {
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            const GetMaterialApp(
              home: BuyerRequestManagementView(
                mode: BuyerRequestMode.requirements,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('My expired requirement'), findsOneWidget);
          expect(
            find.widgetWithText(OutlinedButton, 'Edit'),
            canEdit ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        () => MockClient(
          (request) async => http.Response(
            jsonEncode({
              'success': true,
              'results': [
                {
                  ...requirement,
                  'permissions': {'is_buyer': true, 'can_edit': canEdit},
                },
              ],
              'data': {},
              'pagination': {'has_next': false},
            }),
            200,
          ),
        ),
      );
    });
  }
}
