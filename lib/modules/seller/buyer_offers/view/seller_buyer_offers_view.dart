import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../services/seller_services.dart';
import '../../../../utils/app_preferences.dart';
import '../../../../utils/global_error_handler.dart';
import '../../common/seller_ui.dart';
import 'package:daalsetu/widgets/hero_header.dart';

/// Buyer offer requests a seller can respond to (web: "Buyer Offers").
class SellerBuyerOffersController extends GetxController {
  var isLoading = false.obs;
  var offers = <Map<String, dynamic>>[].obs;
  var search = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
    debounce(search, (_) => fetch(), time: const Duration(milliseconds: 400));
  }

  Future<void> fetch() async {
    try {
      isLoading(true);
      final data = await SellerServices.getBuyerOfferRequests(
        tab: 'incoming',
        search: search.value,
      );
      offers.value = data.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      SellerUi.error(e);
    } finally {
      isLoading(false);
    }
  }
}

class SellerBuyerOffersView extends StatelessWidget {
  const SellerBuyerOffersView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerBuyerOffersController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Buyer Offers",
        subtitle: "Direct offers & deal proposals from buyers",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        trailing: IconButton(
          tooltip: 'Refresh offers',
          onPressed: controller.fetch,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              onChanged: (val) => controller.search.value = val,
              decoration: InputDecoration(
                hintText: "Search buyer offers...",
                prefixIcon: const Icon(
                  IconlyLight.search,
                  color: Color(0xFFE65100),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.offers.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE65100)),
                );
              }
              return RefreshIndicator(
                color: const Color(0xFFE65100),
                onRefresh: controller.fetch,
                child: controller.offers.isEmpty
                    ? SellerUi.emptyState(
                        "No buyer offers for your branches",
                        icon: IconlyLight.ticket,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.offers.length,
                        itemBuilder: (context, index) =>
                            _card(context, controller, controller.offers[index]),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    SellerBuyerOffersController controller,
    Map<String, dynamic> offer,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String nameOf(dynamic v) => v is Map ? '${v['name'] ?? ''}' : '${v ?? ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFFFE0B2).withValues(alpha: 0.7),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFFE65100).withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Get.to(
            () => SellerBuyerOfferDetailView(offerId: offer['id'] as int),
          )?.then((_) => controller.fetch()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        offer['title']?.toString() ?? 'Buyer Offer',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SellerUi.statusChip('${offer['status'] ?? 'requested'}'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${offer['transaction_id'] ?? ''} • ${nameOf(offer['category'])}",
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const Divider(height: 20),
                SellerUi.infoRow(
                  "Quantity",
                  "${offer['requested_quantity'] ?? '-'} ${offer['quantity_unit'] ?? ''}",
                ),
                SellerUi.infoRow(
                  "Buyer Price",
                  "₹${offer['requested_amount'] ?? '-'} / ${offer['amount_unit'] ?? ''}",
                  valueColor: const Color(0xFFE65100),
                ),
                SellerUi.infoRow("Posted", SellerUi.date(offer['created_at'])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SellerBuyerOfferDetailView extends StatefulWidget {
  final int offerId;
  const SellerBuyerOfferDetailView({super.key, required this.offerId});

  @override
  State<SellerBuyerOfferDetailView> createState() =>
      _SellerBuyerOfferDetailViewState();
}

class _SellerBuyerOfferDetailViewState
    extends State<SellerBuyerOfferDetailView> {
  static const _openStatuses = {
    'requested',
    'pending_seller',
    'negotiating',
    'pending_buyer',
  };

  Map<String, dynamic>? _offer;
  Map<String, dynamic>? _thread;
  bool _loading = true;
  bool _refreshInProgress = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (AppForeground.isActive) _load(silent: true);
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final offer = await SellerServices.getBuyerOfferRequest(widget.offerId);
      final myId = int.tryParse(await AppPreferences.getUserId() ?? '');
      // A buyer request holds one response thread per seller; show only this seller's thread.
      Map<String, dynamic>? thread;
      if (offer['parent_request'] != null) {
        thread = offer;
      } else {
        thread = (offer['responses'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .where((r) => myId != null && r['seller'] == myId)
            .cast<Map<String, dynamic>?>()
            .firstWhere((_) => true, orElse: () => null);
      }
      if (mounted) {
        setState(() {
          _offer = offer;
          _thread = thread;
        });
      }
    } catch (e) {
      if (!silent) SellerUi.error(e);
    } finally {
      _refreshInProgress = false;
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Seller acts on its own thread when one exists, otherwise on the buyer request itself.
  int get _actionId => (_thread?['id'] ?? _offer?['id']) as int;

  Future<void> _act(Map<String, dynamic> body) async {
    final result = await SellerUi.run(
      () => SellerServices.buyerOfferAction(_actionId, body),
    );
    if (result != null) _load();
  }

  Future<void> _counter() async {
    final amount = TextEditingController(
      text:
          '${_thread?['latest_offered_amount'] ?? _offer?['requested_amount'] ?? ''}',
    );
    final quantity = TextEditingController(
      text:
          '${_thread?['latest_offered_quantity'] ?? _offer?['requested_quantity'] ?? ''}',
    );
    final bags = TextEditingController();
    final packing = TextEditingController(
      text: '${_offer?['packing_weight_kg'] ?? ''}'.replaceAll('null', ''),
    );
    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      counterText: '',
    );

    final send = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          "Counter Offer",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                maxLength: 10,
                decoration: deco("Your Price *"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: quantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                maxLength: 10,
                decoration: deco("Quantity *"),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: bags,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: deco("Bags (optional)"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: packing,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      maxLength: 10,
                      decoration: deco("Bag Wt kg"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SellerUi.primary),
            onPressed: () {
              if (amount.text.trim().isEmpty || quantity.text.trim().isEmpty) {
                SellerUi.error("Please enter price and quantity");
                return;
              }
              Get.back(result: true);
            },
            child: const Text("SEND", style: TextStyle(color: Colors.white)),
          ),
          OutlinedButton(
            onPressed: () => Get.back(result: false),
            child: const Text("CANCEL"),
          ),
        ],
      ),
    );
    if (send != true) return;
    await _act({
      "action": "seller_negotiate",
      "offered_amount": amount.text.trim(),
      "offered_quantity": quantity.text.trim(),
      if (bags.text.trim().isNotEmpty) "offered_bag_count": bags.text.trim(),
      if (bags.text.trim().isNotEmpty) "packing_weight_kg": packing.text.trim(),
    });
  }

  Future<void> _confirm() async {
    final remark = await SellerUi.askText(
      "Confirm Buyer Price",
      confirmText: "Confirm",
      color: Colors.green,
    );
    if (remark != null) {
      await _act({"action": "seller_confirm", "remark": remark});
    }
  }

  Future<void> _reject() async {
    final remark = await SellerUi.askText(
      "Reject Buyer Offer",
      confirmText: "Reject",
      color: Colors.red,
    );
    if (remark != null) {
      await _act({
        "action": "seller_reject",
        "seller_remark": remark,
        "remark": remark,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    final thread = _thread;
    String nameOf(dynamic v) => v is Map ? '${v['name'] ?? ''}' : '${v ?? ''}';
    final currentStatus = '${thread?['status'] ?? offer?['status'] ?? ''}';
    final canAct =
        _openStatuses.contains(currentStatus) &&
        !(thread != null &&
            thread['latest_offer_by'] == 'seller' &&
            currentStatus == 'pending_buyer');
    final history = (thread?['negotiation_history'] as List? ?? [])
        .whereType<Map>()
        .toList();

    return Scaffold(
      appBar: HeroHeader(
        title: "Buyer Offer Details",
        subtitle: "Live negotiation · auto-refresh",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        trailing: IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Refresh negotiation',
        ),
      ),
      body: _loading && offer == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE65100)),
            )
          : offer == null
          ? const Center(child: Text("Buyer offer not found"))
          : RefreshIndicator(
              color: const Color(0xFFE65100),
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SellerUi.section(
                    context,
                    offer['title']?.toString() ?? 'Buyer Offer',
                    [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SellerUi.statusChip('${offer['status']}'),
                      ),
                      const SizedBox(height: 8),
                      SellerUi.infoRow(
                        "Offer ID",
                        offer['transaction_id']?.toString(),
                      ),
                      SellerUi.infoRow("Category", nameOf(offer['category'])),
                      SellerUi.infoRow("Brand", nameOf(offer['brand'])),
                      SellerUi.infoRow(
                        "Quantity",
                        "${offer['requested_quantity'] ?? '-'} ${offer['quantity_unit'] ?? ''}",
                      ),
                      if (offer['requested_bag_count'] != null)
                        SellerUi.infoRow(
                          "Bags",
                          "${offer['requested_bag_count']} × ${offer['packing_weight_kg'] ?? '-'} kg",
                        ),
                      SellerUi.infoRow(
                        "Buyer Price",
                        "₹${offer['requested_amount'] ?? '-'} / ${offer['amount_unit'] ?? ''}",
                        valueColor: const Color(0xFFE65100),
                      ),
                      SellerUi.infoRow(
                        "Buyer Remark",
                        offer['buyer_remark']?.toString(),
                      ),
                    ],
                  ),
                  if (thread != null)
                    SellerUi.section(context, "My Negotiation", [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SellerUi.statusChip(currentStatus),
                      ),
                      const SizedBox(height: 8),
                      SellerUi.infoRow(
                        "Latest Price",
                        "₹${thread['latest_offered_amount'] ?? '-'}",
                      ),
                      SellerUi.infoRow(
                        "Latest Quantity",
                        "${thread['latest_offered_quantity'] ?? '-'}",
                      ),
                      SellerUi.infoRow(
                        "Latest Offer By",
                        '${thread['latest_offer_by'] ?? '-'}'.toUpperCase(),
                      ),
                      if (history.isNotEmpty) const Divider(height: 20),
                      ...history.map(
                        (h) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            "${'${h['actor_role'] ?? ''}'.toUpperCase()} • ${'${h['action'] ?? ''}'.replaceAll('_', ' ')}"
                            "${'${h['amount'] ?? ''}'.isNotEmpty ? ' • ₹${h['amount']}' : ''}"
                            "${'${h['quantity'] ?? ''}'.isNotEmpty ? ' • ${h['quantity']}' : ''}"
                            "${'${h['remark'] ?? ''}'.isNotEmpty ? '\n${h['remark']}' : ''}"
                            "\n${SellerUi.date(h['timestamp'])}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ]),
                  if (canAct)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _counter,
                          icon: const Icon(IconlyLight.chat, size: 16),
                          label: const Text(
                            "COUNTER",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE65100),
                            side: const BorderSide(color: Color(0xFFE65100)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _confirm,
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "CONFIRM",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _reject,
                          icon: const Icon(
                            Icons.cancel_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "REJECT",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
