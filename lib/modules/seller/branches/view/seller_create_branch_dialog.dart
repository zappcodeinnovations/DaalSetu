import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/seller_branch_controller.dart';

class SellerCreateBranchDialog extends StatefulWidget {
  const SellerCreateBranchDialog({super.key});

  @override
  State<SellerCreateBranchDialog> createState() => _SellerCreateBranchDialogState();
}

class _SellerCreateBranchDialogState extends State<SellerCreateBranchDialog> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _areaController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFFB300);
    final controller = Get.find<SellerBranchController>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Create Warehouse Branch", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Branch / Warehouse Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(labelText: "City", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _stateController,
              decoration: InputDecoration(labelText: "State", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _areaController,
              decoration: InputDecoration(labelText: "Area / Pincode", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
              Get.snackbar("Error", "Branch name and city are required", snackPosition: SnackPosition.BOTTOM);
              return;
            }
            Get.back();
            controller.createBranch(
              locationName: _nameController.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              area: _areaController.text.trim(),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("CREATE BRANCH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
