import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_challan_controller.dart';
import '../../common/seller_ui.dart';
import '../../delivery/controller/seller_delivery_controller.dart';
import '../../delivery/view/seller_challan_details_view.dart';

class SellerDeliveryChallanView extends StatelessWidget {
  const SellerDeliveryChallanView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerChallanController());
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Delivery Challans & Dispatch",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (controller.challansList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconlyLight.work, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text("No delivery challans generated yet", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchChallans,
          color: primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.challansList.length,
            itemBuilder: (context, index) {
              final item = controller.challansList[index];
              final status = (item.status ?? 'draft').toLowerCase();
              // Only draft challans can be dispatched (same rule as the backend).
              final canDispatch = status == 'draft' || status == 'pending';

              return GestureDetector(
                onTap: item.id == null
                    ? null
                    : () {
                        if (!Get.isRegistered<SellerDeliveryController>()) Get.put(SellerDeliveryController());
                        Get.to(() => SellerChallanDetailsView(challanId: item.id!))?.then((_) => controller.fetchChallans());
                      },
                child: Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          SellerUi.statusChip(status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("Buyer: ${item.buyerName ?? 'Buyer'}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Truck Number", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 2),
                                Text(
                                  item.truckNumber ?? 'N/A',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Driver Mobile", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 2),
                                Text(
                                  item.driverMobile ?? 'N/A',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (canDispatch) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => controller.dispatchChallan(item.id!),
                            icon: const Icon(IconlyLight.send, size: 16, color: Colors.white),
                            label: const Text("DISPATCH SHIPMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
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
}
