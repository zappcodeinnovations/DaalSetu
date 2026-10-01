import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../routes/app_routes.dart';
import '../controller/buyer_delivery_challan_controller.dart';
import '../model/buyer_delivery_challan_model.dart';

class BuyerDeliveryChallanView extends StatelessWidget {
  const BuyerDeliveryChallanView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(BuyerDeliveryChallanController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() {
          final theme = Theme.of(context);
          return AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: controller.isSearching.value
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(IconlyLight.arrow_left_2),
                    onPressed: () => Get.back(),
                  ),
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: controller.isSearching.value
                  ? Container(
                      key: const ValueKey('searchField'),
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                      ),
                      child: TextField(
                        autofocus: true,
                        onChanged: (val) {
                          controller.searchQuery.value = val;
                          controller.fetchChallans(isRefresh: true);
                        },
                        decoration: InputDecoration(
                          hintText: "Search challans...",
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    )
                  : Align(
                      key: const ValueKey('titleText'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Delivery Challans",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
            ),
            actions: [
              if (!controller.isSearching.value)
                IconButton(
                  icon: const Icon(IconlyLight.search),
                  onPressed: () {
                    controller.isSearching.value = true;
                  },
                ),
              if (controller.isSearching.value)
                IconButton(
                  icon: const Icon(IconlyLight.close_square),
                  onPressed: () {
                    controller.isSearching.value = false;
                    controller.searchQuery.value = '';
                    controller.fetchChallans(isRefresh: true);
                  },
                ),
              if (!controller.isSearching.value)
                IconButton(
                  icon: const Icon(IconlyLight.filter),
                  onPressed: () {
                    Get.snackbar(
                      "Filter",
                      "Filter options will go here.",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
            ],
          );
        }),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty && controller.challans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 60,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Unable to Load Challans",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => controller.fetchChallans(isRefresh: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.challans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 60,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No Delivery Challans",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "There are no delivery challans available at this time.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => controller.fetchChallans(isRefresh: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Refresh"),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchChallans(isRefresh: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                controller.fetchNextPage();
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: controller.challans.length + (controller.isFetchingMore.value ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == controller.challans.length) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final challan = controller.challans[index];
                return _buildChallanCard(context, challan);
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildChallanCard(BuildContext context, BuyerDeliveryChallanModel challan) {
    final theme = Theme.of(context);
    String status = challan.status ?? "Unknown";
    Color statusColor = Colors.orange;
    
    if (status.toLowerCase().contains("delivered") || status.toLowerCase().contains("received")) {
      statusColor = Colors.green;
    } else if (status.toLowerCase().contains("dispatched") || status.toLowerCase().contains("transit")) {
      statusColor = Colors.blue;
    } else if (status.toLowerCase().contains("cancel")) {
      statusColor = Colors.red;
    }

    String itemName = "Items";
    if (challan.items != null && challan.items!.isNotEmpty) {
      itemName = challan.items!.first.productName ?? "Item";
      if (challan.items!.length > 1) {
        itemName += " +${challan.items!.length - 1} more";
      }
    }

    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.buyerDeliveryChallanDetails, arguments: challan.id);
      },
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    challan.challanNumber ?? "No Number",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(IconlyBold.document, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Seller: ${challan.sellerNameDisplay ?? 'N/A'}",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${challan.totalAmount ?? '0'}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(challan.challanDate),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(IconlyLight.discovery, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "Truck: ${challan.truckNumber ?? 'N/A'}",
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(IconlyLight.profile, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  "Transporter: ${challan.transporterNameDisplay ?? 'N/A'}",
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
}
