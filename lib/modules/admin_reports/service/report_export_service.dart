import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../model/branch_report_model.dart';

class ReportExportService {
  /// ============================================================
  /// EXPORT BRANCH REPORTS AS SPREADSHEET (CSV / EXCEL)
  /// ============================================================
  static Future<String?> exportToCsv({
    required List<BranchReportModel> reports,
    String filterLabel = "All Branches",
  }) async {
    try {
      debugPrint("📊 [ReportExportService] Generating CSV for ${reports.length} branches...");
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      final buffer = StringBuffer();
      // CSV Headers & Meta
      buffer.writeln("DaalSetu - Regional Branch Performance Report");
      buffer.writeln("Generated On,$dateStr");
      buffer.writeln("Filter Scope,$filterLabel");
      buffer.writeln("");
      buffer.writeln("Branch Name,Branch Manager,Status,Closed Deals,Gross Trade Value (INR),Active Sellers,Active Buyers,On-Time Delivery %,Open Issues");

      double totalGtv = 0;
      int totalContracts = 0;
      int totalSellers = 0;
      int totalBuyers = 0;
      int totalOtdSum = 0;

      for (var r in reports) {
        totalGtv += r.gtvMtd;
        totalContracts += r.contractsCount;
        totalSellers += r.sellersCount;
        totalBuyers += r.buyersCount;
        totalOtdSum += r.otdPercent;

        buffer.writeln(
          '"${r.branchName}","${r.adminName}","${r.status.toUpperCase()}",${r.contractsCount},${r.gtvMtd.toStringAsFixed(2)},${r.sellersCount},${r.buyersCount},"${r.otdPercent}%",${r.openIssues}',
        );
      }

      // Summary Row
      final avgOtd = reports.isNotEmpty ? (totalOtdSum / reports.length).toStringAsFixed(1) : "0";
      buffer.writeln("");
      buffer.writeln(
        '"TOTAL / PLATFORM AVERAGE","ALL","ACTIVE",$totalContracts,${totalGtv.toStringAsFixed(2)},$totalSellers,$totalBuyers,"$avgOtd%",0',
      );

      // Save to Temporary Directory
      final tempDir = await getTemporaryDirectory();
      final timeStamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filePath = "${tempDir.path}/Branch_Report_$timeStamp.csv";
      final file = File(filePath);
      await file.writeAsString(buffer.toString());

      debugPrint("✅ [ReportExportService] CSV File saved at: $filePath");

      // Trigger Native Share Sheet
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: "DaalSetu - Branch Performance Report ($filterLabel)",
        text: "Please find attached the latest Branch Performance Report from DaalSetu.",
      );

      return filePath;
    } catch (e) {
      debugPrint("❌ [ReportExportService] Error exporting CSV: $e");
      return null;
    }
  }

  /// ============================================================
  /// SHARE REPORT SUMMARY AS FORMATTED TEXT
  /// ============================================================
  static Future<void> shareTextSummary({
    required List<BranchReportModel> reports,
    String filterLabel = "All Branches",
  }) async {
    try {
      final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

      double totalGtv = 0;
      int totalContracts = 0;
      for (var r in reports) {
        totalGtv += r.gtvMtd;
        totalContracts += r.contractsCount;
      }

      final buffer = StringBuffer();
      buffer.writeln("📊 *DaalSetu - Branch Performance Summary*");
      buffer.writeln("📅 Date: $dateStr");
      buffer.writeln("🎯 Filter: $filterLabel");
      buffer.writeln("---------------------------------------");

      for (var r in reports) {
        buffer.writeln("🏢 *${r.branchName}* (${r.adminName})");
        buffer.writeln("   • GTV: ${r.formattedGtv} | Deals: ${r.contractsCount}");
        buffer.writeln("   • OTD: ${r.otdPercent}% | Sellers: ${r.sellersCount}, Buyers: ${r.buyersCount}");
        buffer.writeln("");
      }

      buffer.writeln("---------------------------------------");
      final formattedTotal = totalGtv >= 10000000
          ? "₹${(totalGtv / 10000000).toStringAsFixed(2)} Cr"
          : "₹${(totalGtv / 100000).toStringAsFixed(2)} Lakhs";

      buffer.writeln("💰 *Total Platform GTV:* $formattedTotal");
      buffer.writeln("📝 *Total Deals Closed:* $totalContracts Contracts");
      buffer.writeln("⚡ _Generated via DaalSetu Admin App_");

      // ignore: deprecated_member_use
      await Share.share(
        buffer.toString(),
        subject: "DaalSetu Branch Performance Summary",
      );
    } catch (e) {
      debugPrint("❌ [ReportExportService] Error sharing summary: $e");
    }
  }
}
