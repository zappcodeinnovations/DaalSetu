import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/products/model/offer_interest_model.dart';
import 'package:daalsetu/services/product_services.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'negotiation_page.dart';

class OfferInterestsDialog extends StatefulWidget {
  final String offerId;
  final String offerTitle;
  final String? availableStock;
  final String? sellerOfferAmount;
  final String? dealExpiry;

  const OfferInterestsDialog({
    super.key,
    required this.offerId,
    required this.offerTitle,
    this.availableStock,
    this.sellerOfferAmount,
    this.dealExpiry,
  });

  @override
  State<OfferInterestsDialog> createState() => _OfferInterestsDialogState();
}

class _OfferInterestsDialogState extends State<OfferInterestsDialog> {
  bool isLoading = true;
  String? error;
  List<OfferInterestModel> interests = [];

  Color get bgColor => Get.theme.scaffoldBackgroundColor;
  Color get cardColor => Get.theme.cardColor;
  Color get textDark => Get.theme.textTheme.bodyLarge?.color ?? Colors.black;
  Color get textLight => Get.theme.textTheme.bodySmall?.color ?? Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final res = await ProductService.getOfferInterests(int.parse(widget.offerId));
      setState(() {
        interests = res;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _openNegotiationPage(OfferInterestModel interest) async {
    final result = await Get.to(() => NegotiationPage(
      offerId: widget.offerId,
      offerTitle: widget.offerTitle,
      availableStock: widget.availableStock,
      sellerOfferAmount: widget.sellerOfferAmount,
      interest: interest,
    ));

    // If the negotiation page returns true, a deal was accepted/rejected, so we refresh the interests
    if (result == true) {
      _loadInterests();
    }
  }

  Future<void> _approveDeal(OfferInterestModel interest) async {
    final remarkCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: Text("Approve Deal", style: TextStyle(color: textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Confirm deal with ${interest.buyerName}?",
              style: TextStyle(color: textDark),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarkCtrl,
              style: TextStyle(color: textDark),
              decoration: InputDecoration(
                labelText: "Admin Remark (Optional)",
                labelStyle: TextStyle(color: textLight),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textLight.withValues(alpha: 0.3))),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryGold)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: TextStyle(color: textLight)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.successGreen),
            child: const Text("Approve", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => isLoading = true);
      try {
        await ProductService.confirmOfferDeal(
          productId: int.parse(widget.offerId),
          interestId: interest.interestId,
          decision: "approve",
          superadminRemark: remarkCtrl.text,
        );
        Get.snackbar('Success', 'Deal approved successfully',
            backgroundColor: Colors.green, colorText: Colors.white);
        await _loadInterests();
      } catch (e) {
        setState(() => isLoading = false);
        Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> _rejectDeal(OfferInterestModel interest) async {
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
                  Text("Rejecting deal with ${interest.buyerName}", style: TextStyle(color: textDark)),
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
      setState(() => isLoading = true);
      try {
        await ProductService.confirmOfferDeal(
          productId: int.parse(widget.offerId),
          interestId: interest.interestId,
          decision: "reject",
          superadminRemark: '${selectedReason}. ${remarkCtrl.text}'.trim(),
        );
        Get.snackbar('Rejected', 'Deal rejected successfully',
            backgroundColor: Colors.red, colorText: Colors.white);
        await _loadInterests();
      } catch (e) {
        setState(() => isLoading = false);
        Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.bottomCenter,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle for visual bottom sheet cue
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: textDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Manage Offer", style: TextStyle(color: textLight, fontSize: 12)),
                        Text(
                          widget.offerTitle,
                          style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge('Active'),
                ],
              ),
            ),
            Divider(color: textLight.withValues(alpha: 0.1)),

            // Summary Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSummaryCard("📦 Available Qty", "${widget.availableStock ?? '-'} QTL"),
                  _buildSummaryCard("💰 Seller Price", "₹${widget.sellerOfferAmount ?? '-'} /QTL"),
                  _buildSummaryCard("📅 Deal Expiry", widget.dealExpiry ?? '-'),
                ],
              ),
            ),
            
            // Interests List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
                  : error != null
                      ? Center(child: Text(error!, style: const TextStyle(color: AppTheme.errorRed)))
                      : interests.isEmpty
                          ? Center(child: Text("No interests found.", style: TextStyle(color: textLight)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: interests.length,
                              itemBuilder: (context, index) {
                                return _buildInterestCard(interests[index]);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textLight.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(color: textLight, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInterestCard(OfferInterestModel interest) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: textLight.withValues(alpha: 0.1)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Code and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  interest.transactionId.isNotEmpty ? interest.transactionId : 'INT-${interest.interestId}',
                  style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  interest.createdAt?.substring(0, 10) ?? '-',
                  style: TextStyle(color: textLight, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Info Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Interested Amount", style: TextStyle(color: textLight, fontSize: 11)),
                      Text("₹${interest.buyerOfferedAmount}/QTL", style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Requested Qty", style: TextStyle(color: textLight, fontSize: 11)),
                      Text("${interest.requiredQuantity ?? '-'} QTL", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Buyer Info
            Row(
              children: [
                Icon(Icons.person, color: textLight, size: 16),
                const SizedBox(width: 6),
                Text(interest.buyerName ?? 'Unknown Buyer', style: TextStyle(color: textDark, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: textLight.withValues(alpha: 0.1)),
            
            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _openNegotiationPage(interest),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.15),
                    foregroundColor: AppTheme.primaryGold,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.handshake, size: 14),
                  label: const Text("Negotiation", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                FilledButton.icon(
                  onPressed: () => _approveDeal(interest),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.successGreen.withValues(alpha: 0.15),
                    foregroundColor: AppTheme.successGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text("Accept", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                FilledButton.icon(
                  onPressed: () => _rejectDeal(interest),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.errorRed.withValues(alpha: 0.15),
                    foregroundColor: AppTheme.errorRed,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text("Reject", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppTheme.primaryGold,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
