import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/app_theme.dart';
import '../controller/transporter_bidding_controller.dart';
import '../model/transporter_bid_model.dart';

class TransporterBiddingView extends StatelessWidget {
  const TransporterBiddingView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransporterBiddingController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: theme.textTheme.bodyLarge?.color,
            ),
            onPressed: () => Get.back(),
          ),
          title: Text(
            "Bidding & Loadings",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(IconlyLight.swap, color: primary),
              tooltip: "Refresh",
              onPressed: controller.fetchAllData,
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: "Available Loads"),
              Tab(text: "My Bids"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AvailableLoadsList(controller: controller),
            _MyBidsList(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _AvailableLoadsList extends StatelessWidget {
  final TransporterBiddingController controller;

  const _AvailableLoadsList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Obx(() {
      if (controller.isLoading.value && controller.availableLoads.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.availableLoads.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(IconlyLight.bag, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No active loadings to bid on",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Consignments open for transport bids will appear here.",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchAllData,
        color: primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.availableLoads.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final load = controller.availableLoads[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.borderColor : AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          load.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "₹${load.basePrice}/${load.quantityUnit}",
                          style: const TextStyle(
                            color: AppTheme.successGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(IconlyLight.location, size: 14, color: primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${load.loadingFrom}  ➔  ${load.loadingTo}",
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Available: ${load.availableQuantity} ${load.quantityUnit}",
                          style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showPlaceBidBottomSheet(context, controller, load),
                        icon: const Icon(IconlyLight.ticket_star, size: 14),
                        label: const Text("Place Bid", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    });
  }

  void _showPlaceBidBottomSheet(BuildContext context, TransporterBiddingController controller, TransporterBidModel load) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    controller.bidPriceController.text = load.basePrice;
    controller.bidQuantityController.text = load.availableQuantity;
    controller.remarksController.clear();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Submit Transport Bid",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Route: ${load.loadingFrom} to ${load.loadingTo}",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller.bidPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Your Offered Price (₹/${load.quantityUnit})",
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller.bidQuantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Transport Capacity / Quantity (${load.quantityUnit})",
                  prefixIcon: const Icon(IconlyLight.bag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller.remarksController,
                decoration: InputDecoration(
                  labelText: "Remarks / Vehicle Details (Optional)",
                  prefixIcon: const Icon(IconlyLight.edit),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () => controller.submitBid(load.productId ?? load.id ?? 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: controller.isSubmitting.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Confirm & Submit Bid", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _MyBidsList extends StatelessWidget {
  final TransporterBiddingController controller;

  const _MyBidsList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Obx(() {
      if (controller.isLoading.value && controller.myBids.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.myBids.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(IconlyLight.ticket_star, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No bids submitted yet",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Your active bids and quotes will be tracked here.",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchAllData,
        color: primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.myBids.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final bid = controller.myBids[index];
            final status = bid.status;
            final isAccepted = status.contains("ACCEPT") || status.contains("AWARD");

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.borderColor : AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bid.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isAccepted ? AppTheme.successGreen : Colors.orange).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: isAccepted ? AppTheme.successGreen : Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "Offered Rate: ₹${bid.myBidPrice ?? bid.basePrice}/${bid.quantityUnit}",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.successGreen,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "Capacity: ${bid.availableQuantity} ${bid.quantityUnit}",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}
