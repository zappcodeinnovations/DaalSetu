import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../controller/buyer_offer_detail_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';

class BuyerOfferDetailsView extends StatelessWidget {
  final int offerId;
  const BuyerOfferDetailsView({super.key, required this.offerId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BuyerOfferDetailController());
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchDetails(offerId);
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Requirement Details",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final rawData = controller.offerDetails.value;
        if (rawData == null) return const Center(child: Text("Data not found"));

        final Map<String, dynamic> data = (rawData['rfq'] is Map)
            ? Map<String, dynamic>.from(rawData['rfq'] as Map)
            : ((rawData['data'] is Map)
                ? Map<String, dynamic>.from(rawData['data'] as Map)
                : ((rawData['offer'] is Map)
                    ? Map<String, dynamic>.from(rawData['offer'] as Map)
                    : Map<String, dynamic>.from(rawData)));

        final status = data['status']?.toString().toLowerCase() ?? 'requested';
        final List<dynamic> quotations = (data['quotations'] is List)
            ? data['quotations']
            : ((data['quotes'] is List) ? data['quotes'] : []);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(status),
              const SizedBox(height: 24),

              _sectionTitle("Product Specifications"),
              _detailCard([
                _infoRow("Title", data['title'] ?? data['product_title'] ?? data['commodity'] ?? "N/A"),
                _infoRow("Category", data['category_name'] ?? data['category'] ?? "N/A"),
                _infoRow("Brand", data['brand_name'] ?? data['brand'] ?? "N/A"),
                if (data['description'] != null && data['description'].toString().trim().isNotEmpty)
                  _infoRow("Description", data['description']),
                if (data['buyer_name'] != null && data['buyer_name'].toString().trim().isNotEmpty)
                  _infoRow("Buyer", data['buyer_name']),
                if (data['seller'] != null || data['seller_name'] != null)
                  _infoRow("Seller", data['seller_name'] ?? data['seller'] ?? "N/A"),
                if (data['seller_company_name'] != null || data['company_name'] != null)
                  _infoRow("Company", data['seller_company_name'] ?? data['company_name'] ?? "N/A"),
              ]),

              const SizedBox(height: 24),
              _sectionTitle("Pricing & Inventory"),
              _detailCard([
                _infoRow("Quantity", "${data['required_quantity'] ?? data['available_quantity'] ?? data['remaining_quantity'] ?? data['requested_quantity'] ?? data['quantity'] ?? '0'} ${data['quantity_unit'] ?? data['price_unit'] ?? data['unit'] ?? ''}".trim()),
                _infoRow("Target Price", "₹${data['target_price'] ?? data['amount'] ?? data['requested_amount'] ?? data['price'] ?? '0'} per ${data['price_unit'] ?? data['amount_unit'] ?? data['unit'] ?? 'qtl'}".trim()),
                if (data['required_bag_count'] != null)
                  _infoRow("Bag Count", "${data['required_bag_count']} Bags"),
                if (data['packing_weight_kg'] != null)
                  _infoRow("Packing Weight", "${data['packing_weight_kg']} kg"),
                if (data['loading_location'] != null && data['loading_location'].toString().isNotEmpty)
                  _infoRow("Loading Location", data['loading_location']),
                if (data['delivery_terms'] != null && data['delivery_terms'].toString().trim().isNotEmpty)
                  _infoRow("Delivery Terms", data['delivery_terms']),
                if (data['buyer_remark'] != null && data['buyer_remark'].toString().trim().isNotEmpty)
                  _infoRow("Buyer Remark", data['buyer_remark']),
                if (data['total_value'] != null)
                  _infoRow("Total Value", "₹${data['total_value']}"),
              ]),

              if (quotations.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle("Received Quotations (${quotations.length})"),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: quotations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final q = quotations[index];
                    return GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                q['seller_name'] ?? "Seller Quote #${index + 1}",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                "₹${q['price'] ?? q['offered_amount'] ?? '0'}",
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text("Offered Qty: ${q['quantity'] ?? '0'} ${q['unit'] ?? ''}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                          if ((q['remark'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text("Note: ${q['remark']}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  AppSnackbar.showInfo(title: "Quote Rejected", message: "Quotation has been rejected.");
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("Reject", style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  AppSnackbar.showSuccess(title: "Quote Accepted", message: "Deal confirmed with seller.");
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("Accept", style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 32),
              if (status == 'requested' || status == 'open' || status == 'active')
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCancelConfirm(context, offerId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(IconlyLight.close_square),
                    label: const Text("CANCEL / CLOSE REQUIREMENT", style: TextStyle(fontWeight: FontWeight.bold)),
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
    if (status.contains('confirm') || status.contains('active') || status.contains('open')) color = Colors.green;
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
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(children: children),
    );
  }

  String _parseStringValue(dynamic val) {
    if (val == null) return "N/A";
    if (val is String) return val.trim().isNotEmpty ? val.trim() : "N/A";
    if (val is Map) {
      return val['name']?.toString() ??
          val['full_name']?.toString() ??
          val['title']?.toString() ??
          val['company_name']?.toString() ??
          val['category_name']?.toString() ??
          val['brand_name']?.toString() ??
          val.toString();
    }
    return val.toString();
  }

  Widget _infoRow(String label, dynamic value) {
    final displayStr = _parseStringValue(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Get.theme.disabledColor)),
          Expanded(child: Text(displayStr, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showCancelConfirm(BuildContext context, int id) {
    Get.defaultDialog(
      title: "Cancel Requirement",
      middleText: "Are you sure you want to cancel and close this buying requirement?",
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
