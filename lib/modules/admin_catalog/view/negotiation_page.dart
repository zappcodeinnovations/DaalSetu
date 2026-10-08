import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/products/model/offer_interest_model.dart';
import 'package:daalsetu/services/product_services.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'package:intl/intl.dart';

import 'approve_deal_dialog.dart';

class NegotiationPage extends StatefulWidget {
  final String offerId;
  final String offerTitle;
  final String? availableStock;
  final String? sellerOfferAmount;
  final OfferInterestModel interest;

  const NegotiationPage({
    super.key,
    required this.offerId,
    required this.offerTitle,
    this.availableStock,
    this.sellerOfferAmount,
    required this.interest,
  });

  @override
  State<NegotiationPage> createState() => _NegotiationPageState();
}

class _NegotiationPageState extends State<NegotiationPage> {
  final TextEditingController _negPriceCtrl = TextEditingController();
  final TextEditingController _negBagsCtrl = TextEditingController();
  final TextEditingController _negWeightCtrl = TextEditingController();
  bool _isLoading = false;

  Color get bgColor => Get.theme.scaffoldBackgroundColor;
  Color get cardColor => Get.theme.cardColor;
  Color get textDark => Get.theme.textTheme.bodyLarge?.color ?? Colors.black;
  Color get textLight => Get.theme.textTheme.bodySmall?.color ?? Colors.grey;

  @override
  void dispose() {
    _negPriceCtrl.dispose();
    _negBagsCtrl.dispose();
    _negWeightCtrl.dispose();
    super.dispose();
  }

  Future<void> _approveDeal() async {
    final result = await showDialog<ApproveDealResult>(
      context: context,
      builder: (ctx) => ApproveDealDialog(
        buyerName: widget.interest.buyerName,
        offerTitle: widget.offerTitle,
      ),
    );

    if (result != null && mounted) {
      setState(() => _isLoading = true);
      try {
        await ProductService.confirmOfferDeal(
          productId: int.parse(widget.offerId),
          interestId: widget.interest.interestId,
          decision: "approve",
          superadminRemark: result.remark,
          subAdminId: result.subAdminId,
        );
        Get.snackbar('Success', 'Deal approved successfully',
            backgroundColor: Colors.green, colorText: Colors.white);
        Get.back(result: true); // Pop back to close negotiation screen
      } catch (e) {
        setState(() => _isLoading = false);
        final message = e.toString().replaceFirst('Exception: ', '');
        Get.snackbar('Error', message, backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> _rejectDeal() async {
    final remarkCtrl = TextEditingController();
    String selectedReason = 'Price too low';
    final reasons = ['Price too low', 'Quantity not available', 'Buyer not verified', 'Other'];

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Reject Deal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.errorRed)),
                  const SizedBox(height: 8),
                  Text("Rejecting deal with ${widget.interest.buyerName}", style: TextStyle(color: textDark)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    dropdownColor: cardColor,
                    style: TextStyle(color: textDark),
                    decoration: InputDecoration(
                      labelText: "Reason",
                      labelStyle: TextStyle(color: textLight),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textLight.withValues(alpha: 0.3))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.errorRed)),
                    ),
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() => selectedReason = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: remarkCtrl,
                    style: TextStyle(color: textDark),
                    decoration: InputDecoration(
                      labelText: "Remarks (Optional)",
                      labelStyle: TextStyle(color: textLight),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textLight.withValues(alpha: 0.3))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.errorRed)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textDark,
                            side: BorderSide(color: textLight.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.errorRed,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Reject", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      },
    );

    if (result == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await ProductService.confirmOfferDeal(
          productId: int.parse(widget.offerId),
          interestId: widget.interest.interestId,
          decision: "reject",
          superadminRemark: '${selectedReason}. ${remarkCtrl.text}'.trim(),
        );
        Get.snackbar('Rejected', 'Deal rejected successfully',
            backgroundColor: Colors.red, colorText: Colors.white);
        Get.back(result: true); // Pop back to close negotiation screen
      } catch (e) {
        setState(() => _isLoading = false);
        Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> _submitNegotiation() async {
    if (_negPriceCtrl.text.isEmpty) {
      Get.snackbar('Error', 'Counter price is required.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final double counterPrice = double.tryParse(_negPriceCtrl.text) ?? 0;
      final int? counterBags = int.tryParse(_negBagsCtrl.text);
      final double? packingWeight = double.tryParse(_negWeightCtrl.text);

      String msgBody = 'Counter offer price: ₹$counterPrice/TON';
      if (counterBags != null && packingWeight != null) {
        msgBody += ' | Bags: $counterBags | Packing: $packingWeight KG';
      }

      await ProductService.sendNegotiationMessage(
        productId: int.parse(widget.offerId),
        interestId: widget.interest.interestId,
        counterPrice: counterPrice.toString(),
        counterQuantity: counterBags?.toString() ?? '',
        message: msgBody,
      );

      Get.snackbar('Success', 'Counter offer submitted', backgroundColor: Colors.green, colorText: Colors.white);
      _negPriceCtrl.clear();
      _negBagsCtrl.clear();
      _negWeightCtrl.clear();
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit: ${e.toString()}', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Negotiation: ${widget.offerTitle}", style: TextStyle(fontSize: 16)),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _buildLayout(),
    );
  }

  Widget _buildLayout() {
    // For smaller screens we can just scroll the whole thing, but a Column is better
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 20),
                _buildNegotiationLog(),
              ],
            ),
          ),
        ),
        _buildBottomForm(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textLight.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Negotiation Summary", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.interest.status ?? 'Interested',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow("Seller Price:", widget.sellerOfferAmount ?? '-'),
                const SizedBox(height: 8),
                _buildSummaryRow("Available Qty:", widget.availableStock ?? '-'),
                const SizedBox(height: 8),
                _buildSummaryRow("Current Offer:", widget.interest.buyerOfferedAmount != null ? '₹${widget.interest.buyerOfferedAmount}/TON' : '-'),
                const SizedBox(height: 8),
                _buildSummaryRow("Current Qty:", widget.interest.requiredQuantity != null ? '${widget.interest.requiredQuantity} QTL' : '-'),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Seller Action", style: TextStyle(color: textLight, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text("Accept"),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _approveDeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text("Reject"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                          side: const BorderSide(color: AppTheme.errorRed),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _rejectDeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: textLight, fontSize: 14)),
        Text(value, style: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildNegotiationLog() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textLight.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text("Negotiation Log", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: textLight.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: textLight.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.interest.buyerName ?? 'Buyer'} submitted initial offer:",
                        style: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text("Price: ₹${widget.interest.buyerOfferedAmount}/TON", style: TextStyle(color: textDark, fontSize: 13)),
                      if (widget.interest.requiredQuantity != null)
                        Text("Requested: ${widget.interest.requiredQuantity} QTL", style: TextStyle(color: textDark, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        widget.interest.createdAt ?? "Recently",
                        style: TextStyle(color: textLight, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "No further negotiation proposals yet.",
                    style: TextStyle(color: textLight, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomForm() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildInput("Counter Price (₹)", _negPriceCtrl, suffix: "/TON"),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildInput("Counter Bags", _negBagsCtrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildInput("Packing KG", _negWeightCtrl),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitNegotiation,
              icon: const Icon(Icons.handshake, size: 18),
              label: const Text("Submit Negotiation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController ctrl, {String? suffix}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      maxLength: 10,
      style: TextStyle(color: textDark, fontSize: 14),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: textLight, fontSize: 12),
        suffixText: suffix,
        suffixStyle: TextStyle(color: textLight, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textLight.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.primaryGold),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: bgColor,
      ),
    );
  }
}
