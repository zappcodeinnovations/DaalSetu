import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/seller_services.dart';

class SellerStockUpdateDialog {
  static void show(BuildContext context, int productId, {required VoidCallback onSuccess}) {
    final qtyCtrl = TextEditingController();
    String selectedMode = 'quantity'; // 'quantity' or 'bag_count'
    String selectedOp = 'set'; // 'set', 'add', 'subtract'

    Get.defaultDialog(
      title: "Update Available Stock",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedMode,
                  decoration: const InputDecoration(labelText: "Stock Mode", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'quantity', child: Text("Quantity (Qtl)")),
                    DropdownMenuItem(value: 'bag_count', child: Text("Bag Count")),
                  ],
                  onChanged: (val) => setState(() => selectedMode = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedOp,
                  decoration: const InputDecoration(labelText: "Operation", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'set', child: Text("Set Exact Value")),
                    DropdownMenuItem(value: 'add', child: Text("Add Stock")),
                    DropdownMenuItem(value: 'subtract', child: Text("Subtract Stock")),
                  ],
                  onChanged: (val) => setState(() => selectedOp = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: const InputDecoration(labelText: "Value", border: OutlineInputBorder()),
                ),
              ],
            ),
          );
        },
      ),
      textConfirm: "UPDATE STOCK",
      textCancel: "CANCEL",
      buttonColor: Colors.amber.shade700,
      onConfirm: () async {
        if (qtyCtrl.text.trim().isEmpty) {
          Get.snackbar("Error", "Please enter a valid stock value");
          return;
        }
        Get.back();
        try {
          Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
          final res = await SellerServices.updateOfferStock(
            productId,
            mode: selectedMode,
            operation: selectedOp,
            quantity: qtyCtrl.text.trim(),
          );
          if (Get.isDialogOpen ?? false) Get.back();
          if (res['success'] == true) {
            Get.snackbar("Success", res['message'] ?? "Stock updated successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
            onSuccess();
          } else {
            Get.snackbar("Error", res['message'] ?? "Failed to update stock", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
          }
        } catch (e) {
          if (Get.isDialogOpen ?? false) Get.back();
          Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }
}
