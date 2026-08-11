import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../controller/buyer_delivery_controller.dart';

class BuyerChallanDetailsView extends StatelessWidget {
  final int challanId;
  const BuyerChallanDetailsView({super.key, required this.challanId});

  static const Color primaryColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BuyerDeliveryController>();
    final theme = Theme.of(context);

    // Fetch details on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchChallanDetails(challanId);
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Shipment Details", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final data = controller.selectedChallan.value;
        if (data == null) return const Center(child: Text("Details not found"));

        final items = data['items'] as List? ?? [];
        final status = data['status']?.toString().toLowerCase() ?? 'pending';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBanner(status),
              const SizedBox(height: 24),
              
              _sectionTitle("Shipment Information"),
              _detailCard([
                _infoRow("Challan ID", "#${data['challan_number'] ?? data['id']}"),
                _infoRow("Truck Number", data['truck_number'] ?? "N/A"),
                _infoRow("Dispatched By", data['dispatched_by_name'] ?? "N/A"),
              ]),

              const SizedBox(height: 24),
              _sectionTitle("Product Items"),
              ...items.map((item) => _itemCard(item)).toList(),

              const SizedBox(height: 24),
              _sectionTitle("Parties Involved"),
              _detailCard([
                _infoRow("Seller", data['seller_name_display'] ?? "N/A"),
                _infoRow("Transporter", data['transporter_name_display'] ?? "N/A"),
              ]),

              const SizedBox(height: 32),
              if (status == 'dispatched')
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => _showReceiveDialog(context, challanId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "MARK AS RECEIVED",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color color = Colors.orange;
    if (status == 'dispatched') color = Colors.blue;
    if (status == 'received') color = Colors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(IconlyLight.info_square, color: color),
          const SizedBox(width: 12),
          Text(
            "Current Status: ${status.toUpperCase()}",
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _detailCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Get.theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Get.theme.disabledColor)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _itemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item['product_name'] ?? "Unknown Product", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _smallInfo("Quantity", "${item['quantity']} ${item['unit']}"),
              _smallInfo("Bags", "${item['bag_count']}"),
              _smallInfo("Rate", "₹${item['rate']}"),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Item Total", style: TextStyle(fontWeight: FontWeight.w500)),
              Text("₹${item['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  Widget _smallInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Get.theme.disabledColor)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
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
