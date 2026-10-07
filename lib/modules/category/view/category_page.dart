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
  /// SEND FOR APPROVAL POPUP DIALOG
  /// ===============================
  void _showIndividualApprovalDialog(
    BuildContext context,
    CategoryController controller,
    CategoryModel category,
  ) {
    final theme = Theme.of(context);
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(IconlyBold.send, color: theme.colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Send For Approval",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            category.categoryName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Do you want to send a request to the Admin for \"${category.categoryName}\" category access?",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "Add note for admin (optional)...",
                    hintStyle: theme.textTheme.bodySmall,
                    prefixIcon: const Icon(IconlyLight.document, size: 18),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("CANCEL"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogCtx).pop();
                          await controller.sendForApproval(
                            categoryIds: [category.id],
                            note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "SEND",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
    final isApproved = category.isApproved;

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
          // Approved cards are untappable (locked, like website)
          // Pending or request cards open the individual Send For Approval dialog
          onTap: isApproved
              ? null
              : () => _showIndividualApprovalDialog(
                    context,
                    controller,
                    category,
                  ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                /// ICON BOX
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isApproved
                          ? [
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                              theme.colorScheme.primary,
                            ]
                          : [
                              Colors.orange.withValues(alpha: 0.8),
                              Colors.orange,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isApproved ? Icons.grid_view_rounded : IconlyLight.time_circle,
                    color: Colors.white,
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
                                color: (isApproved ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category.status!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isApproved ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isApproved
                            ? "Active category."
                            : (category.isPending
                                ? "Pending approval. Tap to request."
                                : "Click to request approval."),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Only show chevron forward arrow on actionable (unapproved) cards
                if (!isApproved) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                ],
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
}
