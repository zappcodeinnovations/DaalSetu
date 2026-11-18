import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/seller_master_controller.dart';
import '../../../../utils/app_snackbar.dart';

class SellerAddBrandDialog extends StatefulWidget {
  const SellerAddBrandDialog({super.key});

  @override
  State<SellerAddBrandDialog> createState() => _SellerAddBrandDialogState();
}

class _SellerAddBrandDialogState extends State<SellerAddBrandDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFFB300);
    final controller = Get.find<SellerMasterController>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Add Pulse Brand", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Brand Name",
              hintText: "e.g. Royal Harvest",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: "Description (Optional)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        Row(children: [
          Expanded(child: ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              AppSnackbar.snackbar("Error", "Brand name is required", snackPosition: SnackPosition.BOTTOM);
              return;
            }
            Get.back();
            controller.createBrand(
              _nameController.text.trim(),
              description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: FittedBox(fit: BoxFit.scaleDown, child: const Text("CREATE BRAND", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
        )),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("CANCEL"),
          )),
        ]),
      ],
    );
  }
}
