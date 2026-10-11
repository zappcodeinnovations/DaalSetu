import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:daalsetu/modules/products/model/offer_interest_model.dart';
import 'package:daalsetu/services/buyer_services.dart';
import 'package:daalsetu/services/product_services.dart';
import 'package:daalsetu/theme/app_theme.dart';

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
  bool _isLoadingThread = false;
  Map<String, dynamic>? _thread;

  Color get bgColor => Get.theme.scaffoldBackgroundColor;
  Color get cardColor => Get.theme.cardColor;
  Color get textDark => Get.theme.textTheme.bodyLarge?.color ?? Colors.black;
  Color get textLight => Get.theme.textTheme.bodySmall?.color ?? Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  Future<void> _loadThread() async {
    if (!mounted) return;
    setState(() => _isLoadingThread = true);
    try {
      final response = await BuyerServices.getOfferInterestThread(
        int.tryParse(widget.offerId) ?? 0,
        widget.interest.interestId,
      );
      final raw = response['data'];
      if (raw is Map && mounted) {
        setState(() {
          _thread = Map<String, dynamic>.from(raw);
        });
      }
    } catch (e) {
      debugPrint('Could not load negotiation thread: $e');
    } finally {
      if (mounted) setState(() => _isLoadingThread = false);
    }
  }

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
                    initialValue: selectedReason,
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
          superadminRemark: '$selectedReason. ${remarkCtrl.text}'.trim(),
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
    final priceText = _negPriceCtrl.text.trim();
    final bagsText = _negBagsCtrl.text.trim();
    final weightText = _negWeightCtrl.text.trim();

    if (priceText.isEmpty && bagsText.isEmpty && weightText.isEmpty) {
      Get.snackbar(
        'Required Fields',
        'Please enter a Counter Price or Packing details.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    if ((bagsText.isNotEmpty && weightText.isEmpty) ||
        (weightText.isNotEmpty && bagsText.isEmpty)) {
      Get.snackbar(
        'Incomplete Packing Details',
        'Seller packing changes require both Bags and Packing Weight.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ProductService.sendNegotiationMessage(
        productId: int.parse(widget.offerId),
        interestId: widget.interest.interestId,
        counterPrice: priceText,
        counterQuantity: '',
        counterBagCount: bagsText,
        counterPackingWeightKg: weightText,
      );

      Get.snackbar(
        'Success',
        'Counter proposal submitted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _negPriceCtrl.clear();
      _negBagsCtrl.clear();
      _negWeightCtrl.clear();

      await _loadThread();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'Error',
        'Failed to submit: $msg',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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

  String _formatPrice(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw == '-') return '-';
    var clean = raw.trim();
    if (!clean.startsWith('₹')) clean = '₹$clean';
    if (!clean.contains('/')) clean = '$clean/TON';
    return clean;
  }

  String _formatQty(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw == '-') return '-';
    var clean = raw.trim();
    final upper = clean.toUpperCase();
    if (!upper.contains('QTL') && !upper.contains('TON') && !upper.contains('KG')) {
      clean = '$clean QTL';
    }
    return clean;
  }

  Widget _buildSummaryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED);
    final headerBorder = isDark ? Colors.white12 : const Color(0xFFFED7AA);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textLight.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Highlighted Table/Card Header (Distinct Background, Bold Styling, Clean Bottom Border)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(color: headerBorder, width: 1.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Negotiation Summary",
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    (widget.interest.status ?? 'Interested').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow("Seller Price:", _formatPrice(widget.sellerOfferAmount)),
                const SizedBox(height: 10),
                _buildSummaryRow("Available Qty:", _formatQty(widget.availableStock)),
                const SizedBox(height: 10),
                _buildSummaryRow("Current Offer:", _formatPrice(widget.interest.buyerOfferedAmount)),
                const SizedBox(height: 10),
                _buildSummaryRow("Current Qty:", _formatQty(widget.interest.requiredQuantity)),
                if (widget.interest.condition != null && widget.interest.condition!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: textLight.withValues(alpha: 0.15)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Buyer Remark: ",
                        style: TextStyle(
                          color: textDark.withValues(alpha: 0.85),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.interest.condition!,
                          style: TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: textLight.withValues(alpha: 0.15)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Seller Action",
                  style: TextStyle(
                    color: textDark.withValues(alpha: 0.85),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text("Accept", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _approveDeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                          side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
        Text(
          label,
          style: TextStyle(
            color: textDark.withValues(alpha: 0.85),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String get _displayBuyerCode {
    final fromThread = _thread?['buyer_code'] ??
        _thread?['buyer_username'] ??
        _thread?['buyer_name'];
    if (fromThread != null && fromThread.toString().trim().isNotEmpty) {
      return fromThread.toString().trim();
    }
    if (widget.interest.buyerName != null &&
        widget.interest.buyerName!.trim().isNotEmpty) {
      return widget.interest.buyerName!.trim();
    }
    return 'Buyer';
  }

  String _formatTimestamp(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw == '-') return '';
    final trimmed = raw.trim();
    try {
      DateTime? dt = DateTime.tryParse(trimmed);
      if (dt == null) {
        final isoCandidate = trimmed.replaceFirst(' ', 'T');
        dt = DateTime.tryParse(isoCandidate);
      }
      if (dt != null) {
        return DateFormat('dd MMM HH:mm').format(dt.toLocal());
      }
    } catch (_) {}
    return trimmed;
  }

  Widget _buildNegotiationLog() {
    const logHeaderBg = Color(0xFFF58220); // Signature web orange header banner
    final messages = (_thread?['messages'] as List?) ?? [];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textLight.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Highlighted Header (Web Parity Orange Header with Bottom Border)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: logHeaderBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Negotiation Log",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (_isLoadingThread)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _loadThread,
                    tooltip: 'Refresh Log',
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Initial Offer Card (Buyer)
                _buildInitialOfferCard(),

                // 2. Ongoing Counter-Proposals
                if (messages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...messages.map((m) {
                    if (m is! Map) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildProposalCard(Map<String, dynamic>.from(m)),
                    );
                  }),
                ] else if (!_isLoadingThread) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "No further negotiation proposals yet.",
                      style: TextStyle(
                        color: textLight,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialOfferCard() {
    final buyerCode = _displayBuyerCode;
    final createdAtRaw =
        _thread?['created_at']?.toString() ?? widget.interest.createdAt;
    final formattedDate = _formatTimestamp(createdAtRaw);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: textLight.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textLight.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "$buyerCode submitted initial offer:",
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (formattedDate.isNotEmpty)
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Price: ${_formatPrice(widget.interest.buyerOfferedAmount)}",
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (widget.interest.requiredQuantity != null) ...[
            const SizedBox(height: 2),
            Text(
              "Requested: ${_formatQty(widget.interest.requiredQuantity)}",
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          if (widget.interest.condition != null &&
              widget.interest.condition!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "Remark: ${widget.interest.condition}",
              style: TextStyle(
                color: textLight,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProposalCard(Map<String, dynamic> msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = (msg['actor_role'] ?? '').toString().toLowerCase();
    final isAdminOrSeller =
        role == 'admin' || role == 'seller' || role.isEmpty;

    String textVal(dynamic v) =>
        v == null || v.toString().trim() == 'null' ? '' : v.toString().trim();
    final price = textVal(msg['counter_price']);
    final quantity = textVal(msg['counter_quantity']);
    final bags = textVal(msg['counter_bag_count']);
    final packingKg = textVal(msg['counter_packing_weight_kg']);
    final status = textVal(msg['to_status']).replaceAll('_', ' ');
    final action = textVal(msg['action']).replaceAll('_', ' ');
    final timeRaw = textVal(msg['created_at']).isNotEmpty
        ? textVal(msg['created_at'])
        : textVal(msg['timestamp']);
    final formattedTime = _formatTimestamp(timeRaw);

    final cardBg = isAdminOrSeller
        ? (isDark ? const Color(0xFF2C1E14) : const Color(0xFFFFF7ED))
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC));
    final cardBorder = isAdminOrSeller
        ? const Color(0xFFFDBA74)
        : textLight.withValues(alpha: 0.2);
    final roleTitle = isAdminOrSeller
        ? (role == 'seller'
            ? 'Seller (Counter-Proposal)'
            : 'Admin (Counter-Proposal)')
        : 'Buyer (Counter-Proposal)';
    final titleColor =
        isAdminOrSeller ? const Color(0xFFEA580C) : textDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isAdminOrSeller
                        ? Icons.admin_panel_settings_outlined
                        : Icons.person_outline,
                    size: 15,
                    color: titleColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    roleTitle,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (formattedTime.isNotEmpty)
                Text(
                  formattedTime,
                  style: TextStyle(
                    color: textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (price.isNotEmpty)
            Text(
              "Counter Price: ${_formatPrice(price)}",
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          if (bags.isNotEmpty || packingKg.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              "Counter Bags: ${bags.isNotEmpty ? '$bags bags' : ''}${packingKg.isNotEmpty ? ' ($packingKg KG)' : ''}",
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          if (quantity.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              "Calculated Quantity: ${_formatQty(quantity)}",
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          if (status.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isAdminOrSeller
                    ? const Color(0xFFFED7AA)
                    : textLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isAdminOrSeller
                      ? const Color(0xFFC2410C)
                      : textDark,
                ),
              ),
            ),
          ] else if (action.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              action,
              style: TextStyle(
                color: textLight,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomForm() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(color: textLight.withValues(alpha: 0.15), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Counter Price + Counter Bags
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  label: "Counter Price (₹)",
                  hint: "Optional",
                  controller: _negPriceCtrl,
                  suffix: "/TON",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  label: "Counter Bags",
                  hint: "Optional",
                  controller: _negBagsCtrl,
                  suffix: "bags",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: Packing Weight
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  label: "Packing Weight",
                  hint: "KG",
                  controller: _negWeightCtrl,
                  suffix: "KG",
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Helper Note
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: textLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Seller packing changes require both Bags and Packing Weight; quantity is calculated automatically.",
                    style: TextStyle(
                      color: textLight,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Submit Negotiation Button (Signature Web Orange)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _submitNegotiation,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                "Submit Negotiation",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF58220),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle:
            TextStyle(color: textLight.withValues(alpha: 0.6), fontSize: 12),
        labelStyle: TextStyle(color: textLight, fontSize: 12),
        suffixText: suffix,
        suffixStyle:
            TextStyle(color: textLight, fontSize: 12, fontWeight: FontWeight.w500),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textLight.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFF58220), width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: bgColor,
      ),
    );
  }
}
