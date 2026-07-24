import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/category_controller.dart';
import '../model/category_model.dart';

class CategoryScreen extends StatelessWidget {
  CategoryScreen({super.key});

  final CategoryController controller =
      Get.put(CategoryController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      /// 🔥 MODERN APP BAR
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor:
            theme.scaffoldBackgroundColor,
        title: Text(
          "Categories",
          style: theme.textTheme.headlineSmall
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Padding(
          //   padding:
          //       const EdgeInsets.only(right: 12),
          //   child: IconButton(
          //     icon: Icon(IconlyLight.plus,
          //         color:
          //             theme.colorScheme.primary),
          //     onPressed: () {},
          //   ),
          // ),
        ],
      ),

      body: Column(
        children: [

          /// 🔥 MODERN SEARCH BAR
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
                    20, 10, 20, 20),
            child: _buildSearchBar(context),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child:
                      CircularProgressIndicator(
                    color: theme
                        .colorScheme.primary,
                  ),
                );
              }

              if (controller
                  .categories.isEmpty) {
                return _buildEmptyState(
                    context);
              }

              return RefreshIndicator(
                color: theme
                    .colorScheme.primary,
                backgroundColor:
                    theme.cardColor,
                onRefresh:
                    controller.fetchCategories,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(
                          horizontal: 20),
                  itemCount: controller
                      .categories.length,
                  separatorBuilder:
                      (_, __) =>
                          const SizedBox(
                              height: 16),
                  itemBuilder:
                      (context, index) {
                    final category =
                        controller
                                .categories[
                            index];
                    return _buildCategoryCard(
                        context,
                        category);
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
  /// MODERN SEARCH BAR
  /// ===============================
  Widget _buildSearchBar(
      BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText:
              "Search categories...",
          hintStyle:
              theme.textTheme.bodySmall,
          prefixIcon: Icon(
            IconlyLight.search,
            color:
                theme.iconTheme.color,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
                  vertical: 16),
        ),
      ),
    );
  }

  /// ===============================
  /// MODERN CATEGORY CARD
  /// ===============================
  Widget _buildCategoryCard(
    BuildContext context,
    CategoryModel category,
  ) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration:
          const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: theme.cardColor,
        borderRadius:
            BorderRadius.circular(22),
        elevation: 3,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(22),
          onTap: () {
            Get.toNamed(
              '/subcategory',
              arguments: {
                "categoryId":
                    category.id,
                "categoryName":
                    category
                        .categoryName,
              },
            );
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
  Widget _buildEmptyState(
      BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            IconlyLight.category,
            size: 80,
            color: theme
                .colorScheme.primary
                .withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No Categories Found",
            style: theme
                .textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            "Pull down to refresh",
            style:
                theme.textTheme.bodySmall,
          ),
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