import 'dart:convert';
import 'package:daalsetu/services/buyer_services.dart';
import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({'access_token': 'test'}),
  );

  for (final catalogue in [
    <Map<String, dynamic>>[],
    [
      {'id': 42, 'title': 'Visible product'},
    ],
  ]) {
    test(
      'interest history cannot restore hidden products with ${catalogue.length} visible products',
      () async {
        await http.runWithClient(
          () async {
            final result = await BuyerServices.getAllOffers();
            final offers = result
                .map(
                  (row) =>
                      BuyerOfferModel.fromJson(Map<String, dynamic>.from(row)),
                )
                .toList();
            expect(result.where((row) => row['product_id'] == 186), isEmpty);
            // An RFQ sharing a product ID is a separate entity, routed as a requirement.
            expect(offers.where((row) => row.isRfq).length, 1);
            expect(offers.where((row) => !row.isRfq).length, catalogue.length);
          },
          () => MockClient((request) async {
            final List<Map<String, dynamic>> rows;
            if (request.url.path == '/api/products/') {
              rows = catalogue;
            } else if (request.url.path == '/api/offers/list/') {
              rows = [
                {
                  'interest_id': 7,
                  'product_id': 186,
                  'product_title': 'Hidden product',
                },
                {
                  'interest_id': 8,
                  'product_id': 42,
                  'product_title': 'Visible product',
                },
              ];
            } else {
              rows = [
                {'id': 42, 'title': 'My requirement', 'quantity': '10'},
              ];
            }
            return http.Response(jsonEncode({'results': rows}), 200);
          }),
        );
      },
    );
  }
}
