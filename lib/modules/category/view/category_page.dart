import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/category_controller.dart';
import '../model/category_model.dart';

class CategoryPageView extends StatelessWidget {
  const CategoryPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final CategoryController controller = Get.put(CategoryController());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      /// 🔥 MODERN APP BAR
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(IconlyLight.arrow_left_2, color: theme.textTheme.bodyLarge?.color),
                onPressed: () => Get.back(),
              )
            : null,
        title: Text(
          "Categories",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Send for Approval",
            icon: Icon(IconlyLight.send, color: theme.colorScheme.primary),
            onPressed: () => _showSendForApprovalBottomSheet(context, controller),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _showSendForApprovalBottomSheet(context, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(IconlyLight.send, color: Colors.white, size: 20),
            label: const Text(
              "SEND FOR APPROVAL",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          /// 🔥 MODERN SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: _buildSearchBar(context, controller),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.allCategories.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                );
              }

              if (controller.categories.isEmpty) {
                return _buildEmptyState(context, controller);
              }

              return RefreshIndicator(
                color: theme.colorScheme.primary,
                backgroundColor: theme.cardColor,
                onRefresh: controller.fetchCategories,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: controller.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final category = controller.categories[index];
                    return _buildCategoryCard(context, controller, category);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// SEND FOR APPROVAL BOTTOM SHEET
  /// ===============================
  void _showSendForApprovalBottomSheet(BuildContext context, CategoryController controller) {
    final theme = Theme.of(context);
    final customNameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final Set<int> selectedCategoryIds = {};

    // Get assigned category IDs to filter out already approved categories
    final assignedIds = controller.allCategories.map((c) => c.id).toSet();
    final unassignedSystemCategories = controller.systemCategories
        .where((c) => !assignedIds.contains(c.id))
        .toList();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(IconlyBold.send, color: theme.colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Send For Approval",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Request new categories for your buyer account",
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  if (unassignedSystemCategories.isNotEmpty) ...[
                    Text(
                      "Select Existing System Categories",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: unassignedSystemCategories.map((cat) {
                        final isSelected = selectedCategoryIds.contains(cat.id);
                        return FilterChip(
                          label: Text(cat.categoryName),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                          checkmarkColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedCategoryIds.add(cat.id);
                              } else {
                                selectedCategoryIds.remove(cat.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    "Or Enter Custom Category Name",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customNameCtrl,
                    decoration: InputDecoration(
                      hintText: "e.g. Yellow Peas, Rajma",
                      prefixIcon: const Icon(IconlyLight.edit, size: 20),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "Remark / Note (Optional)",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Add note for administrator...",
                      prefixIcon: const Icon(IconlyLight.document, size: 20),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedCategoryIds.isEmpty && customNameCtrl.text.trim().isEmpty) {
                          Get.snackbar("Notice", "Please select at least one category or enter a custom category name",
                              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
                          return;
                        }

                        Get.back(); // close bottom sheet
                        await controller.sendForApproval(
                          categoryIds: selectedCategoryIds.toList(),
                          categoryName: customNameCtrl.text.trim().isNotEmpty ? customNameCtrl.text.trim() : null,
                          note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        "SEND FOR APPROVAL",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  /// ===============================
  /// MODERN SEARCH BAR
  /// ===============================
  Widget _buildSearchBar(BuildContext context, CategoryController controller) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        style: theme.textTheme.bodyMedium,
        onChanged: controller.searchCategories,
        decoration: InputDecoration(
          hintText: "Search categories...",
          hintStyle: theme.textTheme.bodySmall,
          prefixIcon: Icon(
            IconlyLight.search,
            color: theme.iconTheme.color,
          ),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                controller.searchCategories('');
              },
            );
          }),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  /// ===============================
  /// MODERN CATEGORY CARD
  /// ===============================
  Widget _buildCategoryCard(
    BuildContext context,
    CategoryController controller,
    CategoryModel category,
  ) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        elevation: 3,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            controller.fetchCategoryBrands(category.id);
          },
          child: Padding(
            padding:
                const EdgeInsets.all(18),
            child: Row(
              children: [

                /// ICON BOX
                Container(
                  padding:
                      const EdgeInsets.all(
                          16),
                  decoration:
                      BoxDecoration(
                    gradient:
                        LinearGradient(
                      colors: [
                        theme
                            .colorScheme
                            .primary
                            .withOpacity(
                                0.8),
                        theme
                            .colorScheme
                            .primary,
                      ],
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(18),
                  ),
                  child: const Icon(
                    Icons
                        .grid_view_rounded,
                    color:
                        Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 18),

                /// TEXT SECTION
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.categoryName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (category.status != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (category.status?.toLowerCase() == 'approved' ? Colors.green : Colors.orange).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category.status!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: category.status?.toLowerCase() == 'approved' ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.createdAt != null
                            ? "Created on ${_formatDate(category.createdAt!)}"
                            : "Approved Category",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ===============================
  /// EMPTY STATE
  /// ===============================
  Widget _buildEmptyState(BuildContext context, CategoryController controller) {
    final theme = Theme.of(context);
    final isSearching = controller.searchQuery.value.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconlyLight.category,
            size: 70,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? "No Matching Categories" : "No Categories Found",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? "No categories match '${controller.searchQuery.value}'"
                : "Pull down to refresh",
            style: theme.textTheme.bodySmall,
          ),
          if (isSearching) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => controller.searchCategories(''),
              child: const Text("Clear Search"),
            ),
          ],
        ],
      ),
    );
  }

  /// ===============================
  /// DATE FORMAT
  /// ===============================
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }
}
