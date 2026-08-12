import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/seller_branch_controller.dart';

class SellerJoinBranchDialog extends StatefulWidget {
  const SellerJoinBranchDialog({super.key});

  @override
  State<SellerJoinBranchDialog> createState() => _SellerJoinBranchDialogState();
}

class _SellerJoinBranchDialogState extends State<SellerJoinBranchDialog> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFFB300);
    final controller = Get.find<SellerBranchController>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Join Branch Network", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Enter unique branch code provided by main company admin:", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: "Branch Code",
              hintText: "e.g. BR-IND-001",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
        ElevatedButton(
          onPressed: () {
            if (_codeController.text.trim().isEmpty) {
              Get.snackbar("Error", "Please enter a valid branch code", snackPosition: SnackPosition.BOTTOM);
              return;
            }
            Get.back();
            controller.joinBranchByCode(_codeController.text.trim());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("SUBMIT REQUEST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
