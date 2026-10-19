import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_complaints_view.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_detail_config.dart';
import 'package:daalsetu/routes/app_routes.dart';

void main() {
  group('Admin Reopened Trio Fixes Tests', () {
    testWidgets('AdminComplaintsView renders KPI metric banner, search, and complaint tickets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminComplaintsView(initialOpenCount: 3),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen title
      expect(find.text('Complaints & Issues'), findsOneWidget);

      // Verify KPI banner values
      expect(find.text('Open Issues'), findsOneWidget);
      expect(find.text('In Investigation'), findsOneWidget);
      expect(find.text('Resolved MTD'), findsOneWidget);

      // Verify tickets rendered
      expect(find.text('CMP-1042'), findsOneWidget);
      expect(find.text('Moisture & Foreign Matter Variance'), findsOneWidget);
      expect(find.text('Contract: JBC2610183467'), findsOneWidget);
      expect(find.text('High Priority'), findsWidgets);

      // Verify filter chip interaction
      await tester.tap(find.text('Logistics'));
      await tester.pumpAndSettle();

      expect(find.text('CMP-1039'), findsOneWidget);
      expect(find.text('Delayed Dispatch by Transporter'), findsOneWidget);
      expect(find.text('CMP-1042'), findsNothing);
    });

    test('Offer Videos config resolves video_url|video|file|download_url keys properly', () {
      final config = AdminModules.byKey('offer_videos');
      expect(config.key, 'offer_videos');
      expect(config.detailSections.length, greaterThanOrEqualTo(2));

      final previewSection = config.detailSections.firstWhere((s) => s.title == 'Preview');
      expect(previewSection.fields.length, 1);
      final videoField = previewSection.fields.first;
      expect(videoField.type, AdminDetailFieldType.video);
      expect(videoField.key, contains('video_url'));
      expect(videoField.key, contains('video'));
      expect(videoField.key, contains('download_url'));
    });

    test('AppRoutes declares adminComplaints route properly', () {
      expect(AppRoutes.adminComplaints, '/admin/complaints');
    });
  });
}
