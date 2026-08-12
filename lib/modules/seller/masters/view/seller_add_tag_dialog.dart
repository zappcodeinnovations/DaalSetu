import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/seller_master_controller.dart';

class SellerAddTagDialog extends StatefulWidget {
  const SellerAddTagDialog({super.key});

  @override
  State<SellerAddTagDialog> createState() => _SellerAddTagDialogState();
}

class _SellerAddTagDialogState extends State<SellerAddTagDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFFB300);
    final controller = Get.find<SellerMasterController>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Add Quality Tag", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Tag Name",
              hintText: "e.g. Sortex Cleaned",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              Get.snackbar("Error", "Tag name is required", snackPosition: SnackPosition.BOTTOM);
              return;
            }
            Get.back();
            controller.createTag(_nameController.text.trim());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("CREATE TAG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
