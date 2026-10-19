import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import 'buyer_my_interests_view.dart';
import 'buyer_request_management_view.dart';
import 'add_buyer_offer_view.dart';
import 'package:daalsetu/widgets/app_shell.dart';

class BuyerActivityView extends StatelessWidget {
  final int initialIndex;

  const BuyerActivityView({
    super.key,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      initialIndex: (initialIndex >= 0 && initialIndex < 2) ? initialIndex : 0,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: AppBarLeading(child: Navigator.canPop(context)
              ? IconButton(
                  icon: Icon(
                    IconlyLight.arrow_left_2,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  onPressed: () => Get.back(),
                )
              : null), leadingWidth: AppBarLeading.widthFor(context, hasChild: true),
          title: Text(
            "My Activity",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "My Interests"),
              Tab(text: "My Requirements"),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 76.0),
          child: FloatingActionButton.extended(
            heroTag: 'buyer_activity_post_requirement_fab',
            onPressed: () => Get.to(() => const AddBuyerOfferScreen()),
            icon: const Icon(IconlyLight.plus, color: Colors.white),
            label: Text(
              "Post Requirement",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            backgroundColor: theme.colorScheme.primary,
            elevation: 4,
          ),
        ),
        body: const TabBarView(
          children: [
            BuyerMyInterestsView(showAppBar: false),
            BuyerRequestManagementView(mode: BuyerRequestMode.requirements),
          ],
        ),
      ),
    );
  }
}
