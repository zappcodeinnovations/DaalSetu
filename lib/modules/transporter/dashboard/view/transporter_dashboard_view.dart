import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:agro_broker/theme/glass_widgets.dart';
import 'package:agro_broker/routes/app_routes.dart';

class TransporterDashboardView extends StatelessWidget {
  const TransporterDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      {'title': 'Branch', 'icon': IconlyLight.location, 'route': AppRoutes.transporterBranch},
      {'title': 'Brands', 'icon': IconlyLight.star, 'route': AppRoutes.transporterBrands},
      {'title': 'Category', 'icon': IconlyLight.category, 'route': AppRoutes.transporterCategory},
      {'title': 'Company', 'icon': IconlyLight.work, 'route': AppRoutes.transporterCompany},
      {'title': 'KYC', 'icon': IconlyLight.document, 'route': AppRoutes.transporterKyc},
      {'title': 'Contracts', 'icon': IconlyLight.paper, 'route': AppRoutes.transporterContracts},
      {'title': 'Notifications', 'icon': IconlyLight.notification, 'route': AppRoutes.transporterNotifications},
      {'title': 'Offers', 'icon': IconlyLight.ticket_star, 'route': AppRoutes.transporterOffers},
      {'title': 'Products', 'icon': IconlyLight.bag, 'route': AppRoutes.transporterProducts},
      {'title': 'RFQ', 'icon': IconlyLight.chat, 'route': AppRoutes.transporterRfq},
      {'title': 'Users', 'icon': IconlyLight.user_1, 'route': AppRoutes.transporterUsers},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Dashboard",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
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
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
