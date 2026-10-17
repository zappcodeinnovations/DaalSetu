import 'package:daalsetu/modules/admin_catalog/config/admin_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Admin Catalog Date Formatting Tests', () {
    test('Formats Brand Master created_at timestamp with +05:30 timezone offset', () {
      const raw = '2026-07-25T10:13:26.684876+05:30';
      final formatted = adminDisplayValue(raw, key: 'created_at');
      
      // Should format into human-readable dd MMM yyyy, hh:mm a
      expect(formatted, contains('2026'));
      expect(formatted, contains('Jul'));
      expect(formatted, isNot(contains('T')));
      expect(formatted, isNot(contains('+05:30')));
      expect(formatted, isNot(contains('684876')));
    });

    test('Formats second Brand Master timestamp correctly', () {
      const raw = '2026-07-11T13:12:31.166123+05:30';
      final formatted = adminDisplayValue(raw, key: 'created_at');
      
      expect(formatted, contains('2026'));
      expect(formatted, contains('Jul'));
      expect(formatted, contains('PM'));
      expect(formatted, isNot(contains('T')));
      expect(formatted, isNot(contains('166123')));
    });

    test('Formats Offer Videos created_at timestamp correctly', () {
      const raw = '2026-10-17T18:58:00.254510+05:30';
      final formatted = adminDisplayValue(raw, key: 'created_at');
      
      expect(formatted, contains('2026'));
      expect(formatted, contains('Oct'));
      expect(formatted, contains('PM'));
      expect(formatted, isNot(contains('T')));
      expect(formatted, isNot(contains('254510')));
    });

    test('Formats date-only string without time', () {
      const raw = '2026-07-25';
      final formatted = adminDisplayValue(raw, key: 'date');
      
      expect(formatted, equals('25 Jul 2026'));
    });

    test('Preserves non-date strings without altering them', () {
      expect(adminDisplayValue('Pradeep H Jhawar', key: 'created_by_name'), equals('Pradeep H Jhawar'));
      expect(adminDisplayValue('active', key: 'status'), equals('active'));
      expect(adminDisplayValue('TATA sampann', key: 'brand_name'), equals('TATA sampann'));
      expect(adminDisplayValue('154', key: 'product'), equals('154'));
      expect(adminDisplayValue('AMA462M', key: 'branch_code'), equals('AMA462M'));
    });

    test('Formats ISO strings even when key is not provided', () {
      const raw = '2026-07-25T10:13:26.684876+05:30';
      final formatted = adminDisplayValue(raw);
      
      expect(formatted, contains('2026'));
      expect(formatted, contains('Jul'));
      expect(formatted, isNot(contains('T')));
    });
  });
}
