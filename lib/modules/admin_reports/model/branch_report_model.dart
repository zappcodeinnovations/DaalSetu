import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BranchReportModel {
  final String branchName;
  final String adminName;
  final int sellersCount;
  final int buyersCount;
  final int contractsCount;
  final double gtvMtd;
  /// On-time delivery %; null when the branch has no delivered challans yet.
  final int? otdPercent;
  final int openIssues;
  final String status;

  BranchReportModel({
    required this.branchName,
    required this.adminName,
    required this.sellersCount,
    required this.buyersCount,
    required this.contractsCount,
    required this.gtvMtd,
    this.otdPercent,
    required this.openIssues,
    required this.status,
  });

  factory BranchReportModel.fromJson(Map<String, dynamic> json) {
    return BranchReportModel(
      branchName: json['name']?.toString() ?? json['branch_name']?.toString() ?? 'Main Branch',
      adminName: json['admin']?.toString() ?? json['admin_name']?.toString() ?? 'Branch Admin',
      sellersCount: int.tryParse(json['sellers']?.toString() ?? '0') ?? 0,
      buyersCount: int.tryParse(json['buyers']?.toString() ?? '0') ?? 0,
      contractsCount: int.tryParse(json['contracts']?.toString() ?? '0') ?? 0,
      gtvMtd: double.tryParse(json['gtv_mtd']?.toString() ?? json['gtv']?.toString() ?? '0') ?? 0.0,
      otdPercent: int.tryParse(json['otd_percent']?.toString() ?? ''),
      openIssues: int.tryParse(json['open_issues']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString().toLowerCase() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': branchName,
      'admin': adminName,
      'sellers': sellersCount,
      'buyers': buyersCount,
      'contracts': contractsCount,
      'gtv_mtd': gtvMtd,
      'otd_percent': otdPercent,
      'open_issues': openIssues,
      'status': status,
    };
  }

  // ── Convenience Getters ──────────────────────────────────────────────────
  String get formattedGtv {
    if (gtvMtd >= 10000000) {
      return "₹${(gtvMtd / 10000000).toStringAsFixed(2)} Cr";
    } else if (gtvMtd >= 100000) {
      return "₹${(gtvMtd / 100000).toStringAsFixed(2)} L";
    } else {
      final formatter = NumberFormat('#,##,###');
      return "₹${formatter.format(gtvMtd)}";
    }
  }

  Color get statusColor {
    switch (status) {
      case 'active':
        return const Color(0xFF059669); // Green
      case 'watchlist':
        return const Color(0xFFD97706); // Amber
      case 'inactive':
      default:
        return const Color(0xFF64748B); // Muted
    }
  }

  String get otdLabel => otdPercent == null ? '—' : '$otdPercent%';

  Color get otdColor {
    final otd = otdPercent;
    if (otd == null) return Colors.grey;
    if (otd >= 90) {
      return const Color(0xFF059669);
    } else if (otd >= 80) {
      return const Color(0xFF2563EB);
    } else {
      return const Color(0xFFD97706);
    }
  }
}
