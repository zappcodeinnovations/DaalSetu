import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/buyer_dashboard_controller.dart';
import '../../../profile/controller/profile_controller.dart';
import '../../../category/model/category_model.dart';
import '../../../category/view/category_page.dart';
import '../../orders/view/buyer_orders_view.dart';
import '../../offers/view/buyer_offers_view.dart';
import '../../../seller/notifications/view/seller_notification_view.dart';

class BuyerDashboardView extends StatelessWidget {
  BuyerDashboardView({super.key});

  final BuyerDashboardController controller = Get.put(BuyerDashboardController());
  final ProfileController profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                _buildSectionHeader(context, "Recent Deals & Orders", "View All", onTap: () {
                  Get.to(() => const BuyerOrdersView());
                }),
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
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            'assets/images/app_name.png',
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(IconlyLight.notification, size: 28),
                onPressed: () => Get.to(() => const SellerNotificationView()),
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
      ),
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
          Text.rich(
            TextSpan(
              text: "Hello, ",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
              children: [
                TextSpan(
                  text: name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const TextSpan(text: " 👋"),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            onPressed: () => Get.to(() => const BuyerOffersView(initialIndex: 5)),
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
    
    final displayCategories = categories.take(6).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: displayCategories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      IconlyBold.category,
                      size: 28,
                      color: Colors.amber[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.categoryName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
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
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 17,
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
                radius: 22,
                backgroundColor: Colors.amber[100],
                child: Icon(IconlyBold.bag, color: Colors.amber[800], size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['commodity']?.toString() ?? "Commodity",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Order ID: ${order['id']}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(IconlyLight.bag, size: 12, color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            order['quantity']?.toString() ?? "-",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodySmall?.color),
                          ),
                        ),
                        const SizedBox(width: 10),
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${order['value'] ?? '0'}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
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
