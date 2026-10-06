import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/glass_widgets.dart';
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
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showCreateCategoryDialog(context, controller),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(IconlyLight.plus, color: Colors.white),
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
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

  void _showCreateCategoryDialog(BuildContext context, CategoryController controller) {
    final theme = Theme.of(context);
    final nameCtrl = TextEditingController();
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Create Category",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GlassTextField(
                controller: nameCtrl,
                hintText: "Category Name",
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty) {
                        Get.back();
                        controller.createCategory(nameCtrl.text);
                      }
                    },
                    child: const Text("Create"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        category
                            .categoryName,
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                      ),
                      const SizedBox(
                          height: 6),
                      Text(
                        "Created on ${_formatDate(category.createdAt ?? DateTime.now())}",
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: theme
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(
                                      0.7),
                            ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 16,
                  color: theme
                      .colorScheme
                      .primary,
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
