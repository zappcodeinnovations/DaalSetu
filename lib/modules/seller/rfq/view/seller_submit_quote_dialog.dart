import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    Get.dialog(
      AlertDialog(
        title: Text(
          "Submit Quotation",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${rfq.title} • Target ₹${rfq.targetPrice ?? '-'} / ${rfq.priceUnit}",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: deco("Your Price (₹ / ${rfq.priceUnit}) *"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: deco("Quantity (${rfq.quantityUnit}) *"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bagCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: deco("Bags (optional)"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: deco("Bag Wt kg"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: termsCtrl,
                decoration: deco("Delivery Terms"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarkCtrl,
                maxLines: 2,
                decoration: deco("Remark"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SellerUi.primary),
            onPressed: () {
              if (priceCtrl.text.trim().isEmpty ||
                  qtyCtrl.text.trim().isEmpty) {
                SellerUi.error("Please enter price and quantity");
                return;
              }
              Get.back();
              controller.submitQuote(
                price: priceCtrl.text.trim(),
                quantity: qtyCtrl.text.trim(),
                bagCount: bagCtrl.text.trim(),
                packingWeight: bagCtrl.text.trim().isEmpty
                    ? null
                    : weightCtrl.text.trim(),
                deliveryTerms: termsCtrl.text.trim(),
                remark: remarkCtrl.text.trim(),
              );
            },
            child: const Text(
              "SUBMIT",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Counter offer and/or message inside an existing negotiation thread.
  static void showCounter(SellerRfqDetailController controller) {
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final bagCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '30');
    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    Get.dialog(
      AlertDialog(
        title: Text(
          "Submit Negotiation",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: deco("Counter Price (optional)"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: deco("Counter Quantity (optional)"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bagCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: deco("Bags (optional)"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: deco("Packing KG"),
              ),
              const SizedBox(height: 16),
              Text(
                "Only counter price or quantity can be submitted. Free-text messages are disabled.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SellerUi.primary),
            onPressed: () {
              if (priceCtrl.text.trim().isEmpty &&
                  qtyCtrl.text.trim().isEmpty &&
                  bagCtrl.text.trim().isEmpty) {
                SellerUi.error("Enter a counter price or quantity");
                return;
              }
              Get.back();
              controller.sendMessage(
                counterPrice: priceCtrl.text.trim(),
                counterQuantity: qtyCtrl.text.trim(),
                bagCount: bagCtrl.text.trim(),
                packingWeight: bagCtrl.text.trim().isEmpty
                    ? null
                    : weightCtrl.text.trim(),
              );
            },
            child: const Text(
              "SUBMIT NEGOTIATION",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
