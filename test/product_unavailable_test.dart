import 'dart:convert';

import 'package:daalsetu/modules/products/view/product_detail.dart';
import 'package:daalsetu/modules/seller/notifications/model/notification_model.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/services/product_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({'access_token': 'test'}),
  );

  test('interest reference cannot override its product link', () {
    final notification = AppNotificationModel(
      type: 'interest',
      referenceId: 186,
      redirectUrl: '/offers/?manage_product=42#manage-interest-block',
    );
    expect(notification.productTargetId, 42);
    expect(
      AppNotificationModel(type: 'interest', referenceId: 186).productTargetId,
      isNull,
    );
    expect(
      AppNotificationModel(
        type: 'product',
        referenceId: 186,
        redirectUrl: '/products/42/',
      ).productTargetId,
      42,
    );
    expect(
      AppNotificationModel(type: 'product', referenceId: 186).productTargetId,
      186,
    );
    expect(
      AppNotificationModel(
        type: 'interest',
        referenceId: 186,
        relatedProduct: 7,
        redirectUrl: '/products/42/',
      ).productTargetId,
      7,
    );
  });

  test('product 404 retains its status for the screen', () async {
    await http.runWithClient(
      () async {
        await expectLater(
          ProductService.getProductDetail(186, silent: true),
          throwsA(
            isA<ApiRequestException>().having(
              (e) => e.statusCode,
              'status',
              404,
            ),
          ),
        );
      },
      () => MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': 'No Product matches the given query.',
            'detail': 'Not found.',
          }),
          404,
        ),
      ),
    );
  });

  for (final status in [404, 500]) {
    testWidgets('product $status displays an inline state', (tester) async {
      var calls = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const ProductDetailScreen(productId: 186),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          if (status == 404) {
            expect(find.text('Product unavailable'), findsOneWidget);
            expect(find.text('Retry'), findsNothing);
            await tester.tap(find.text('Go back'));
            await tester.pumpAndSettle();
            expect(find.text('Open'), findsOneWidget);
          } else {
            expect(find.text('Could not load product'), findsOneWidget);
            await tester.tap(find.text('Retry'));
            await tester.pumpAndSettle();
            expect(calls, 2);
          }
          expect(tester.takeException(), isNull);
        },
        () => MockClient((_) async {
          calls++;
          return http.Response(jsonEncode({'detail': 'Not found.'}), status);
        }),
      );
    });
  }
}
