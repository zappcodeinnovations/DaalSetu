import '../../../utils/app_date.dart';
import '../../../utils/dashboard_filter.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/repository/admin_catalog_repository.dart';
import 'package:get/get.dart';
import '../../../utils/app_snackbar.dart';

class AdminCatalogController extends GetxController {
  AdminCatalogController(this.repository);

  final AdminCatalogRepository repository;
  final records = <AdminRecord>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();
  final search = ''.obs;
  final selectedFilter = ''.obs;
  final total = RxnInt();

  /// The list's date filter (From - To, or a preset). No filter = every record.
  final dateFilter = DashboardFilterValue.none.obs;

  /// The record's own date: the first of these keys that holds a readable date.
  static const dateKeys = [
    'created_at',
    'requested_at',
    'confirmed_at',
    'date_joined',
    'bill_date',
    'delivery_date',
    'challan_date',
    'updated_at',
  ];

  static DateTime? recordDate(AdminRecord record) {
    for (final key in dateKeys) {
      final parsed = AppDate.parse(record[key]);
      if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
    }
    return null;
  }

  /// A record is kept when it falls inside the chosen days (a record without any date is kept).
  bool _inRange(AdminRecord record) {
    final (from, to) = dateFilter.value.toRange();
    if (from == null || to == null) return true;
    final date = recordDate(record);
    if (date == null) return true;
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  String get _dateFromParam {
    final (from, _) = dateFilter.value.toRange();
    return from == null ? '' : AppDate.apiDate(from);
  }

  String get _dateToParam {
    final (_, to) = dateFilter.value.toRange();
    return to == null ? '' : AppDate.apiDate(to);
  }

  Future<void> setDateFilter(DashboardFilterValue value) async {
    dateFilter.value = value;
    await load(refresh: true);
  }
  int _page = 1;
  bool _hasNext = true;
  static const _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    search.value = '';
    load();
  }

  void resetSearch() {
    search.value = '';
  }

  Future<void> load({bool refresh = false, bool resetSearch = false}) async {
    if (isLoading.value) return;
    if (resetSearch) {
      search.value = '';
    }
    if (refresh) {
      _page = 1;
      _hasNext = true;
    }
    isLoading.value = true;
    error.value = null;
    try {
      var result = await repository.fetch(
        page: 1,
        pageSize: _pageSize,
        search: search.value,
        filter: selectedFilter.value,
        dateFrom: _dateFromParam,
        dateTo: _dateToParam,
      );
      var kept = result.records.where(_inRange).toList();
      var hasNext = result.hasNext || (result.total == null && result.records.length == _pageSize);
      var page = 1;
      // With a date filter some pages can be mostly outside the range: read on (a few pages) until it is full.
      while (dateFilter.value.isActive && hasNext && kept.length < _pageSize && page < 10) {
        page += 1;
        result = await repository.fetch(
          page: page,
          pageSize: _pageSize,
          search: search.value,
          filter: selectedFilter.value,
          dateFrom: _dateFromParam,
          dateTo: _dateToParam,
        );
        kept.addAll(result.records.where(_inRange));
        hasNext = result.hasNext || (result.total == null && result.records.length == _pageSize);
      }
      records.assignAll(kept);
      total.value = dateFilter.value.isActive ? null : result.total;
      _hasNext = hasNext;
      _page = page;
    } catch (exception) {
      error.value = _message(exception);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!_hasNext || isLoading.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final nextPage = _page + 1;
      final result = await repository.fetch(
        page: nextPage,
        pageSize: _pageSize,
        search: search.value,
        filter: selectedFilter.value,
        dateFrom: _dateFromParam,
        dateTo: _dateToParam,
      );
      records.addAll(result.records.where(_inRange));
      _page = nextPage;
      _hasNext = result.hasNext || (result.total == null && result.records.length == _pageSize);
    } catch (exception) {
      AppSnackbar.snackbar('Error', _message(exception));
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<bool> delete(AdminRecord record) async {
    try {
      await repository.delete(repository.config.recordId(record));
      await load(refresh: true);
      AppSnackbar.snackbar('Success', 'Deleted successfully');
      return true;
    } catch (exception) {
      AppSnackbar.snackbar('Error', _message(exception));
      return false;
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
