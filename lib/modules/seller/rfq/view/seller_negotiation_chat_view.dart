import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import '../../common/seller_ui.dart';
import '../controller/seller_rfq_controller.dart';
import '../model/seller_rfq_model.dart';

class SellerNegotiationChatView extends StatefulWidget {
  final String rfqId;

  const SellerNegotiationChatView({super.key, required this.rfqId});

  @override
  State<SellerNegotiationChatView> createState() => _SellerNegotiationChatViewState();
}

class _SellerNegotiationChatViewState extends State<SellerNegotiationChatView> {
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final bagController = TextEditingController();
  final packingController = TextEditingController(text: '30');
  final scrollController = ScrollController();
  bool showPacking = false;
  late final SellerRfqDetailController controller;
  Worker? messageWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SellerRfqDetailController>(tag: 'seller_rfq_${widget.rfqId}');
    messageWorker = ever(controller.thread, (_) => _scrollToLatest());
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
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
    await controller.sendMessage(
      counterPrice: price,
      counterQuantity: quantity,
      bagCount: bags,
      packingWeight: bags.isEmpty ? null : packingController.text.trim(),
    );
    priceController.clear();
    quantityController.clear();
    bagController.clear();
    if (mounted) setState(() => showPacking = false);
    _scrollToLatest();
  }

  @override
  void dispose() {
    messageWorker?.dispose();
    priceController.dispose();
    quantityController.dispose();
    bagController.dispose();
    packingController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rfq = controller.rfq.value;
      final quotation = controller.thread.value;
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rfq?.title ?? 'Negotiation', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('Auto-refresh on', style: GoogleFonts.inter(fontSize: 11, color: Colors.green)),
            ],
          ),
          actions: [
            IconButton(onPressed: () => controller.load(), icon: const Icon(IconlyLight.swap), tooltip: 'Refresh'),
          ],
        ),
        body: quotation == null
            ? const Center(child: Text('Negotiation is not available.'))
            : Column(
                children: [
                  _summary(context, rfq, quotation),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.load,
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                        children: [
                          _initialQuotation(context, quotation),
                          ...quotation.messages.map((message) => _bubble(context, message, quotation)),
                          if (quotation.messages.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text('No counter proposals yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (quotation.canAccept || quotation.canReject) _decisionBar(quotation),
                  if (quotation.canReply) _composer(context),
                ],
              ),
      );
    });
  }

  Widget _summary(BuildContext context, SellerRfqModel? rfq, SellerQuotationModel quotation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      child: Text(
        'Buyer target: ₹${rfq?.targetPrice ?? '-'} / ${rfq?.priceUnit ?? ''}  •  Latest: ₹${quotation.latestPrice ?? quotation.offeredPrice ?? '-'} / ${quotation.priceUnit ?? ''}',
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _initialQuotation(BuildContext context, SellerQuotationModel quotation) {
    return Align(
      alignment: Alignment.centerRight,
      child: _messageCard(
        context,
        mine: true,
        title: 'You submitted the initial quotation',
        body: '₹${quotation.offeredPrice ?? '-'} / ${quotation.priceUnit ?? ''}\n${quotation.offeredQuantity ?? '-'} ${quotation.quantityUnit ?? ''}',
        time: quotation.createdAt,
      ),
    );
  }

  Widget _bubble(BuildContext context, NegotiationMessageModel message, SellerQuotationModel quotation) {
    final mine = message.senderRole == 'seller';
    final parts = <String>[
      if ((message.counterPrice ?? '').isNotEmpty) 'Price: ₹${message.counterPrice} / ${message.priceUnit ?? quotation.priceUnit ?? ''}',
      if ((message.counterQuantity ?? '').isNotEmpty) 'Quantity: ${message.counterQuantity} ${message.quantityUnit ?? quotation.quantityUnit ?? ''}',
      if ((message.message ?? '').isNotEmpty) message.message!,
    ];
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: _messageCard(
        context,
        mine: mine,
        title: mine ? 'You' : (message.senderName ?? message.senderRole.capitalizeFirst ?? 'Buyer'),
        body: parts.join('\n'),
        time: message.createdAt,
      ),
    );
  }

  Widget _messageCard(BuildContext context, {required bool mine, required String title, required String body, String? time}) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mine ? SellerUi.primary.withValues(alpha: 0.18) : Theme.of(context).cardColor,
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
          Text(title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(body, style: GoogleFonts.inter(fontSize: 13, height: 1.35)),
          const SizedBox(height: 4),
          Text(SellerUi.date(time), style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _decisionBar(SellerQuotationModel quotation) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          if (quotation.canAccept)
            Expanded(child: OutlinedButton.icon(onPressed: controller.accept, icon: const Icon(Icons.check), label: const Text('Accept'))),
          if (quotation.canAccept && quotation.canReject) const SizedBox(width: 8),
          if (quotation.canReject)
            Expanded(child: OutlinedButton.icon(onPressed: controller.reject, icon: const Icon(Icons.close), label: const Text('Withdraw'))),
        ],
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
                    Expanded(child: TextField(controller: bagController, keyboardType: TextInputType.number, decoration: decoration('Bags'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: packingController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: decoration('Packing KG'))),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(onPressed: () => setState(() => showPacking = !showPacking), icon: const Icon(Icons.inventory_2_outlined), tooltip: 'Bags & packing'),
                Expanded(child: TextField(controller: priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: decoration('Counter price'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: quantityController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: decoration('Counter qty'))),
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
