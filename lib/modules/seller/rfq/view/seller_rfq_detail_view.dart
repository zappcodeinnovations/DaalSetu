import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../common/seller_ui.dart';
import '../controller/seller_rfq_controller.dart';
import '../model/seller_rfq_model.dart';
import 'seller_submit_quote_dialog.dart';
import 'seller_negotiation_chat_view.dart';

class SellerRfqDetailView extends StatelessWidget {
  final String rfqId;
  const SellerRfqDetailView({super.key, required this.rfqId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerRfqDetailController(rfqId), tag: 'seller_rfq_$rfqId');

    return Scaffold(
      appBar: SellerUi.appBar(context, "Requirement Details"),
      body: Obx(() {
        final rfq = controller.rfq.value;
        if (controller.isLoading.value && rfq == null) {
          return const Center(child: CircularProgressIndicator(color: SellerUi.primary));
        }
        if (rfq == null) return const Center(child: Text("Requirement not found"));
        final thread = controller.thread.value;

        return RefreshIndicator(
          color: SellerUi.primary,
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SellerUi.section(context, rfq.title, [
                Align(alignment: Alignment.centerLeft, child: SellerUi.statusChip(rfq.status)),
                const SizedBox(height: 8),
                SellerUi.infoRow("Requirement ID", rfq.rfqId),
                SellerUi.infoRow("Buyer", rfq.buyerName),
                SellerUi.infoRow("Category", rfq.categoryName),
                SellerUi.infoRow("Brand", rfq.brandName ?? "Any / Loose"),
                SellerUi.infoRow("Quantity", "${rfq.requiredQuantity ?? '-'} ${rfq.quantityUnit}"),
                if (rfq.requiredBagCount != null) SellerUi.infoRow("Bags", "${rfq.requiredBagCount} × ${rfq.packingWeightKg ?? '-'} kg"),
                SellerUi.infoRow("Target Price", "₹${rfq.targetPrice ?? '-'} / ${rfq.priceUnit}", valueColor: SellerUi.primary),
                SellerUi.infoRow("Delivery Terms", rfq.deliveryTerms),
                SellerUi.infoRow("Branches", rfq.targetBranches.join(', ')),
                SellerUi.infoRow("Expires", SellerUi.date(rfq.expiryDatetime)),
                if ((rfq.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(rfq.description!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ],
              ]),
              if (rfq.canQuote)
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => SellerSubmitQuoteDialog.show(controller, rfq),
                    icon: const Icon(IconlyLight.send, color: Colors.white, size: 18),
                    label: const Text("SUBMIT QUOTATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SellerUi.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              if (thread != null) ...[
                SellerUi.section(context, "My Quotation", [
                  Align(alignment: Alignment.centerLeft, child: SellerUi.statusChip(thread.status)),
                  const SizedBox(height: 8),
                  SellerUi.infoRow("Offered Price", "â‚¹${thread.offeredPrice ?? '-'} / ${thread.priceUnit ?? ''}"),
                  SellerUi.infoRow("Offered Quantity", "${thread.offeredQuantity ?? '-'} ${thread.quantityUnit ?? ''}"),
                ]),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(() => SellerNegotiationChatView(rfqId: rfqId)),
                    icon: const Icon(IconlyLight.chat, color: Colors.white),
                    label: const Text("OPEN NEGOTIATION CHAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: SellerUi.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ],
              if (!rfq.canQuote && thread == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("This requirement is not open for quotations.",
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                ),
            ],
          ),
        );
      }),
    );
  }

  // Kept temporarily for backwards-compatible rendering while negotiation now opens on its own screen.
  // ignore: unused_element
  List<Widget> _threadSection(BuildContext context, SellerRfqDetailController controller, SellerQuotationModel thread) {
    return [
      SellerUi.section(context, "My Quotation", [
        Align(alignment: Alignment.centerLeft, child: SellerUi.statusChip(thread.status)),
        const SizedBox(height: 8),
        SellerUi.infoRow("Offered Price", "₹${thread.offeredPrice ?? '-'} / ${thread.priceUnit ?? ''}"),
        SellerUi.infoRow("Offered Quantity", "${thread.offeredQuantity ?? '-'} ${thread.quantityUnit ?? ''}"),
        SellerUi.infoRow("Latest Terms", "₹${thread.latestPrice ?? '-'} for ${thread.latestQuantity ?? '-'}"),
        SellerUi.infoRow("Latest Offer By", (thread.latestOfferBy ?? '-').toUpperCase()),
        SellerUi.infoRow("Delivery Terms", thread.deliveryTerms),
      ]),
      SellerUi.section(context, "Negotiation & Counter Proposals", [
        if (thread.messages.isEmpty)
          Text("No messages yet.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ...thread.messages.map((m) => _bubble(context, m, thread)),
      ]),
      if (thread.canReply || thread.canAccept || thread.canReject)
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (thread.canReply)
              OutlinedButton.icon(
                onPressed: () => SellerSubmitQuoteDialog.showCounter(controller),
                icon: const Icon(IconlyLight.chat, size: 16),
                label: const Text("SUBMIT NEGOTIATION"),
                style: OutlinedButton.styleFrom(foregroundColor: SellerUi.primary, side: const BorderSide(color: SellerUi.primary)),
              ),
            if (thread.canAccept)
              ElevatedButton.icon(
                onPressed: controller.accept,
                icon: const Icon(Icons.check, size: 16, color: Colors.white),
                label: const Text("ACCEPT", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            if (thread.canReject)
              ElevatedButton.icon(
                onPressed: controller.reject,
                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                label: const Text("WITHDRAW", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
          ],
        ),
    ];
  }

  Widget _bubble(BuildContext context, NegotiationMessageModel m, SellerQuotationModel thread) {
    final mine = m.senderRole == 'seller';
    final who = mine ? "You" : (m.senderRole == 'buyer' ? (thread.buyerDisplayId ?? "Buyer") : "Admin");
    final terms = [
      if ((m.counterPrice ?? '').isNotEmpty && m.counterPrice != 'null') "₹${m.counterPrice} / ${m.priceUnit ?? ''}",
      if ((m.counterQuantity ?? '').isNotEmpty && m.counterQuantity != 'null') "${m.counterQuantity} ${m.quantityUnit ?? ''}",
    ].join(' • ');
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (mine ? SellerUi.primary : Colors.blueGrey).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(who, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
            if (terms.isNotEmpty) Text("Counter: $terms", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if ((m.message ?? '').isNotEmpty) Text(m.message!, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 2),
            Text(SellerUi.date(m.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
