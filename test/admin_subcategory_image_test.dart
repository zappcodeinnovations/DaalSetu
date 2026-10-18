import 'package:daalsetu/modules/admin_catalog/config/admin_detail_config.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'dummy_token'});
  });

  group('Sub-Category & Category Image Configuration Tests', () {
    test('sub_categories image field key supports both image_url and image', () {
      final config = AdminModules.byKey('sub_categories');
      final section = config.detailSections.first;
      final imageField = section.fields.firstWhere((f) => f.label == 'Image');

      expect(imageField.key, contains('image_url'));
      expect(imageField.key, contains('image'));
      expect(imageField.type, AdminDetailFieldType.image);
    });

    test('categories image field key supports both image_url and image', () {
      final config = AdminModules.byKey('categories');
      final mediaSection = config.detailSections.firstWhere((s) => s.title == 'Media');
      final imageField = mediaSection.fields.firstWhere((f) => f.label == 'Category Image');

      expect(imageField.key, contains('image_url'));
      expect(imageField.key, contains('image'));
      expect(imageField.type, AdminDetailFieldType.image);
    });

    test('offer_images image field key supports both image_url and image', () {
      final config = AdminModules.byKey('offer_images');
      final previewSection = config.detailSections.firstWhere((s) => s.title == 'Preview');
      final imageField = previewSection.fields.firstWhere((f) => f.label == 'Image');

      expect(imageField.key, contains('image_url'));
      expect(imageField.key, contains('image'));
      expect(imageField.type, AdminDetailFieldType.image);
    });
  });

  group('AdminRecordDetailScreen Image Rendering Tests', () {
    // Uses detailEndpoint: null so detail() returns the provided record without network calls
    AdminModuleConfig createTestConfig() {
      final base = AdminModules.byKey('sub_categories');
      return AdminModuleConfig(
        key: base.key,
        title: base.title,
        icon: base.icon,
        listEndpoint: base.listEndpoint,
        titleKeys: base.titleKeys,
        detailSections: base.detailSections,
      );
    }

    testWidgets('renders image preview and download button when payload has "image"', (tester) async {
      final config = createTestConfig();
      const record = AdminRecord({
        'id': 117,
        'category_name': 'sub',
        'parent_name': 'Toor Dal',
        'full_path': 'Toor Dal > sub',
        'status': 'active',
        'is_active': true,
        'image': 'https://www.daall-setu.com/media/category_images/sub.png',
        'created_at': '2026-10-12T19:15:00Z',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdminRecordDetailScreen(
            config: config,
            record: record,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // "Not Available" should NOT be displayed for the image
      expect(find.text('Not Available'), findsNothing);
      expect(find.text('Download Image'), findsOneWidget);
    });

    testWidgets('renders image preview when payload has relative path in "image"', (tester) async {
      final config = createTestConfig();
      const record = AdminRecord({
        'id': 117,
        'category_name': 'sub',
        'parent_name': 'Toor Dal',
        'full_path': 'Toor Dal > sub',
        'status': 'active',
        'is_active': true,
        'image': '/media/category_images/sub.png',
        'created_at': '2026-10-12T19:15:00Z',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdminRecordDetailScreen(
            config: config,
            record: record,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Not Available'), findsNothing);
      expect(find.text('Download Image'), findsOneWidget);
    });

    testWidgets('renders "Not Available" when image is legitimately null or empty', (tester) async {
      final config = createTestConfig();
      const record = AdminRecord({
        'id': 118,
        'category_name': 'sub_no_img',
        'parent_name': 'Toor Dal',
        'full_path': 'Toor Dal > sub_no_img',
        'status': 'active',
        'is_active': true,
        'image': null,
        'created_at': '2026-10-12T19:15:00Z',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdminRecordDetailScreen(
            config: config,
            record: record,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Not Available'), findsOneWidget);
      expect(find.text('Download Image'), findsNothing);
    });
  });
}
