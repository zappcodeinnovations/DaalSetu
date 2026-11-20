import 'package:daalsetu/widgets/page_auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_contract_controller.dart';
import '../../common/seller_ui.dart';
import 'seller_contract_detail_view.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class SellerContractsView extends StatelessWidget {
  const SellerContractsView({super.key});

  @override
  Widget build(BuildContext context) => PageAutoRefresh(
    onRefresh: () => Get.find<SellerContractController>().fetchContracts(silent: true),
    child: _buildPageContent(context),
  );

  Widget _buildPageContent(BuildContext context) {
    final controller = Get.put(SellerContractController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Deal Contracts",
        subtitle: "Signed deals & legal trade agreements",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        trailing: IconButton(
          tooltip: 'Refresh contracts',
          onPressed: controller.fetchContracts,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (controller.contractsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    IconlyLight.document,
                    size: 56,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No signed deal contracts yet",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Confirmed deals and agreements will appear here",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchContracts,
          color: primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.contractsList.length,
            itemBuilder: (context, index) {
              final item = controller.contractsList[index];
              final status = _statusPresentation(item.status);
              return GestureDetector(
                onTap: item.id == null
                    ? null
                    : () => Get.to(
                        () => SellerContractDetailView(contractId: item.id!),
                      ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFFFE0B2).withValues(alpha: 0.7),
                    ),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xFFE65100).withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
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
                                "Contract #${item.contractId ?? item.id}",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: status.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: status.color.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                status.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: status.color,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if ((item.productTitle != null && item.productTitle!.trim().isNotEmpty) ||
                            (item.brandName != null && item.brandName!.trim().isNotEmpty)) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (item.productTitle != null && item.productTitle!.trim().isNotEmpty)
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        IconlyLight.bag,
                                        size: 14,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          item.productTitle!.trim(),
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item.brandName != null && item.brandName!.trim().isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 11,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 130),
                                        child: Text(
                                          item.brandName!.trim(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          "Buyer: ${item.buyerCompany ?? 'Buyer'}",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Deal Amount",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "₹${item.dealAmount ?? 'N/A'}",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: const Color(0xFFE65100),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Commodity",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.categoryName ?? 'Pulse',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              IconlyLight.calendar,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Date: ${SellerUi.date(item.createdAt)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            // Visible affordance: the whole card opens the contract, and this says so.
                            OutlinedButton.icon(
                              key: Key('contract-view-${item.id}'),
                              onPressed: item.id == null
                                  ? null
                                  : () => Get.to(
                                      () => SellerContractDetailView(contractId: item.id!),
                                    ),
                              icon: const Icon(Icons.visibility_outlined, size: 16),
                              label: const Text('View'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: const BorderSide(color: primaryColor),
                                minimumSize: const Size(0, 34),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  _ContractStatusPresentation _statusPresentation(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.contains('expired')) {
      return const _ContractStatusPresentation('EXPIRED', Colors.deepOrange);
    }
    if (normalized.contains('cancel') || normalized.contains('reject')) {
      return const _ContractStatusPresentation('CANCELLED', Colors.red);
    }
    if (normalized.contains('pending') || normalized.contains('review')) {
      return const _ContractStatusPresentation('PENDING', Colors.orange);
    }
    if (normalized.contains('complete') || normalized.contains('deliver')) {
      return const _ContractStatusPresentation('COMPLETED', Colors.green);
    }
    return _ContractStatusPresentation(
      normalized.isEmpty ? 'ACTIVE' : normalized.toUpperCase(),
      Colors.green,
    );
  }
}

class _ContractStatusPresentation {
  const _ContractStatusPresentation(this.label, this.color);

  final String label;
  final Color color;
}
