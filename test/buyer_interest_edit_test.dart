import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';

void main() {
  group('Buyer My Interests Edit Button and API URL Tests', () {
    test('ApiUrls.offerInterestUpdate formats correct endpoint', () {
      expect(
        ApiUrls.offerInterestUpdate(42, 108),
        equals('/api/offers/42/interests/108/update/'),
      );
    });

    test('Offer with status interested parses as interested and editable', () {
      final json = {
        'id': 101,
        'product_id': 55,
        'status': 'interested',
        'title': 'Split Yellow',
        'brand': 'Organic Tattva',
        'buyer_offered_amount': '50.00',
        'buyer_required_quantity': '2.500',
        'loading_to': 'AMR158M, Amalner, Maharashtra, India',
        'loading_from': 'Shop no 12, krishna mandir, Bhopal',
      };

      final offer = BuyerOfferModel.fromJson(json);

      expect(offer.isInterested, isTrue);
      expect(offer.isConfirmed, isFalse);
      expect(offer.displayStatus?.toLowerCase(), equals('interested'));
    });

    test('Offer with deal_confirmed is not marked as editable interest', () {
      final json = {
        'id': 102,
        'product_id': 56,
        'status': 'deal_confirmed',
        'title': 'Polished Fortune',
        'quantity': '10.0',
      };

      final offer = BuyerOfferModel.fromJson(json);

      expect(offer.isConfirmed, isTrue);
      expect(offer.isInterested, isFalse);
    });

    testWidgets('Edit button is rendered when card status is Interested',
        (WidgetTester tester) async {
      final offer = BuyerOfferModel.fromJson({
        'id': 201,
        'product_id': 12,
        'status': 'interested',
        'title': 'Moong Dal',
        'quantity': '10.0',
      });

      final isInterestedCard =
          offer.displayStatus?.trim().toLowerCase() == 'interested' ||
          (offer.status ?? '').trim().toLowerCase() == 'interested' ||
          offer.isInterested ||
          offer.canEditInterest;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('View'),
                ),
                if (isInterestedCard)
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                if (!offer.isConfirmed)
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Negotiation'),
                  ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('View'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Negotiation'), findsOneWidget);
    });

    testWidgets('Edit button is NOT rendered when card status is Deal Confirmed',
        (WidgetTester tester) async {
      final offer = BuyerOfferModel.fromJson({
        'id': 202,
        'product_id': 13,
        'status': 'deal_confirmed',
        'title': 'Polished Fortune',
        'quantity': '10.0',
      });

      final isInterestedCard =
          offer.displayStatus?.trim().toLowerCase() == 'interested' ||
          (offer.status ?? '').trim().toLowerCase() == 'interested' ||
          offer.isInterested ||
          offer.canEditInterest;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('View'),
                ),
                if (isInterestedCard)
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                if (!offer.isConfirmed)
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Negotiation'),
                  ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('View'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Negotiation'), findsNothing);
    });
  });
}
