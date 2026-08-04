import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../controller/buyer_delivery_controller.dart';
import '../model/buyer_challan_model.dart';
import 'buyer_challan_details_view.dart';
import 'package:google_fonts/google_fonts.dart';

class BuyerDeliveryChallanView extends StatelessWidget {
  const BuyerDeliveryChallanView({super.key});

  static const Color primaryColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BuyerDeliveryController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Incoming Shipments",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchChallans,
        color: primaryColor,
        child: Obx(() {
          if (controller.isLoading.value && controller.challans.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (controller.challans.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.document, size: 64, color: theme.disabledColor),
                      const SizedBox(height: 16),
                      Text("No shipments found", style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.challans.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final challan = controller.challans[index];
              return _buildChallanCard(context, challan);
            },
          );
        }),
      ),
    );
  }

  Widget _buildChallanCard(BuildContext context, BuyerChallanModel challan) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = Get.find<BuyerDeliveryController>();

    Color statusColor = Colors.orange;
    if (challan.status.toLowerCase() == 'dispatched') statusColor = Colors.blue;
    if (challan.status.toLowerCase() == 'received') statusColor = Colors.green;

    return GestureDetector(
      onTap: () => Get.to(() => BuyerChallanDetailsView(challanId: challan.id)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
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
                    "Challan: #${challan.challanNumber}",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    challan.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(IconlyLight.user_1, "Seller: ${challan.sellerName}", theme),
            _infoRow(IconlyLight.activity, "Transporter: ${challan.transporterName}", theme),
            _infoRow(IconlyLight.location, "Truck: ${challan.truckNumber}", theme),
            
            if (challan.items.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(IconlyLight.buy, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${challan.items[0].productName} (${challan.items[0].quantity} ${challan.items[0].unit})",
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ],

            if (challan.status.toLowerCase() == 'dispatched') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showReceiveDialog(context, challan.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("MARK AS RECEIVED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiveDialog(BuildContext context, int id) {
    final controller = Get.find<BuyerDeliveryController>();
    final remarksController = TextEditingController();

    Get.defaultDialog(
      title: "Receive Shipment",
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: remarksController,
          decoration: const InputDecoration(
            hintText: "Add remarks (optional)",
            border: OutlineInputBorder(),
          ),
        ),
      ),
      textConfirm: "CONFIRM",
      confirmTextColor: Colors.white,
      buttonColor: Colors.green,
      onConfirm: () {
        Get.back();
        controller.markAsReceived(id, remarksController.text.trim());
      },
      textCancel: "CANCEL",
    );
  }
}
