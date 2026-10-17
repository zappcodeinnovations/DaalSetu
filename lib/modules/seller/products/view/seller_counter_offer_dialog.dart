import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/seller_negotiation_controller.dart';
import '../model/offer_interest_model.dart';
import '../../common/seller_ui.dart';

class SellerCounterOfferDialog {
  static void show(
    BuildContext context,
    SellerNegotiationController controller,
    OfferInterestModel interest,
  ) {
    final priceCtrl = TextEditingController(
      text: interest.buyerOfferedAmount ?? '',
    );
    final qtyCtrl = TextEditingController(
      text: interest.buyerRequiredQuantity ?? '',
    );
    final bagCtrl = TextEditingController(
      text: interest.counterBagCount?.toString() ?? '',
    );
    final weightCtrl = TextEditingController(
      text: interest.counterPackingWeightKg ?? '',
    );

    Get.defaultDialog(
      title: "Send Counter Offer",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: "Counter Price (Rs)",
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: "Counter Quantity (Qtl)",
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bagCtrl,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: "Counter Bag Count",
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: "Counter Packing Weight (KG)",
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
      ),
      textConfirm: "SEND COUNTER",
      textCancel: "CANCEL",
      buttonColor: Colors.amber.shade700,
      onConfirm: () {
        final priceText = priceCtrl.text.trim();
        final qtyText = qtyCtrl.text.trim();
        final bagText = bagCtrl.text.trim();
        final weightText = weightCtrl.text.trim();

        if (priceText.isEmpty && qtyText.isEmpty && bagText.isEmpty) {
          SellerUi.error(
            "Please enter a Counter Price, Quantity, or Packing details.",
          );
          return;
        }

        if ((bagText.isNotEmpty && weightText.isEmpty) ||
            (weightText.isNotEmpty && bagText.isEmpty)) {
          SellerUi.error(
            "Seller packing changes require both Bags and Packing Weight.",
          );
          return;
        }

        Get.back();
        controller.sendCounterOffer(
          interestId: interest.id!,
          counterPrice: priceText,
          counterQuantity: qtyText,
          counterBagCount: int.tryParse(bagText),
          counterPackingWeightKg: weightText.isNotEmpty ? weightText : null,
        );
      },
    );
  }
}
