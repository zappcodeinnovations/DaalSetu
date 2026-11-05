import 'dart:convert';

import 'package:daalsetu/modules/admin_catalog/view/approve_deal_dialog.dart';
import 'package:daalsetu/modules/admin_catalog/view/offer_interests_dialog.dart';
import 'package:daalsetu/modules/admin_catalog/view/negotiation_page.dart';
import 'package:daalsetu/modules/products/model/offer_interest_model.dart';
import 'package:daalsetu/modules/shared/view/offer_interest_negotiation_chat_view.dart';
import 'package:daalsetu/services/product_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test',
      'user_role': 'admin',
    });
  });
  tearDown(() => Get.reset());

  test('terminal decisions override stale server permission flags', () {
    for (final status in [
      'deal_confirmed',
      'rejected',
      'cancelled',
      ' APPROVED ',
    ]) {
      final interest = OfferInterestModel.fromJson({
        'status': status,
        'can_seller_action': true,
        'can_admin_final_action': true,
        'can_seller_reject': true,
      });
      expect(interest.canAcceptForRole(isAdmin: true), isFalse);
      expect(interest.canRejectForRole(isAdmin: true), isFalse);
    }
    final denied = OfferInterestModel.fromJson({
      'status': 'buyer_confirmed',
      'can_admin_final_action': false,
    });
    expect(denied.canAcceptForRole(isAdmin: true), isFalse);
    final allowed = OfferInterestModel.fromJson({
      'status': 'buyer_confirmed',
      'can_admin_final_action': true,
      'is_read_only': true,
    });
    expect(allowed.canAcceptForRole(isAdmin: true), isTrue);
  });

  for (final approve in [true, false]) {
    testWidgets(
      '${approve ? 'approve' : 'reject'} hides completed buttons even if the list refresh is stale',
      (tester) async {
        var decisions = 0;
        await http.runWithClient(
          () async {
            await tester.pumpWidget(
              GetMaterialApp(
                home: const Scaffold(
                  body: OfferInterestsDialog(
                    offerId: '7',
                    offerTitle: 'Test offer',
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('Approve'), findsOneWidget);
            expect(find.text('Reject'), findsOneWidget);
            await tester.tap(find.text(approve ? 'Approve' : 'Reject'));
            await tester.pumpAndSettle();
            if (approve) {
              final context = tester.element(find.byType(ApproveDealDialog));
              Navigator.of(
                context,
              ).pop(ApproveDealResult(remark: 'Reviewed', subAdminId: 9));
            } else {
              await tester.tap(
                find.descendant(
                  of: find.byType(BottomSheet),
                  matching: find.text('Reject'),
                ),
              );
            }
            await tester.pumpAndSettle();
            expect(decisions, 1);
            expect(find.text('Approve'), findsNothing);
            expect(find.text('Reject'), findsNothing);
            expect(
              find.text(approve ? 'deal_confirmed' : 'rejected'),
              findsOneWidget,
            );
            await tester.pump(const Duration(seconds: 10));
            await tester.pumpAndSettle();
            expect(find.text('Approve'), findsNothing);
            expect(find.text('Reject'), findsNothing);
            await tester.pumpWidget(const SizedBox());
            await tester.pumpAndSettle();
          },
          () => MockClient((request) async {
            if (request.method == 'POST') {
              decisions++;
              return http.Response(jsonEncode({'success': true}), 200);
            }
            if (request.url.path.endsWith('/interests/')) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'interests': [
                    {
                      'interest_id': 11,
                      'transaction_id': 'INT-11',
                      'status': 'buyer_confirmed',
                      'buyer_offered_amount': '50',
                      'buyer_required_quantity': '2',
                      'can_admin_final_action': true,
                      'is_read_only': true,
                    },
                  ],
                }),
                200,
              );
            }
            if (request.url.path.contains('sub-admin')) {
              return http.Response(
                jsonEncode({
                  'results': [
                    {'id': 9, 'username': 'Sub Admin'},
                  ],
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'product': {
                  'title': 'Test offer',
                  'quantity': '50',
                  'amount': '50',
                },
              }),
              200,
            );
          }),
        );
      },
    );
  }

  testWidgets('admin chat has no decisions or composer after final approval', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          GetMaterialApp(
            home: OfferInterestNegotiationChatView(
              productId: 7,
              interestId: 11,
              isBuyer: false,
              isAdmin: true,
              onAdminAccept: () async {},
              onAdminReject: () async {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Accept Interest'), findsNothing);
        expect(find.text('Reject'), findsNothing);
        expect(find.text('Submit Negotiation'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
      () => MockClient(
        (request) async => http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'status': 'deal_confirmed',
              'can_admin_final_action': true,
              'can_seller_action': true,
              'can_reply': true,
              'seller_price': '50',
              'available_quantity': '50',
              'messages': [],
            },
          }),
          200,
        ),
      ),
    );
  });

  testWidgets(
    'admin negotiation removes completed actions after server refresh',
    (tester) async {
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            GetMaterialApp(
              home: NegotiationPage(
                offerId: '7',
                offerTitle: 'Test offer',
                interest: OfferInterestModel.fromJson({
                  'interest_id': 11,
                  'status': 'buyer_confirmed',
                  'can_admin_final_action': true,
                }),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Accept'), findsNothing);
          expect(find.text('Reject'), findsNothing);
          expect(find.text('Submit Negotiation'), findsNothing);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
        () => MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'status': 'deal_confirmed',
                'can_admin_final_action': true,
                'can_seller_action': true,
                'can_reply': true,
                'messages': [],
              },
            }),
            200,
          ),
        ),
      );
    },
  );

  test(
    'failed decision response is not treated as a successful approval',
    () async {
      await http.runWithClient(
        () async {
          await expectLater(
            ProductService.confirmOfferDeal(
              productId: 7,
              interestId: 11,
              decision: 'approve',
            ),
            throwsException,
          );
        },
        () => MockClient(
          (_) async => http.Response(
            jsonEncode({'success': false, 'message': 'Not ready'}),
            200,
          ),
        ),
      );
    },
  );
}
