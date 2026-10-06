import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import '../../../../routes/app_routes.dart';
import '../../branches/view/seller_branches_view.dart';
import '../../buyer_offers/view/seller_buyer_offers_view.dart';
import '../../challans/view/seller_delivery_challan_view.dart';
import '../../company/view/seller_company_view.dart';
import '../../consignments/view/seller_consignments_view.dart';
import '../../contracts/view/seller_contracts_view.dart';
import '../../masters/view/seller_master_management_view.dart';
import '../../products/controller/seller_product_controller.dart';
import '../../products/view/add_product_view.dart';
import '../../products/view/seller_product_view.dart';
import '../../rfq/view/seller_rfq_list_view.dart';

class SellerWorkspaceView extends StatelessWidget {
  const SellerWorkspaceView({super.key});

  Future<void> _openCreateOffer() async {
    if (!Get.isRegistered<SellerProductController>()) {
      Get.put(SellerProductController());
    }
    await Get.to(() => const AddProductView());
  }

  void _openOfferMedia() {
    Get.to(() => const SellerProductView());
    Get.snackbar(
      'Offer Media',
      'Open an offer and choose its image or video option.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Seller Workspace',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Get.toNamed(AppRoutes.sellerNotifications),
            icon: const Icon(IconlyLight.notification),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Text(
            'All seller tools in one place',
            style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color),
          ),
          const SizedBox(height: 20),
          _section(context, 'Offers', [
            _Action(
              'Create Offer',
              'Publish a new listing',
              IconlyBold.plus,
              Colors.orange,
              _openCreateOffer,
            ),
            _Action(
              'My Offers',
              'Stock, status and buyer interest',
              IconlyBold.bag,
              Colors.deepOrange,
              () => Get.to(() => const SellerProductView()),
            ),
            _Action(
              'Buyer Requirements',
              'View RFQs and submit quotations',
              IconlyBold.document,
              Colors.blue,
              () => Get.to(() => const SellerRfqListView()),
            ),
            _Action(
              'Buyer Offers',
              'Negotiate buyer requests',
              IconlyBold.ticket,
              Colors.indigo,
              () => Get.to(() => const SellerBuyerOffersView()),
            ),
            _Action(
              'Offer Media',
              'Manage offer images and videos',
              IconlyBold.image,
              Colors.purple,
              _openOfferMedia,
            ),
          ]),
          _section(context, 'Masters & Business', [
            _Action(
              'Category Master',
              'Categories and sub-categories',
              IconlyBold.category,
              Colors.green,
              () => Get.toNamed(AppRoutes.sellerCategory),
            ),
            _Action(
              'Brand & Tag Master',
              'Manage brands and quality tags',
              IconlyBold.bookmark,
              Colors.teal,
              () => Get.to(() => const SellerMasterManagementView()),
            ),
            _Action(
              'Companies',
              'Registered seller companies',
              IconlyBold.home,
              Colors.brown,
              () => Get.to(() => const SellerCompanyView()),
            ),
            _Action(
              'My Branches',
              'Branch membership and requests',
              IconlyBold.location,
              Colors.cyan,
              () => Get.to(() => const SellerBranchesView()),
            ),
          ]),
          _section(context, 'Deals & Dispatch', [
            _Action(
              'Contracts',
              'Confirmed seller deals',
              IconlyBold.paper,
              Colors.blueGrey,
              () => Get.to(() => const SellerContractsView()),
            ),
            _Action(
              'Consignments',
              'Loading and consignment workflow',
              IconlyBold.buy,
              Colors.teal,
              () => Get.to(() => const SellerConsignmentsView()),
            ),
            _Action(
              'Delivery Challans',
              'Dispatch and challan tracking',
              IconlyBold.document,
              Colors.deepPurple,
              () => Get.to(() => const SellerDeliveryChallanView()),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<_Action> actions) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...actions.map((action) => _actionTile(context, action)),
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context, _Action action) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        onTap: action.onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(action.icon, color: action.color),
        ),
        title: Text(
          action.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(action.subtitle, style: GoogleFonts.inter(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _Action {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _Action(this.title, this.subtitle, this.icon, this.color, this.onTap);
}
