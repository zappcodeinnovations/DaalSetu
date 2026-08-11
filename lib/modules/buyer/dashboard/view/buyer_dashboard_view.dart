import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:daalsetu/theme/glass_widgets.dart';
import 'package:daalsetu/routes/app_routes.dart';
import 'package:daalsetu/modules/buyer/dashboard/controller/buyer_dashboard_controller.dart';
import 'package:daalsetu/modules/profile/controller/profile_controller.dart';
import 'package:daalsetu/modules/category/model/category_model.dart';
import 'package:daalsetu/modules/category/view/category_page.dart';

class BuyerDashboardView extends StatelessWidget {
  BuyerDashboardView({super.key});

  final BuyerDashboardController controller = Get.put(BuyerDashboardController());
  final ProfileController profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.isError.value) {
          return Center(
            child: Text(
              "Error: ${controller.errorMessage.value}",
              style: TextStyle(color: theme.colorScheme.error),
            ),
          );
        }

        final data = controller.dashboardData.value;
        if (data == null) {
          return const Center(child: Text("No Data Found"));
        }

        return RefreshIndicator(
          onRefresh: controller.fetchDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(context),
                const SizedBox(height: 16),
                // _buildSearchBar(context),
                // const SizedBox(height: 24),
                _buildBannerSlider(context, data.recentRfqs),
                const SizedBox(height: 30),
                _buildSectionHeader(context, "Shop by Category", "View All", onTap: () {
                  Get.to(() => CategoryPageView());
                }),
                const SizedBox(height: 16),
                _buildCategoriesList(context, controller.categories),
                const SizedBox(height: 30),
                _buildKPIGrid(context, data.kpis),
                const SizedBox(height: 30),
                _buildSectionHeader(context, "Recent Deals & Orders", "View All", onTap: () {}),
                const SizedBox(height: 16),
                _buildRecentOrdersList(context, data.recentOrders),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Obx(() {
        final theme = Theme.of(context);
        return AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: controller.isSearching.value
                ? Container(
                    key: const ValueKey('searchField'),
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                    ),
                    child: TextField(
                      autofocus: true,
                      onChanged: (val) => controller.searchQuery.value = val,
                      decoration: InputDecoration(
                        hintText: "Search here...",
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  )
                : Align(
                    key: const ValueKey('logoImage'),
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/images/app_name.png',
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
          actions: [
            if (!controller.isSearching.value)
              IconButton(
                icon: const Icon(IconlyLight.search, size: 26),
                onPressed: () {
                  controller.isSearching.value = true;
                },
              ),
            if (controller.isSearching.value)
              IconButton(
                icon: const Icon(IconlyLight.close_square, size: 26),
                onPressed: () {
                  controller.isSearching.value = false;
                  controller.searchQuery.value = '';
                },
              )
            else
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(IconlyLight.notification, size: 28),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 8),
          ],
        );
      }),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final profile = profileController.profile.value;
      final name = profile == null ? "Buyer" : "${profile.firstName} ${profile.lastName}";
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Hello, ",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const Text(" 👋", style: TextStyle(fontSize: 22)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Welcome back! Here's what's happening today.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(IconlyLight.search, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search for pulses, dals, commodities...",
                hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Icon(IconlyLight.filter, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSlider(BuildContext context, List<dynamic> rfqs) {
    final theme = Theme.of(context);
    
    // Find the first open RFQ to feature
    var featuredRfq = rfqs.firstWhere(
      (rfq) => rfq['status']?.toString().toLowerCase() == 'open', 
      orElse: () => rfqs.isNotEmpty ? rfqs.first : null
    );

    if (featuredRfq == null) {
      return const SizedBox(); // Hide banner if no data
    }

    String title = featuredRfq['title']?.toString() ?? "Special Deal";
    // Clean up title if it contains API-DOC prefixes
    if (title.contains("API-DOC")) {
       title = title.split(" ").skip(1).join(" ");
    }
    String price = featuredRfq['price']?.toString() ?? "";
    String qty = featuredRfq['quantity']?.toString() ?? "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconlyBold.discount, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                "ACTIVE REQUIREMENT",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (price.isNotEmpty)
            Text(
              "₹$price",
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          const SizedBox(height: 4),
          if (qty.isNotEmpty)
            Text(
              "Quantity Needed: $qty",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("View Details", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(IconlyLight.arrow_right_2, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String action, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesList(BuildContext context, List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Only show first 3 categories
    final displayCategories = categories.take(3).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: displayCategories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    IconlyBold.category,
                    size: 32,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.categoryName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKPIGrid(BuildContext context, Map<String, dynamic> kpis) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKPICard(context, "Total Spent", kpis['spent']?.toString() ?? "₹0", kpis['spent_delta']?.toString() ?? "", IconlyBold.wallet, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard(context, "Active Offers", kpis['open_rfq']?.toString() ?? "0", "Live offers available", IconlyBold.ticket_star, Colors.redAccent)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildKPICard(context, "Active Orders", kpis['active_orders']?.toString() ?? "0", "View all orders", IconlyBold.bag, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard(context, "Membership", "Gold Buyer", "Valid till 31 Dec 2025", IconlyBold.star, Colors.amber)),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(BuildContext context, String title, String value, String subtitle, IconData icon, Color color) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersList(BuildContext context, List<dynamic> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text("No recent orders"));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length > 5 ? 5 : orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final theme = Theme.of(context);
        
        String status = order['transport_status'] ?? 'Pending';
        Color statusColor = Colors.orange;
        if (status.toLowerCase().contains("transit")) statusColor = Colors.blue;
        if (status.toLowerCase().contains("completed") || status.toLowerCase().contains("delivered")) statusColor = Colors.green;

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.amber[100],
                child: Icon(IconlyBold.bag, color: Colors.amber[800], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['commodity']?.toString() ?? "Commodity",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Order ID: ${order['id']}",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(IconlyLight.bag, size: 12, color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(
                          order['quantity']?.toString() ?? "-",
                          style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodySmall?.color),
                        ),
                        const SizedBox(width: 12),
                        Icon(IconlyLight.calendar, size: 12, color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(
                          "Today",
                          style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${order['value'] ?? '0'}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "per Qtl",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
