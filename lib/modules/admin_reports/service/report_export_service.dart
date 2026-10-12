import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../model/branch_report_model.dart';

class ReportExportService {
  /// ============================================================
  /// EXPORT BRANCH REPORTS AS PROFESSIONALLY STYLED EXCEL (.xlsx)
  /// ============================================================
  static Future<String?> exportToExcel({
    required List<BranchReportModel> reports,
    String filterLabel = "All Branches",
  }) async {
    try {
      debugPrint("📊 [ReportExportService] Generating styled Excel (.xlsx) for ${reports.length} branches...");
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      final excel = Excel.createExcel();
      const sheetName = 'Branch Performance';
      final sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Column widths (9 columns)
      final colWidths = [26.0, 22.0, 15.0, 16.0, 26.0, 16.0, 16.0, 20.0, 16.0];
      for (int i = 0; i < colWidths.length; i++) {
        sheet.setColumnWidth(i, colWidths[i]);
      }

      // Styled Header Theme (#1E293B Navy / White text)
      final titleStyle = CellStyle(
        bold: true,
        fontSize: 13,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#1E293B'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final metaStyle = CellStyle(
        bold: false,
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#334155'),
        backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final headerStyle = CellStyle(
        bold: true,
        fontSize: 11,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#1E293B'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Data Row Styles (Zebra striping #FFFFFF / #F8FAFC)
      final evenLeftStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );
      final oddLeftStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

      final evenCenterStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      final oddCenterStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final evenRightStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );
      final oddRightStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      // Distinct Summary Row Style (#FEF3C7 Amber highlight)
      final summaryLeftStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        backgroundColorHex: ExcelColor.fromHexString('#FEF3C7'),
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );
      final summaryCenterStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        backgroundColorHex: ExcelColor.fromHexString('#FEF3C7'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      final summaryRightStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        backgroundColorHex: ExcelColor.fromHexString('#FEF3C7'),
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      // Row 0: Title Banner
      for (int c = 0; c < 9; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).cellStyle = titleStyle;
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
          TextCellValue('DAALSETU - REGIONAL BRANCH PERFORMANCE REPORT');

      // Row 1: Subtitle / Scope
      for (int c = 0; c < 9; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1)).cellStyle = metaStyle;
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
          TextCellValue('Generated: $dateStr   |   Scope / Timeframe: $filterLabel');

      // Row 3: Column Headers
      final headers = [
        'Branch Name',
        'Branch Manager',
        'Status',
        'Closed Deals',
        'Gross Trade Value (INR)',
        'Active Sellers',
        'Active Buyers',
        'On-Time Delivery %',
        'Open Issues',
      ];
      for (int c = 0; c < headers.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3));
        cell.value = TextCellValue(headers[c]);
        cell.cellStyle = headerStyle;
      }

      // Rows 4+: Branch Data Rows
      double totalGtv = 0;
      int totalContracts = 0;
      int totalSellers = 0;
      int totalBuyers = 0;
      int totalOtdSum = 0;
      int otdBranches = 0;
      int totalIssues = 0;

      int currentRow = 4;
      for (int i = 0; i < reports.length; i++) {
        final r = reports[i];
        final isOdd = (i % 2 != 0);
        final leftStyle = isOdd ? oddLeftStyle : evenLeftStyle;
        final centerStyle = isOdd ? oddCenterStyle : evenCenterStyle;
        final rightStyle = isOdd ? oddRightStyle : evenRightStyle;

        totalGtv += r.gtvMtd;
        totalContracts += r.contractsCount;
        totalSellers += r.sellersCount;
        totalBuyers += r.buyersCount;
        totalIssues += r.openIssues;
        if (r.otdPercent != null) {
          totalOtdSum += r.otdPercent!;
          otdBranches++;
        }

        // Branch Name (Left aligned)
        final c0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
        c0.value = TextCellValue(r.branchName);
        c0.cellStyle = leftStyle;

        // Branch Manager (Left aligned)
        final c1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
        c1.value = TextCellValue(r.adminName);
        c1.cellStyle = leftStyle;

        // Status (Centered)
        final c2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
        c2.value = TextCellValue(r.status.toUpperCase());
        c2.cellStyle = centerStyle;

        // Closed Deals (Right aligned number)
        final c3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
        c3.value = IntCellValue(r.contractsCount);
        c3.cellStyle = rightStyle;

        // GTV in INR (Right aligned number)
        final c4 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow));
        c4.value = DoubleCellValue(r.gtvMtd);
        c4.cellStyle = rightStyle;

        // Active Sellers (Right aligned)
        final c5 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow));
        c5.value = IntCellValue(r.sellersCount);
        c5.cellStyle = rightStyle;

        // Active Buyers (Right aligned)
        final c6 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow));
        c6.value = IntCellValue(r.buyersCount);
        c6.cellStyle = rightStyle;

        // OTD % (Right aligned)
        final c7 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow));
        c7.value = TextCellValue(r.otdLabel);
        c7.cellStyle = rightStyle;

        // Open Issues (Right aligned)
        final c8 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRow));
        c8.value = IntCellValue(r.openIssues);
        c8.cellStyle = rightStyle;

        currentRow++;
      }

      // Summary / Total Row
      currentRow++; // Spacer
      final avgOtd = otdBranches > 0 ? "${(totalOtdSum / otdBranches).toStringAsFixed(1)}%" : "—";

      final s0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      s0.value = TextCellValue('TOTAL / PLATFORM AVERAGE');
      s0.cellStyle = summaryLeftStyle;

      final s1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
      s1.value = TextCellValue('ALL');
      s1.cellStyle = summaryLeftStyle;

      final s2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
      s2.value = TextCellValue('ACTIVE');
      s2.cellStyle = summaryCenterStyle;

      final s3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
      s3.value = IntCellValue(totalContracts);
      s3.cellStyle = summaryRightStyle;

      final s4 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow));
      s4.value = DoubleCellValue(totalGtv);
      s4.cellStyle = summaryRightStyle;

      final s5 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow));
      s5.value = IntCellValue(totalSellers);
      s5.cellStyle = summaryRightStyle;

      final s6 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow));
      s6.value = IntCellValue(totalBuyers);
      s6.cellStyle = summaryRightStyle;

      final s7 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow));
      s7.value = TextCellValue(avgOtd);
      s7.cellStyle = summaryRightStyle;

      final s8 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRow));
      s8.value = IntCellValue(totalIssues);
      s8.cellStyle = summaryRightStyle;

      // Save to Temporary Directory as .xlsx
      final tempDir = await getTemporaryDirectory();
      final timeStamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filePath = "${tempDir.path}/Branch_Report_$timeStamp.xlsx";
      final fileBytes = excel.save();
      if (fileBytes != null) {
        await File(filePath).writeAsBytes(fileBytes);
        debugPrint("✅ [ReportExportService] Styled Excel file saved at: $filePath");

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: "DaalSetu - Branch Performance Report ($filterLabel)",
          text: "Please find attached the latest Branch Performance Report (.xlsx) from DaalSetu.",
        );
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint("❌ [ReportExportService] Error exporting Excel: $e");
      return null;
    }
  }

  /// ============================================================
  /// BACKWARD COMPATIBLE CSV EXPORT
  /// ============================================================
  static Future<String?> exportToCsv({
    required List<BranchReportModel> reports,
    String filterLabel = "All Branches",
  }) async {
    // Delegates to styled Excel for rich formatting, or falls back to CSV if needed
    final excelResult = await exportToExcel(reports: reports, filterLabel: filterLabel);
    if (excelResult != null) return excelResult;

    try {
      debugPrint("📊 [ReportExportService] Fallback to CSV for ${reports.length} branches...");
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      final buffer = StringBuffer();
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
      int otdBranches = 0;

      for (var r in reports) {
        totalGtv += r.gtvMtd;
        totalContracts += r.contractsCount;
        totalSellers += r.sellersCount;
        totalBuyers += r.buyersCount;
        if (r.otdPercent != null) {
          totalOtdSum += r.otdPercent!;
          otdBranches++;
        }

        buffer.writeln(
          '"${r.branchName}","${r.adminName}","${r.status.toUpperCase()}",${r.contractsCount},${r.gtvMtd.toStringAsFixed(2)},${r.sellersCount},${r.buyersCount},"${r.otdLabel}",${r.openIssues}',
        );
      }

      final avgOtd = otdBranches > 0 ? "${(totalOtdSum / otdBranches).toStringAsFixed(1)}%" : "—";
      final totalIssues = reports.fold<int>(0, (sum, r) => sum + r.openIssues);
      buffer.writeln("");
      buffer.writeln(
        '"TOTAL / PLATFORM AVERAGE","ALL","ACTIVE",$totalContracts,${totalGtv.toStringAsFixed(2)},$totalSellers,$totalBuyers,"$avgOtd",$totalIssues',
      );

      final tempDir = await getTemporaryDirectory();
      final timeStamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filePath = "${tempDir.path}/Branch_Report_$timeStamp.csv";
      final file = File(filePath);
      await file.writeAsString(buffer.toString());

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
        buffer.writeln("   • OTD: ${r.otdLabel} | Sellers: ${r.sellersCount}, Buyers: ${r.buyersCount}");
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
