import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:daalsetu/modules/products/model/offer_interest_model.dart';
import 'package:daalsetu/services/product_services.dart';
import 'package:daalsetu/services/seller_services.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:daalsetu/modules/shared/view/offer_interest_negotiation_chat_view.dart';
import 'approve_deal_dialog.dart';
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
  String _role = '';

  String? _loadedTitle;
  String? _loadedStock;
  String? _loadedPrice;
  String? _loadedExpiry;

  bool get _isAdminRole =>
      const {'admin', 'super_admin', 'sub_admin'}.contains(_role);

  Color get bgColor => Get.theme.scaffoldBackgroundColor;
  Color get cardColor => Get.theme.cardColor;
  Color get textDark => Get.theme.textTheme.bodyLarge?.color ?? Colors.black;
  Color get textLight => Get.theme.textTheme.bodySmall?.color ?? Colors.grey;

  String get displayTitle {
    if (_loadedTitle != null && _loadedTitle!.isNotEmpty) return _loadedTitle!;
    if (widget.offerTitle.isNotEmpty &&
        !widget.offerTitle.startsWith('Offer #') &&
        !widget.offerTitle.toLowerCase().contains('notification') &&
        !widget.offerTitle.toLowerCase().contains('confirmed')) {
      return widget.offerTitle;
    }
    return _loadedTitle ?? 'Offer #${widget.offerId}';
  }

  String get displayStock {
    if (_loadedStock != null && _loadedStock!.isNotEmpty) return _loadedStock!;
    if (widget.availableStock != null && widget.availableStock!.isNotEmpty) {
      return widget.availableStock!.endsWith('QTL')
          ? widget.availableStock!
          : "${widget.availableStock} QTL";
    }
    return "- QTL";
  }

  String get displayPrice {
    if (_loadedPrice != null && _loadedPrice!.isNotEmpty) return _loadedPrice!;
    if (widget.sellerOfferAmount != null && widget.sellerOfferAmount!.isNotEmpty) {
      final amt = widget.sellerOfferAmount!;
      return amt.startsWith('₹') ? amt : "₹$amt/TON";
    }
    return "-";
  }

  String get displayExpiry {
    final raw = _loadedExpiry ?? widget.dealExpiry;
    return _formatDealExpiry(raw);
  }

  @override
  void initState() {
    super.initState();
    _loadInterests();
    AppPreferences.getRole().then((role) {
      if (mounted) setState(() => _role = (role ?? '').trim().toLowerCase());
    });
  }

  Future<void> _loadInterests() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final res = await ProductService.getOfferInterests(
        int.parse(widget.offerId),
      );

      // Auto-fetch extra offer specifications if not passed directly
      if (_loadedTitle == null) {
        try {
          final prodId = int.tryParse(widget.offerId);
          if (prodId != null) {
            final detail = await SellerServices.getOfferDetail(prodId);
            final map = (detail['product'] is Map)
                ? detail['product']
                : ((detail['data'] is Map)
                    ? detail['data']
                    : ((detail['offer'] is Map) ? detail['offer'] : detail));
            if (map is Map) {
              _loadedTitle = map['title']?.toString() ?? map['product_title']?.toString();
              final stock = map['available_quantity'] ??
                  map['remaining_quantity'] ??
                  map['quantity_qtl'] ??
                  map['quantity'];
              if (stock != null) _loadedStock = '$stock QTL';
              final amt = map['amount'] ?? map['seller_offer_amount'] ?? map['price'];
              final unit = (map['amount_unit'] ?? map['quantity_unit'] ?? 'TON')
                  .toString()
                  .toUpperCase();
              if (amt != null) _loadedPrice = '₹$amt/$unit';
              _loadedExpiry = map['deal_expiry_datetime']?.toString() ??
                  map['loading_to']?.toString();
            }
          }
        } catch (e) {
          debugPrint("Note: Could not fetch additional offer details: $e");
        }
      }

      if (mounted) {
        setState(() {
          interests = res;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  String _formatDealExpiry(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw == '-') return '-';
    final trimmed = raw.trim();

    // 1. Try ISO datetime regex: 2026-10-14T00:00:00...
    final isoMatch = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})',
    ).firstMatch(trimmed);
    if (isoMatch != null) {
      final y = int.tryParse(isoMatch.group(1)!) ?? 0;
      final m = int.tryParse(isoMatch.group(2)!) ?? 1;
      final d = int.tryParse(isoMatch.group(3)!) ?? 1;
      final h = int.tryParse(isoMatch.group(4)!) ?? 0;
      final min = int.tryParse(isoMatch.group(5)!) ?? 0;

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final monthName = (m >= 1 && m <= 12) ? months[m - 1] : '$m';
      final hour12 = h % 12 == 0 ? 12 : h % 12;
      final minuteStr = min.toString().padLeft(2, '0');
      final amPm = h >= 12 ? 'PM' : 'AM';
      return '$d $monthName $y, $hour12:$minuteStr $amPm';
    }

    // 2. Try ISO date only regex: 2026-10-14
    final dateOnlyMatch =
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
    if (dateOnlyMatch != null) {
      final y = int.tryParse(dateOnlyMatch.group(1)!) ?? 0;
      final m = int.tryParse(dateOnlyMatch.group(2)!) ?? 1;
      final d = int.tryParse(dateOnlyMatch.group(3)!) ?? 1;
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final monthName = (m >= 1 && m <= 12) ? months[m - 1] : '$m';
      return '$d $monthName $y';
    }

    // 3. Try standard DateTime parsing with DateFormat
    try {
      final dt = DateTime.parse(trimmed).toLocal();
      return DateFormat('d MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return trimmed;
    }
  }

  void _openNegotiationPage(OfferInterestModel interest) async {
    final result = await Get.to(
      () => _isAdminRole
          ? NegotiationPage(
              offerId: widget.offerId,
              offerTitle: displayTitle,
              availableStock: displayStock,
              sellerOfferAmount: displayPrice,
              interest: interest,
            )
          : OfferInterestNegotiationChatView(
              productId: int.parse(widget.offerId),
              interestId: interest.interestId,
              isBuyer: false,
              allowDecisions: !_isAdminRole,
            ),
    );

    // If the negotiation page returns true, a deal was accepted/rejected, so we refresh the interests
    if (result == true) {
      _loadInterests();
    }
  }

  Future<void> _approveDeal(OfferInterestModel interest) async {
    final status = (interest.status ?? '').trim().toLowerCase();
    late final ApproveDealResult result;
    final adminResult = await showDialog<ApproveDealResult>(
      context: context,
      builder: (ctx) => ApproveDealDialog(
        buyerName: interest.buyerName,
        offerTitle: displayTitle,
      ),
    );
    if (adminResult == null) return;
    result = adminResult;

    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      if (status == 'interested') {
        await SellerServices.approveBuyerInterest(
          int.parse(widget.offerId),
          interest.interestId,
          remark: result.remark,
          subAdminId: result.subAdminId,
        );
        Get.snackbar(
          'Accepted',
          'Interest accepted. Waiting for buyer confirmation.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        await ProductService.confirmOfferDeal(
          productId: int.parse(widget.offerId),
          interestId: interest.interestId,
          decision: "approve",
          superadminRemark: result.remark,
          subAdminId: result.subAdminId,
        );
        Get.snackbar(
          'Success',
          'Deal approved successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
      await _loadInterests();
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      final message = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _rejectDeal(OfferInterestModel interest) async {
    final remarkCtrl = TextEditingController();
    String selectedReason = 'Price too low';
    final reasons = [
      'Price too low',
      'Quantity not available',
      'Buyer not verified',
      'Other',
    ];

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
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reject Deal",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    decoration: InputDecoration(
                      labelText: "Reason",
                      labelStyle: TextStyle(color: textLight),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: textLight.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.errorRed),
                      ),
                    ),
                    items: reasons
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
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
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: textLight.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.errorRed),
                      ),
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
                            side: BorderSide(
                              color: textLight.withValues(alpha: 0.3),
                            ),
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
                          child: const Text(
                            "Reject",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      setState(() => isLoading = true);
      try {
        final status = (interest.status ?? '').trim().toLowerCase();
        final remark = '$selectedReason. ${remarkCtrl.text}'.trim();
        if (status == 'interested') {
          await SellerServices.rejectBuyerInterest(
            int.parse(widget.offerId),
            interest.interestId,
            remark: remark,
          );
        } else {
          await ProductService.confirmOfferDeal(
            productId: int.parse(widget.offerId),
            interestId: interest.interestId,
            decision: "reject",
            superadminRemark: remark,
          );
        }
        Get.snackbar(
          'Rejected',
          'Deal rejected successfully',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        await _loadInterests();
      } catch (e) {
        setState(() => isLoading = false);
        Get.snackbar(
          'Error',
          e.toString(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFDF8);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      alignment: Alignment.center,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: mediaQuery.size.height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: dialogBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Orange Header matching website modal: "Manage Offer: <Title>" + Close "✕"
                _buildHeader(),

                // 2. Offer Summary Section (Available, Seller Offer Amount, Deal Expiry)
                _buildSummaryInfo(isDark),

                // 3. Responsive Content: Mobile Cards or Tablet Table (Zero Render Overflow)
                Expanded(
                  child: _buildInterestsContent(isDark, isMobile),
                ),

                // 4. Modal Footer: [Close] button
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Orange Header Banner (Web Parity) ───────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF58220), // Website's exact orange brand banner
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Manage Offer: $displayTitle",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Summary Info Section (Web Parity) ───────────────────────────────────
  Widget _buildSummaryInfo(bool isDark) {
    final infoBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB);
    return Container(
      width: double.infinity,
      color: infoBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
              children: [
                const TextSpan(
                  text: "Available: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: displayStock,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
              children: [
                const TextSpan(
                  text: "Seller Offer Amount: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: displayPrice,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
              children: [
                const TextSpan(
                  text: "Deal Expiry: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: displayExpiry,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Responsive Content Section ─────────────────────────────────────────
  Widget _buildInterestsContent(bool isDark, bool isMobile) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF58220)),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.errorRed),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadInterests,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (interests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            "No interested buyers found for this offer.",
            style: TextStyle(color: textLight, fontSize: 13),
          ),
        ),
      );
    }

    // ── On Mobile Phones: Responsive Card Layout (Zero Horizontal Scroll, Zero Overflow)
    if (isMobile) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        itemCount: interests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _buildMobileInterestCard(interests[index], isDark);
        },
      );
    }

    // ── On Tablet / Desktop: Full Web Table Layout
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 620),
              child: SizedBox(
                width: 680,
                child: Column(
                  children: [
                    _buildTableHeader(isDark),
                    Expanded(
                      child: ListView.builder(
                        itemCount: interests.length,
                        itemBuilder: (context, index) {
                          final item = interests[index];
                          final isLast = index == interests.length - 1;
                          return _buildTableRow(item, isLast, isDark);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile Responsive Interest Card (Zero Overflow Guaranteed) ───────────
  Widget _buildMobileInterestCard(OfferInterestModel interest, bool isDark) {
    final statusStr = interest.statusLabel.toLowerCase();
    final canDecide = _isAdminRole ||
        interest.canSellerAction ||
        interest.canAdminFinalAction ||
        statusStr == 'interested' ||
        statusStr == 'pending' ||
        statusStr == 'countered';

    final canNegotiate = interest.canOpenNegotiation ||
        _isAdminRole ||
        interest.isReadOnly ||
        statusStr != 'rejected';

    final interestCode = interest.transactionId.isNotEmpty
        ? interest.transactionId
        : (interest.buyerName != null && interest.buyerName!.isNotEmpty
            ? interest.buyerName!
            : 'INT-${interest.interestId}');

    final interestAmount = interest.buyerOfferedAmount.isNotEmpty
        ? '₹${interest.buyerOfferedAmount}'
        : '-';

    const goldText = Color(0xFFB45309);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Code and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "INTERESTED CODE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: goldText,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      interestCode,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    if (interest.createdAt != null && interest.createdAt!.isNotEmpty)
                      Text(
                        interest.createdAt!.length >= 10
                            ? interest.createdAt!.substring(0, 10)
                            : interest.createdAt!,
                        style: TextStyle(color: textLight, fontSize: 10),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(statusStr),
            ],
          ),

          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 10),

          // Row 2: Amount & Quantity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "INTERESTED AMOUNT",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: goldText,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    interestAmount,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              if (interest.requiredQuantity != null &&
                  interest.requiredQuantity!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "REQ QUANTITY",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textLight,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${interest.requiredQuantity} QTL",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 3: Action Buttons (Wrap guarantees 0 horizontal overflow)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canNegotiate) _buildNegotiateButton(interest),
              if (canDecide) _buildAcceptButton(interest),
              if (canDecide) _buildRejectButton(interest),
            ],
          ),
        ],
      ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────────
  Widget _buildNegotiateButton(OfferInterestModel interest) {
    return InkWell(
      onTap: () => _openNegotiationPage(interest),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 13,
              color: Color(0xFFEA580C),
            ),
            const SizedBox(width: 5),
            Text(
              interest.isReadOnly ? "History" : "Negotiation",
              style: const TextStyle(
                color: Color(0xFFEA580C),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptButton(OfferInterestModel interest) {
    return InkWell(
      onTap: () => _approveDeal(interest),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF6EE7B7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_rounded,
              size: 14,
              color: Color(0xFF059669),
            ),
            const SizedBox(width: 4),
            Text(
              interest.canAdminFinalAction ? "Approve" : "Accept",
              style: const TextStyle(
                color: Color(0xFF059669),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectButton(OfferInterestModel interest) {
    return InkWell(
      onTap: () => _rejectDeal(interest),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFFDC2626),
            ),
            SizedBox(width: 4),
            Text(
              "Reject",
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String statusStr) {
    Color bg;
    Color text;
    if (statusStr.contains('accept') || statusStr.contains('confirm')) {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF15803D);
    } else if (statusStr.contains('reject') || statusStr.contains('cancel')) {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFB91C1C);
    } else {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusStr,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  // ── Tablet / Desktop Table Elements ───────────────────────────────────────
  Widget _buildTableHeader(bool isDark) {
    final headerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB);
    const goldText = Color(0xFFB45309);

    return Container(
      color: headerBg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "INTERESTED CODE",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: goldText,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "INTERESTED AMOUNT",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: goldText,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "STATUS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: goldText,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              "ACTION",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: goldText,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(OfferInterestModel interest, bool isLast, bool isDark) {
    final statusStr = interest.statusLabel.toLowerCase();
    final canDecide = _isAdminRole ||
        interest.canSellerAction ||
        interest.canAdminFinalAction ||
        statusStr == 'interested' ||
        statusStr == 'pending' ||
        statusStr == 'countered';

    final canNegotiate = interest.canOpenNegotiation ||
        _isAdminRole ||
        interest.isReadOnly ||
        statusStr != 'rejected';

    final interestCode = interest.transactionId.isNotEmpty
        ? interest.transactionId
        : (interest.buyerName != null && interest.buyerName!.isNotEmpty
            ? interest.buyerName!
            : 'INT-${interest.interestId}');

    final interestAmount = interest.buyerOfferedAmount.isNotEmpty
        ? '₹${interest.buyerOfferedAmount}'
        : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. INTERESTED CODE
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  interestCode,
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (interest.createdAt != null && interest.createdAt!.isNotEmpty)
                  Text(
                    interest.createdAt!.length >= 10
                        ? interest.createdAt!.substring(0, 10)
                        : interest.createdAt!,
                    style: TextStyle(color: textLight, fontSize: 10),
                  ),
              ],
            ),
          ),

          // 2. INTERESTED AMOUNT
          Expanded(
            flex: 2,
            child: Text(
              interestAmount,
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),

          // 3. STATUS
          Expanded(
            flex: 2,
            child: _buildStatusBadge(statusStr),
          ),

          const SizedBox(width: 8),

          // 4. ACTION (Negotiation | Accept | Reject) with Wrap
          Expanded(
            flex: 5,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 4,
              children: [
                if (canNegotiate) _buildNegotiateButton(interest),
                if (canDecide) _buildAcceptButton(interest),
                if (canDecide) _buildRejectButton(interest),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Bottom Footer (Web Parity) ──────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: textLight.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: textDark,
              side: BorderSide(color: textLight.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Close",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
