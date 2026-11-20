import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/buyer_delivery_challan_controller.dart';

/// A dispatched challan the buyer can still confirm: not yet delivered, received or completed.
bool canBuyerReceiveChallan(String? status) {
  final value = (status ?? '').toLowerCase().trim().replaceAll(' ', '_');
  const receivable = {'dispatched', 'in_transit', 'shipped'};
  return receivable.contains(value);
}

/// "Mark as Received" confirmation (with optional remarks) used by the challan list's quick action.
void showBuyerReceiveChallanDialog(int challanId) {
  final controller = Get.find<BuyerDeliveryChallanController>();
  final remarks = TextEditingController();
  Get.dialog(
    AlertDialog(
      title: const Text("Receive Challan"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Are you sure you want to mark this challan as received?"),
          const SizedBox(height: 16),
          TextField(
            controller: remarks,
            decoration: const InputDecoration(labelText: "Remarks (Optional)", border: OutlineInputBorder()),
            maxLines: 3,
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 46),
                ),
                onPressed: () {
                  Get.back();
                  controller.receiveChallan(challanId, remarks.text, closeDetails: false);
                },
                child: const Text("Confirm"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                onPressed: () => Get.back(),
                child: const Text("Cancel"),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
