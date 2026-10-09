import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_contract_controller.dart';
import 'seller_contract_detail_view.dart';

class SellerContractsView extends StatelessWidget {
  const SellerContractsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerContractController());
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "My Deal Contracts",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
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
                Icon(
                  IconlyLight.document,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No signed deal contracts yet",
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
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
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                                color: status.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: status.color,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: primaryColor,
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
                              "Date: ${item.createdAt ?? 'N/A'}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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
