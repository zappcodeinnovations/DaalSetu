import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';

class SellerStockUpdateDialog {
  static void show(
    BuildContext context,
    int productId, {
    required VoidCallback onSuccess,
  }) {
    final qtyCtrl = TextEditingController();
    String selectedMode = 'quantity'; // 'quantity' or 'bag_count'
    String selectedOp = 'set'; // 'set', 'add', 'subtract'

    Future<void> submit() async {
      if (qtyCtrl.text.trim().isEmpty) {
        SellerUi.error("Please enter a valid stock value");
        return;
      }
      Get.back();
      try {
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        final res = await SellerServices.updateOfferStock(
          productId,
          mode: selectedMode,
          operation: selectedOp,
          quantity: qtyCtrl.text.trim(),
        );
        if (Get.isDialogOpen ?? false) Get.back();
        if (res['success'] == true) {
          SellerUi.success(res['message'] ?? "Stock updated successfully");
          onSuccess();
        } else {
          SellerUi.error(res['message'] ?? "Failed to update stock");
        }
      } catch (e) {
        if (Get.isDialogOpen ?? false) Get.back();
        SellerUi.error(e);
      }
    }

    const fieldGap = SizedBox(height: 14);
    InputDecoration field(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        );

    // Own Dialog instead of Get.defaultDialog: even padding around the title,
    // full-width fields and two equal action buttons (QA spacing/alignment).
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Update Available Stock",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMode,
                    isExpanded: true,
                    decoration: field("Stock Mode"),
                    items: const [
                      DropdownMenuItem(value: 'quantity', child: Text("Quantity (Qtl)")),
                      DropdownMenuItem(value: 'bag_count', child: Text("Bag Count")),
                    ],
                    onChanged: (val) => setState(() => selectedMode = val!),
                  ),
                  fieldGap,
                  DropdownButtonFormField<String>(
                    initialValue: selectedOp,
                    isExpanded: true,
                    decoration: field("Operation"),
                    items: const [
                      DropdownMenuItem(value: 'set', child: Text("Set Exact Value")),
                      DropdownMenuItem(value: 'add', child: Text("Add Stock")),
                      DropdownMenuItem(value: 'subtract', child: Text("Subtract Stock")),
                    ],
                    onChanged: (val) => setState(() => selectedOp = val!),
                  ),
                  fieldGap,
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                    decoration: field("Value"),
                  ),
                  const SizedBox(height: 22),
                  // Fixed 46px height for both, one-line labels: "UPDATE STOCK" wrapped
                  // to two lines and made that button taller than CANCEL.
                  SizedBox(
                    height: 46,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: Get.back,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              foregroundColor: Colors.amber.shade800,
                              side: BorderSide(color: Colors.amber.shade700),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const _OneLine("CANCEL"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const _OneLine("UPDATE STOCK"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Button label kept on one line, shrinking to fit narrow screens.
class _OneLine extends StatelessWidget {
  const _OneLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
