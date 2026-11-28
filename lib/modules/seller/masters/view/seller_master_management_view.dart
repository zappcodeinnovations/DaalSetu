import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_master_controller.dart';
import 'seller_add_brand_dialog.dart';
import 'seller_add_tag_dialog.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class SellerMasterManagementView extends StatelessWidget {
  const SellerMasterManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerMasterController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFFFFB300);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: HeroHeader(
          title: "Master Data",
          subtitle: "Registered brands & commodity quality tags",
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => goBackOrHome(context),
          ),
          trailing: IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: controller.fetchAllMasters,
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: "Brands"),
              Tab(text: "Quality Tags"),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          return TabBarView(
            children: [
              // 1. BRANDS TAB
              RefreshIndicator(
                onRefresh: controller.fetchAllMasters,
                color: primaryColor,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text("Registered Brands", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (controller.brandsList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text("No brands found in master list", style: TextStyle(color: Colors.grey))),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: controller.brandsList.length,
                        itemBuilder: (context, index) {
                          final brand = controller.brandsList[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Get.bottomSheet(
                                  Container(
                                    color: theme.cardColor,
                                    child: SafeArea(
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            leading: const Icon(IconlyLight.edit),
                                            title: const Text("Edit Brand"),
                                            onTap: () {
                                              Get.back();
                                              controller.editBrand(brand);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(IconlyLight.delete, color: Colors.red),
                                            title: const Text("Delete Brand", style: TextStyle(color: Colors.red)),
                                            onTap: () {
                                              Get.back();
                                              controller.deleteBrand(brand);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: primaryColor.withValues(alpha: 0.15),
                                        child: Text(
                                          (brand.name != null && brand.name!.isNotEmpty) ? brand.name![0].toUpperCase() : "B",
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              brand.name ?? 'Brand',
                                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (brand.status != 'active')
                                              Text(
                                                brand.status == 'pending'
                                                    ? 'Pending approval'
                                                    : brand.status[0].toUpperCase() + brand.status.substring(1),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: brand.status == 'pending' ? Colors.orange : Colors.red,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              // 2. QUALITY TAGS TAB
              RefreshIndicator(
                onRefresh: controller.fetchAllMasters,
                color: primaryColor,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text("Quality Tags Master", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (controller.tagsList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text("No quality tags found", style: TextStyle(color: Colors.grey))),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.tagsList.map((tag) {
                          return ActionChip(
                            backgroundColor: isDark
                                ? const Color(0xFF282828)
                                : primaryColor.withValues(alpha: 0.12),
                            side: BorderSide(
                              color: primaryColor.withValues(alpha: 0.35),
                            ),
                            avatar: const Icon(IconlyBold.discount, size: 14, color: primaryColor),
                            label: Text(
                              tag.name ?? 'Tag',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100),
                                fontSize: 12,
                              ),
                            ),
                            // Admin tags are for every seller of the branch: used, not changed here.
                            onPressed: () => !tag.canEdit
                                ? Get.snackbar('Admin tag', 'You can use this tag on offers; only the admin can change it.')
                                : Get.bottomSheet(
                              Container(
                                color: theme.cardColor,
                                child: SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(IconlyLight.edit),
                                        title: const Text("Edit Quality Tag"),
                                        onTap: () {
                                          Get.back();
                                          controller.editTag(tag);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(IconlyLight.delete, color: Colors.red),
                                        title: const Text("Delete Quality Tag", style: TextStyle(color: Colors.red)),
                                        onTap: () {
                                          Get.back();
                                          controller.deleteTag(tag);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          );
        }),
        // Adds to whichever tab is open; a seller brand is live at once (MoM point 26).
        floatingActionButton: Builder(
          builder: (tabContext) => Container(
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              heroTag: null,
              elevation: 0,
              highlightElevation: 0,
              backgroundColor: Colors.transparent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text("Add", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                final isBrandTab = DefaultTabController.of(tabContext).index == 0;
                Get.dialog(isBrandTab ? const SellerAddBrandDialog() : const SellerAddTagDialog());
              },
            ),
          ),
        ),
      ),
    );
  }
}
