import 'dart:convert';
import 'dart:io';

import 'package:daalsetu/modules/transporter/bidding/model/transporter_bid_model.dart';
import 'package:daalsetu/modules/transporter/dashboard/controller/transporter_dashboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Responses captured from the real backend (test/fixtures/transporter_api_samples.json).
void main() {
  final samples = jsonDecode(File('test/fixtures/transporter_api_samples.json').readAsStringSync()) as Map<String, dynamic>;

  test('parses open shipment offers from /api/transport-bids/?view=open', () {
    final row = (samples['bids_open']['contracts'] as List).first as Map<String, dynamic>;
    final offer = ShipmentOfferModel.fromJson(row);
    expect(offer.id, greaterThan(0));
    expect(offer.contractId, isNotEmpty);
    expect(offer.pickupLocation, 'Nagpur Warehouse');
    expect(offer.deliveryLocation, 'Bhopal Warehouse');
  });

  test('parses my deals with assignment and fleet options', () {
    final data = samples['bids_mine'] as Map<String, dynamic>;
    final bid = MyBidModel.fromJson((data['results'] as List).first as Map<String, dynamic>);
    expect(bid.status, 'accepted');
    expect(bid.bidAmount, '5000.00');
    expect(bid.contractId, isNotEmpty);
    expect(bid.assignment['truck_number'], 'MP04AB1234');
    expect((data['vehicles'] as List), isNotEmpty);
    expect((data['drivers'] as List), isNotEmpty);
  });

  test('dashboard chart series tolerates missing data', () {
    final series = ChartSeries.fromJson({'labels': ['Mon', 'Tue'], 'shipments': [0, 2]}, 'labels', 'shipments');
    expect(series.values, [0, 2]);
    expect(series.isEmpty, isFalse);
    expect(ChartSeries.fromJson(null, 'labels', 'counts').isEmpty, isTrue);
  });
}
