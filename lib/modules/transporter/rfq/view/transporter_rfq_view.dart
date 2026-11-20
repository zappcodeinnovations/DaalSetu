import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../seller/rfq/controller/seller_rfq_controller.dart';
import '../../../../theme/app_theme.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class TransporterRfqView extends StatelessWidget {
  const TransporterRfqView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerRfqController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Buyer Requirements",
        subtitle: "Active buyer procurement tenders & RFQ",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        trailing: IconButton(
          icon: const Icon(IconlyLight.swap, color: Colors.white),
          tooltip: "Refresh",
          onPressed: controller.fetchRFQs,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/images/thumb_logo.png',
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Obx(() {
            if (controller.isLoading.value && controller.rfqList.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)));
            }

            if (controller.rfqList.isEmpty) {
              return RefreshIndicator(
                onRefresh: controller.fetchRFQs,
                color: primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(IconlyLight.chat, size: 56, color: Color(0xFFFF9800)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No buyer requirements",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Active buyer tenders and requirements will appear here.",
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.fetchRFQs,
              color: primary,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: controller.rfqList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final rfq = controller.rfqList[index];
                  const rfqNumber = "RFQ";
                  final title = rfq.categoryName ?? rfq.brandName ?? "Requirement";
                  final price = rfq.targetPrice != null ? "₹${rfq.targetPrice}/${rfq.priceUnit}" : "Price on Request";
                  final qty = "${rfq.requiredQuantity ?? ''} ${rfq.quantityUnit}".trim();
                  final status = rfq.status.toUpperCase();
                  final buyer = rfq.buyerName ?? "Buyer";

                  Color statusColor = const Color(0xFF2E7D32);
                  Color statusBg = const Color(0xFFE8F5E9);
                  Color statusBorder = const Color(0xFF81C784);
                  if (status == 'PENDING') {
                    statusColor = const Color(0xFFE65100);
                    statusBg = const Color(0xFFFFF3E0);
                    statusBorder = const Color(0xFFFFB74D);
                  } else if (status == 'CLOSED' || status == 'EXPIRED') {
                    statusColor = Colors.grey.shade700;
                    statusBg = Colors.grey.shade100;
                    statusBorder = Colors.grey.shade300;
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardColor : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                rfqNumber,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: const Color(0xFFE65100),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusBorder, width: 0.8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              price,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                            const Spacer(),
                            if (qty.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade900 : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Req: $qty",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(IconlyLight.profile, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Buyer: $buyer",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
