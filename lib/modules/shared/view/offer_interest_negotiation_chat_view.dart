import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/buyer_services.dart';
import '../../../services/seller_services.dart';
import '../../../utils/app_snackbar.dart';
import '../../seller/common/seller_ui.dart';

/// One live chat for a ProductInterest.  It intentionally powers both the
/// buyer's My Interests route and the seller's Buyer Interests route so the
/// same thread, counter-proposal format, refresh behaviour and action rules apply to
/// both parties.
class OfferInterestNegotiationChatView extends StatefulWidget {
  final int productId;
  final int interestId;
  final bool isBuyer;

  const OfferInterestNegotiationChatView({
    super.key,
    required this.productId,
    required this.interestId,
    required this.isBuyer,
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
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _load(silent: true),
    );
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
    final title = thread?['product_title']?.toString() ?? 'Negotiation';
    final status = thread?['status']?.toString().toLowerCase() ?? '';
    final isReadOnly = _permission(thread?['is_read_only']) ?? false;
    final canReply = !isReadOnly && (_permission(thread?['can_reply']) ?? true);
    final canAccept = widget.isBuyer
        ? (_permission(thread?['can_buyer_accept']) ?? false)
        : !isReadOnly &&
              (_permission(thread?['can_seller_accept']) ??
                  _permission(thread?['can_seller_action']) ??
                  status == 'interested');
    final canReject = widget.isBuyer
        ? (_permission(thread?['can_buyer_reject']) ?? false)
        : !isReadOnly &&
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
              ],
            ),
    );
  }

  Widget _summary(BuildContext context, Map<String, dynamic> thread) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      child: Text(
        'Interest terms: ₹${thread['offered_amount'] ?? '-'} / ${thread['price_unit'] ?? ''}  •  Qty: ${thread['required_quantity'] ?? '-'} ${thread['quantity_unit'] ?? ''}',
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _initialInterest(BuildContext context, Map<String, dynamic> thread) {
    final mine = widget.isBuyer;
    final details = <String>[
      '₹${thread['offered_amount'] ?? '-'} / ${thread['price_unit'] ?? ''}',
      '${thread['required_quantity'] ?? '-'} ${thread['quantity_unit'] ?? ''}',
      if (thread['required_bag_count'] != null)
        '${thread['required_bag_count']} bags × ${thread['packing_weight_kg'] ?? '-'} kg',
      if (thread['buyer_remark']?.toString().trim().isNotEmpty == true)
        thread['buyer_remark'].toString(),
    ];
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: _messageCard(
        context,
        mine: mine,
        title: mine
            ? 'You submitted the interest'
            : 'Buyer submitted the interest',
        body: details.join('\n'),
        time: null,
      ),
    );
  }

  Widget _bubble(BuildContext context, Map<String, dynamic> message) {
    final role = message['actor_role']?.toString().toLowerCase() ?? '';
    final mine = widget.isBuyer ? role == 'buyer' : role == 'seller';
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
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * .78,
      ),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mine
            ? SellerUi.primary.withValues(alpha: .18)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16),
        ),
        border: Border.all(color: Theme.of(context).dividerColor),
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
          if (time != null && time.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              SellerUi.date(time),
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _decisionBar(bool canAccept, bool canReject) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          if (canAccept)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sending ? null : () => _decide(accept: true),
                icon: const Icon(Icons.check),
                label: Text(widget.isBuyer ? 'Accept' : 'Accept Interest'),
              ),
            ),
          if (canAccept && canReject) const SizedBox(width: 8),
          if (canReject)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sending ? null : () => _decide(accept: false),
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _composer(BuildContext context) {
    final priceUnit = _thread?['price_unit']?.toString().toUpperCase() ?? '';
    final quantityUnit =
        _thread?['quantity_unit']?.toString().toUpperCase() ?? '';
    InputDecoration decoration(String label, {String? suffixText}) =>
        InputDecoration(
          labelText: label,
          suffixText: suffixText,
          counterText: '',
          isDense: true,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
        );
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showPacking && !widget.isBuyer)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bagsController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        decoration: decoration('Bags'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _packingController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        maxLength: 10,
                        decoration: decoration('Packing KG', suffixText: 'KG'),
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
                    icon: const Icon(Icons.inventory_2_outlined),
                    tooltip: 'Bags & packing',
                  ),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    maxLength: 10,
                    decoration: decoration(
                      'Counter price',
                      suffixText: priceUnit.isEmpty ? null : '/ $priceUnit',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    maxLength: 10,
                    decoration: decoration(
                      'Counter quantity',
                      suffixText: quantityUnit.isEmpty ? null : quantityUnit,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor: SellerUi.primary,
                  child: IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
