import 'package:flutter/material.dart';
import '../../../../utils/money_format.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_challan_controller.dart';
import '../../common/seller_ui.dart';
import '../../delivery/controller/seller_delivery_controller.dart';
import '../../delivery/view/seller_challan_details_view.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/utils/app_date.dart';

class SellerDeliveryChallanView extends StatelessWidget {
  const SellerDeliveryChallanView({super.key, this.statusFilter});

  /// Show only challans with this status (e.g. 'dispatched' for the In Transit KPI).
  final String? statusFilter;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerChallanController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: statusFilter == 'dispatched' ? "In Transit" : "Delivery Challans",
        subtitle: statusFilter == 'dispatched'
            ? "Dispatched shipments on the way"
            : "Dispatched shipments & transit tracking",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        trailing: IconButton(
          tooltip: 'Refresh challans',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: controller.fetchChallans,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }
        final visible = statusFilter == null
            ? controller.challansList.toList()
            : controller.challansList
                  .where((c) => (c.status ?? 'draft').toLowerCase() == statusFilter)
                  .toList();

        if (visible.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(IconlyLight.work, size: 48, color: primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  "No Delivery Challans Found",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color),
                ),
                const SizedBox(height: 6),
                Text(
                  "Delivery challans generated for confirmed deals will appear here.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchChallans,
          color: primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final item = visible[index];
              final status = (item.status ?? 'draft').toLowerCase();
              // Only draft challans can be dispatched (same rule as the backend).
              final canDispatch = status == 'draft' || status == 'pending';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: item.id == null
                        ? null
                        : () {
                            if (!Get.isRegistered<SellerDeliveryController>()) {
                              Get.put(SellerDeliveryController());
                            }
                            Get.to(() => SellerChallanDetailsView(challanId: item.id!))
                                ?.then((_) => controller.fetchChallans());
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Challan #${item.challanNumber ?? item.id}",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.textTheme.titleMedium?.color,
                                  ),
                                ),
                              ),
                              SellerUi.statusChip(status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Buyer: ${item.buyerName ?? 'Buyer'} • ${AppDate.date(item.challanDate, empty: 'Date not available')}",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (item.itemSummary.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                              ),
                              child: Text(
                                item.itemSummary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          // Transport metadata banner
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFFFF8E1).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFB300).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFFE65100)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Truck Number", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                            const SizedBox(height: 1),
                                            Text(
                                              item.truckNumber ?? 'N/A',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.25)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.phone_outlined, size: 16, color: Color(0xFFE65100)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Driver Mobile", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                            const SizedBox(height: 1),
                                            Text(
                                              item.driverMobile ?? 'N/A',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _infoChip(Icons.inventory_2_outlined, '${item.items.length} item${item.items.length == 1 ? '' : 's'}', isDark),
                              if (item.totalBags > 0) _infoChip(Icons.shopping_bag_outlined, '${item.totalBags} bags', isDark),
                              if ((item.totalAmount ?? '').isNotEmpty)
                                _infoChip(Icons.currency_rupee_rounded, formatInr(item.totalAmount), isDark, highlight: true),
                              if ((item.companyName ?? '').isNotEmpty)
                                _infoChip(Icons.apartment_outlined, item.companyName!, isDark),
                            ],
                          ),
                          if (canDispatch) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => controller.dispatchChallan(item.id!),
                                icon: const Icon(IconlyLight.send, size: 16, color: Colors.white),
                                label: Text(
                                  "DISPATCH SHIPMENT",
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _infoChip(IconData icon, String label, bool isDark, {bool highlight = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFFFFB300).withValues(alpha: isDark ? 0.2 : 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight
                ? const Color(0xFFFFB300).withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: highlight ? const Color(0xFFE65100) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                color: highlight
                    ? (isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100))
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
              ),
            ),
          ],
        ),
      );
}
