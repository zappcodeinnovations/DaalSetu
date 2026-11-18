import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import 'buyer_my_interests_view.dart';
import 'buyer_request_management_view.dart';
import 'add_buyer_offer_view.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class BuyerActivityView extends StatelessWidget {
  final int initialIndex;

  const BuyerActivityView({
    super.key,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final fabBottom = isKeyboardOpen ? 0.0 : mediaQuery.padding.bottom;

    return DefaultTabController(
      length: 2,
      initialIndex: (initialIndex >= 0 && initialIndex < 2) ? initialIndex : 0,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: HeroHeader(
          leading: AppBarLeading(
            child: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(
                      IconlyLight.arrow_left_2,
                      color: Colors.white,
                    ),
                    onPressed: () => Get.back(),
                  )
                : null,
          ),
          title: "My Activity",
          bottom: const TabBar(
            tabs: [
              Tab(text: "My Interests"),
              Tab(text: "My Requirements"),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: fabBottom),
          child: FloatingActionButton.extended(
            key: const Key('buyer_activity_post_requirement_fab'),
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
            BuyerRequestManagementView(mode: BuyerRequestMode.requirements, wrapInScaffold: false),
          ],
        ),
      ),
    );
  }
}
