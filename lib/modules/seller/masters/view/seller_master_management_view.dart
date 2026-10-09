import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_master_controller.dart';
import 'seller_add_brand_dialog.dart';
import 'seller_add_tag_dialog.dart';

class SellerMasterManagementView extends StatelessWidget {
  const SellerMasterManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerMasterController());
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFFB300);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Master Data Management",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
          ),
          bottom: TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
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
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text("Registered Brands", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
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
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
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
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: primaryColor.withValues(alpha: 0.15),
                                      child: Text(
                                        (brand.name != null && brand.name!.isNotEmpty) ? brand.name![0].toUpperCase() : "B",
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        brand.name ?? 'Brand',
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text("Quality Tags Master", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
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
                            backgroundColor: primaryColor.withValues(alpha: 0.15),
                            avatar: const Icon(IconlyBold.discount, size: 14, color: primaryColor),
                            label: Text(tag.name ?? 'Tag', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12)),
                            onPressed: () => Get.bottomSheet(
                              Container(
                                color: theme.cardColor,
                                child: SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(IconlyLight.edit),
                                        title: const Text("Edit Tag"),
                                        onTap: () {
                                          Get.back();
                                          controller.editTag(tag);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(IconlyLight.delete, color: Colors.red),
                                        title: const Text("Delete Tag", style: TextStyle(color: Colors.red)),
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
        // Adds to whichever tab is open; seller brands go to admin for approval.
        floatingActionButton: Builder(
          builder: (tabContext) => FloatingActionButton.extended(
            heroTag: null,
            backgroundColor: primaryColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              final isBrandTab = DefaultTabController.of(tabContext).index == 0;
              Get.dialog(isBrandTab ? const SellerAddBrandDialog() : const SellerAddTagDialog());
            },
          ),
        ),
      ),
    );
  }
}
