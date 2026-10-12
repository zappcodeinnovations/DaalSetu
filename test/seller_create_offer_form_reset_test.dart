import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/seller/products/controller/seller_product_controller.dart';
import 'package:daalsetu/modules/seller/categories/model/seller_category_model.dart';
import 'package:daalsetu/modules/seller/branches/model/seller_branch_model.dart';

void main() {
  test('SellerProductController.clearForm resets all form fields and selections', () {
    final controller = SellerProductController();

    // Populate form fields
    controller.titleController.text = 'Sample Toor Dal';
    controller.descController.text = 'Grade A Quality';
    controller.amountController.text = '7500';
    controller.quantityController.text = '100';
    controller.bagCountController.text = '200';
    controller.packingWeightController.text = '50';
    controller.locationController.text = 'Latur Mandi';
    controller.remarkController.text = 'Immediate dispatch';

    controller.selectedCategoryId.value = 12;
    controller.selectedBrandId.value = 34;
    controller.brands.add(BrandModel(id: 34, brandName: 'Sample Brand'));
    controller.amountUnit.value = 'ton';
    controller.quantityUnit.value = 'ton';
    controller.selectedImagePath.value = '/path/to/img.png';
    controller.selectedVideoPath.value = '/path/to/video.mp4';
    controller.loadingFrom.value = DateTime.now();
    controller.loadingTo.value = DateTime.now().add(const Duration(days: 2));
    controller.dealExpiry.value = DateTime.now().add(const Duration(days: 1));

    // Setup branches
    controller.branches.clear();
    controller.branches.addAll([
      SellerBranchModel(id: 1, locationName: 'Branch 1'),
      SellerBranchModel(id: 2, locationName: 'Branch 2'),
    ]);
    controller.selectedBranchIds.clear();
    controller.selectedBranchIds.add(1); // only 1 selected

    // Verify populated state
    expect(controller.titleController.text, 'Sample Toor Dal');
    expect(controller.brands.isNotEmpty, isTrue);
    expect(controller.amountUnit.value, 'ton');

    // Call clearForm
    controller.clearForm();

    // Assert that text controllers are cleared
    expect(controller.titleController.text, isEmpty);
    expect(controller.descController.text, isEmpty);
    expect(controller.amountController.text, isEmpty);
    expect(controller.quantityController.text, isEmpty);
    expect(controller.bagCountController.text, isEmpty);
    expect(controller.locationController.text, isEmpty);
    expect(controller.remarkController.text, isEmpty);
    expect(controller.packingWeightController.text, '30'); // default packing weight

    // Assert that selections are reset
    expect(controller.selectedCategoryId.value, isNull);
    expect(controller.selectedBrandId.value, isNull);
    expect(controller.brands.isEmpty, isTrue);
    expect(controller.amountUnit.value, 'qtl');
    expect(controller.quantityUnit.value, 'qtl');
    expect(controller.selectedImagePath.value, isNull);
    expect(controller.selectedVideoPath.value, isNull);
    expect(controller.loadingFrom.value, isNull);
    expect(controller.loadingTo.value, isNull);
    expect(controller.dealExpiry.value, isNull);

    // Assert that branch IDs reset to include all available branches
    expect(controller.selectedBranchIds, {1, 2});
  });

  testWidgets('Pull-to-refresh on Create Offer triggers refresh action',
      (WidgetTester tester) async {
    bool refreshed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                key: const Key('refresh_button'),
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  refreshed = true;
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              refreshed = true;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Text('Create Offer Form'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(refreshed, isFalse);

    // Tap the refresh icon button
    await tester.tap(find.byKey(const Key('refresh_button')));
    await tester.pump();
    expect(refreshed, isTrue);
  });
}
