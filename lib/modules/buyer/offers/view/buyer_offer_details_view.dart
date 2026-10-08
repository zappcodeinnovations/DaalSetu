import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/buyer_offer_detail_controller.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';

class BuyerOfferDetailsView extends StatefulWidget {
  final int offerId;
  const BuyerOfferDetailsView({super.key, required this.offerId});

  @override
  State<BuyerOfferDetailsView> createState() => _BuyerOfferDetailsViewState();
}

class _BuyerOfferDetailsViewState extends State<BuyerOfferDetailsView> {
  late final BuyerOfferDetailController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(BuyerOfferDetailController());
    controller.fetchDetails(widget.offerId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: "Refresh Details",
            onPressed: () => controller.fetchDetails(widget.offerId),
          ),
        ],
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

        final rfqCode = data['rfq_id'] ?? data['code'] ?? widget.offerId.toString();
        final status = data['status']?.toString().toLowerCase() ?? 'requested';
        final List<dynamic> quotations = (data['quotations'] is List)
            ? data['quotations']
            : ((data['quotes'] is List) ? data['quotes'] : []);

        return RefreshIndicator(
          onRefresh: () => controller.fetchDetails(widget.offerId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                      final quoteId = q['id'] ?? (index + 1);
                      final sellerName = q['seller_name'] ?? (q['seller'] is Map ? q['seller']['name'] : null) ?? "Seller Quote #$quoteId";
                      final quotePrice = q['price'] ?? q['offered_amount'] ?? '0';
                      final quoteQty = q['quantity'] ?? '0';
                      final quoteUnit = q['unit'] ?? 'QTL';
                      final quoteRemark = q['remark'] ?? '';
                      final List<dynamic> quoteMsgs = (q['messages'] is List) ? q['messages'] : [];

                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sellerName.toString(),
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  "₹$quotePrice",
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text("Offered Qty: $quoteQty $quoteUnit", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                            if (quoteRemark.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text("Note: $quoteRemark", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                            ],

                            // Messages / Proposals under quotation
                            if (quoteMsgs.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: quoteMsgs.map((m) {
                                    final sRole = m['sender_role'] ?? m['role'] ?? 'buyer';
                                    final mText = m['message'] ?? '';
                                    final cp = m['counter_price'] ?? '';
                                    final cq = m['counter_quantity'] ?? '';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${sRole.toString().toUpperCase()}: $mText",
                                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                          if (cp.toString().isNotEmpty || cq.toString().isNotEmpty)
                                            Text(
                                              "Counter: ₹$cp | $cq QTL",
                                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFE65100)),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _openNegotiateDialog(
                                    context,
                                    rfqId: rfqCode,
                                    quotationId: quoteId,
                                    defaultPrice: quotePrice.toString(),
                                    defaultQty: quoteQty.toString(),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE65100),
                                    side: const BorderSide(color: Color(0xFFE65100)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline, size: 14),
                                  label: const Text("Counter / Message", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    AppSnackbar.showInfo(title: "Quote Rejected", message: "Quotation has been rejected.");
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  child: const Text("Reject", style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    AppSnackbar.showSuccess(title: "Quote Accepted", message: "Deal confirmed with seller.");
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  child: const Text("Accept", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                      onPressed: () => _showCancelConfirm(context, widget.offerId),
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
          ),
        );
      }),
    );
  }

  void _openNegotiateDialog(
    BuildContext context, {
    required dynamic rfqId,
    required dynamic quotationId,
    required String defaultPrice,
    required String defaultQty,
  }) {
    final msgCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: defaultPrice != '0' ? defaultPrice : '');
    final qtyCtrl = TextEditingController(text: defaultQty != '0' ? defaultQty : '');
    final bagCtrl = TextEditingController();
    final weightCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Counter Proposal / Message", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GlassTextField(
                        controller: priceCtrl,
                        hintText: "Counter Price (₹)",
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassTextField(
                        controller: qtyCtrl,
                        hintText: "Counter Qty",
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GlassTextField(
                        controller: bagCtrl,
                        hintText: "Bag Count (opt)",
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassTextField(
                        controller: weightCtrl,
                        hintText: "Packing Wt (kg)",
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GlassTextField(
                  controller: msgCtrl,
                  hintText: "Message / Remark...",
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final msg = msgCtrl.text.trim();
                        if (msg.isEmpty && priceCtrl.text.trim().isEmpty) {
                          AppSnackbar.showWarning(title: "Required", message: "Please enter a message or counter price");
                          return;
                        }
                        Get.back();
                        controller.sendQuoteMessage(
                          rfqId: rfqId,
                          quotationId: quotationId,
                          message: msg.isNotEmpty ? msg : "Counter Proposal: Price ₹${priceCtrl.text.trim()}",
                          counterPrice: priceCtrl.text.trim(),
                          counterQuantity: qtyCtrl.text.trim(),
                          bagCount: bagCtrl.text.trim(),
                          packingWeightKg: weightCtrl.text.trim(),
                        );
                      },
                      child: const Text("Send Proposal"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
