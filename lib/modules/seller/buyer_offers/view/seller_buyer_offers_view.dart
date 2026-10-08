import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../services/seller_services.dart';
import '../../../../utils/app_preferences.dart';
import '../../common/seller_ui.dart';

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
      final data = await SellerServices.getBuyerOfferRequests(tab: 'incoming', search: search.value);
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
    return Scaffold(
      appBar: SellerUi.appBar(context, "Buyer Offers"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (val) => controller.search.value = val,
              decoration: InputDecoration(
                hintText: "Search buyer offers...",
                prefixIcon: const Icon(IconlyLight.search, color: SellerUi.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.offers.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: SellerUi.primary));
              }
              return RefreshIndicator(
                color: SellerUi.primary,
                onRefresh: controller.fetch,
                child: controller.offers.isEmpty
                    ? SellerUi.emptyState("No buyer offers for your branches", icon: IconlyLight.ticket)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.offers.length,
                        itemBuilder: (context, index) => _card(controller, controller.offers[index]),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _card(SellerBuyerOffersController controller, Map<String, dynamic> offer) {
    String nameOf(dynamic v) => v is Map ? '${v['name'] ?? ''}' : '${v ?? ''}';
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(() => SellerBuyerOfferDetailView(offerId: offer['id'] as int))?.then((_) => controller.fetch()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(offer['title']?.toString() ?? 'Buyer Offer',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  SellerUi.statusChip('${offer['status'] ?? 'requested'}'),
                ],
              ),
              const SizedBox(height: 4),
              Text("${offer['transaction_id'] ?? ''} • ${nameOf(offer['category'])}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const Divider(height: 20),
              SellerUi.infoRow("Quantity", "${offer['requested_quantity'] ?? '-'} ${offer['quantity_unit'] ?? ''}"),
              SellerUi.infoRow("Buyer Price", "₹${offer['requested_amount'] ?? '-'} / ${offer['amount_unit'] ?? ''}", valueColor: SellerUi.primary),
              SellerUi.infoRow("Posted", SellerUi.date(offer['created_at'])),
            ],
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
  State<SellerBuyerOfferDetailView> createState() => _SellerBuyerOfferDetailViewState();
}

class _SellerBuyerOfferDetailViewState extends State<SellerBuyerOfferDetailView> {
  static const _openStatuses = {'requested', 'pending_seller', 'negotiating', 'pending_buyer'};

  Map<String, dynamic>? _offer;
  Map<String, dynamic>? _thread;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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
      setState(() {
        _offer = offer;
        _thread = thread;
      });
    } catch (e) {
      SellerUi.error(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Seller acts on its own thread when one exists, otherwise on the buyer request itself.
  int get _actionId => (_thread?['id'] ?? _offer?['id']) as int;

  Future<void> _act(Map<String, dynamic> body) async {
    final result = await SellerUi.run(() => SellerServices.buyerOfferAction(_actionId, body));
    if (result != null) _load();
  }

  Future<void> _counter() async {
    final amount = TextEditingController(text: '${_thread?['latest_offered_amount'] ?? _offer?['requested_amount'] ?? ''}');
    final quantity = TextEditingController(text: '${_thread?['latest_offered_quantity'] ?? _offer?['requested_quantity'] ?? ''}');
    final bags = TextEditingController();
    final packing = TextEditingController(text: '${_offer?['packing_weight_kg'] ?? ''}'.replaceAll('null', ''));
    InputDecoration deco(String label) => InputDecoration(labelText: label, border: const OutlineInputBorder());

    final send = await Get.dialog<bool>(AlertDialog(
      title: Text("Counter Offer", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), maxLength: 10, decoration: deco("Your Price *")),
          const SizedBox(height: 10),
          TextField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), maxLength: 10, decoration: deco("Quantity *")),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: bags, keyboardType: TextInputType.number, maxLength: 10, decoration: deco("Bags (optional)"))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: packing, keyboardType: const TextInputType.numberWithOptions(decimal: true), maxLength: 10, decoration: deco("Bag Wt kg"))),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text("CANCEL")),
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
      ],
    ));
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
    final remark = await SellerUi.askText("Confirm Buyer Price", confirmText: "Confirm", color: Colors.green);
    if (remark != null) await _act({"action": "seller_confirm", "remark": remark});
  }

  Future<void> _reject() async {
    final remark = await SellerUi.askText("Reject Buyer Offer", confirmText: "Reject", color: Colors.red);
    if (remark != null) await _act({"action": "seller_reject", "seller_remark": remark, "remark": remark});
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    final thread = _thread;
    String nameOf(dynamic v) => v is Map ? '${v['name'] ?? ''}' : '${v ?? ''}';
    final currentStatus = '${thread?['status'] ?? offer?['status'] ?? ''}';
    final canAct = _openStatuses.contains(currentStatus) && !(thread != null && thread['latest_offer_by'] == 'seller' && currentStatus == 'pending_buyer');
    final history = (thread?['negotiation_history'] as List? ?? []).whereType<Map>().toList();

    return Scaffold(
      appBar: SellerUi.appBar(context, "Buyer Offer"),
      body: _loading && offer == null
          ? const Center(child: CircularProgressIndicator(color: SellerUi.primary))
          : offer == null
              ? const Center(child: Text("Buyer offer not found"))
              : RefreshIndicator(
                  color: SellerUi.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SellerUi.section(context, offer['title']?.toString() ?? 'Buyer Offer', [
                        Align(alignment: Alignment.centerLeft, child: SellerUi.statusChip('${offer['status']}')),
                        const SizedBox(height: 8),
                        SellerUi.infoRow("Offer ID", offer['transaction_id']?.toString()),
                        SellerUi.infoRow("Category", nameOf(offer['category'])),
                        SellerUi.infoRow("Brand", nameOf(offer['brand'])),
                        SellerUi.infoRow("Quantity", "${offer['requested_quantity'] ?? '-'} ${offer['quantity_unit'] ?? ''}"),
                        if (offer['requested_bag_count'] != null)
                          SellerUi.infoRow("Bags", "${offer['requested_bag_count']} × ${offer['packing_weight_kg'] ?? '-'} kg"),
                        SellerUi.infoRow("Buyer Price", "₹${offer['requested_amount'] ?? '-'} / ${offer['amount_unit'] ?? ''}", valueColor: SellerUi.primary),
                        SellerUi.infoRow("Buyer Remark", offer['buyer_remark']?.toString()),
                      ]),
                      if (thread != null)
                        SellerUi.section(context, "My Negotiation", [
                          Align(alignment: Alignment.centerLeft, child: SellerUi.statusChip(currentStatus)),
                          const SizedBox(height: 8),
                          SellerUi.infoRow("Latest Price", "₹${thread['latest_offered_amount'] ?? '-'}"),
                          SellerUi.infoRow("Latest Quantity", "${thread['latest_offered_quantity'] ?? '-'}"),
                          SellerUi.infoRow("Latest Offer By", '${thread['latest_offer_by'] ?? '-'}'.toUpperCase()),
                          if (history.isNotEmpty) const Divider(height: 20),
                          ...history.map((h) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "${'${h['actor_role'] ?? ''}'.toUpperCase()} • ${'${h['action'] ?? ''}'.replaceAll('_', ' ')}"
                                  "${'${h['amount'] ?? ''}'.isNotEmpty ? ' • ₹${h['amount']}' : ''}"
                                  "${'${h['quantity'] ?? ''}'.isNotEmpty ? ' • ${h['quantity']}' : ''}"
                                  "${'${h['remark'] ?? ''}'.isNotEmpty ? '\n${h['remark']}' : ''}"
                                  "\n${SellerUi.date(h['timestamp'])}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              )),
                        ]),
                      if (canAct)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _counter,
                              icon: const Icon(IconlyLight.chat, size: 16),
                              label: const Text("COUNTER"),
                              style: OutlinedButton.styleFrom(foregroundColor: SellerUi.primary, side: const BorderSide(color: SellerUi.primary)),
                            ),
                            ElevatedButton.icon(
                              onPressed: _confirm,
                              icon: const Icon(Icons.check, size: 16, color: Colors.white),
                              label: const Text("CONFIRM", style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                            ElevatedButton.icon(
                              onPressed: _reject,
                              icon: const Icon(Icons.close, size: 16, color: Colors.white),
                              label: const Text("REJECT", style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }
}
