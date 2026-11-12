import 'package:flutter_test/flutter_test.dart';

String resolveDisplayBuyerCode({
  Map<String, dynamic>? thread,
  String? interestBuyerName,
}) {
  // 1. Primary: Official Buyer Code / Unique ID (e.g. BUY-20261010-SKGT)
  final fromThreadCode =
      thread?['buyer_display_id'] ??
      thread?['buyer_unique_id'] ??
      thread?['buyer_code'] ??
      thread?['buyer_unique_code'] ??
      (thread?['buyer'] is Map
          ? (thread?['buyer']['unique_id'] ??
             thread?['buyer']['buyer_unique_id'] ??
             thread?['buyer']['code'] ??
             thread?['buyer']['display_id'])
          : null);

  if (fromThreadCode != null && fromThreadCode.toString().trim().isNotEmpty) {
    return fromThreadCode.toString().trim();
  }

  // 2. Secondary: Company name
  final company =
      thread?['buyer_company_name'] ??
      thread?['buyer_company'] ??
      thread?['company_name'];
  if (company != null && company.toString().trim().isNotEmpty) {
    return company.toString().trim();
  }

  // 3. Tertiary: Fallback name or username
  final fromThreadName =
      thread?['buyer_name'] ??
      thread?['buyer_username'] ??
      (thread?['buyer'] is Map
          ? (thread?['buyer']['username'] ?? thread?['buyer']['name'])
          : null);
  if (fromThreadName != null && fromThreadName.toString().trim().isNotEmpty) {
    final name = fromThreadName.toString().trim();
    if (RegExp(r'^buyer\s+(\d+)$', caseSensitive: false).hasMatch(name)) {
      return name.replaceAllMapped(
        RegExp(r'^buyer\s+(\d+)$', caseSensitive: false),
        (m) => 'Buyer #${m[1]}',
      );
    }
    return name;
  }

  if (interestBuyerName != null && interestBuyerName.trim().isNotEmpty) {
    final name = interestBuyerName.trim();
    if (RegExp(r'^buyer\s+(\d+)$', caseSensitive: false).hasMatch(name)) {
      return name.replaceAllMapped(
        RegExp(r'^buyer\s+(\d+)$', caseSensitive: false),
        (m) => 'Buyer #${m[1]}',
      );
    }
    return name;
  }

  return 'Buyer';
}

void main() {
  group('Negotiation Buyer Code Resolution Tests', () {
    test('Prioritizes buyer_display_id over buyer_name and company', () {
      final thread = {
        'buyer_display_id': 'BUY-20261010-SKGT',
        'buyer_name': 'Buyer 137',
        'buyer_company_name': 'SK Trading Co',
      };
      expect(resolveDisplayBuyerCode(thread: thread), 'BUY-20261010-SKGT');
    });

    test('Prioritizes buyer_unique_id if buyer_display_id is absent', () {
      final thread = {
        'buyer_unique_id': 'BUY-20261010-SKGT',
        'buyer_name': 'Buyer 137',
      };
      expect(resolveDisplayBuyerCode(thread: thread), 'BUY-20261010-SKGT');
    });

    test('Prioritizes nested buyer.unique_id', () {
      final thread = {
        'buyer': {'unique_id': 'BUY-20261010-SKGT', 'name': 'Buyer 137'},
        'buyer_name': 'Buyer 137',
      };
      expect(resolveDisplayBuyerCode(thread: thread), 'BUY-20261010-SKGT');
    });

    test('Falls back to buyer company name if no buyer code is present', () {
      final thread = {
        'buyer_company_name': 'Agro Pulses Ltd',
        'buyer_name': 'Buyer 137',
      };
      expect(resolveDisplayBuyerCode(thread: thread), 'Agro Pulses Ltd');
    });

    test('Formats raw buyer ID cleanly as Buyer #137 if only buyer_name exists', () {
      final thread = {
        'buyer_name': 'Buyer 137',
      };
      expect(resolveDisplayBuyerCode(thread: thread), 'Buyer #137');
    });

    test('Falls back to interest buyerName when thread has no buyer details', () {
      expect(
        resolveDisplayBuyerCode(thread: {}, interestBuyerName: 'Buyer 137'),
        'Buyer #137',
      );
    });

    test('Returns default Buyer when all sources are empty', () {
      expect(resolveDisplayBuyerCode(thread: null, interestBuyerName: null), 'Buyer');
    });
  });
}
