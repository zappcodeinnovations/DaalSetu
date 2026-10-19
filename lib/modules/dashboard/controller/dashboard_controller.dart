import 'package:flutter/foundation.dart';
import '../../../services/dashboard_service.dart';
import 'package:get/get.dart';
import '../model/dashboard_model.dart';
import '../../../utils/app_snackbar.dart';

class DashboardController extends GetxController {
  final isLoading = false.obs;
  final dashboardData = Rxn<DashboardModel>();
  final isPaymentsExpanded = false.obs;
  final isKpiExpanded = false.obs;
  final selectedGtvPeriod = '1M (This Month)'.obs;
  final isUpdatingTrend = false.obs;

  @override
  void onInit() {
    fetchDashboard();
    super.onInit();
  }

  void toggleKpi() {
    isKpiExpanded.value = !isKpiExpanded.value;
  }

  void togglePayments() {
    isPaymentsExpanded.value = !isPaymentsExpanded.value;
  }

  Future<void> updateGtvPeriod(String period) async {
    selectedGtvPeriod.value = period;
    isUpdatingTrend.value = true;
    try {
      final data = await DashboardService.fetchDashboard(period: period);
      dashboardData.value = data;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Period filter error: $e");
      }
    } finally {
      isUpdatingTrend.value = false;
    }
  }

  Future<void> fetchDashboard() async {
    try {
      isLoading.value = true;
      isKpiExpanded.value = false;

      if (kDebugMode) {
        debugPrint("🚀 Fetching Dashboard Data...");
      }

      final data = await DashboardService.fetchDashboard();

      dashboardData.value = data;

      /// 🔥 PRINT PARSED MODEL DATA
      if (kDebugMode) {
        debugPrint("✅ Dashboard Model Parsed Successfully");
        debugPrint("Active Contracts: ${data.kpis.activeContracts}");
        debugPrint("GTV MTD: ${data.kpis.gtvMtd}");
        debugPrint("Pipeline Stages: ${data.charts.pipelineByStage.labels}");
        debugPrint("Commodity Mix: ${data.charts.commodityMix.labels}");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint("❌ Dashboard Error: $e");
        debugPrint("StackTrace: $stackTrace");
      }

      AppSnackbar.snackbar("Error", "Failed to load dashboard");
    } finally {
      isLoading.value = false;
    }
  }
}
