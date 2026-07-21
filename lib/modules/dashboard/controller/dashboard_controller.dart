import 'package:flutter/foundation.dart';
import 'package:agro_broker/services/dashboard_service.dart';
import 'package:get/get.dart';
import '../model/dashboard_model.dart';

class DashboardController extends GetxController {
  final isLoading = false.obs;
  final dashboardData = Rxn<DashboardModel>();
  final isPaymentsExpanded = false.obs;
  final isKpiExpanded = false.obs;

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

      Get.snackbar("Error", "Failed to load dashboard");
    } finally {
      isLoading.value = false;
    }
  }
}
