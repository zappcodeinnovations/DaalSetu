import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../services/buyer_services.dart';
import '../../../services/product_services.dart';
import '../../../services/seller_services.dart';
import '../../../utils/app_snackbar.dart';
import 'package:daalsetu/utils/global_error_handler.dart';

/// One live chat for a ProductInterest.  It intentionally powers both the
/// buyer's My Interests route and the seller's Buyer Interests route so the
/// same thread, counter-proposal format, refresh behaviour and action rules apply to
/// both parties.
class OfferInterestNegotiationChatView extends StatefulWidget {
  final int productId;
  final int interestId;
  final bool isBuyer;
  final bool allowDecisions;
  final bool isAdmin;
  final String? title;
  final Future<void> Function()? onAdminAccept;
  final Future<void> Function()? onAdminReject;

  const OfferInterestNegotiationChatView({
    super.key,
    required this.productId,
    required this.interestId,
    required this.isBuyer,
    this.allowDecisions = true,
    this.isAdmin = false,
    this.title,
    this.onAdminAccept,
    this.onAdminReject,
  });

  @override
  State<OfferInterestNegotiationChatView> createState() =>
      _OfferInterestNegotiationChatViewState();
}

class _OfferInterestNegotiationChatViewState
    extends State<OfferInterestNegotiationChatView> {
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _bagsController = TextEditingController();
  final _packingController = TextEditingController(text: '30');
  final _scrollController = ScrollController();

  Map<String, dynamic>? _thread;
  Timer? _pollTimer;
  bool _loading = true;
  bool _sending = false;
  bool _loadingInBackground = false;
  bool _showPacking = false;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (AppForeground.isActive) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _priceController.dispose();
    _quantityController.dispose();
    _bagsController.dispose();
    _packingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _messages =>
      ((_thread?['messages'] as List?) ?? const [])
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList();

  /// Older API deployments can serialise boolean permissions as strings. Keep
  /// the screen compatible with those responses while current APIs return real
  /// booleans.
  bool? _permission(dynamic value) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    if (const {'true', '1', 'yes'}.contains(normalized)) return true;
    if (const {'false', '0', 'no'}.contains(normalized)) return false;
    return null;
  }

  Future<void> _load({bool silent = false}) async {
    if (_loadingInBackground) return;
    _loadingInBackground = true;
    if (!silent && mounted) setState(() => _loading = true);
    final oldCount = _messages.length;
    try {
      final response = await BuyerServices.getOfferInterestThread(
        widget.productId,
        widget.interestId,
      );
      final raw = response['data'];
      if (raw is! Map || !mounted) return;
      final newThread = Map<String, dynamic>.from(raw);
      final productMap = (newThread['product'] is Map ? newThread['product'] : null) ??
          (newThread['offer'] is Map ? newThread['offer'] : null) ??
          (newThread['product_detail'] is Map ? newThread['product_detail'] : null);
      if (productMap != null) {
        newThread['seller_price'] ??= productMap['amount'] ?? productMap['seller_price'] ?? productMap['price'];
        newThread['available_quantity'] ??= productMap['available_quantity'] ?? productMap['remaining_quantity'] ?? productMap['stock_quantity'] ?? productMap['quantity'];
        newThread['price_unit'] ??= productMap['amount_unit'] ?? productMap['price_unit'];
        newThread['quantity_unit'] ??= productMap['quantity_unit'];
      }

      if (widget.productId > 0 &&
          (newThread['seller_price'] == null || newThread['available_quantity'] == null)) {
        try {
          final productDetail = await ProductService.getProductDetail(widget.productId);
          newThread['seller_price'] ??= productDetail.amount;
          newThread['available_quantity'] ??= productDetail.availableQuantity.isNotEmpty
              ? productDetail.availableQuantity
              : productDetail.remainingQuantity;
          if (newThread['price_unit'] == null || newThread['price_unit'].toString().isEmpty) {
            newThread['price_unit'] = productDetail.amountUnit.isNotEmpty ? productDetail.amountUnit : 'TON';
          }
          if (newThread['quantity_unit'] == null || newThread['quantity_unit'].toString().isEmpty) {
            newThread['quantity_unit'] = productDetail.quantityUnit.isNotEmpty ? productDetail.quantityUnit : 'QTL';
          }
        } catch (_) {}
      }

      final newCount = (newThread['messages'] as List?)?.length ?? 0;
      setState(() => _thread = newThread);
      if (!silent || newCount > oldCount) _scrollToLatest();
    } catch (error) {
      if (!silent) {
        AppSnackbar.showError(
          title: 'Negotiation unavailable',
          message: error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      _loadingInBackground = false;
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final price = _priceController.text.trim();
    final quantity = _quantityController.text.trim();
    final bags = _bagsController.text.trim();
    final packing = _packingController.text.trim();
    if (price.isEmpty && quantity.isEmpty && bags.isEmpty) {
      AppSnackbar.showWarning(
        title: 'Enter counter terms',
        message: 'Enter a counter price, quantity, or bags.',
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await BuyerServices.sendOfferInterestMessage(
        widget.productId,
        widget.interestId,
        counterPrice: price,
        counterQuantity: quantity,
        counterBagCount: widget.isBuyer ? '' : bags,
        counterPackingWeightKg: widget.isBuyer || bags.isEmpty ? '' : packing,
      );
      _priceController.clear();
      _quantityController.clear();
      _bagsController.clear();
      if (mounted) setState(() => _showPacking = false);
      await _load(silent: true);
      _scrollToLatest();
    } catch (error) {
      AppSnackbar.showError(
        title: 'Could not send counter',
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<bool> _confirmDecision({required bool accept}) async {
    final approved = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          '${accept ? 'Accept' : 'Reject'} ${widget.isBuyer ? 'offer' : 'buyer interest'}?',
        ),
        content: Text(
          accept
              ? 'This will move the negotiation to the next confirmation step.'
              : 'This action cannot be undone.',
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
            child: Text(accept ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );
    return approved == true;
  }

  Future<void> _decide({required bool accept}) async {
    final verb = accept ? 'accept' : 'reject';
    if (widget.isAdmin) {
      final action = accept ? widget.onAdminAccept : widget.onAdminReject;
      if (action == null) return;
      setState(() => _sending = true);
      try {
        await action();
        await _load(silent: true);
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }
    if (!await _confirmDecision(accept: accept)) return;

    setState(() => _sending = true);
    try {
      final result = widget.isBuyer
          ? accept
                ? await BuyerServices.confirmOfferInterest(
                    widget.productId,
                    widget.interestId,
                    remark: '',
                  )
                : await BuyerServices.rejectOfferInterest(
                    widget.productId,
                    widget.interestId,
                    remark: '',
                  )
          : accept
          ? await SellerServices.approveBuyerInterest(
              widget.productId,
              widget.interestId,
              remark: '',
            )
          : await SellerServices.rejectBuyerInterest(
              widget.productId,
              widget.interestId,
              remark: '',
            );
      AppSnackbar.showSuccess(
        title: accept ? 'Accepted' : 'Rejected',
        message: result['message'] ?? 'Negotiation $verb successfully.',
      );
      await _load(silent: true);
    } catch (error) {
      AppSnackbar.showError(
        title: 'Could not $verb',
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    final title =
        widget.title ?? thread?['product_title']?.toString() ?? 'Negotiation';
    final status = thread?['status']?.toString().toLowerCase() ?? '';
    final isReadOnly = _permission(thread?['is_read_only']) ?? false;
    final canReply =
        widget.isAdmin ||
        (!isReadOnly && (_permission(thread?['can_reply']) ?? false));
    final canAccept = widget.isAdmin
        ? true
        : widget.allowDecisions && widget.isBuyer
        ? (_permission(thread?['can_buyer_accept']) ?? false)
        : widget.allowDecisions &&
              !isReadOnly &&
              (_permission(thread?['can_seller_accept']) ??
                  _permission(thread?['can_seller_action']) ??
                  status == 'interested');
    final canReject = widget.isAdmin
        ? true
        : widget.allowDecisions && widget.isBuyer
        ? (_permission(thread?['can_buyer_reject']) ?? false)
        : widget.allowDecisions &&
              !isReadOnly &&
              (_permission(thread?['can_seller_reject']) ??
                  _permission(thread?['can_seller_action']) ??
                  status == 'interested');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Live negotiation · auto-refresh',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.green),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _sending ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh negotiation',
          ),
        ],
      ),
      body: _loading && thread == null
          ? const Center(child: CircularProgressIndicator())
          : thread == null
          ? const Center(child: Text('Negotiation is not available.'))
          : Column(
              children: [
                _summary(context, thread),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                      children: [
                        _initialInterest(context, thread),
                        ..._messages.map(
                          (message) => _bubble(context, message),
                        ),
                        if (_messages.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No counter proposals yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (canAccept || canReject) _decisionBar(canAccept, canReject),
                if (canReply) _composer(context),
                if (!isReadOnly && !canAccept && !canReject && !canReply)
                  _waitingBar(),
              ],
            ),
    );
  }

  Widget _summary(BuildContext context, Map<String, dynamic> thread) {
    final status =
        thread['status']?.toString().replaceAll('_', ' ') ?? 'Pending';
    final sellerPrice =
        thread['seller_price'] ??
        thread['seller_amount'] ??
        thread['amount'] ??
        thread['product_amount'] ??
        '-';
    final priceUnit = (thread['price_unit'] ?? thread['amount_unit'] ?? 'TON')
        .toString()
        .toUpperCase();
    final availableQty =
        thread['available_quantity'] ??
        thread['available_stock'] ??
        thread['quantity'] ??
        '-';
    final currentOffer =
        thread['latest_offered_amount'] ??
        thread['offered_amount'] ??
        thread['amount'] ??
        '-';
    final currentQty =
        thread['latest_offered_quantity'] ??
        thread['buyer_required_quantity'] ??
        thread['required_quantity'] ??
        thread['quantity'] ??
        '-';
    final qtyUnit = (thread['quantity_unit'] ?? 'QTL')
        .toString()
        .toUpperCase();
    final buyerRemark =
        thread['buyer_remark'] ?? thread['remark'] ?? thread['initial_remark'];

    String formatPrice(dynamic raw) {
      if (raw == null || raw.toString().trim().isEmpty || raw.toString().trim() == '-') return '-';
      final clean = raw.toString().replaceAll('₹', '').replaceAll(',', '').trim();
      final numVal = double.tryParse(clean);
      if (numVal != null) {
        return NumberFormat('#,##0.00', 'en_IN').format(numVal);
      }
      return clean;
    }

    String formatQty(dynamic raw) {
      if (raw == null || raw.toString().trim().isEmpty || raw.toString().trim() == '-') return '-';
      final clean = raw.toString().replaceAll(',', '').trim();
      final numVal = double.tryParse(clean);
      if (numVal != null) {
        if (clean.contains('.')) {
          final decimals = clean.split('.')[1].length;
          return numVal.toStringAsFixed(decimals < 3 ? 3 : decimals);
        }
        return numVal.toStringAsFixed(3);
      }
      return clean;
    }

    final pSeller = formatPrice(sellerPrice);
    final qAvail = formatQty(availableQty);
    final pOffer = formatPrice(currentOffer);
    final qOffer = formatQty(currentQty);

    String titleCase(String text) {
      if (text.isEmpty) return text;
      return text
          .split(' ')
          .map((w) {
            if (w.isEmpty) return w;
            return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
          })
          .join(' ');
    }

    Widget row(
      String label,
      String value, {
      Color? valueColor,
      bool bold = true,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: valueColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Negotiation Summary",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  titleCase(status),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          row("Seller Price:", pSeller == '-' ? '₹-' : "₹$pSeller / $priceUnit"),
          row("Available Qty:", qAvail == '-' ? '-' : "$qAvail $qtyUnit"),
          row("Current Offer:", pOffer == '-' ? '₹-' : "₹$pOffer / $priceUnit"),
          row("Current Qty:", qOffer == '-' ? '-' : "$qOffer $qtyUnit"),
          if (buyerRemark != null &&
              buyerRemark.toString().trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Buyer Remark",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    buyerRemark.toString().trim(),
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _initialInterest(BuildContext context, Map<String, dynamic> thread) {
    final buyerId =
        thread['buyer_display_id'] ??
        thread['buyer_unique_id'] ??
        thread['buyer_code'] ??
        (thread['buyer'] is Map
            ? (thread['buyer']['unique_id'] ?? thread['buyer']['name'])
            : null) ??
        'Buyer';
    final rawPrice = thread['initial_offered_amount'] ??
        thread['buyer_offered_amount'] ??
        thread['offered_amount'] ??
        '-';
    final priceUnit = (thread['price_unit'] ?? thread['amount_unit'] ?? 'TON')
        .toString()
        .toUpperCase();
    final rawQuantity = thread['buyer_required_quantity'] ??
        thread['initial_required_quantity'] ??
        thread['initial_quantity'] ??
        thread['requested_quantity'] ??
        thread['required_quantity'] ??
        '-';
    final qtyUnit = (thread['quantity_unit'] ?? 'QTL')
        .toString()
        .toUpperCase();
    final timestamp = _formatNegotiationDateTime(
      thread['created_at'] ??
      thread['interest_created_at'] ??
      thread['submitted_at'] ??
      thread['timestamp'] ??
      (_messages.isNotEmpty ? _messages.first['created_at'] : null),
    );

    final cleanPrice = rawPrice.toString().replaceAll('₹', '').replaceAll(',', '').trim();
    final numPrice = double.tryParse(cleanPrice);
    final displayPrice = numPrice != null
        ? NumberFormat('#,##0.00', 'en_IN').format(numPrice)
        : rawPrice;

    final cleanQty = rawQuantity.toString().replaceAll(',', '').trim();
    final numQty = double.tryParse(cleanQty);
    final displayQty = numQty != null
        ? (cleanQty.contains('.')
            ? numQty.toStringAsFixed(cleanQty.split('.')[1].length < 3 ? 3 : cleanQty.split('.')[1].length)
            : numQty.toStringAsFixed(3))
        : rawQuantity;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * .82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$buyerId submitted initial offer:",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayPrice == '-' ? "Price: ₹-" : "Price: ₹$displayPrice/$priceUnit",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              displayQty == '-' ? "Requested: -" : "Requested: $displayQty $qtyUnit",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            if (timestamp.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                timestamp,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNegotiationDateTime(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty || raw.toString().trim() == '-') return '';
    final trimmed = raw.toString().trim();

    DateTime? dt = DateTime.tryParse(trimmed);

    if (dt == null && trimmed.contains(' ')) {
      final isoCandidate = trimmed.replaceFirst(' ', 'T');
      dt = DateTime.tryParse(isoCandidate);
    }

    if (dt != null && !dt.isUtc) {
      final hasTz = RegExp(
        r'(Z|[+-]\d{2}:?\d{2})$',
        caseSensitive: false,
      ).hasMatch(trimmed);
      if (!hasTz) {
        dt = DateTime.utc(
          dt.year,
          dt.month,
          dt.day,
          dt.hour,
          dt.minute,
          dt.second,
          dt.millisecond,
          dt.microsecond,
        );
      }
    }

    if (dt == null) {
      final formats = [
        DateFormat('MMM d, yyyy h:mm a'),
        DateFormat('MMM dd, yyyy h:mm a'),
        DateFormat('MMM d, yyyy hh:mm a'),
        DateFormat('MMM dd, yyyy hh:mm a'),
        DateFormat('d MMM yyyy, h:mm a'),
        DateFormat('dd MMM yyyy, h:mm a'),
        DateFormat('d MMM yyyy, hh:mm a'),
        DateFormat('dd MMM yyyy, hh:mm a'),
        DateFormat('dd-MM-yyyy hh:mm a'),
        DateFormat('dd/MM/yyyy hh:mm a'),
        DateFormat('yyyy-MM-dd HH:mm:ss'),
        DateFormat('yyyy-MM-dd HH:mm'),
        DateFormat('dd-MM-yyyy HH:mm'),
      ];
      for (final fmt in formats) {
        try {
          final parsed = fmt.parseLoose(trimmed);
          dt = DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
          );
          break;
        } catch (_) {}
      }
    }

    if (dt != null) {
      return DateFormat('dd/MM/yyyy hh:mm a').format(dt.toLocal());
    }

    return trimmed;
  }

  Widget _bubble(BuildContext context, Map<String, dynamic> message) {
    final role =
        (message['actor_role'] ?? message['sender_role'])
            ?.toString()
            .toLowerCase() ??
        '';
    final mine = widget.isAdmin
        ? role.contains('admin')
        : widget.isBuyer
        ? role == 'buyer'
        : role == 'seller';
    String text(dynamic value) =>
        value == null || value.toString().trim().isEmpty || value == 'null'
        ? ''
        : value.toString();
    final price = text(message['counter_price']);
    final quantity = text(message['counter_quantity']);
    final bags = text(message['counter_bag_count']);
    final packing = text(message['counter_packing_weight_kg']);
    final action = text(message['action']).replaceAll('_', ' ');
    final status = text(message['to_status']).replaceAll('_', ' ');
    final body = <String>[
      if (price.isNotEmpty) 'Price: ₹$price / ${message['price_unit'] ?? ''}',
      if (quantity.isNotEmpty)
        'Quantity: $quantity ${message['quantity_unit'] ?? ''}',
      if (bags.isNotEmpty) 'Bags: $bags × $packing kg',
      if (status.isNotEmpty) 'Status: $status',
    ].join('\n');
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: _messageCard(
        context,
        mine: mine,
        title: mine
            ? 'You'
            : role.isEmpty
            ? 'System'
            : role[0].toUpperCase() + role.substring(1),
        body: body.isEmpty ? action : body,
        time:
            message['timestamp']?.toString() ??
            message['created_at']?.toString(),
      ),
    );
  }

  Widget _messageCard(
    BuildContext context, {
    required bool mine,
    required String title,
    required String body,
    required String? time,
  }) {
    final formattedTime = _formatNegotiationDateTime(time);
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * .78,
      ),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mine
            ? const Color(0xFFF58220).withValues(alpha: .15)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16),
        ),
        border: Border.all(
          color: mine
              ? const Color(0xFFF58220).withValues(alpha: .3)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(body, style: GoogleFonts.inter(fontSize: 13, height: 1.35)),
          ],
          if (formattedTime.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              formattedTime,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _decisionBar(bool canAccept, bool canReject) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          if (canAccept)
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : () => _decide(accept: true),
                  icon: const Icon(Icons.check, size: 18, color: Colors.white),
                  label: Text(
                    widget.isAdmin
                        ? 'Approve Deal'
                        : widget.isBuyer
                        ? 'Accept'
                        : 'Accept Interest',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          if (canAccept && canReject) const SizedBox(width: 12),
          if (canReject)
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _sending ? null : () => _decide(accept: false),
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFFD32F2F),
                  ),
                  label: Text(
                    'Reject',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                    side: const BorderSide(
                      color: Color(0xFFD32F2F),
                      width: 1.5,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _waitingBar() {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: const Text(
          'Waiting for the other party to respond.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _composer(BuildContext context) {
    final rawPriceUnit = _thread?['price_unit']?.toString().toUpperCase() ?? '';
    final priceUnit = rawPriceUnit.isNotEmpty ? rawPriceUnit : 'TON';
    final rawQuantityUnit =
        _thread?['quantity_unit']?.toString().toUpperCase() ?? '';
    final quantityUnit = rawQuantityUnit.isNotEmpty ? rawQuantityUnit : 'QTL';

    InputDecoration inputDecoration({
      required String label,
      String? hint,
      String? suffixText,
    }) =>
        InputDecoration(
          labelText: label,
          hintText: hint ?? 'Optional',
          suffixText: suffixText,
          counterText: '',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          hintStyle: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
          suffixStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(
              color: Color(0xFFF58220),
              width: 1.5,
            ),
          ),
        );

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showPacking && !widget.isBuyer)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bagsController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        decoration: inputDecoration(
                          label: 'Counter Bags',
                          hint: 'Optional',
                          suffixText: 'bags',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _packingController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        maxLength: 10,
                        decoration: inputDecoration(
                          label: 'Packing Weight',
                          hint: 'KG',
                          suffixText: 'KG',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                if (!widget.isBuyer)
                  IconButton(
                    onPressed: () =>
                        setState(() => _showPacking = !_showPacking),
                    icon: Icon(
                      _showPacking ? Icons.inventory_2 : Icons.inventory_2_outlined,
                      color: const Color(0xFFF58220),
                    ),
                    tooltip: 'Bags & packing',
                  ),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    maxLength: 10,
                    decoration: inputDecoration(
                      label: 'Counter Price (₹)',
                      hint: 'Optional',
                      suffixText: '/$priceUnit',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    maxLength: 10,
                    decoration: inputDecoration(
                      label: 'Counter Qty',
                      hint: 'Optional',
                      suffixText: quantityUnit,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.isBuyer
                          ? "Bags are calculated automatically from the seller's packing configuration. Free text messages are disabled."
                          : "Seller packing changes require both Bags and Packing Weight; quantity is calculated automatically.",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _sending ? 'Submitting...' : 'Submit Negotiation',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF58220),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
