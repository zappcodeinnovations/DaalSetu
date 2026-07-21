import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/product_controller.dart';

class AddProductScreen extends StatelessWidget {
  AddProductScreen({super.key});

  final ProductController controller = Get.find();

  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final locationController = TextEditingController();

  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxString selectedCategory = "".obs;

  final ImagePicker picker = ImagePicker();

  Future<void> pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      selectedImage.value = File(picked.path);
    }
  }

  void submit() {
    if (titleController.text.isEmpty ||
        amountController.text.isEmpty ||
        locationController.text.isEmpty ||
        selectedCategory.value.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill all fields",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    controller.createProduct(
      title: titleController.text,
      amount: amountController.text,
      location: locationController.text,
      categoryId: selectedCategory.value,
      imagePath: selectedImage.value?.path,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Product"),
        centerTitle: true,
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              /// IMAGE CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Product Image",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: selectedImage.value == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text("Tap to upload product image"),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  selectedImage.value!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// FORM CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [

                    /// TITLE
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Product Title",
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// AMOUNT
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Base Amount",
                        prefixIcon: const Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// LOCATION
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: "Loading Location",
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // const SizedBox(height: 16),

                    // /// CATEGORY DROPDOWN
                    // Obx(() {

                    //   if (controller.categories.isEmpty) {
                    //     return const Center(
                    //       child: CircularProgressIndicator(),
                    //     );
                    //   }

                    //   return DropdownButtonFormField<String>(
                    //     value: selectedCategory.value.isEmpty
                    //         ? null
                    //         : selectedCategory.value,

                    //     items: controller.categories.map((cat) {
                    //       return DropdownMenuItem(
                    //         value: cat.id.toString(),
                    //         child: Text(cat.categoryName),
                    //       );
                    //     }).toList(),

                    //     onChanged: (value) {
                    //       selectedCategory.value = value!;
                    //     },

                    //     decoration: InputDecoration(
                    //       labelText: "Select Category",
                    //       prefixIcon: const Icon(Icons.category_outlined),
                    //       border: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //     ),
                    //   );

                    // }),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Create Product",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
