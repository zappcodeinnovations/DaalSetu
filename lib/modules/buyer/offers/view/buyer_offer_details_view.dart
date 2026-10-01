import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../controller/buyer_offer_detail_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class BuyerOfferDetailsView extends StatelessWidget {
  final int offerId;
  const BuyerOfferDetailsView({super.key, required this.offerId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BuyerOfferDetailController());
    final theme = Theme.of(context);

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchDetails(offerId);
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Requirement Details", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFB300)));
        }

        final data = controller.offerDetails.value;
        if (data == null) return const Center(child: Text("Data not found"));

        final status = data['status']?.toString().toLowerCase() ?? 'requested';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(status),
              const SizedBox(height: 24),

              _sectionTitle("Product Specifications"),
              _detailCard([
                _infoRow("Title", data['title'] ?? "N/A"),
                _infoRow("Category", data['category_name'] ?? "N/A"),
                _infoRow("Brand", data['brand_name'] ?? "N/A"),
              ]),

              const SizedBox(height: 24),
              _sectionTitle("Order Quantity & Target"),
              _detailCard([
                _infoRow("Requested Quantity", "${data['requested_quantity']} ${data['quantity_unit']}"),
                _infoRow("Target Price", "₹${data['requested_amount']} per ${data['amount_unit']}"),
                _infoRow("Total Value", "₹${data['total_value'] ?? 'Calculated on deal'}"),
              ]),

              const SizedBox(height: 32),
              if (status == 'requested')
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => _showCancelConfirm(context, offerId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("CANCEL REQUIREMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusHeader(String status) {
    Color color = const Color(0xFFFFB300);
    if (status.contains('confirm')) color = Colors.green;
    if (status.contains('cancel') || status.contains('reject')) color = Colors.red;

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
          Text("STATUS: ${status.toUpperCase()}", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showCancelConfirm(BuildContext context, int id) {
    Get.defaultDialog(
      title: "Cancel Requirement",
      middleText: "Are you sure you want to cancel this buying request?",
      textConfirm: "YES, CANCEL",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        Get.find<BuyerOfferDetailController>().cancelOffer(id);
      },
      textCancel: "NO",
    );
  }
}
