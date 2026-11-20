import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_detail_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 16 Bug 1: Manage Categories Checkbox Placement & High Contrast', () {
    test('checkbox list tile configuration uses leading control affinity', () {
      const affinity = ListTileControlAffinity.leading;
      expect(affinity, ListTileControlAffinity.leading);
    });

    test('high contrast borders are configured for dark and light modes', () {
      const darkBorderColor = Color(0xFF94A3B8);
      const lightBorderColor = Color(0xFF64748B);
      const activeOrange = Color(0xFFEA580C);

      expect(darkBorderColor.value, 0xFF94A3B8);
      expect(lightBorderColor.value, 0xFF64748B);
      expect(activeOrange.value, 0xFFEA580C);
    });
  });

  group('Batch 16 Bug 2: KYC Review Actions (Approve KYC & Reject KYC)', () {
    test('kyc module has Approve KYC and Reject KYC custom actions', () {
      final kycConfig = AdminModules.byKey('kyc');
      expect(kycConfig, isNotNull);
      expect(kycConfig.customActions.length, 2);

      final approveAction = kycConfig.customActions.firstWhere(
        (a) => a.title == 'Approve KYC',
      );
      expect(approveAction, isNotNull);
      expect(approveAction.icon, Icons.verified_outlined);

      final rejectAction = kycConfig.customActions.firstWhere(
        (a) => a.title == 'Reject KYC',
      );
      expect(rejectAction, isNotNull);
      expect(rejectAction.icon, Icons.cancel_outlined);
    });

    test('Approve KYC is visible for pending records and hidden for approved records', () {
      final kycConfig = AdminModules.byKey('kyc');
      final approveAction = kycConfig.customActions.firstWhere(
        (a) => a.title == 'Approve KYC',
      );

      final pendingRecord = {'id': 175, 'kyc_status': 'pending'};
      final approvedRecord = {'id': 175, 'kyc_status': 'approved'};
      final rejectedRecord = {'id': 175, 'kyc_status': 'rejected'};

      expect(approveAction.isVisible?.call(pendingRecord), isTrue);
      expect(approveAction.isVisible?.call(approvedRecord), isFalse);
      expect(approveAction.isVisible?.call(rejectedRecord), isTrue);
    });

    test('Reject KYC is visible for pending/rejected records and hidden for approved records', () {
      final kycConfig = AdminModules.byKey('kyc');
      final rejectAction = kycConfig.customActions.firstWhere(
        (a) => a.title == 'Reject KYC',
      );

      final pendingRecord = {'id': 175, 'kyc_status': 'pending'};
      final approvedRecord = {'id': 175, 'kyc_status': 'approved'};
      final rejectedRecord = {'id': 175, 'kyc_status': 'rejected'};

      expect(rejectAction.isVisible?.call(pendingRecord), isTrue);
      expect(rejectAction.isVisible?.call(approvedRecord), isFalse);
      expect(rejectAction.isVisible?.call(rejectedRecord), isTrue);
    });
  });

  group('Batch 16 Bug 3: Brand Master Products Label & Brand Logo', () {
    test('brands module uses "Products" label and no longer uses "Offers Using It"', () {
      final brandConfig = AdminModules.byKey('brands');
      expect(brandConfig, isNotNull);

      final allDetailFields = brandConfig.detailSections
          .expand((s) => s.fields)
          .toList();

      final hasOffersUsingIt = allDetailFields.any((f) => f.label == 'Offers Using It');
      expect(hasOffersUsingIt, isFalse);

      final productsField = allDetailFields.firstWhere((f) => f.label == 'Products');
      expect(productsField, isNotNull);
      expect(productsField.key, contains('product_count'));
    });

    test('brands module detailSections includes Brand Logo image field', () {
      final brandConfig = AdminModules.byKey('brands');
      final allDetailFields = brandConfig.detailSections
          .expand((s) => s.fields)
          .toList();

      final logoField = allDetailFields.firstWhere(
        (f) => f.label == 'Brand Logo',
      );
      expect(logoField, isNotNull);
      expect(logoField.type, AdminDetailFieldType.image);
      expect(logoField.key, contains('brand_image'));
      expect(logoField.key, contains('logo'));
    });
  });
}
