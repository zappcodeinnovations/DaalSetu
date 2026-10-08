import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../../services/buyer_services.dart';
import '../model/buyer_offer_model.dart';

class BuyerNegotiationView extends StatefulWidget {
  final BuyerOfferModel offer;

  const BuyerNegotiationView({super.key, required this.offer});

  @override
  State<BuyerNegotiationView> createState() => _BuyerNegotiationViewState();
}

class _BuyerNegotiationViewState extends State<BuyerNegotiationView> {
  final TextEditingController _msgCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _isLoading = false;
  bool _isSending = false;
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _interestDetail;
  Timer? _pollTimer;

  int get effectiveProductId {
    if (_interestDetail != null) {
      final p = _interestDetail!['product_id'] ?? _interestDetail!['product'];
      if (p is Map && p['id'] != null) {
        final parsed = int.tryParse(p['id'].toString());
        if (parsed != null && parsed > 0) return parsed;
      }
      if (p != null) {
        final parsed = int.tryParse(p.toString());
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return widget.offer.productId ?? widget.offer.id ?? 0;
  }

  int get effectiveInterestId {
    if (_interestDetail != null) {
      final i = _interestDetail!['interest_id'] ?? _interestDetail!['id'];
      if (i is Map && i['id'] != null) {
        final parsed = int.tryParse(i['id'].toString());
        if (parsed != null && parsed > 0) return parsed;
      }
      if (i != null) {
        final parsed = int.tryParse(i.toString());
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return widget.offer.interestId ?? widget.offer.id ?? 0;
  }

  int get productId => effectiveProductId;
  int get interestId => effectiveInterestId;

  @override
  void initState() {
    super.initState();
    _fetchNegotiationDetails();
    // Auto-refresh negotiations live every 3 seconds in background without needing manual reload
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _fetchNegotiationDetails(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String formatDateTimeLocal(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      DateTime dt;
      if (raw.contains('T')) {
        dt = DateTime.parse(raw).toLocal();
      } else if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw)) {
        dt = DateTime.parse(raw).toLocal();
      } else {
        return raw;
      }
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return "$day-$month-${dt.year} $hour:$min";
    } catch (_) {
      return raw;
    }
  }

  Future<void> _fetchNegotiationDetails({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? matchedInterest;

      // 1. Fetch from authorized buyer endpoint: /api/offers/my-interests/list/
      try {
        final interests = await BuyerServices.getMyInterests();
        for (var item in interests) {
          if (item is Map) {
            final pId = item['product_id'] ?? (item['product'] is Map ? item['product']['id'] : item['product']);
            final iId = item['interest_id'] ?? item['id'];
            final baseId = item['id'];

            final targetPId = widget.offer.productId ?? widget.offer.id;
            final targetIId = widget.offer.interestId ?? widget.offer.id;

            if ((pId != null && targetPId != null && pId.toString() == targetPId.toString()) ||
                (iId != null && targetIId != null && iId.toString() == targetIId.toString()) ||
                (baseId != null && (baseId.toString() == targetIId.toString() || baseId.toString() == targetPId.toString()))) {
              matchedInterest = Map<String, dynamic>.from(item);
              break;
            }
          }
        }
      } catch (_) {}

      if (matchedInterest != null && mounted) {
        final List<Map<String, dynamic>> serverMsgs = [];

        // Check nested messages, proposals, or chat logs from backend
        dynamic rawList = matchedInterest['messages'] ??
            matchedInterest['proposals'] ??
            matchedInterest['negotiations'] ??
            matchedInterest['history'] ??
            matchedInterest['chat'];

        if (rawList is List) {
          for (var item in rawList) {
            if (item is Map) {
              final senderRole = item['sender_role'] ?? item['role'] ?? item['sender'];
              final String sender = (senderRole?.toString().toLowerCase() == 'seller' ||
                      senderRole?.toString().toLowerCase() == 'admin')
                  ? 'Seller'
                  : 'Buyer';
              serverMsgs.add({
                "id": item['id'],
                "sender": sender,
                "message": item['message'] ?? item['text'] ?? item['remark'] ?? '',
                "counter_price": item['counter_price'] ?? item['price'] ?? item['offered_amount'] ?? '',
                "counter_quantity": item['counter_quantity'] ?? item['quantity'] ?? item['required_quantity'] ?? '',
                "created_at": item['created_at'] ?? item['timestamp'] ?? item['created'] ?? '',
              });
            }
          }
        }

        // Check if there's a seller counter proposal field (e.g. 45 or remark)
        final counterPrice = matchedInterest['counter_price'] ??
            matchedInterest['seller_counter_amount'] ??
            matchedInterest['admin_counter_price'];
        final counterQty = matchedInterest['counter_quantity'] ??
            matchedInterest['seller_counter_quantity'];
        final sellerRemark = matchedInterest['seller_remark'] ??
            matchedInterest['admin_remark'] ??
            matchedInterest['counter_remark'];

        if ((counterPrice != null && counterPrice.toString().isNotEmpty) ||
            (sellerRemark != null && sellerRemark.toString().isNotEmpty)) {
          final exists = serverMsgs.any((m) =>
              m['counter_price']?.toString() == counterPrice?.toString() &&
              m['sender'] == 'Seller');
          if (!exists) {
            serverMsgs.add({
              "sender": "Seller",
              "counter_price": counterPrice?.toString() ?? '',
              "counter_quantity": counterQty?.toString() ?? '',
              "message": sellerRemark?.toString() ?? '',
              "created_at": matchedInterest['updated_at'] ?? matchedInterest['created_at'] ?? '',
            });
          }
        }

        setState(() {
          _interestDetail = matchedInterest;
          if (serverMsgs.isNotEmpty) {
            // Merge with existing local messages without duplicates
            for (var sm in serverMsgs) {
              final exists = _messages.any((lm) =>
                  (sm['id'] != null && lm['id'] != null && sm['id'].toString() == lm['id'].toString()) ||
                  (lm['message'] == sm['message'] &&
                      lm['counter_price']?.toString() == sm['counter_price']?.toString() &&
                      lm['counter_quantity']?.toString() == sm['counter_quantity']?.toString() &&
                      lm['sender'] == sm['sender']));
              if (!exists) {
                _messages.add(sm);
              }
            }
          }
        });
      }
    } catch (_) {
    } finally {
      if (!silent && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitNegotiation() async {
    final msg = _msgCtrl.text.trim();
    String price = _priceCtrl.text.replaceAll('₹', '').replaceAll(',', '').trim();
    String qty = _qtyCtrl.text.replaceAll(',', '').trim();

    if (msg.isEmpty && price.isEmpty && qty.isEmpty) {
      AppSnackbar.showWarning(title: "Required", message: "Please enter a message or counter offer values");
      return;
    }

    // Default price to current offer price if omitted
    if (price.isEmpty) {
      price = _interestDetail?['buyer_offered_amount']?.toString() ??
          _interestDetail?['offered_amount']?.toString() ??
          widget.offer.requestedAmount ??
          '';
    }

    // Default qty to current requested/available quantity if omitted
    if (qty.isEmpty) {
      qty = _interestDetail?['buyer_required_quantity']?.toString() ??
          _interestDetail?['required_quantity']?.toString() ??
          widget.offer.requestedQuantity ??
          widget.offer.displayQuantity ??
          '';
    }

    final int targetPId = effectiveProductId > 0 ? effectiveProductId : (widget.offer.productId ?? widget.offer.id ?? 0);
    final int targetIId = effectiveInterestId > 0 ? effectiveInterestId : (widget.offer.interestId ?? widget.offer.id ?? 0);

    print("📤 SUBMITTING NEGOTIATION -> ProductId: $targetPId | InterestId: $targetIId | Price: $price | Qty: $qty");

    setState(() => _isSending = true);
    try {
      final res = await BuyerServices.sendNegotiationMessage(
        targetPId,
        targetIId,
        message: msg.isNotEmpty ? msg : "Counter Proposal: Price ₹$price, Qty $qty",
        counterAmount: price,
        counterQuantity: qty,
      );

      AppSnackbar.showSuccess(
        title: "Submitted",
        message: res['message'] ?? "Negotiation proposal submitted successfully",
      );

      // Unpack response data from senior's API spec if available
      final data = res['data'];
      final String senderRole = (data is Map && data['sender_role'] != null)
          ? (data['sender_role'].toString().toLowerCase() == 'seller' ? 'Seller' : 'Buyer')
          : 'Buyer';
      final String newMsgText = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (msg.isNotEmpty ? msg : "Counter Proposal: Price ₹$price");
      final String newPrice = (data is Map && data['counter_price'] != null)
          ? data['counter_price'].toString()
          : price;
      final String newQty = (data is Map && data['counter_quantity'] != null)
          ? data['counter_quantity'].toString()
          : qty;
      final String createdAt = (data is Map && data['created_at'] != null)
          ? data['created_at'].toString()
          : DateTime.now().toLocal().toIso8601String();

      // Append locally to timeline and update current offer values in summary immediately
      setState(() {
        if (_interestDetail != null) {
          if (price.isNotEmpty) {
            _interestDetail!['buyer_offered_amount'] = price;
            _interestDetail!['offered_amount'] = price;
          }
          if (qty.isNotEmpty) {
            _interestDetail!['buyer_required_quantity'] = qty;
            _interestDetail!['required_quantity'] = qty;
          }
        }
        _messages.add({
          "id": data is Map ? data['id'] : null,
          "sender": senderRole,
          "message": newMsgText,
          "counter_price": newPrice.isNotEmpty ? newPrice : price,
          "counter_quantity": newQty.isNotEmpty ? newQty : qty,
          "created_at": createdAt,
        });
      });

      _msgCtrl.clear();
      _priceCtrl.clear();
      _qtyCtrl.clear();

      await _fetchNegotiationDetails(silent: true);

      // Smoothly scroll down
      if (_scrollCtrl.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      AppSnackbar.showError(title: "Failed", message: e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleAccept() async {
    final remarkCtrl = TextEditingController();
    final confirm = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Accept & Confirm Deal", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text("Are you sure you want to accept this proposal and confirm the deal?", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 14),
              GlassTextField(
                controller: remarkCtrl,
                hintText: "Enter remark (optional)...",
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Get.back(result: false), child: const Text("Cancel")),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () => Get.back(result: true),
                    child: const Text("Accept Deal"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await BuyerServices.confirmOffer(productId, interestId, remarkCtrl.text.trim());
        AppSnackbar.showSuccess(title: "Deal Confirmed", message: "Deal confirmed successfully!");
        Get.back(result: true);
      } catch (e) {
        AppSnackbar.showError(title: "Error", message: e.toString().replaceAll("Exception: ", ""));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleReject() async {
    final remarkCtrl = TextEditingController();
    final confirm = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Reject Proposal", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text("Are you sure you want to reject this proposal and close negotiations?", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 14),
              GlassTextField(
                controller: remarkCtrl,
                hintText: "Enter rejection reason...",
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Get.back(result: false), child: const Text("Cancel")),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: () => Get.back(result: true),
                    child: const Text("Reject"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await BuyerServices.rejectInterest(productId, interestId, remarkCtrl.text.trim());
        AppSnackbar.showSuccess(title: "Rejected", message: "Interest rejected successfully.");
        Get.back(result: true);
      } catch (e) {
        AppSnackbar.showError(title: "Error", message: e.toString().replaceAll("Exception: ", ""));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offer = widget.offer;
    final isConfirmed = offer.isConfirmed;
    final isRejected = offer.isRejected;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Negotiation: ${offer.displayTitle ?? 'Offer'}",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "Buyer: ${offer.code?.isNotEmpty == true ? offer.code! : (offer.transactionId ?? 'Buyer')} | Seller: ${offer.sellerName?.isNotEmpty == true ? offer.sellerName! : 'Seller'}",
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: "Refresh Negotiation",
            onPressed: () => _fetchNegotiationDetails(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _fetchNegotiationDetails(),
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Negotiation Summary Card
                          _buildSummaryCard(theme),
                          const SizedBox(height: 16),

                          // 2. Negotiation Log Card
                          _buildNegotiationLogCard(theme),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Bottom Negotiation Proposal Form (if active)
                if (!isConfirmed && !isRejected)
                  _buildBottomNegotiationForm(theme),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final offer = widget.offer;
    final status = _interestDetail?['status']?.toString().toUpperCase() ?? offer.displayStatus ?? 'INTERESTED';
    final isConfirmed = status.contains('CONFIRM') || offer.isConfirmed;
    final isRejected = status.contains('REJECT') || status.contains('CLOSE') || offer.isRejected;

    Color badgeColor = const Color(0xFFFFB300);
    if (isConfirmed) badgeColor = Colors.green;
    if (isRejected) badgeColor = Colors.red;

    // Current price / offer from updated interestDetail if available
    final currentOfferPrice = _interestDetail?['buyer_offered_amount']?.toString() ??
        _interestDetail?['offered_amount']?.toString() ??
        offer.requestedAmount ??
        '55.00';
    final currentQty = _interestDetail?['buyer_required_quantity']?.toString() ??
        _interestDetail?['required_quantity']?.toString() ??
        offer.requestedQuantity ??
        offer.displayQuantity ??
        '500.100';

    final remarkVal = _interestDetail?['buyer_remark'] ??
        _interestDetail?['condition'] ??
        _interestDetail?['remark'] ??
        "test";

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Negotiation Summary",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Detail rows
          _buildSummaryRow("Seller Price:", offer.displayPrice?.isNotEmpty == true ? offer.displayPrice! : "₹55.00/QTL"),
          const SizedBox(height: 8),
          _buildSummaryRow("Available Qty:", offer.displayQuantity?.isNotEmpty == true ? offer.displayQuantity! : "500.100 QTL"),
          const SizedBox(height: 8),
          _buildSummaryRow("Current Offer:", "₹$currentOfferPrice/TON"),
          const SizedBox(height: 8),
          _buildSummaryRow("Current Qty:", "$currentQty QTL"),

          const Divider(height: 20),

          // Buyer Remark section
          Text("Buyer Remark", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              remarkVal.toString(),
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ),

          // Buyer Actions (Accept / Reject)
          if (!isConfirmed && !isRejected) ...[
            const Divider(height: 20),
            Text("Buyer Action", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text("Accept", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildNegotiationLogCard(ThemeData theme) {
    final offer = widget.offer;
    final buyerCode = offer.transactionId?.isNotEmpty == true
        ? offer.transactionId!
        : (offer.code?.isNotEmpty == true ? offer.code! : "You");
    final sellerName = offer.sellerName?.isNotEmpty == true
        ? offer.sellerName!
        : "Seller";

    final priceVal = _interestDetail?['buyer_offered_amount']?.toString() ??
        offer.requestedAmount ??
        "55.00";
    final qtyVal = _interestDetail?['buyer_required_quantity']?.toString() ??
        offer.requestedQuantity ??
        (offer.availableQuantity ?? "500.100");

    final rawCreatedAt = _interestDetail?['created_at']?.toString() ?? offer.createdAt;
    final dateVal = formatDateTimeLocal(rawCreatedAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Icon(IconlyLight.chat, size: 18),
              const SizedBox(width: 8),
              Text(
                "Negotiation Chat",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text("LIVE", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Initial offer bubble (Right-aligned / Buyer side)
        _buildChatBubble(
          theme: theme,
          isMe: true,
          senderName: "$buyerCode (Initial Offer)",
          message: _interestDetail?['buyer_remark']?.toString() ?? _interestDetail?['remark']?.toString() ?? '',
          counterPrice: priceVal,
          counterQuantity: qtyVal,
          timestamp: dateVal.isNotEmpty ? dateVal : "08-10-2026 18:57",
          isInitialOffer: true,
        ),

        // Timeline proposals / messages
        if (_messages.isNotEmpty) ...[
          ..._messages.map((m) {
            final senderRaw = (m['sender_role'] ?? m['role'] ?? m['sender'] ?? '').toString();
            final bool isMe = senderRaw.toLowerCase() == 'buyer' ||
                senderRaw.toLowerCase() == 'you' ||
                senderRaw == 'Buyer';

            final senderDisplay = isMe
                ? "$buyerCode (You)"
                : (senderRaw.isNotEmpty ? (senderRaw.toLowerCase() == 'seller' ? sellerName : senderRaw) : sellerName);

            final msg = m['message'] ?? m['remark'] ?? '';
            final cPrice = m['counter_price'] ?? m['price'] ?? m['offered_amount'] ?? '';
            final cQty = m['counter_quantity'] ?? m['quantity'] ?? '';
            final rawDate = m['created_at'] ?? m['timestamp'] ?? '';
            final cDate = formatDateTimeLocal(rawDate.toString());

            return _buildChatBubble(
              theme: theme,
              isMe: isMe,
              senderName: senderDisplay,
              message: msg.toString(),
              counterPrice: cPrice.toString(),
              counterQuantity: cQty.toString(),
              timestamp: cDate,
            );
          }),
        ],

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildChatBubble({
    required ThemeData theme,
    required bool isMe,
    required String senderName,
    required String message,
    required String counterPrice,
    required String counterQuantity,
    required String timestamp,
    bool isInitialOffer = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

    // WhatsApp-inspired color scheme
    final Color bubbleColor = isMe
        ? (isDark ? const Color(0xFF005D4B) : const Color(0xFFE7FFDB))
        : (isDark ? const Color(0xFF262D31) : Colors.white);

    final Color borderColor = isMe
        ? (isDark ? const Color(0xFF007A63) : const Color(0xFFC8E6C9))
        : (isDark ? const Color(0xFF384146) : const Color(0xFFE0E0E0));

    final Color textColor = isMe
        ? (isDark ? Colors.white : const Color(0xFF1B381E))
        : (isDark ? Colors.white : const Color(0xFF212121));

    final Color headerColor = isMe
        ? (isDark ? const Color(0xFF80CBC4) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100));

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(2),
      bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(14),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sender Name & Counter Badge Row
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      senderName,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: headerColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (counterPrice.isNotEmpty || counterQuantity.isNotEmpty || isInitialOffer) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMe
                            ? (isDark ? const Color(0xFF00796B) : const Color(0xFF2E7D32))
                            : const Color(0xFFE65100),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        isInitialOffer ? "INITIAL OFFER" : "COUNTER PROPOSAL",
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Counter Price and Qty Card if present
              if (counterPrice.isNotEmpty || counterQuantity.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMe
                        ? (isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.7))
                        : (isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFFFFF3E0)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMe
                          ? (isDark ? const Color(0xFF004D40) : const Color(0xFFA5D6A7))
                          : const Color(0xFFFFCC80),
                      width: 0.6,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (counterPrice.isNotEmpty)
                        Text(
                          "Price: ₹$counterPrice/QTL",
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isMe ? (isDark ? Colors.white : const Color(0xFF1B5E20)) : const Color(0xFFBF360C),
                          ),
                        ),
                      if (counterQuantity.isNotEmpty)
                        Text(
                          "Quantity: $counterQuantity QTL",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: textColor.withValues(alpha: 0.85),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // Message Body
              if (message.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  message.trim(),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              ],

              const SizedBox(height: 4),

              // Timestamp & WhatsApp double checkmark
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  Text(
                    timestamp,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      color: textColor.withValues(alpha: 0.55),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, size: 13, color: Color(0xFF34B7F1)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNegotiationForm(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Counter Price & Counter Qty
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                  ),
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "Counter Price (₹/QTL)",
                      hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                      prefixIcon: const Icon(Icons.currency_rupee, size: 14, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                  ),
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "Counter Qty (QTL)",
                      hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                      prefixIcon: const Icon(Icons.scale_outlined, size: 14, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Message Input & WhatsApp style Round Send Button
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _msgCtrl,
                    minLines: 1,
                    maxLines: 3,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Type a counter message...",
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    elevation: 2,
                  ),
                  onPressed: _isSending ? null : _submitNegotiation,
                  child: _isSending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
