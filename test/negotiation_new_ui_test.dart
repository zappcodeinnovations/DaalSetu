import 'dart:convert';

import 'package:daalsetu/modules/shared/view/offer_interest_negotiation_chat_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The negotiation screen: compact deal summary on top, the chat takes the room, and one
/// button opens the counter-offer form (so nothing is squeezed or cut off).
void main() {
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({'access_token': 'test', 'user_role': 'seller'});
  });
  tearDown(() => Get.reset());

  Map<String, dynamic> thread({bool reply = true, bool decide = true, int messages = 6}) => {
    'status': 'interested',
    'product_title': 'MIX DAAL',
    'seller_price': '40.00',
    'available_quantity': '40.000',
    'price_unit': 'qtl',
    'quantity_unit': 'qtl',
    'buyer_display_id': 'BUY-20261105-F9PJ',
    'buyer_required_quantity': '40.000',
    'initial_offered_amount': '40.00',
    'latest_offered_amount': '42.00',
    'offered_amount': '42.00',
    'offer_delivery_from': '2026-11-20',
    'offer_delivery_to': '2026-11-21',
    'delivery_date': '2026-11-22',
    'delivery_date_to': '2026-11-23',
    'created_at': '2026-11-18T16:33:00',
    'can_reply': reply,
    'can_seller_accept': decide,
    'can_seller_reject': decide,
    'is_read_only': false,
    'messages': [
      for (var i = 0; i < messages; i++)
        {
          'actor_role': i.isEven ? 'buyer' : 'seller',
          'action': 'negotiation_message',
          'counter_price': '${40 + i}',
          'price_unit': 'qtl',
          'quantity_unit': 'qtl',
          'timestamp': '2026-11-18T16:${40 + i}:00',
        },
    ],
  };

  Future<List<http.Request>> pump(WidgetTester tester, Map<String, dynamic> body, {Size size = const Size(360, 800)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final posts = <http.Request>[];
    await http.runWithClient(() async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: OfferInterestNegotiationChatView(productId: 7, interestId: 9, isBuyer: false),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }, () => MockClient((request) async {
      if (request.method == 'POST') posts.add(request);
      return http.Response(
        jsonEncode({'success': true, 'data': body, 'message': 'ok'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));
    return posts;
  }

  testWidgets('the chat gets most of the screen and the counter form is not on the page', (tester) async {
    await pump(tester, thread());
    expect(find.byKey(const Key('negotiation-snapshot')), findsOneWidget);
    expect(find.text('Offer price / QTL'), findsOneWidget);
    expect(find.text('₹42.00'), findsOneWidget); // current offer, big
    expect(find.text('Seller ₹40.00'), findsOneWidget); // seller's price, small
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    // The form is behind a button; the actions stay visible.
    expect(find.text('Make a counter offer'), findsOneWidget);
    expect(find.text('Accept Interest'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Submit Negotiation'), findsNothing);
    expect(find.text('Counter Price (₹)'), findsNothing);
    // The conversation has well over a third of an 800 px screen.
    final chat = tester.getSize(find.byType(ListView).first);
    expect(chat.height, greaterThan(300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Details opens the full summary and Less closes it', (tester) async {
    await pump(tester, thread());
    expect(find.text('Seller Price:'), findsNothing);
    await tester.tap(find.byKey(const Key('negotiation-snapshot-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Seller Price:'), findsOneWidget);
    expect(find.text('Available Qty:'), findsOneWidget);
    await tester.tap(find.byKey(const Key('negotiation-snapshot-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Seller Price:'), findsNothing);
  });

  testWidgets('the counter button opens the form in a sheet and a sent offer closes it', (tester) async {
    final posts = await pump(tester, thread());
    await http.runWithClient(() async {
      await tester.tap(find.byKey(const Key('open-counter-sheet')));
      await tester.pumpAndSettle();
      expect(find.text('Counter offer'), findsOneWidget);
      expect(find.text('Submit Negotiation'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Counter Price (₹)'), '44');
      await tester.tap(find.text('Submit Negotiation'));
      await tester.pumpAndSettle();
    }, () => MockClient((request) async {
      if (request.method == 'POST') posts.add(request);
      return http.Response(
        jsonEncode({'success': true, 'data': thread(), 'message': 'ok'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));
    expect(posts, isNotEmpty);
    expect(posts.first.body, contains('44'));
    // Sent: the sheet is gone and the page is back.
    expect(find.text('Submit Negotiation'), findsNothing);
    expect(find.text('Make a counter offer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with nothing to do the bottom bar disappears and the chat fills the screen', (tester) async {
    await pump(tester, thread(reply: false, decide: false));
    expect(find.text('Make a counter offer'), findsNothing);
    expect(find.text('Accept Interest'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a small phone keeps the summary, the chat and the button without overflow', (tester) async {
    await pump(tester, thread(), size: const Size(320, 568));
    // Short phone: Accept, Reject and Counter share one slim row.
    expect(find.byKey(const Key('compact-accept')), findsOneWidget);
    expect(find.byKey(const Key('compact-reject')), findsOneWidget);
    expect(find.byKey(const Key('open-counter-sheet')), findsOneWidget);
    expect(tester.getSize(find.byType(ListView).first).height, greaterThan(120));
    expect(tester.takeException(), isNull);
  });

  testWidgets('after the deal the summary shows the agreed terms, and the first message keeps its own price', (tester) async {
    // Seller 40 @ 12000; buyer asks 45 @ 12000; seller counters 45 @ 12500; buyer accepts.
    await pump(tester, {
      ...thread(reply: false, decide: false, messages: 0),
      'status': 'buyer_confirmed',
      'deal_agreed': true,
      'agreed_by': 'buyer',
      'agreed_amount': '12500.00',
      'agreed_quantity': '45.000',
      'initial_offered_amount': '12000.00',
      'initial_required_quantity': '45.000',
      'seller_offer_amount': '12000.00',
      'seller_offer_quantity': '40.000',
      'seller_price': '12000.00',
      'latest_offered_amount': '12500.00',
      'offered_amount': '12500.00',
      'buyer_required_quantity': '45.000',
      'messages': [
        {
          'actor_role': 'seller',
          'action': 'negotiation_message',
          'counter_price': '12500',
          'counter_quantity': '45',
          'price_unit': 'qtl',
          'quantity_unit': 'qtl',
          'timestamp': '2026-11-18T16:45:00',
        },
      ],
    });
    // Compact summary: the agreed deal, with the seller's own offer as the reference.
    expect(find.text('Agreed price / QTL'), findsOneWidget);
    expect(find.text('₹12,500.00'), findsOneWidget);
    expect(find.text('Seller ₹12,000.00'), findsOneWidget);
    expect(find.text('Agreed quantity'), findsOneWidget);
    expect(find.text('45.000 QTL'), findsWidgets);
    expect(find.text('Seller offered 40.000'), findsOneWidget);
    // The buyer's first message still shows the first offer, not the countered 12500.
    expect(find.text('Price: ₹12,000.00/QTL'), findsOneWidget);
    expect(find.text('Price: ₹12,500.00/QTL'), findsNothing);
    // The seller's counter keeps its own price in the chat.
    expect(find.text('₹12500 / qtl'), findsOneWidget);
    // Details show the agreed block.
    await tester.tap(find.byKey(const Key('negotiation-snapshot-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Agreed Price:'), findsOneWidget);
    expect(find.text('Agreed Qty:'), findsOneWidget);
    expect(find.text('Seller Offered Qty:'), findsOneWidget);
    expect(find.text('Accepted by:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
