import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/buyer_offer_detail_controller.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../../services/buyer_services.dart';

class BuyerOfferDetailsView extends StatefulWidget {
  final int offerId;
  final bool preferBuyerOffer;
  final bool preferBuyerRequirement;

  const BuyerOfferDetailsView({
    super.key,
    required this.offerId,
    this.preferBuyerOffer = false,
    this.preferBuyerRequirement = false,
  });

  @override
  State<BuyerOfferDetailsView> createState() => _BuyerOfferDetailsViewState();
}

class _BuyerOfferDetailsViewState extends State<BuyerOfferDetailsView> {
  late final BuyerOfferDetailController controller;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    controller = Get.put(BuyerOfferDetailController());
    controller.fetchDetails(
      widget.offerId,
      preferBuyerOffer: widget.preferBuyerOffer,
      preferBuyerRequirement: widget.preferBuyerRequirement,
    );
    if (widget.preferBuyerRequirement) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        controller.fetchDetails(
          widget.offerId,
          silent: true,
          preferBuyerRequirement: true,
        );
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
          widget.preferBuyerOffer
              ? "Buyer Offer Details"
              : "Requirement Details",
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
            onPressed: () => controller.fetchDetails(
              widget.offerId,
              preferBuyerOffer: widget.preferBuyerOffer,
              preferBuyerRequirement: widget.preferBuyerRequirement,
            ),
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

        final rfqCode =
            data['rfq_id'] ?? data['code'] ?? widget.offerId.toString();
        final status = data['status']?.toString().toLowerCase() ?? 'requested';
        final List<dynamic> quotations = (data['quotations'] is List)
            ? data['quotations']
            : ((data['quotes'] is List) ? data['quotes'] : []);
        final List<dynamic> sellerResponses = (data['responses'] is List)
            ? data['responses']
            : const [];
        final isBuyerOfferResponse =
            data['parent_request'] != null && data['seller'] != null;
        final permissions = data['permissions'] is Map
            ? Map<String, dynamic>.from(data['permissions'] as Map)
            : const <String, dynamic>{};

        return RefreshIndicator(
          onRefresh: () => controller.fetchDetails(
            widget.offerId,
            preferBuyerOffer: widget.preferBuyerOffer,
            preferBuyerRequirement: widget.preferBuyerRequirement,
          ),
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
                  _infoRow(
                    "Title",
                    data['title'] ??
                        data['product_title'] ??
                        data['commodity'] ??
                        "N/A",
                  ),
                  _infoRow(
                    "Category",
                    data['category_name'] ?? data['category'] ?? "N/A",
                  ),
                  _infoRow(
                    "Brand",
                    data['brand_name'] ?? data['brand'] ?? "N/A",
                  ),
                  if (data['description'] != null &&
                      data['description'].toString().trim().isNotEmpty)
                    _infoRow("Description", data['description']),
                  if (data['buyer_name'] != null &&
                      data['buyer_name'].toString().trim().isNotEmpty)
                    _infoRow("Buyer", data['buyer_name']),
                  if (data['seller'] != null || data['seller_name'] != null)
                    _infoRow(
                      "Seller",
                      data['seller_name'] ?? data['seller'] ?? "N/A",
                    ),
                  if (data['seller_company_name'] != null ||
                      data['company_name'] != null)
                    _infoRow(
                      "Company",
                      data['seller_company_name'] ??
                          data['company_name'] ??
                          "N/A",
                    ),
                ]),

                const SizedBox(height: 24),
                _sectionTitle("Pricing & Inventory"),
                _detailCard([
                  _infoRow(
                    "Quantity",
                    "${data['required_quantity'] ?? data['available_quantity'] ?? data['remaining_quantity'] ?? data['requested_quantity'] ?? data['quantity'] ?? '0'} ${data['quantity_unit'] ?? data['price_unit'] ?? data['unit'] ?? ''}"
                        .trim(),
                  ),
                  _infoRow(
                    "Target Price",
                    "₹${data['target_price'] ?? data['amount'] ?? data['requested_amount'] ?? data['price'] ?? '0'} per ${data['price_unit'] ?? data['amount_unit'] ?? data['unit'] ?? 'qtl'}"
                        .trim(),
                  ),
                  if (data['required_bag_count'] != null)
                    _infoRow("Bag Count", "${data['required_bag_count']} Bags"),
                  if (data['packing_weight_kg'] != null)
                    _infoRow(
                      "Packing Weight",
                      "${data['packing_weight_kg']} kg",
                    ),
                  if (data['loading_location'] != null &&
                      data['loading_location'].toString().isNotEmpty)
                    _infoRow("Loading Location", data['loading_location']),
                  if (data['delivery_terms'] != null &&
                      data['delivery_terms'].toString().trim().isNotEmpty)
                    _infoRow("Delivery Terms", data['delivery_terms']),
                  if (data['buyer_remark'] != null &&
                      data['buyer_remark'].toString().trim().isNotEmpty)
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
                      final sellerName =
                          q['seller_name'] ??
                          (q['seller'] is Map ? q['seller']['name'] : null) ??
                          "Seller Quote #$quoteId";
                      final quotePrice =
                          q['offered_price'] ??
                          q['price'] ??
                          q['offered_amount'] ??
                          '0';
                      final quoteQty =
                          q['offered_quantity'] ?? q['quantity'] ?? '0';
                      final quoteUnit =
                          q['quantity_unit'] ?? q['unit'] ?? 'QTL';
                      final quoteRemark =
                          q['seller_remark'] ?? q['remark'] ?? '';
                      final canReply = q['can_reply'] == true;
                      final canAccept = q['can_accept'] == true;
                      final canReject = q['can_reject'] == true;
                      final List<dynamic> quoteMsgs = (q['messages'] is List)
                          ? (q['messages'] as List).where((message) {
                              if (message is! Map) return false;
                              return [
                                message['counter_price'],
                                message['counter_quantity'],
                                message['counter_bag_count'],
                              ].any(
                                (value) =>
                                    value != null &&
                                    value.toString().trim().isNotEmpty,
                              );
                            }).toList()
                          : [];

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
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "₹$quotePrice",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Offered Qty: $quoteQty $quoteUnit",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (quoteRemark.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Note: $quoteRemark",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],

                            // Messages / Proposals under quotation
                            if (quoteMsgs.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: quoteMsgs.map((m) {
                                    final sRole =
                                        m['sender_role'] ??
                                        m['role'] ??
                                        'buyer';
                                    final cp = m['counter_price'] ?? '';
                                    final cq = m['counter_quantity'] ?? '';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sRole.toString().toUpperCase(),
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (cp.toString().isNotEmpty ||
                                              cq.toString().isNotEmpty)
                                            Text(
                                              "Counter: ₹$cp | $cq QTL",
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: const Color(0xFFE65100),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],

                            if (canReply || canAccept || canReject) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (canReply)
                                    OutlinedButton.icon(
                                      onPressed: () => _openNegotiateDialog(
                                        context,
                                        rfqId: rfqCode,
                                        quotationId: quoteId,
                                        defaultPrice: quotePrice.toString(),
                                        defaultQty: quoteQty.toString(),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFE65100,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFE65100),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.chat_bubble_outline,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        "Counter",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (canReject)
                                    OutlinedButton(
                                      onPressed: () => _updateQuotationStatus(
                                        context,
                                        rfqId: rfqCode,
                                        quotationId: quoteId,
                                        accept: false,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text(
                                        "Reject",
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  if (canAccept)
                                    ElevatedButton(
                                      onPressed: () => _updateQuotationStatus(
                                        context,
                                        rfqId: rfqCode,
                                        quotationId: quoteId,
                                        accept: true,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text(
                                        "Accept",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],

                if (widget.preferBuyerOffer && sellerResponses.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _sectionTitle('Seller Responses (${sellerResponses.length})'),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sellerResponses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buyerOfferResponseCard(
                      Map<String, dynamic>.from(sellerResponses[index] as Map),
                    ),
                  ),
                ],

                // The buyer-offer list may contain the seller's response row
                // directly (rather than its root request).  Keep its real
                // buyer actions available in that route as well.
                if (widget.preferBuyerOffer &&
                    sellerResponses.isEmpty &&
                    isBuyerOfferResponse) ...[
                  const SizedBox(height: 24),
                  _sectionTitle('Seller Response'),
                  _buyerOfferResponseCard(data),
                ],

                const SizedBox(height: 32),
                if ((widget.preferBuyerOffer &&
                        data['actions'] is Map &&
                        (data['actions'] as Map)['can_buyer_cancel'] == true) ||
                    (!widget.preferBuyerOffer &&
                        permissions['can_close'] == true))
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCancelConfirm(
                        context,
                        widget.offerId,
                        buyerOffer: widget.preferBuyerOffer,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(IconlyLight.close_square),
                      label: const Text(
                        "CANCEL / CLOSE REQUIREMENT",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  Widget _buyerOfferResponseCard(Map<String, dynamic> response) {
    final theme = Theme.of(context);
    final actions = response['actions'] is Map
        ? Map<String, dynamic>.from(response['actions'] as Map)
        : const <String, dynamic>{};
    final id = int.tryParse((response['id'] ?? '').toString());
    final status = response['status']?.toString() ?? 'pending';
    final seller = response['seller_name'] ?? 'Seller';
    final amount =
        response['latest_offered_amount'] ?? response['seller_offered_amount'];
    final quantity =
        response['latest_offered_quantity'] ??
        response['seller_offered_quantity'];
    final unit = response['quantity_unit'] ?? 'QTL';
    final priceUnit = response['amount_unit'] ?? unit;
    final canConfirm = id != null && actions['can_buyer_confirm'] == true;
    final canNegotiate = id != null && actions['can_buyer_negotiate'] == true;
    final canReject = id != null && actions['can_buyer_reject'] == true;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  seller.toString(),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Offer: ₹${amount ?? '-'} / $priceUnit · Qty: ${quantity ?? '-'} $unit',
            style: theme.textTheme.bodySmall,
          ),
          if (response['seller_remark']?.toString().trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                response['seller_remark'].toString(),
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (canConfirm || canNegotiate || canReject) ...[
            const Divider(height: 24),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canNegotiate)
                  OutlinedButton.icon(
                    onPressed: () => _openBuyerOfferNegotiateDialog(
                      responseId: id,
                      defaultPrice: amount?.toString() ?? '',
                      defaultQty: quantity?.toString() ?? '',
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Counter'),
                  ),
                if (canReject)
                  OutlinedButton(
                    onPressed: () => _confirmBuyerOfferAction(
                      responseId: id,
                      action: 'buyer_reject',
                      title: 'Reject seller response?',
                      confirmLabel: 'Reject',
                      color: Colors.red,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                  ),
                if (canConfirm)
                  ElevatedButton.icon(
                    onPressed: () => _confirmBuyerOfferAction(
                      responseId: id,
                      action: 'buyer_confirm',
                      title: 'Confirm seller response?',
                      confirmLabel: 'Confirm',
                      color: Colors.green,
                    ),
                    icon: const Icon(Icons.check, size: 17),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.toLowerCase();
    final color = normalized.contains('reject') || normalized.contains('cancel')
        ? Colors.red
        : normalized.contains('confirm') || normalized.contains('deal')
        ? Colors.green
        : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Future<void> _confirmBuyerOfferAction({
    required int responseId,
    required String action,
    required String title,
    required String confirmLabel,
    required Color color,
  }) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: const Text('This action will update the live negotiation.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _submitBuyerOfferAction(responseId, <String, dynamic>{
        'action': action,
      });
    }
  }

  void _openBuyerOfferNegotiateDialog({
    required int responseId,
    required String defaultPrice,
    required String defaultQty,
  }) {
    final priceController = TextEditingController(text: defaultPrice);
    final quantityController = TextEditingController(text: defaultQty);
    final bagsController = TextEditingController();
    final packingController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Counter seller response'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Counter price *'),
              ),
              TextField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Counter quantity *',
                ),
              ),
              TextField(
                controller: bagsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Bags (optional)'),
              ),
              TextField(
                controller: packingController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Packing weight KG (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final price = priceController.text.trim();
              final quantity = quantityController.text.trim();
              if (price.isEmpty || quantity.isEmpty) {
                AppSnackbar.showWarning(
                  title: 'Counter required',
                  message: 'Enter both counter price and quantity.',
                );
                return;
              }
              Get.back();
              _submitBuyerOfferAction(responseId, <String, dynamic>{
                'action': 'buyer_negotiate',
                'offered_amount': price,
                'offered_quantity': quantity,
                if (bagsController.text.trim().isNotEmpty)
                  'offered_bag_count': bagsController.text.trim(),
                if (packingController.text.trim().isNotEmpty)
                  'packing_weight_kg': packingController.text.trim(),
              });
            },
            child: const Text('Send counter'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBuyerOfferAction(
    int responseId,
    Map<String, dynamic> body,
  ) async {
    try {
      controller.isSending(true);
      final result = await BuyerServices.buyerOfferAction(responseId, body);
      AppSnackbar.showSuccess(
        title: 'Updated',
        message: result['message'] ?? 'Buyer offer updated successfully.',
      );
      await controller.fetchDetails(
        widget.offerId,
        silent: true,
        preferBuyerOffer: true,
      );
    } catch (error) {
      AppSnackbar.showError(
        title: 'Could not update offer',
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      controller.isSending(false);
    }
  }

  void _openNegotiateDialog(
    BuildContext context, {
    required dynamic rfqId,
    required dynamic quotationId,
    required String defaultPrice,
    required String defaultQty,
  }) {
    final priceCtrl = TextEditingController(
      text: defaultPrice != '0' ? defaultPrice : '',
    );
    final qtyCtrl = TextEditingController(
      text: defaultQty != '0' ? defaultQty : '',
    );
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
                    Text(
                      "Counter Proposal",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassTextField(
                        controller: qtyCtrl,
                        hintText: "Counter Qty",
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        if (priceCtrl.text.trim().isEmpty &&
                            qtyCtrl.text.trim().isEmpty &&
                            bagCtrl.text.trim().isEmpty) {
                          AppSnackbar.showWarning(
                            title: "Counter required",
                            message: "Enter a counter price, quantity, or bags.",
                          );
                          return;
                        }
                        Get.back();
                        controller.sendQuoteMessage(
                          rfqId: rfqId,
                          quotationId: quotationId,
                          counterPrice: priceCtrl.text.trim(),
                          counterQuantity: qtyCtrl.text.trim(),
                          bagCount: bagCtrl.text.trim(),
                          packingWeightKg: weightCtrl.text.trim(),
                          reloadDetailId: widget.offerId,
                          preferBuyerRequirement: widget.preferBuyerRequirement,
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

  Future<void> _updateQuotationStatus(
    BuildContext context, {
    required dynamic rfqId,
    required dynamic quotationId,
    required bool accept,
  }) async {
    final label = accept ? 'accept' : 'reject';
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(accept ? 'Accept quotation?' : 'Reject quotation?'),
        content: Text(
          accept
              ? 'This confirms the seller quotation and closes the other active quotations.'
              : 'This quotation will be rejected and cannot be negotiated further.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accept ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(accept ? 'Accept offer' : 'Reject quotation'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      controller.isSending(true);
      final result = accept
          ? await BuyerServices.acceptRfqQuotation(
              rfqId: rfqId,
              quotationId: quotationId,
            )
          : await BuyerServices.rejectRfqQuotation(quotationId: quotationId);
      AppSnackbar.showSuccess(
        title: accept ? 'Quotation accepted' : 'Quotation rejected',
        message: result['message'] ?? 'Quotation $label successfully.',
      );
      await controller.fetchDetails(
        widget.offerId,
        silent: true,
        preferBuyerOffer: widget.preferBuyerOffer,
        preferBuyerRequirement: widget.preferBuyerRequirement,
      );
    } catch (error) {
      AppSnackbar.showError(
        title: 'Could not $label quotation',
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      controller.isSending(false);
    }
  }

  Widget _buildStatusHeader(String status) {
    Color color = const Color(0xFFFFB300);
    if (status.contains('confirm') ||
        status.contains('active') ||
        status.contains('open'))
      color = Colors.green;
    if (status.contains('cancel') || status.contains('reject'))
      color = Colors.red;

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
          Text(
            "STATUS: ${status.toUpperCase()}",
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
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
          Expanded(
            child: Text(
              displayStr,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirm(
    BuildContext context,
    int id, {
    required bool buyerOffer,
  }) {
    Get.defaultDialog(
      title: "Cancel Requirement",
      middleText:
          "Are you sure you want to cancel and close this buying requirement?",
      textConfirm: "YES, CANCEL",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        try {
          if (buyerOffer) {
            await BuyerServices.buyerOfferAction(id, {
              'action': 'buyer_cancel',
            });
          } else {
            await BuyerServices.cancelOffer(id);
          }
          AppSnackbar.showSuccess(
            title: 'Cancelled',
            message: buyerOffer
                ? 'Buyer offer cancelled successfully.'
                : 'Requirement cancelled successfully.',
          );
          await controller.fetchDetails(
            id,
            silent: true,
            preferBuyerOffer: buyerOffer,
            preferBuyerRequirement: !buyerOffer,
          );
        } catch (error) {
          AppSnackbar.showError(
            title: 'Could not cancel',
            message: error.toString().replaceFirst('Exception: ', ''),
          );
        }
      },
      textCancel: "NO",
    );
  }
}
