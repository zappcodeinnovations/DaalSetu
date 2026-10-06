import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/seller_ui.dart';
import '../controller/seller_rfq_controller.dart';
import '../model/seller_rfq_model.dart';

class SellerSubmitQuoteDialog {
  static void show(SellerRfqDetailController controller, SellerRfqModel rfq) {
    final priceCtrl = TextEditingController(text: rfq.targetPrice ?? '');
    final qtyCtrl = TextEditingController(text: rfq.requiredQuantity ?? '');
    final bagCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: rfq.packingWeightKg ?? '');
    final termsCtrl = TextEditingController(text: rfq.deliveryTerms ?? '');
    final remarkCtrl = TextEditingController();

    InputDecoration deco(String label) => InputDecoration(labelText: label, border: const OutlineInputBorder());

    Get.dialog(
      AlertDialog(
        title: Text("Submit Quotation", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${rfq.title} • Target ₹${rfq.targetPrice ?? '-'} / ${rfq.priceUnit}",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: deco("Your Price (₹ / ${rfq.priceUnit}) *")),
              const SizedBox(height: 10),
              TextField(controller: qtyCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: deco("Quantity (${rfq.quantityUnit}) *")),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: bagCtrl, keyboardType: TextInputType.number, decoration: deco("Bags (optional)"))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: deco("Bag Wt kg"))),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: termsCtrl, decoration: deco("Delivery Terms")),
              const SizedBox(height: 10),
              TextField(controller: remarkCtrl, maxLines: 2, decoration: deco("Remark")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SellerUi.primary),
            onPressed: () {
              if (priceCtrl.text.trim().isEmpty || qtyCtrl.text.trim().isEmpty) {
                SellerUi.error("Please enter price and quantity");
                return;
              }
              Get.back();
              controller.submitQuote(
                price: priceCtrl.text.trim(),
                quantity: qtyCtrl.text.trim(),
                bagCount: bagCtrl.text.trim(),
                packingWeight: bagCtrl.text.trim().isEmpty ? null : weightCtrl.text.trim(),
                deliveryTerms: termsCtrl.text.trim(),
                remark: remarkCtrl.text.trim(),
              );
            },
            child: const Text("SUBMIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Counter offer and/or message inside an existing negotiation thread.
  static void showCounter(SellerRfqDetailController controller) {
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    InputDecoration deco(String label) => InputDecoration(labelText: label, border: const OutlineInputBorder());

    Get.dialog(
      AlertDialog(
        title: Text("Counter Offer / Message", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: deco("Counter Price (optional)")),
              const SizedBox(height: 10),
              TextField(controller: qtyCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: deco("Counter Quantity (optional)")),
              const SizedBox(height: 10),
              TextField(controller: msgCtrl, maxLines: 3, decoration: deco("Message")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SellerUi.primary),
            onPressed: () {
              if (priceCtrl.text.trim().isEmpty && qtyCtrl.text.trim().isEmpty && msgCtrl.text.trim().isEmpty) {
                SellerUi.error("Enter a counter price, quantity or message");
                return;
              }
              Get.back();
              controller.sendMessage(
                counterPrice: priceCtrl.text.trim(),
                counterQuantity: qtyCtrl.text.trim(),
                message: msgCtrl.text.trim(),
              );
            },
            child: const Text("SEND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
