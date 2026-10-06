import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../comman/api_url.dart';
import '../../../../network/api_client.dart';
import '../model/transporter_brand_model.dart';

class TransporterBrandsController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isDashboardLoading = false.obs;
  final RxString dashboardError = ''.obs;

  final Rx<TransporterBrandDashboardData?> dashboardData = Rxn<TransporterBrandDashboardData>();
  final RxList<TransporterBrandModel> brandsList = <TransporterBrandModel>[].obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  List<TransporterBrandModel> get filteredBrands {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return brandsList;
    }
    return brandsList.where((brand) {
      final nameMatches = brand.name.toLowerCase().contains(query);
      final companyMatches = brand.companyName?.toLowerCase().contains(query) ?? false;
      final descMatches = brand.description?.toLowerCase().contains(query) ?? false;
      return nameMatches || companyMatches || descMatches;
    }).toList();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    dashboardError.value = '';
    try {
      await Future.wait([
        fetchBrandsDashboard(),
        fetchBrandsList(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBrandsDashboard() async {
    try {
      isDashboardLoading.value = true;
      final response = await ApiClient.get(
        endpoint: ApiUrls.brandsDashboard,
        requireAuth: true,
      );

      debugPrint("📡 [Brands Dashboard] Response: $response");

      if (response != null && response is Map) {
        dashboardData.value = TransporterBrandDashboardData.fromJson(response);
        debugPrint(
          "📊 [Brands Dashboard] Parsed: total=${dashboardData.value?.totalBrands}, "
          "active=${dashboardData.value?.activeBrands}, inUse=${dashboardData.value?.brandsInUse}",
        );
      }
    } catch (e) {
      debugPrint("❌ [Brands Dashboard] Error: $e");
      dashboardError.value = e.toString();
    } finally {
      isDashboardLoading.value = false;
    }
  }

  Future<void> fetchBrandsList() async {
    try {
      List<dynamic> rawList = [];

      // 1. Try brands dropdown endpoint
      try {
        final dropdownRes = await ApiClient.get(
          endpoint: ApiUrls.brandsDropdown,
          requireAuth: true,
        );
        debugPrint("📡 [Brands Dropdown] Response: $dropdownRes");
        rawList = _extractListFromResponse(dropdownRes);
      } catch (e) {
        debugPrint("⚠️ [Brands Dropdown] 404/Error (backend has no dropdown data): $e");
      }

      // 2. If dropdown returned nothing or 404, fallback to /api/brands/
      if (rawList.isEmpty) {
        try {
          final brandsRes = await ApiClient.get(
            endpoint: ApiUrls.brands,
            requireAuth: true,
          );
          debugPrint("📡 [Brands List] Fallback Response: $brandsRes");
          rawList = _extractListFromResponse(brandsRes);
        } catch (e) {
          debugPrint("⚠️ [Brands List] Fallback endpoint error: $e");
        }
      }

      // 3. Fallback: check categories tree for brands if master list is empty
      if (rawList.isEmpty) {
        try {
          final treeRes = await ApiClient.get(
            endpoint: ApiUrls.categoriesTree,
            requireAuth: true,
          );
          if (treeRes is List) {
            final Set<String> seenNames = {};
            for (var cat in treeRes) {
              if (cat is Map && cat['brands'] is List) {
                for (var b in cat['brands']) {
                  if (b is Map) {
                    final name = (b['brand_name'] ?? b['name'] ?? '').toString().trim();
                    if (name.isNotEmpty && !seenNames.contains(name.toLowerCase())) {
                      seenNames.add(name.toLowerCase());
                      rawList.add(b);
                    }
                  }
                }
              }
            }
          }
        } catch (_) {}
      }

      brandsList.value = rawList
          .whereType<Map>()
          .map((json) => TransporterBrandModel.fromJson(json))
          .toList();

      debugPrint("📊 [Brands List] Processed ${brandsList.length} items.");
    } catch (e) {
      debugPrint("❌ [Brands List] General error: $e");
    }
  }

  List<dynamic> _extractListFromResponse(dynamic response) {
    if (response == null) return [];
    if (response is List) return response;

    if (response is Map) {
      // Check for direct list keys
      if (response['data'] is List) {
        return response['data'] as List;
      }
      if (response['results'] is List) {
        return response['results'] as List;
      }
      if (response['brands'] is List) {
        return response['brands'] as List;
      }

      // Check wrapped in body
      if (response['body'] is Map) {
        final body = response['body'] as Map;
        if (body['data'] is List) {
          return body['data'] as List;
        }
        if (body['results'] is List) {
          return body['results'] as List;
        }
      } else if (response['body'] is List) {
        return response['body'] as List;
      }
    }

    return [];
  }
}
