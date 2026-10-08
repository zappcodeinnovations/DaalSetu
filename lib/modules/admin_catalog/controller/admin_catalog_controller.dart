import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/repository/admin_catalog_repository.dart';
import 'package:get/get.dart';

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
  int _page = 1;
  bool _hasNext = true;
  static const _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({bool refresh = false}) async {
    if (isLoading.value) return;
    if (refresh) {
      _page = 1;
      _hasNext = true;
    }
    isLoading.value = true;
    error.value = null;
    try {
      final result = await repository.fetch(
        page: 1,
        pageSize: _pageSize,
        search: search.value,
        filter: selectedFilter.value,
      );
      records.assignAll(result.records);
      total.value = result.total;
      _hasNext = result.hasNext || (result.total == null && result.records.length == _pageSize);
      _page = 1;
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
      );
      records.addAll(result.records);
      _page = nextPage;
      _hasNext = result.hasNext || (result.total == null && result.records.length == _pageSize);
    } catch (exception) {
      Get.snackbar('Error', _message(exception));
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<bool> delete(AdminRecord record) async {
    try {
      await repository.delete(repository.config.recordId(record));
      await load(refresh: true);
      Get.snackbar('Success', 'Deleted successfully');
      return true;
    } catch (exception) {
      Get.snackbar('Error', _message(exception));
      return false;
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
