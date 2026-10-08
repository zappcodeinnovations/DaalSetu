import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../model/branch_report_model.dart';

class BranchReportCard extends StatelessWidget {
  final BranchReportModel report;

  const BranchReportCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1E2638) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header: Branch Name & Status Badge ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_city_rounded,
                          color: AppTheme.primaryGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.branchName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Manager: ${report.adminName}",
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: report.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: report.statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: report.statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 14),

            // ── Middle Metrics Row: GTV & Contracts ──────────────────────────
            Row(
              children: [
                // GTV Metric
                Expanded(
                  child: _metricBox(
                    label: "Gross Trade Value (MTD)",
                    value: report.formattedGtv,
                    color: AppTheme.primaryGold,
                    icon: Icons.currency_rupee_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                // Closed Contracts
                Expanded(
                  child: _metricBox(
                    label: "Closed Deals",
                    value: "${report.contractsCount} Deals",
                    color: const Color(0xFF2563EB),
                    icon: Icons.handshake_outlined,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Secondary Metrics Row: Sellers, Buyers, OTD% ─────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161D2B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _subMetric(
                    label: "Sellers",
                    value: report.sellersCount.toString(),
                    color: const Color(0xFF059669),
                    textMuted: textMuted,
                  ),
                  _divider(borderColor),
                  _subMetric(
                    label: "Buyers",
                    value: report.buyersCount.toString(),
                    color: const Color(0xFF2563EB),
                    textMuted: textMuted,
                  ),
                  _divider(borderColor),
                  _subMetric(
                    label: "OTD %",
                    value: "${report.otdPercent}%",
                    color: report.otdColor,
                    textMuted: textMuted,
                  ),
                  _divider(borderColor),
                  _subMetric(
                    label: "Open Issues",
                    value: report.openIssues.toString(),
                    color: report.openIssues > 5 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                    textMuted: textMuted,
                  ),
                ],
              ),
            ),

            // ── On-Time Delivery Progress Bar ────────────────────────────────
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (report.otdPercent / 100).clamp(0.0, 1.0),
                      backgroundColor: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
                      color: report.otdColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "On-Time: ${report.otdPercent}%",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: report.otdColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D2B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subMetric({
    required String label,
    required String value,
    required Color color,
    required Color textMuted,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _divider(Color color) {
    return Container(
      width: 1,
      height: 24,
      color: color,
    );
  }
}
