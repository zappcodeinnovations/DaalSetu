import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/controller/admin_catalog_controller.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/repository/admin_catalog_repository.dart';
import 'package:daalsetu/utils/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Repo extends AdminCatalogRepository {
  _Repo(super.config);
  final calls = <Map<String, String>>[];

  @override
  Future<AdminPageResult> fetch({
    required int page,
    required int pageSize,
    String search = '',
    String filter = '',
    String dateFrom = '',
    String dateTo = '',
  }) async {
    calls.add({'page': '$page', 'from': dateFrom, 'to': dateTo});
    final rows = page == 1
        ? [
            {'id': 1, 'created_at': '2026-11-18T10:00:00+05:30'},
            {'id': 2, 'created_at': '2026-10-02T10:00:00+05:30'},
            {'id': 3, 'note': 'no date at all'},
          ]
        : <Map<String, dynamic>>[];
    return AdminPageResult(records: rows.map(AdminRecord.new).toList(), hasNext: false, total: rows.length);
  }
}

void main() {
  setUp(Get.reset);

  test('presets turn into real days (weeks start on Monday)', () {
    final now = DateTime(2026, 11, 19); // a Thursday
    expect(const DashboardFilterValue(period: 'today').toRange(now), (DateTime(2026, 11, 19), DateTime(2026, 11, 19)));
    expect(const DashboardFilterValue(period: 'this_week').toRange(now).$1, DateTime(2026, 11, 16));
    expect(const DashboardFilterValue(period: 'last_7_days').toRange(now).$1, DateTime(2026, 11, 13));
    expect(const DashboardFilterValue(period: 'last_month').toRange(now), (DateTime(2026, 10, 1), DateTime(2026, 10, 31)));
    expect(const DashboardFilterValue(month: '2026-02').toRange(now).$2, DateTime(2026, 2, 28));
    expect(DashboardFilterValue.none.toRange(now), (null, null));
  });

  test('a list keeps only the records inside the chosen dates, and asks the server for them too', () async {
    final repo = _Repo(AdminModules.byKey('brands'));
    final controller = AdminCatalogController(repo);
    Get.put(controller);
    await Future<void>.delayed(Duration.zero);

    await controller.setDateFilter(
      DashboardFilterValue(from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 30)),
    );
    final ids = controller.records.map((r) => r['id']).toList();
    expect(ids, [1, 3]); // October is out; a record with no date stays
    expect(repo.calls.last['from'], '2026-11-01');
    expect(repo.calls.last['to'], '2026-11-30');

    await controller.setDateFilter(DashboardFilterValue.none);
    expect(controller.records.length, 3);
    expect(repo.calls.last['from'], '');
  });
}
