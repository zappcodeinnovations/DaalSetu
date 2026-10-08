import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';

/// Full negotiation history of one buyer interest (GET /api/offers/<id>/interests/<id>/).
class SellerInterestThreadView extends StatefulWidget {
  final int productId;
  final int interestId;
  const SellerInterestThreadView({super.key, required this.productId, required this.interestId});

  @override
  State<SellerInterestThreadView> createState() => _SellerInterestThreadViewState();
}

class _SellerInterestThreadViewState extends State<SellerInterestThreadView> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  Timer? _refreshTimer;
  bool _refreshInProgress = false;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    if (!silent) setState(() => _loading = true);
    try {
      final response = await SellerServices.getOfferInterestThread(widget.productId, widget.interestId);
      if (!mounted) return;
      
      final newData = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : null;
      final oldMessagesCount = ((_data?['messages'] as List?)?.length ?? 0);
      final newMessagesCount = ((newData?['messages'] as List?)?.length ?? 0);
      
      _data = newData;
      if (!silent || newMessagesCount > oldMessagesCount) {
        if (mounted) _scrollToLatest();
      }
    } catch (e) {
      if (!silent) SellerUi.error(e);
    } finally {
      _refreshInProgress = false;
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final bagController = TextEditingController();
  final packingController = TextEditingController(text: '30');
  final scrollController = ScrollController();
  bool showPacking = false;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    priceController.dispose();
    quantityController.dispose();
    bagController.dispose();
    packingController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final price = priceController.text.trim();
    final quantity = quantityController.text.trim();
    final bags = bagController.text.trim();
    if (price.isEmpty && quantity.isEmpty && bags.isEmpty) {
      SellerUi.error('Enter a counter price or quantity.');
      return;
    }
    
    final result = await SellerUi.run(() => SellerServices.sendCounterOfferMessage(
          widget.productId,
          widget.interestId,
          counterPrice: price,
          counterQuantity: quantity,
          counterBagCount: bags.isEmpty ? null : int.tryParse(bags),
          counterPackingWeightKg: bags.isEmpty ? null : packingController.text.trim(),
        ));
    if (result != null) {
      priceController.clear();
      quantityController.clear();
      bagController.clear();
      if (mounted) setState(() => showPacking = false);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final rows = (data?['messages'] as List? ?? []).whereType<Map>().toList();
    final bool canAction = data != null && data['can_seller_action'] == true && data['is_read_only'] != true;

    return Scaffold(
      appBar: SellerUi.appBar(context, "Negotiation"),
      body: _loading && data == null
          ? const Center(child: CircularProgressIndicator(color: SellerUi.primary))
          : data == null
              ? const Center(child: Text("Negotiation not found"))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        color: SellerUi.primary,
                        onRefresh: _load,
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          children: [
                            SellerUi.section(context, data['product_title']?.toString() ?? 'Offer', [
                              Align(alignment: Alignment.centerLeft, child: SellerUi.statusChip('${data['status']}')),
                              const SizedBox(height: 8),
                              SellerUi.infoRow("Buyer", data['buyer_display_id']?.toString()),
                              SellerUi.infoRow("Buyer Price", "₹${data['offered_amount'] ?? '-'}", valueColor: SellerUi.primary),
                              SellerUi.infoRow("Quantity", data['required_quantity']?.toString()),
                              if (data['required_bag_count'] != null)
                                SellerUi.infoRow("Bags", "${data['required_bag_count']} × ${data['packing_weight_kg'] ?? '-'} kg"),
                              SellerUi.infoRow("Buyer Remark", data['buyer_remark']?.toString()),
                            ]),
                            if (rows.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text("No negotiation yet.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                              ),
                            ...rows.map((row) => _bubble(context, row)),
                          ],
                        ),
                      ),
                    ),
                    if (canAction) _composer(context),
                  ],
                ),
    );
  }

  Widget _bubble(BuildContext context, Map row) {
    final role = '${row['actor_role'] ?? ''}';
    final mine = role == 'seller';
    String present(dynamic v) => (v == null || '$v'.isEmpty || '$v' == 'null') ? '' : '$v';
    final price = present(row['counter_price']);
    final quantity = present(row['counter_quantity']);
    final bags = present(row['counter_bag_count']);
    final statusChange = present(row['to_status']);
    final lines = <String>[
      if (price.isNotEmpty) "Price: ₹$price ${present(row['price_unit'])}",
      if (quantity.isNotEmpty) "Quantity: $quantity ${present(row['quantity_unit'])}",
      if (bags.isNotEmpty) "Bags: $bags × ${present(row['counter_packing_weight_kg'])} kg",
      if (statusChange.isNotEmpty) "Status → ${statusChange.replaceAll('_', ' ')}",
      if (present(row['message']).isNotEmpty) present(row['message']),
    ];
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (mine ? SellerUi.primary : Colors.blueGrey).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${mine ? 'You' : (role.isEmpty ? 'System' : role[0].toUpperCase() + role.substring(1))} • ${present(row['action']).replaceAll('_', ' ')}",
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            ...lines.map((l) => Text(l, style: const TextStyle(fontSize: 13))),
            const SizedBox(height: 2),
            Text(SellerUi.date(row['timestamp']), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _composer(BuildContext context) {
    InputDecoration decoration(String hint) => InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
        );
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPacking)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: bagController, keyboardType: TextInputType.number, maxLength: 10, decoration: decoration('Bags'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: packingController, keyboardType: const TextInputType.numberWithOptions(decimal: true), maxLength: 10, decoration: decoration('Packing KG'))),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(onPressed: () => setState(() => showPacking = !showPacking), icon: const Icon(Icons.inventory_2_outlined), tooltip: 'Bags & packing'),
                Expanded(child: TextField(controller: priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), maxLength: 10, decoration: decoration('Counter price'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: quantityController, keyboardType: const TextInputType.numberWithOptions(decimal: true), maxLength: 10, decoration: decoration('Counter qty'))),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor: SellerUi.primary,
                  child: IconButton(onPressed: _send, icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
