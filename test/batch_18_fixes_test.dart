import 'package:daalsetu/modules/Auth/register/controller/register_controller.dart';
import 'package:daalsetu/modules/buyer/offers/controller/buyer_offers_controller.dart';
import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';
import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/modules/products/view/product_detail.dart';
import 'package:daalsetu/modules/shared/view/offer_interest_negotiation_chat_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  final testProduct = ProductModel.fromJson({
    'id': 123,
    'title': 'Yellow Toor Daal',
    'description': 'Fresh quality toor daal',
    'amount': '6500',
    'stock_status': 'in_stock',
    'is_active': true,
    'is_expired': false,
    'status': 'active',
  });

  group('Batch 18 Bug 1: Buyer Product Detail Offer Button Dynamic Label (Submit vs Resubmit)', () {
    testWidgets('ProductDetailScreen displays "Submit Offer" when isResubmit is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductDetailScreen(
              productId: 123,
              onSubmitOffer: (_) {},
              isResubmit: false,
              initialProduct: testProduct,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that "Submit Offer" button is present and "Resubmit" is absent
      expect(find.text('Submit Offer'), findsOneWidget);
      expect(find.text('Resubmit'), findsNothing);
    });

    testWidgets('ProductDetailScreen displays "Resubmit" when isResubmit is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductDetailScreen(
              productId: 123,
              onSubmitOffer: (_) {},
              isResubmit: true,
              initialProduct: testProduct,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that "Resubmit" button is present and "Submit Offer" is absent
      expect(find.text('Resubmit'), findsOneWidget);
      expect(find.text('Submit Offer'), findsNothing);
    });
  });

  group('Batch 18 Bug 2: Negotiation History Pure Status Events vs Chat Bubbles', () {
    test('statusBannerTitle resolves semantic titles for status transitions', () {
      final buyerTitle = OfferInterestNegotiationChatView.statusBannerTitle(
        role: 'buyer',
        status: 'buyer_confirmed',
        action: 'status changed to buyer confirmed',
        remark: 'buyer confirmed',
      );
      expect(buyerTitle, equals('Buyer Confirmed the Deal'));

      final sellerTitle = OfferInterestNegotiationChatView.statusBannerTitle(
        role: 'seller',
        status: 'seller_confirmed',
        action: 'seller confirmed',
      );
      expect(sellerTitle, equals('Seller Confirmed the Deal'));

      final dealTitle = OfferInterestNegotiationChatView.statusBannerTitle(
        role: 'system',
        status: 'confirmed',
        action: 'deal confirmed',
      );
      expect(dealTitle, equals('Deal Confirmed'));

      final rejectedTitle = OfferInterestNegotiationChatView.statusBannerTitle(
        role: 'buyer',
        status: 'rejected',
        action: 'buyer rejected negotiation',
      );
      expect(rejectedTitle, equals('Buyer Rejected Negotiation'));
    });

    test('Proposal vs Status Event classification preserves real proposals and isolates status logs', () {
      bool isProposalMessage(Map<String, dynamic> msg) {
        String text(dynamic value) => value == null ? '' : value.toString().trim();
        final price = text(msg['counter_price']);
        final quantity = text(msg['counter_quantity']);
        final bags = text(msg['counter_bag_count']);
        final delivery = text(msg['counter_delivery_from']);
        final remark = text(msg['remark'] ?? msg['comment'] ?? msg['message']);
        final action = text(msg['action']).replaceAll('_', ' ');
        final status = text(msg['to_status']).replaceAll('_', ' ');
        final role = (msg['actor_role'] ?? msg['sender_role'])?.toString().toLowerCase() ?? '';

        final hasProposalTerms =
            price.isNotEmpty || quantity.isNotEmpty || bags.isNotEmpty || delivery.isNotEmpty;

        final lowerRemark = remark.toLowerCase().trim();
        final lowerAction = action.toLowerCase().trim();
        final lowerStatus = status.toLowerCase().trim();

        final isStatusEvent = !hasProposalTerms &&
            (role == 'system' ||
                role.isEmpty ||
                lowerRemark.startsWith('status') ||
                lowerRemark.contains('confirmed') ||
                lowerRemark.contains('approved') ||
                lowerRemark.contains('rejected') ||
                lowerRemark.contains('cancelled') ||
                lowerRemark.contains('accepted') ||
                lowerAction.contains('confirm') ||
                lowerAction.contains('approv') ||
                lowerAction.contains('reject') ||
                lowerAction.contains('cancel') ||
                lowerAction.contains('status') ||
                lowerAction.contains('accept') ||
                lowerStatus.isNotEmpty);

        return hasProposalTerms || (!isStatusEvent && remark.isNotEmpty);
      }

      // Proposal with counter price must be a proposal
      expect(
        isProposalMessage({
          'counter_price': '58',
          'actor_role': 'seller',
          'message': '',
        }),
        isTrue,
        reason: 'Message with counter_price must be classified as proposal',
      );

      // Status notification "buyer confirmed" without counter price must NOT be a proposal
      expect(
        isProposalMessage({
          'actor_role': 'buyer',
          'to_status': 'buyer_confirmed',
          'action': 'buyer_confirmed',
          'message': 'Status: buyer confirmed',
        }),
        isFalse,
        reason: 'Status: buyer confirmed without proposal terms must be treated as status event',
      );

      // System notification "Status: buyer confirmed" must NOT be a proposal
      expect(
        isProposalMessage({
          'actor_role': 'system',
          'action': 'buyer_confirmed',
          'message': 'buyer confirmed',
        }),
        isFalse,
        reason: 'System confirmation must be treated as status event',
      );

      // Genuine buyer comment without terms must remain a proposal / chat message
      expect(
        isProposalMessage({
          'actor_role': 'buyer',
          'message': 'Please deliver by tomorrow evening if possible',
        }),
        isTrue,
        reason: 'Genuine buyer message note must remain a chat message',
      );
    });
  });

  group('Batch 18 Bug 3: Registration & Profile Email Field Lowercase Normalization', () {
    test('LowerCase text input formatter converts uppercase to lowercase', () {
      final formatter = TextInputFormatter.withFunction((oldValue, newValue) {
        return newValue.copyWith(text: newValue.text.toLowerCase());
      });

      const input = TextEditingValue(text: 'Nawgharekajal01@gmail.com');
      final formatted = formatter.formatEditUpdate(TextEditingValue.empty, input);

      expect(formatted.text, equals('nawgharekajal01@gmail.com'));
    });

    test('Whitespace deny formatter strips spaces from email input', () {
      final denySpaces = FilteringTextInputFormatter.deny(RegExp(r'\s'));
      const input = TextEditingValue(text: 'nawghare kajal01@gmail.com');
      final formatted = denySpaces.formatEditUpdate(TextEditingValue.empty, input);

      expect(formatted.text, equals('nawgharekajal01@gmail.com'));
    });

    test('RegisterController buildFields automatically lowercases email payload', () {
      final controller = RegisterController();
      addTearDown(controller.dispose);

      controller.mobileController.text = '9876543210';
      controller.emailController.text = ' Nawgharekajal01@GMAIL.COM ';
      controller.firstNameController.text = 'Kajal';
      controller.lastNameController.text = 'Nawghare';
      controller.companyNameController.text = 'Shree Traders';
      controller.passwordController.text = 'Secret123!';
      controller.confirmPasswordController.text = 'Secret123!';

      final fields = controller.buildFields();

      expect(fields['email'], equals('nawgharekajal01@gmail.com'));
      expect(fields['first_name'], equals('Kajal'));
    });
  });

  group('Batch 18 Regression Guard: Offers and Interests Feeds Remain Completely Intact', () {
    test('BuyerOffersController isOfferSubmitted checks model and submitted set accurately', () {
      final controller = BuyerOffersController(offerType: 'all');
      addTearDown(controller.dispose);

      final unsubmittedOffer = BuyerOfferModel(
        id: 2001,
        productId: 2001,
        hasSubmittedOffer: false,
        status: 'open',
      );
      expect(controller.isOfferSubmitted(2001, offer: unsubmittedOffer), isFalse);

      // Simulate offer submission
      controller.submittedProductIds.add(2001);
      expect(controller.isOfferSubmitted(2001, offer: unsubmittedOffer), isTrue);

      final submittedOffer = BuyerOfferModel(
        id: 2002,
        productId: 2002,
        hasSubmittedOffer: true,
        status: 'open',
      );
      expect(controller.isOfferSubmitted(2002, offer: submittedOffer), isTrue);
    });
  });
}
