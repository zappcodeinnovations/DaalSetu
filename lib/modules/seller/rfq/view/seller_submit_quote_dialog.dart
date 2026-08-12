import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/seller_rfq_controller.dart';
import '../model/seller_rfq_model.dart';

class SellerSubmitQuoteDialog {
  static void show(BuildContext context, SellerRfqController controller, SellerRfqModel rfq) {
    final priceCtrl = TextEditingController(text: rfq.targetPrice ?? '');
    final qtyCtrl = TextEditingController(text: rfq.requiredQuantity ?? '');
    final bagCtrl = TextEditingController(text: '50');
    final weightCtrl = TextEditingController(text: '50.0');
    final remarkCtrl = TextEditingController();

    Get.defaultDialog(
      title: "Submit Quote on Buyer RFQ",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Buyer: ${rfq.buyerName ?? 'Buyer'} • ${rfq.categoryName ?? 'Pulse'}",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Quoted Price (₹/Qtl)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Offered Quantity (Qtl)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: bagCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Bag Count", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Bag Wt (kg)", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: remarkCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Remarks / Delivery Note", border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      textConfirm: "SUBMIT QUOTE",
      textCancel: "CANCEL",
      buttonColor: const Color(0xFFFFB300),
      onConfirm: () async {
        if (priceCtrl.text.trim().isEmpty || qtyCtrl.text.trim().isEmpty) {
          Get.snackbar("Error", "Please enter price and quantity");
          return;
        }
        Get.back();
        await controller.submitQuote(
          rfq.id!,
          quotedPrice: priceCtrl.text.trim(),
          offeredQuantity: qtyCtrl.text.trim(),
          bagCount: int.tryParse(bagCtrl.text.trim()) ?? 0,
          packingWeight: weightCtrl.text.trim(),
          remarks: remarkCtrl.text.trim(),
        );
      },
    );
  }
}
