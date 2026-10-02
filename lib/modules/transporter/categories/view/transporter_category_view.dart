import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../seller/categories/controller/seller_category_controller.dart';
import '../../../seller/categories/model/seller_category_model.dart';
import '../../../../theme/app_theme.dart';

class TransporterCategoryView extends StatelessWidget {
  const TransporterCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerCategoryController());
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: theme.textTheme.bodyLarge?.color,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Categories",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(IconlyLight.swap, color: primary),
            tooltip: "Refresh",
            onPressed: controller.fetchAllData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/images/thumb_logo.png',
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: controller.fetchAllData,
            color: primary,
            child: Obx(() {
              if (controller.isLoading.value && controller.categoryTree.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDashboard(context, controller),
                    const SizedBox(height: 16),
                    _buildSearchBar(context, controller),
                    const SizedBox(height: 16),
                    controller.isSearching.value
                        ? _buildSearchResults(context, controller)
                        : _buildCategoryTree(context, controller),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, SellerCategoryController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = controller.dashboardData.value;
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.borderColor : AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconlyLight.category, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Category Overview",
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Total Categories", data.total.toString(), AppTheme.primaryGold),
              _buildStatItem("Root", data.root.toString(), AppTheme.successGreen),
              _buildStatItem("Sub Categories", data.sub.toString(), AppTheme.secondaryOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, SellerCategoryController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgSecondary : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.borderColor : AppTheme.borderLight),
      ),
      child: TextField(
        onChanged: controller.search,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search categories...",
          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
          prefixIcon: Icon(IconlyLight.search, color: theme.colorScheme.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, SellerCategoryController controller) {
    if (controller.searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text("No matching categories found", style: TextStyle(color: Colors.grey))),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = controller.searchResults[index];
        return _buildCategoryTile(context, item.name, item.isActive);
      },
    );
  }

  Widget _buildCategoryTree(BuildContext context, SellerCategoryController controller) {
    if (controller.categoryTree.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text("No categories available", style: TextStyle(color: Colors.grey))),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.categoryTree.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final node = controller.categoryTree[index];
        return _buildCategoryNode(context, node);
      },
    );
  }

  Widget _buildCategoryNode(BuildContext context, CategoryTreeModel node) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.borderColor : AppTheme.borderLight),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          child: Icon(IconlyLight.category, color: theme.colorScheme.primary, size: 18),
        ),
        title: Text(
          node.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          "${node.childrenCount} Subcategories",
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
        ),
        children: node.children.map((child) => _buildChildNode(context, child)).toList(),
      ),
    );
  }

  Widget _buildChildNode(BuildContext context, CategoryTreeModel child) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              child.name,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text("ACTIVE", style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, String name, bool isActive) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.borderColor : AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Icon(IconlyLight.category, color: theme.colorScheme.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (isActive ? Colors.green : Colors.grey).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(isActive ? "ACTIVE" : "INACTIVE", style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
