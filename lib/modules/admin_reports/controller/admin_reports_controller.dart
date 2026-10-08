import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../model/branch_report_model.dart';
import '../service/admin_reports_service.dart';
import '../service/report_export_service.dart';

class AdminReportsController extends GetxController {
  final isLoading = false.obs;
  final isExporting = false.obs;

  final reports = <BranchReportModel>[].obs;
  final filteredReports = <BranchReportModel>[].obs;

  // Filters
  final selectedBranch = 'All'.obs;
  final selectedDateRange = 'Month (MTD)'.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    fetchReports();
  }

  @override
  void onClose() {
    searchFocusNode.dispose();
    searchController.dispose();
    super.onClose();
  }

  // ── Reactive KPI Metrics ─────────────────────────────────────────────────
  int get totalBranchesCount => filteredReports.length;

  int get totalContractsCount =>
      filteredReports.fold(0, (sum, r) => sum + r.contractsCount);

  double get totalGtvValue =>
      filteredReports.fold(0.0, (sum, r) => sum + r.gtvMtd);

  String get totalGtvFormatted {
    final gtv = totalGtvValue;
    if (gtv >= 10000000) {
      return "₹${(gtv / 10000000).toStringAsFixed(2)} Cr";
    } else if (gtv >= 100000) {
      return "₹${(gtv / 100000).toStringAsFixed(2)} L";
    } else {
      final formatter = NumberFormat('#,##,###');
      return "₹${formatter.format(gtv)}";
    }
  }

  /// Average over branches that have delivered challans; null when none have.
  int? get avgOtdPercent {
    final values = filteredReports.map((r) => r.otdPercent).whereType<int>().toList();
    if (values.isEmpty) return null;
    return (values.reduce((a, b) => a + b) / values.length).round();
  }

  List<String> get availableBranches {
    final set = reports.map((r) => r.branchName).toSet();
    return ['All', ...set];
  }

  // ── Fetch Branch Reports ─────────────────────────────────────────────────
  Future<void> fetchReports({bool isRefresh = false}) async {
    try {
      isLoading.value = true;
      debugPrint("📊 [AdminReportsController] Fetching reports... (isRefresh: $isRefresh)");

      final list = await AdminReportsService.getBranchReports();
      reports.assignAll(list);
      applyFilters();

      debugPrint("✅ [AdminReportsController] Loaded ${reports.length} branch reports.");
    } catch (e) {
      debugPrint("❌ [AdminReportsController] Error loading reports: $e");
      Get.snackbar(
        "Notice",
        "Could not refresh branch reports. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Filter Management ────────────────────────────────────────────────────
  void setBranchFilter(String branch) {
    selectedBranch.value = branch;
    applyFilters();
  }

  void setDateRange(String range) {
    selectedDateRange.value = range;
    applyFilters();
  }

  void onSearchChanged(String query) {
    searchQuery.value = query.trim().toLowerCase();
    applyFilters();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    searchFocusNode.unfocus();
    applyFilters();
  }

  void applyFilters() {
    final branch = selectedBranch.value;
    final query = searchQuery.value;

    filteredReports.assignAll(
      reports.where((r) {
        // Branch Match
        bool matchBranch = true;
        if (branch != 'All') {
          matchBranch = r.branchName.toLowerCase() == branch.toLowerCase();
        }

        // Search Match
        bool matchQuery = true;
        if (query.isNotEmpty) {
          final bName = r.branchName.toLowerCase();
          final aName = r.adminName.toLowerCase();
          matchQuery = bName.contains(query) || aName.contains(query);
        }

        return matchBranch && matchQuery;
      }).toList(),
    );
  }

  // ── Export Actions ───────────────────────────────────────────────────────
  Future<void> exportCsv() async {
    if (filteredReports.isEmpty) {
      Get.snackbar(
        "Export Notice",
        "No data available to export.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    try {
      isExporting.value = true;
      final label = "${selectedBranch.value} (${selectedDateRange.value})";
      final filePath = await ReportExportService.exportToCsv(
        reports: filteredReports,
        filterLabel: label,
      );

      if (filePath != null) {
        Get.snackbar(
          "Success",
          "Report exported and ready to share!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF059669),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        );
      }
    } catch (e) {
      Get.snackbar(
        "Export Error",
        "Failed to generate export file: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> exportSummaryText() async {
    if (filteredReports.isEmpty) return;

    try {
      isExporting.value = true;
      final label = "${selectedBranch.value} (${selectedDateRange.value})";
      await ReportExportService.shareTextSummary(
        reports: filteredReports,
        filterLabel: label,
      );
    } finally {
      isExporting.value = false;
    }
  }
}
