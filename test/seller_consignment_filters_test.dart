import 'dart:convert';

import 'package:daalsetu/modules/seller/consignments/view/seller_consignments_view.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> row(int id, {String status = 'active', bool dispatched = false, String? visibleAt}) => {
  'id': id,
  'contract_id': 'C$id',
  'status': status,
  'is_dispatched': dispatched,
  'transporter_visible_at': visibleAt,
};

http.Response ok(List<Map<String, dynamic>> rows) => http.Response(
  jsonEncode({'success': true, 'results': rows, 'pagination': {}}),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'access_token': 'test', 'user_role': 'seller'});
  });
  tearDown(Get.reset);

  test('every card stage maps to its own filter', () {
    final s = SellerConsignmentController.stageOf;
    expect(s(row(1)), 'pending');
    expect(s(row(2, visibleAt: '2026-11-18')), 'ready');
    expect(s(row(3, dispatched: true, visibleAt: '2026-11-18')), 'dispatched');
    expect(s(row(4, status: 'received', dispatched: true)), 'received');
  });

  test('the Ready filter never shows a Dispatched or Pending card, even if the server sends one', () async {
    await http.runWithClient(() async {
      final c = SellerConsignmentController();
      c.workflowStatus.value = 'ready';
      await c.fetch();
      expect(c.rows.map((r) => r['id']), [2]);
    }, () => MockClient((request) async => ok([
      row(1), // pending
      row(2, visibleAt: '2026-11-18'), // ready
      row(3, dispatched: true, visibleAt: '2026-11-18'), // dispatched
    ])));
  });

  test('a slow answer for the old filter cannot overwrite the new filter\'s list', () async {
    await http.runWithClient(() async {
      final c = SellerConsignmentController();
      c.workflowStatus.value = 'all';
      final slowAll = c.fetch(); // answers last
      c.setStatus('ready'); // answers first
      await Future.wait([slowAll]);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(c.workflowStatus.value, 'ready');
      expect(c.rows.map((r) => r['id']), [2]);
      expect(c.isLoading.value, isFalse);
    }, () => MockClient((request) async {
      if (!request.url.queryParameters.containsKey('workflow_status')) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        return ok([row(1), row(2, visibleAt: 'x'), row(3, dispatched: true, visibleAt: 'x')]);
      }
      return ok([row(2, visibleAt: 'x')]);
    }));
  });
}
