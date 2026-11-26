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
  final String _status = 'active';
  final Set<int> _categoryIds = {};

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
      content: SingleChildScrollView(child: Column(
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
          // The web brand form has no description, so the app does not ask for one either (kept commented out).
          // TextField(
          //   controller: _descController,
          //   decoration: InputDecoration(
          //     labelText: "Description (Optional)",
          //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          //   ),
          // ),
          // const SizedBox(height: 12),
          // A new brand is live at once (the server always saves it as Approved), so the status is shown,
          // not chosen - the same as the web form.
          InputDecorator(
            key: const Key('brand-status-readonly'),
            decoration: InputDecoration(
              labelText: "Status",
              helperText: "New brands are live as soon as they are created.",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Approved", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Mapped Parent Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 6),
          Obx(() {
            final roots = controller.categoryTreeList
                .whereType<Map>()
                .where((c) => c['id'] != null)
                .toList();
            if (roots.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("No categories available", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              );
            }
            return Container(
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              // A Column in a scroll view (not a ListView): the dialog measures its content's intrinsic
              // size, which a shrink-wrapped ListView cannot answer (the dialog then fails to open).
              child: SingleChildScrollView(
                child: Column(
                children: roots.map((c) {
                  final id = int.tryParse(c['id'].toString());
                  final name = (c['category_name'] ?? c['name'] ?? '').toString();
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(name, style: const TextStyle(fontSize: 14)),
                    value: id != null && _categoryIds.contains(id),
                    onChanged: id == null
                        ? null
                        : (v) => setState(() {
                              v == true ? _categoryIds.add(id) : _categoryIds.remove(id);
                            }),
                  );
                }).toList(),
              )),
            );
          }),
        ],
      )),
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
              status: _status,
              categoryIds: _categoryIds.toList(),
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
