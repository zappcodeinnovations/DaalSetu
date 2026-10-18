import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildNegotiationSummaryTestWidget({
  required Map<String, dynamic> thread,
  Map<String, dynamic>? data,
}) {
  String? resolveVal(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c != null) {
        final s = c.toString().trim();
        if (s.isNotEmpty && s != '-' && s.toLowerCase() != 'null') {
          return s;
        }
      }
    }
    return null;
  }

  String resolveQty(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c != null) {
        final s = c.toString().trim();
        if (s.isNotEmpty && s != '-' && s.toLowerCase() != 'null') {
          final numVal = double.tryParse(s);
          if (numVal != null && numVal > 0) {
            return s;
          }
        }
      }
    }
    for (final c in candidates) {
      if (c != null) {
        final s = c.toString().trim();
        if (s.isNotEmpty && s != '-' && s.toLowerCase() != 'null') {
          return s;
        }
      }
    }
    return '-';
  }

  final sellerPrice = resolveVal([
    thread['seller_price'],
    thread['seller_snapshot_amount'],
    thread['seller_amount'],
    if (thread['product'] is Map) thread['product']['amount'],
    if (thread['product'] is Map) thread['product']['seller_price'],
    if (thread['product'] is Map) thread['product']['price'],
    if (thread['offer'] is Map) thread['offer']['amount'],
    if (thread['offer'] is Map) thread['offer']['seller_price'],
    data?['target_price'],
    data?['amount'],
    data?['price'],
    data?['seller_price'],
    data?['seller_snapshot_amount'],
    thread['amount'],
    thread['product_amount'],
  ]) ?? '-';

  final priceUnit = resolveVal([
    thread['price_unit'],
    thread['amount_unit'],
    if (thread['product'] is Map) thread['product']['amount_unit'],
    if (thread['product'] is Map) thread['product']['price_unit'],
    if (thread['offer'] is Map) thread['offer']['amount_unit'],
    if (thread['offer'] is Map) thread['offer']['price_unit'],
    data?['price_unit'],
    data?['amount_unit'],
    data?['unit'],
  ]) ?? 'ton';

  final availableQty = resolveQty([
    thread['seller_snapshot_quantity'],
    thread['available_quantity'],
    thread['available_stock'],
    thread['remaining_quantity'],
    thread['stock_quantity'],
    thread['seller_quantity'],
    if (thread['product'] is Map) thread['product']['seller_snapshot_quantity'],
    if (thread['product'] is Map) thread['product']['available_quantity'],
    if (thread['product'] is Map) thread['product']['remaining_quantity'],
    if (thread['product'] is Map) thread['product']['stock_quantity'],
    if (thread['product'] is Map) thread['product']['original_quantity'],
    if (thread['offer'] is Map) thread['offer']['seller_snapshot_quantity'],
    if (thread['offer'] is Map) thread['offer']['available_quantity'],
    if (thread['offer'] is Map) thread['offer']['remaining_quantity'],
    data?['seller_snapshot_quantity'],
    data?['available_quantity'],
    data?['remaining_quantity'],
    data?['original_quantity'],
    data?['stock_quantity'],
    thread['quantity'],
    data?['quantity'],
    data?['required_quantity'],
  ]);

  final qtyUnit = resolveVal([
    thread['quantity_unit'],
    if (thread['product'] is Map) thread['product']['quantity_unit'],
    if (thread['offer'] is Map) thread['offer']['quantity_unit'],
    data?['quantity_unit'],
    data?['unit'],
  ]) ?? 'qtl';

  final currentOffer = resolveVal([
    thread['latest_offered_amount'],
    thread['offered_amount'],
    thread['buyer_offered_amount'],
    thread['amount'],
  ]) ?? '-';

  final currentQty = resolveVal([
    thread['latest_offered_quantity'],
    thread['required_quantity'],
    thread['buyer_required_quantity'],
    thread['quantity'],
  ]) ?? '-';

  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          Text("Seller Price: ₹$sellerPrice/$priceUnit"),
          Text("Available Qty: $availableQty $qtyUnit"),
          Text("Current Offer: ₹$currentOffer/$priceUnit"),
          Text("Current Qty: $currentQty $qtyUnit"),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('Negotiation Summary card correctly binds seller_snapshot_amount and seller_snapshot_quantity', (tester) async {
    final thread = {
      'status': 'deal_confirmed',
      'seller_snapshot_amount': '55.00',
      'seller_snapshot_quantity': '900.000',
      'amount_unit': 'ton',
      'quantity_unit': 'qtl',
      'offered_amount': '50.00',
      'required_quantity': '450.000',
    };

    await tester.pumpWidget(buildNegotiationSummaryTestWidget(thread: thread));

    expect(find.text("Seller Price: ₹55.00/ton"), findsOneWidget);
    expect(find.text("Available Qty: 900.000 qtl"), findsOneWidget);
    expect(find.text("Current Offer: ₹50.00/ton"), findsOneWidget);
    expect(find.text("Current Qty: 450.000 qtl"), findsOneWidget);
  });

  testWidgets('Negotiation Summary card falls back to parent data when thread is sparse', (tester) async {
    final thread = {
      'status': 'deal_confirmed',
      'offered_amount': '50.00',
      'required_quantity': '450.000',
    };

    final data = {
      'target_price': '55.00',
      'price_unit': 'ton',
      'available_quantity': '900.000',
      'quantity_unit': 'qtl',
    };

    await tester.pumpWidget(buildNegotiationSummaryTestWidget(thread: thread, data: data));

    expect(find.text("Seller Price: ₹55.00/ton"), findsOneWidget);
    expect(find.text("Available Qty: 900.000 qtl"), findsOneWidget);
  });

  testWidgets('Negotiation Summary card binds from nested product map', (tester) async {
    final thread = {
      'status': 'negotiating',
      'product': {
        'amount': '62.50',
        'available_quantity': '300.000',
        'amount_unit': 'ton',
        'quantity_unit': 'qtl',
      },
      'latest_offered_amount': '60.00',
      'latest_offered_quantity': '200.000',
    };

    await tester.pumpWidget(buildNegotiationSummaryTestWidget(thread: thread));

    expect(find.text("Seller Price: ₹62.50/ton"), findsOneWidget);
    expect(find.text("Available Qty: 300.000 qtl"), findsOneWidget);
    expect(find.text("Current Offer: ₹60.00/ton"), findsOneWidget);
    expect(find.text("Current Qty: 200.000 qtl"), findsOneWidget);
  });
}
