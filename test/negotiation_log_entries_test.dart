import 'package:daalsetu/modules/buyer/offers/view/buyer_offer_details_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Requirement Details "Negotiation Log": no empty SYSTEM cards, events in plain words.
void main() {
  test('events with nothing to say and the system actor are not shown as empty cards', () {
    final entries = negotiationLogEntries([
      {'actor_role': 'buyer', 'action': 'status_changed_to_buyer_confirmed', 'timestamp': '2026-11-18T18:57:10+00:00'},
      {'actor_role': 'system', 'action': 'negotiation_message', 'timestamp': '2026-11-18T18:57:12+00:00'},
      {'actor_role': 'system', 'timestamp': '2026-11-18T18:57:13+00:00'},
      {'actor_role': 'admin', 'to_status': 'deal_confirmed', 'timestamp': '2026-11-18T19:03:00+00:00'},
    ]);
    final headings = entries.map((e) => e.heading).toList();
    expect(headings.any((h) => h.toUpperCase().contains('SYSTEM')), isFalse);
    expect(headings, ['Buyer confirmed', 'Deal confirmed (Admin)']);
  });

  test('a counter offer shows who made it, and the same event logged twice shows once', () {
    final entries = negotiationLogEntries([
      {'actor_role': 'seller', 'counter_price': '80', 'counter_quantity': '85', 'timestamp': '2026-11-18T13:10:30+00:00'},
      {'actor_role': 'buyer', 'to_status': 'buyer_confirmed', 'timestamp': '2026-11-18T13:20:00+00:00'},
      {'actor_role': 'buyer', 'action': 'status_changed_to_buyer_confirmed', 'timestamp': '2026-11-18T13:20:00+00:00'},
    ]);
    expect(entries.map((e) => e.heading), ['Seller counter offer', 'Buyer confirmed']);
    expect(entries.first.time, isNot(contains('T'))); // "18 Nov 18:40", not the raw ISO text
  });
}
