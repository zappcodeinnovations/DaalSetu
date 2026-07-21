import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/subcategory_controller.dart';

class SubCategoryScreen extends StatelessWidget {
  SubCategoryScreen({super.key});

  final SubCategoryController controller = Get.put(SubCategoryController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      /// 🔹 APP BAR
      appBar: AppBar(
        // elevation: 0,
        // centerTitle: true,
        // title: Obx(
        //   () => Text(
        //     (controller.categoryName as String).isEmpty
        //         ? "Sub Categories"
        //         : controller.categoryName as String,
        //     style: theme.textTheme.titleLarge?.copyWith(
        //       fontWeight: FontWeight.bold,
        //     ),
        //   ),
        // ),
      ),

      /// 🔹 BODY
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
        }

        if (controller.subcategories.isEmpty) {
          return _emptyState(context);
        }

        return RefreshIndicator(
          onRefresh: controller.fetchSubCategories,
          color: theme.colorScheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: controller.subcategories.length,
            itemBuilder: (context, index) {
              final item = controller.subcategories[index];

              return _buildCard(context, item);
            },
          ),
        );
      }),
    );
  }

  /// 🔹 PREMIUM CARD
  Widget _buildCard(BuildContext context, dynamic item) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        print("Clicked SubCategory ID: ${item.id}");
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            /// 🔹 ICON WITH GRADIENT
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.category_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),

            const SizedBox(width: 16),

            /// 🔹 TEXT SECTION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Subcategory Name
                  Text(
                    item.subcategoryName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// Category
                  Row(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.category?.categoryName ?? "Unknown",
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// Created Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.createdAt != null
                            ? item.createdAt.toLocal().toString().split(' ')[0]
                            : "N/A",
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// 🔹 ARROW
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.iconTheme.color?.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 EMPTY STATE
  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No Sub Categories Found",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text("Pull down to refresh", style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
