import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_category_controller.dart';
import '../model/seller_category_model.dart';

class SellerCategoryView extends StatelessWidget {
  const SellerCategoryView({super.key});

  static const Color primaryColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerCategoryController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Categories",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => _showAddRootDialog(context),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text("Add Category", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            return const Center(child: CircularProgressIndicator(color: primaryColor));
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
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _dashboardItem(context, "Total", data.total.toString(), Icons.inventory_2_outlined),
          _dashboardItem(context, "Root", data.root.toString(), Icons.account_tree_outlined),
          _dashboardItem(context, "Active", data.active.toString(), Icons.check_circle_outline),
          _dashboardItem(context, "Pending", data.pending.toString(), Icons.pending_actions),
        ],
      ),
    );
  }

  Widget _dashboardItem(BuildContext context, String title, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(title, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final controller = Get.find<SellerCategoryController>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.search,
        decoration: InputDecoration(
          hintText: "Search Categories...",
          prefixIcon: const Icon(IconlyLight.search),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final controller = Get.find<SellerCategoryController>();
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

  Widget _buildSearchResultNode(BuildContext context, CategoryDetailModel category) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = Get.find<SellerCategoryController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
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
                      errorBuilder: (context, error, stackTrace) => const Icon(IconlyLight.category, color: primaryColor),
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
            _categoryInfoRow(IconlyLight.category, "${category.childrenCount} sub-categories", theme),
            _categoryInfoRow(
              category.status == 'active' ? Icons.check_circle_outline : Icons.pending_actions,
              "Status: ${category.status.toUpperCase()}",
              theme,
              textColor: category.status == 'active' ? Colors.green : Colors.orange,
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
    );
  }

  Widget _buildCategoryTree(BuildContext context) {
    final controller = Get.find<SellerCategoryController>();
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
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
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
                        errorBuilder: (context, error, stackTrace) => const Icon(IconlyLight.category, color: primaryColor),
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
              _categoryInfoRow(IconlyLight.category, "${node.childrenCount} sub-categories", theme),
              _categoryInfoRow(
                node.status == 'active' ? Icons.check_circle_outline : Icons.pending_actions,
                "Status: ${node.status.toUpperCase()}",
                theme,
                textColor: node.status == 'active' ? Colors.green : Colors.orange,
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
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
          children: node.children.map((child) => _buildCategoryNode(context, child)).toList(),
        ),
      ),
    );
  }

  Widget _categoryInfoRow(IconData icon, String text, ThemeData theme, {Color? textColor}) {
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
                color: textColor ?? theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                fontWeight: textColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRootDialog(BuildContext context) {
    final controller = Get.find<SellerCategoryController>();
    controller.categoryNameController.clear();
    controller.selectedBrandIds.clear();

    _showGlossyDialog(
      context: context,
      title: "Add Root Category",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller.categoryNameController,
            decoration: InputDecoration(
              hintText: "Enter Category Name",
              filled: true,
              fillColor: Theme.of(context).cardColor.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(IconlyLight.category),
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Select Brands", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.brandsList.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                ),
                child: const Column(
                  children: [
                    Icon(IconlyLight.info_square, color: Colors.red, size: 24),
                    SizedBox(height: 8),
                    Text("Brands not Found", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }

            return Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: controller.brandsList.length,
                itemBuilder: (context, index) {
                  final brand = controller.brandsList[index];
                  return CheckboxListTile(
                    title: Text(brand.brandName, style: const TextStyle(fontSize: 14)),
                    value: controller.selectedBrandIds.contains(brand.id),
                    onChanged: (val) => controller.toggleBrandSelection(brand.id),
                    activeColor: primaryColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                },
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Theme.of(context).cardColor.withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                content,
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Get.back(), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text("SAVE", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, int id) {
    Get.defaultDialog(
      title: "Delete Category",
      middleText: "Are you sure you want to delete this category? This action cannot be undone.",
      textConfirm: "DELETE",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        Get.find<SellerCategoryController>().deleteCategory(id);
      },
      textCancel: "CANCEL",
    );
  }
}
