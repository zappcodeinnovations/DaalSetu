import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:agro_broker/theme/glass_widgets.dart';
import 'package:agro_broker/routes/app_routes.dart';
import 'package:agro_broker/modules/buyer/dashboard/controller/buyer_dashboard_controller.dart';

class BuyerDashboardView extends StatelessWidget {
  const BuyerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(BuyerDashboardController());

    final items = [
      {'title': 'My Interests', 'icon': IconlyLight.heart, 'route': AppRoutes.buyerMyInterests},
      {'title': 'Today\'s Offers', 'icon': IconlyLight.ticket_star, 'route': AppRoutes.buyerTodayOffers},
      {'title': 'Pending Offers', 'icon': IconlyLight.time_circle, 'route': AppRoutes.buyerPendingOffers},
      {'title': 'Previous Offers', 'icon': IconlyLight.document, 'route': AppRoutes.buyerPreviousOffers},
      {'title': 'Delivery Challan', 'icon': IconlyLight.paper, 'route': AppRoutes.buyerDeliveryChallan},
      {'title': 'Orders', 'icon': IconlyLight.bag, 'route': AppRoutes.buyerOrders},
      {'title': 'Transport Tracking', 'icon': IconlyLight.location, 'route': AppRoutes.buyerTransportTracking},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Buyer Dashboard",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
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
        final spent = data?.kpis['spent'] ?? '₹0.00';
        final activeOrders = data?.kpis['active_orders'] ?? 0;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn("Total Spent", spent.toString(), theme),
                      _buildStatColumn("Active Orders", activeOrders.toString(), theme),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "Quick Links",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () => Get.toNamed(item['route'] as String),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 36,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item['title'] as String,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatColumn(String title, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
