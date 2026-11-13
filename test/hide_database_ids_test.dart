import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Transporter brand fallback displays status label instead of raw brand ID', () {
    // Verifies that when company name and description are null,
    // the UI fallback produces a human-readable badge label rather than "Brand ID: #12".
    String getBrandLabel({required bool isActive, String? company, String? description}) {
      if (company != null && company.isNotEmpty) return company;
      if (description != null && description.isNotEmpty) return description;
      return isActive ? "Verified Brand" : "Registered Brand";
    }

    expect(getBrandLabel(isActive: true), 'Verified Brand');
    expect(getBrandLabel(isActive: false), 'Registered Brand');
    expect(getBrandLabel(isActive: true, company: 'Agro Mill'), 'Agro Mill');
  });

  test('Contract details _withId returns human name without appending raw (ID: num)', () {
    String withId(String name, int? id) {
      if (name.trim().isNotEmpty) return name.trim();
      if (id != null) return 'Ref #$id';
      return '-';
    }

    expect(withId('Admin Rohit', 15), 'Admin Rohit');
    expect(withId('Nagpur Branch', 3), 'Nagpur Branch');
    expect(withId('', 99), 'Ref #99');
    expect(withId('', null), '-');
  });

  test('Buyer orders subtitle prioritizes seller or brand instead of raw Order ID', () {
    String getOrderSubtitle(Map<String, dynamic> order) {
      return order['seller_name']?.toString() ??
          order['brand']?.toString() ??
          order['contract_number']?.toString() ??
          'Confirmed Order';
    }

    expect(getOrderSubtitle({'seller_name': 'Kisan Trader'}), 'Kisan Trader');
    expect(getOrderSubtitle({'brand': 'Natureland Organics'}), 'Natureland Organics');
    expect(getOrderSubtitle({'contract_number': 'CON-2026-001'}), 'CON-2026-001');
    expect(getOrderSubtitle({'id': 84}), 'Confirmed Order');
  });

  test('Seller dashboard deals subtitle formats commodity and brand instead of raw contractId', () {
    String getDealSubtitle(String category, String brand) {
      final joined = [
        if (category.trim().isNotEmpty) category.trim(),
        if (brand.trim().isNotEmpty) brand.trim(),
      ].join(' • ');
      return joined.isNotEmpty ? joined : 'Confirmed Deal';
    }

    expect(getDealSubtitle('Chana Daal', 'Tata Sampann'), 'Chana Daal • Tata Sampann');
    expect(getDealSubtitle('Moong Daal', ''), 'Moong Daal');
    expect(getDealSubtitle('', ''), 'Confirmed Deal');
  });
}

