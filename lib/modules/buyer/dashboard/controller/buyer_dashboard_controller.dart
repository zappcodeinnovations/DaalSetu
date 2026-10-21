import '../model/buyer_dashboard_model.dart';
import '../../../../services/buyer_services.dart';
import 'package:get/get.dart';

import '../../../../network/api_client.dart';
import '../../../../services/category_services.dart';
import '../../../category/model/category_model.dart';
import '../../offers/model/buyer_offer_model.dart';

typedef BuyerDashboardLoader =
    Future<Map<String, dynamic>> Function({String? range});
typedef BuyerCategoryLoader = Future<List<CategoryModel>> Function();
typedef BuyerOffersLoader = Future<List<dynamic>> Function();

class BuyerDashboardController extends GetxController {
  BuyerDashboardController({
    BuyerDashboardLoader? dashboardLoader,
    BuyerCategoryLoader? categoryLoader,
    BuyerOffersLoader? offersLoader,
  }) : _dashboardLoader = dashboardLoader ?? BuyerServices.getDashboard,
       _categoryLoader = categoryLoader ?? CategoryService.fetchBuyerCategories,
       _offersLoader = offersLoader ?? _defaultOffersLoader;

  final BuyerDashboardLoader _dashboardLoader;
  final BuyerCategoryLoader _categoryLoader;
  final BuyerOffersLoader _offersLoader;
  var isLoading = true.obs;
  var isError = false.obs;
  var errorMessage = ''.obs;

  Rx<BuyerDashboardModel?> dashboardData = Rx<BuyerDashboardModel?>(null);
  var selectedRange = '7D'.obs;
  var isRangeLoading = false.obs;
  var categories = <CategoryModel>[].obs;
  var activeOffers = <BuyerOfferModel>[].obs;
  var isOffersLoading = false.obs;
  var isSearching = false.obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> setRange(String range) async {
    if (selectedRange.value == range) return;
    selectedRange.value = range;
    await fetchDashboardData(range: range);
  }

  static Future<List<dynamic>> _defaultOffersLoader() async {
    try {
      final all = await BuyerServices.getAllOffers();
      if (all.isNotEmpty) return all;
    } catch (_) {}
    try {
      final today = await BuyerServices.getTodayOffers();
      if (today.isNotEmpty) return today;
    } catch (_) {}
    try {
      final pending = await BuyerServices.getPendingOffers();
      if (pending.isNotEmpty) return pending;
    } catch (_) {}
    return [];
  }

  /// Filters a list of raw items or models to return only valid, in-stock,
  /// non-expired, and actionable offers for the dashboard carousel.
  static List<BuyerOfferModel> filterValidOffers(List<dynamic> rawItems) {
    final seen = <String>{};
    final valid = <BuyerOfferModel>[];

    for (final raw in rawItems) {
      if (raw == null) continue;
      final BuyerOfferModel offer;
      if (raw is BuyerOfferModel) {
        offer = raw;
      } else if (raw is Map) {
        offer = BuyerOfferModel.fromJson(Map<String, dynamic>.from(raw));
      } else {
        continue;
      }

      // 1. Exclude out-of-stock
      if (offer.isOutOfStock) continue;

      // 2. Exclude expired deals (flag, status or a past expiry date)
      if (offer.hasExpired) continue;

      // 3. Exclude inactive or hidden items
      if (!offer.isActive) continue;

      // 4. Exclude confirmed or rejected items
      if (offer.isRejected || offer.isConfirmed) continue;

      final title = (offer.displayTitle ?? offer.title ?? '').trim();
      if (title.isEmpty) continue;

      final key =
          '${offer.productId ?? offer.id ?? offer.interestId ?? title}-$title';
      if (!seen.contains(key)) {
        seen.add(key);
        valid.add(offer);
      }
    }

    return valid;
  }

  Future<void> fetchDashboardData({String? range}) async {
    final effectiveRange = range ?? selectedRange.value;
    final isInitialLoad = dashboardData.value == null;
    try {
      if (isInitialLoad) {
        isLoading(true);
      } else {
        isRangeLoading(true);
      }
      isError(false);
      errorMessage('');

      final data = await _dashboardLoader(range: effectiveRange);

      // If the API nests it in a body key, we extract it.
      final actualData = data.containsKey('body') ? data['body'] : data;
      if (actualData is! Map) {
        throw const FormatException('Invalid buyer dashboard response');
      }

      dashboardData.value = BuyerDashboardModel.fromJson(
        Map<String, dynamic>.from(actualData),
      );
    } catch (e) {
      if (isInitialLoad) {
        isError(true);
        errorMessage(ApiClient.userFriendlyErrorMessage(e.toString()));
      }
    } finally {
      isLoading(false);
      isRangeLoading(false);
    }

    // Categories are independent of dashboard analytics. A dashboard API
    // failure must not stop this section from refreshing.
    try {
      final cats = await _categoryLoader();
      categories.assignAll(cats);
    } catch (_) {
      // Keep the existing category list on a transient request failure.
    }

    // Load and filter valid active offers for the dashboard banner/carousel
    try {
      isOffersLoading(true);
      final rawOffers = await _offersLoader();
      var filtered = filterValidOffers(rawOffers);

      // If marketplace offers are empty, fallback to valid RFQs from dashboardData
      if (filtered.isEmpty && dashboardData.value != null) {
        filtered = filterValidOffers(dashboardData.value!.recentRfqs);
      }
      activeOffers.assignAll(filtered);
    } catch (_) {
      // Fallback on transient error
      if (dashboardData.value != null) {
        activeOffers.assignAll(
          filterValidOffers(dashboardData.value!.recentRfqs),
        );
      }
    } finally {
      isOffersLoading(false);
    }
  }
}
