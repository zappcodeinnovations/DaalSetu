import 'dart:io';
import 'package:daalsetu/widgets/confirm_actions.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_category_controller.dart';
import '../model/seller_category_model.dart';
import 'package:daalsetu/widgets/app_shell.dart';

class SellerCategoryView extends StatelessWidget {
  const SellerCategoryView({super.key});

  static const Color primaryColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SellerCategoryController>()
        ? Get.find<SellerCategoryController>()
        : Get.put(SellerCategoryController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(leading: const AppBarLeading(), leadingWidth: AppBarLeading.widthFor(context), 
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Categories",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => _showAddRootDialog(context),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                "Add",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchAllData,
        color: primaryColor,
        child: Obx(() {
          if (controller.isLoading.value && controller.categoryTree.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          return Column(
            children: [
              _buildDashboard(context),
              _buildSearchBar(context),
              Expanded(
                child: controller.isSearching.value
                    ? _buildSearchResults(context)
                    : _buildCategoryTree(context),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final controller = Get.find<SellerCategoryController>();
    final theme = Theme.of(context);
    final data = controller.dashboardData.value;

    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _dashboardItem(
            context,
            "Total",
            data.total.toString(),
            Icons.inventory_2_outlined,
          ),
          _dashboardItem(
            context,
            "Root",
            data.root.toString(),
            Icons.account_tree_outlined,
          ),
          _dashboardItem(
            context,
            "Active",
            data.active.toString(),
            Icons.check_circle_outline,
          ),
          _dashboardItem(
            context,
            "Pending",
            data.pending.toString(),
            Icons.pending_actions,
          ),
        ],
      ),
    );
  }

  Widget _dashboardItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final controller = Get.find<SellerCategoryController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller.searchController,
        builder: (context, value, _) {
          return TextField(
            controller: controller.searchController,
            onChanged: controller.search,
            decoration: InputDecoration(
              hintText: "Search Categories...",
              prefixIcon: const Icon(IconlyLight.search),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      key: const Key('clear_category_search_btn'),
                      icon: const Icon(Icons.clear, size: 20),
                      splashRadius: 20,
                      tooltip: "Clear search",
                      onPressed: () {
                        controller.searchController.clear();
                        controller.search('');
                      },
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final controller = Get.find<SellerCategoryController>();
    final theme = Theme.of(context);

    if (controller.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconlyLight.search,
                size: 64,
                color: theme.disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                "No categories found",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "No categories match \"${controller.searchController.text.trim()}\"",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.disabledColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: controller.searchResults.length,
      itemBuilder: (context, index) {
        final category = controller.searchResults[index];
        // Reusing the same node structure for search results
        return _buildSearchResultNode(context, category);
      },
    );
  }

  Widget _buildSearchResultNode(
    BuildContext context,
    CategoryDetailModel category,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = Get.find<SellerCategoryController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child: CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.1),
            child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      category.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(IconlyLight.category, color: primaryColor),
                    ),
                  )
                : const Icon(IconlyLight.category, color: primaryColor),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            if (category.fullPath.isNotEmpty &&
                category.fullPath.toLowerCase() != category.name.toLowerCase())
              _categoryInfoRow(
                IconlyLight.arrow_right_2,
                category.fullPath,
                theme,
              ),
            _categoryInfoRow(
              IconlyLight.category,
              "${category.childrenCount} sub-categories",
              theme,
            ),
            _categoryInfoRow(
              categoryStatusIcon(category.status),
              "Status: ${category.status.toUpperCase()}",
              theme,
              textColor: categoryStatusColor(category.status),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'add':
                _showAddSubDialog(context, category.id);
                break;
              case 'edit':
                _showEditDialog(context, category.id, category.name);
                break;
              case 'image':
                controller.uploadImage(category.id);
                break;
              case 'delete':
                _showDeleteConfirm(context, category.id);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'add',
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 20),
                  SizedBox(width: 8),
                  Text("Add Sub-Category"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(IconlyLight.edit, size: 20),
                  SizedBox(width: 8),
                  Text("Edit Category"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'image',
              child: Row(
                children: [
                  Icon(IconlyLight.image, size: 20),
                  SizedBox(width: 8),
                  Text("Upload Image"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(IconlyLight.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text("Delete", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildCategoryTree(BuildContext context) {
    final controller = Get.find<SellerCategoryController>();
    if (controller.categoryTree.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconlyLight.category,
                size: 64,
                color: theme.disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                "No categories available",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: controller.categoryTree.length,
      itemBuilder: (context, index) {
        return _buildCategoryNode(context, controller.categoryTree[index]);
      },
    );
  }

  Widget _buildCategoryNode(BuildContext context, CategoryTreeModel node) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = Get.find<SellerCategoryController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: node.image != null && node.image!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        node.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              IconlyLight.category,
                              color: primaryColor,
                            ),
                      ),
                    )
                  : const Icon(IconlyLight.category, color: primaryColor),
            ),
          ),
          title: Text(
            node.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              _categoryInfoRow(
                IconlyLight.category,
                "${node.childrenCount} sub-categories",
                theme,
              ),
              _categoryInfoRow(
                categoryStatusIcon(node.status),
                "Status: ${node.status.toUpperCase()}",
                theme,
                textColor: categoryStatusColor(node.status),
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 12,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'add':
                  _showAddSubDialog(context, node.id);
                  break;
                case 'edit':
                  _showEditDialog(context, node.id, node.name);
                  break;
                case 'image':
                  controller.uploadImage(node.id);
                  break;
                case 'delete':
                  _showDeleteConfirm(context, node.id);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text("Add Sub-Category"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(IconlyLight.edit, size: 20),
                    SizedBox(width: 8),
                    Text("Edit Category"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'image',
                child: Row(
                  children: [
                    Icon(IconlyLight.image, size: 20),
                    SizedBox(width: 8),
                    Text("Upload Image"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(IconlyLight.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Delete", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          children: node.children
              .map((child) => _buildCategoryNode(context, child))
              .toList(),
        ),
      ),
      ),
    );
  }

  Widget _categoryInfoRow(
    IconData icon,
    String text,
    ThemeData theme, {
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor ?? theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    textColor ??
                    theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                fontWeight: textColor != null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRootDialog(BuildContext context) {
    final controller = Get.find<SellerCategoryController>();
    controller.resetAddForm();

    _showGlossyDialog(
      context: context,
      title: "Add Category",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller.categoryNameController,
            decoration: InputDecoration(
              hintText: "Enter Category Name",
              filled: true,
              fillColor: Theme.of(context).cardColor.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(IconlyLight.category),
            ),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final roots = controller.categoryTree;
            return DropdownButtonFormField<int?>(
              key: ValueKey('parent-${controller.selectedParentId.value}'),
              initialValue: controller.selectedParentId.value,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Parent Category",
                filled: true,
                fillColor: Theme.of(context).cardColor.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text("None (Root Category)"),
                ),
                ...roots.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) => controller.selectedParentId.value = v,
            );
          }),
          const SizedBox(height: 14),
          InputDecorator(
            decoration: InputDecoration(
              labelText: "Status",
              filled: true,
              fillColor: Theme.of(context).cardColor.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            child: const Text(
              "Pending - active once the admin approves",
              style: TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final path = controller.pickedImagePath.value;
            return Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: Colors.grey.withOpacity(0.15),
                    child: path == null
                        ? const Icon(Icons.image_outlined, color: Colors.grey)
                        : Image.file(File(path), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: controller.pickCategoryImage,
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: Text(path == null ? "Category Image" : "Change Image"),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Optional. JPG, PNG or WEBP, max 2MB.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (path != null)
                  IconButton(
                    onPressed: () => controller.pickedImagePath.value = null,
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
              ],
            );
          }),
          const SizedBox(height: 20),
          Obx(() => controller.selectedParentId.value != null
              ? const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    "Brands are mapped on the parent category. A sub-category uses the parent mapping automatically.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )
              : const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select Brands",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                )),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.selectedParentId.value != null) {
              return const SizedBox.shrink();
            }
            if (controller.isBrandsLoading.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (controller.brandsList.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      IconlyLight.info_square,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "No active brands found",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        // Backend links only active brands; seller-added brands stay pending until admin approval.
                        "Brands you add stay pending until the admin approves them, then they appear here.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: controller.fetchBrands,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: controller.brandsList.length,
                  itemBuilder: (context, index) {
                    final brand = controller.brandsList[index];
                    // Own Obx: list items are built lazily, outside the parent Obx,
                    // so without it a tap never redraws the tick.
                    return Obx(() => CheckboxListTile(
                      title: Text(
                        brand.brandName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: controller.selectedBrandIds.contains(brand.id),
                      onChanged: (val) =>
                          controller.toggleBrandSelection(brand.id),
                      controlAffinity: ListTileControlAffinity.leading,
                      side: BorderSide(color: Colors.grey.shade500, width: 1.5),
                      activeColor: primaryColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ));
                  },
                ),
              ),
            );
          }),
        ],
      ),
      onConfirm: controller.addRootCategory,
    );
  }

  void _showAddSubDialog(BuildContext context, int parentId) {
    final controller = Get.find<SellerCategoryController>();
    controller.categoryNameController.clear();
    _showGlossyDialog(
      context: context,
      title: "Add Sub-Category",
      content: TextField(
        controller: controller.categoryNameController,
        decoration: InputDecoration(
          hintText: "Enter Sub-Category Name",
          filled: true,
          fillColor: Theme.of(context).cardColor.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onConfirm: () => controller.addSubCategory(parentId),
    );
  }

  void _showEditDialog(BuildContext context, int id, String currentName) {
    final controller = Get.find<SellerCategoryController>();
    controller.categoryNameController.text = currentName;
    _showGlossyDialog(
      context: context,
      title: "Edit Category",
      content: TextField(
        controller: controller.categoryNameController,
        decoration: InputDecoration(
          hintText: "Enter Category Name",
          filled: true,
          fillColor: Theme.of(context).cardColor.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onConfirm: () => controller.updateCategory(id),
    );
  }

  void _showGlossyDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required VoidCallback onConfirm,
  }) {
    final theme = Theme.of(context);
    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: theme.cardColor.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: "Close",
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: content,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "SAVE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          "CANCEL",
                          style: TextStyle(
                            color: theme.disabledColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, int id) {
    Get.defaultDialog(
      title: "Delete Category",
      middleText:
          "Are you sure you want to delete this category? This action cannot be undone.",
      actions: confirmActions(
        confirmText: "DELETE",
        color: Colors.red,
        onConfirm: () {
        Get.back();
        Get.find<SellerCategoryController>().deleteCategory(id);
      },
        cancelText: "CANCEL",
      ),
    );
  }
}

/// Icon for a category status: active ticked, inactive / rejected blocked, anything else waiting.
IconData categoryStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return Icons.check_circle_outline;
    case 'inactive':
    case 'rejected':
      return Icons.block;
    default:
      return Icons.pending_actions;
  }
}

Color categoryStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return Colors.green;
    case 'inactive':
      return Colors.grey;
    case 'rejected':
      return Colors.red;
    default:
      return Colors.orange;
  }
}
