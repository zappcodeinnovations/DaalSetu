import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/category_controller.dart';
import '../model/category_model.dart';
import '../model/category_request_model.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import '../../../utils/app_snackbar.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class CategoryPageView extends StatelessWidget {
  const CategoryPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final CategoryController controller = Get.put(CategoryController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,

        /// 🔥 MODERN APP BAR WITH TABS
        appBar: HeroHeader(
          leading: AppBarLeading(
            child: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(IconlyLight.arrow_left_2, color: Colors.white, size: 20),
                    onPressed: () => Get.back(),
                  )
                : null,
          ),
          title: "Commodity Categories",
          trailing: IconButton(
            tooltip: "Send for Approval",
            icon: const Icon(IconlyLight.send, color: Colors.white, size: 21),
            onPressed: controller.sendSelectedForApproval,
          ),
          bottom: TabBar(
            onTap: (_) => controller.fetchCategories(),
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              const Tab(text: "My Categories"),
              Obx(() {
                final count = controller.recentRequests.length;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Recent Requests"),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "$count",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
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
              child: Obx(() => ElevatedButton.icon(
                onPressed: controller.sendSelectedForApproval,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(IconlyLight.send, color: Colors.white, size: 20),
                label: Text(
                  controller.selectedRequestIds.isEmpty
                      ? "SEND FOR APPROVAL"
                      : "SEND FOR APPROVAL (${controller.selectedRequestIds.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                ),
              )),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildCategoriesTab(context, controller),
            _buildRecentRequestsTab(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab(BuildContext context, CategoryController controller) {
    final theme = Theme.of(context);
    return Column(
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

            final requestable = controller.requestableCategories;
            if (controller.categories.isEmpty && requestable.isEmpty) {
              return _buildEmptyState(context, controller);
            }

            // Top of the page: the categories you can still ask for, ready to tick. Below: your own.
            return RefreshIndicator(
              color: theme.colorScheme.primary,
              backgroundColor: theme.cardColor,
              onRefresh: controller.fetchCategories,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (requestable.isNotEmpty) ...[
                    _buildRequestableSection(context, controller, requestable),
                    const SizedBox(height: 18),
                  ],
                  if (controller.categories.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "Your Categories",
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    for (var i = 0; i < controller.categories.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      _buildCategoryCard(context, controller, controller.categories[i]),
                    ],
                  ],
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Categories the buyer can still request, listed right on the page with a tick box each.
  Widget _buildRequestableSection(
    BuildContext context,
    CategoryController controller,
    List<CategoryModel> requestable,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
      ),
      // A Material under the tick boxes so their ink shows above the card's background colour.
      child: Material(
        color: Colors.transparent,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              "Available Categories - tick and send for approval",
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          for (final cat in requestable)
            CheckboxListTile(
              value: controller.selectedRequestIds.contains(cat.id),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: theme.colorScheme.primary,
              title: Text(
                cat.categoryName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: controller.selectedRequestIds.contains(cat.id) ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              onChanged: (selected) => controller.toggleRequest(cat.id, selected == true),
            ),
          const SizedBox(height: 6),
        ],
      )),
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
                        (category.requestedAt ?? category.createdAt) != null
                            ? "Requested on ${_formatDateTime((category.requestedAt ?? category.createdAt)!)}"
                            : (category.status?.toLowerCase() == 'pending'
                                ? "Waiting for approval"
                                : (category.status?.toLowerCase() == 'request'
                                    ? "Click to request approval"
                                    : "Approved Category")),
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
  /// RECENT REQUESTS TAB (APPROVAL REQUESTS)
  /// ===============================
  Widget _buildRecentRequestsTab(BuildContext context, CategoryController controller) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoading.value && controller.recentRequests.isEmpty) {
        return Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        );
      }

      if (controller.recentRequests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconlyLight.time_circle,
                size: 70,
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                "No Recent Requests",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Your category approval requests will appear here",
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: theme.colorScheme.primary,
        backgroundColor: theme.cardColor,
        onRefresh: controller.fetchCategories,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          itemCount: controller.recentRequests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final req = controller.recentRequests[index];
            return _buildRequestCard(context, req);
          },
        ),
      );
    });
  }

  Widget _buildRequestCard(BuildContext context, CategoryRequestModel req) {
    final theme = Theme.of(context);
    final status = req.status.toLowerCase();
    final isApproved = status == 'approved';
    final isPending = status == 'pending';
    final statusColor = isApproved
        ? Colors.green
        : (isPending ? Colors.orange : Colors.red);

    // The category name is the card's title, so a newly sent category is recognisable at a glance.
    final title = req.categoryNames.isNotEmpty
        ? req.categoryNames.join(', ')
        : ((req.requestNote ?? '').trim().isNotEmpty ? req.requestNote!.trim() : "Category Request");

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isApproved
                        ? Icons.check_circle_outline_rounded
                        : (isPending ? IconlyLight.time_circle : Icons.cancel_outlined),
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (req.requestedAt != null)
                        Row(
                          children: [
                            Icon(IconlyLight.calendar, size: 13, color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(req.requestedAt!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    req.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (req.reviewedAt != null || (req.requestNote != null && req.requestNote!.isNotEmpty)) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.4)),
              const SizedBox(height: 8),
              if (req.reviewedAt != null)
                Text(
                  "Reviewed on: ${_formatDateTime(req.reviewedAt!)}${req.reviewerName != null ? ' by ${req.reviewerName}' : ''}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                  ),
                ),
              if (req.adminComment != null && req.adminComment!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Admin note: ${req.adminComment}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
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
  /// DATE & TIME FORMAT
  /// ===============================
  static const _months = [
    'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar',
    'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'
  ];

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[local.month - 1];
    final year = local.year.toString();

    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? "PM" : "AM";
    final hourFormatted = hour.toString().padLeft(2, '0');

    return "$day $month $year, $hourFormatted:$minute $amPm";
  }
}
