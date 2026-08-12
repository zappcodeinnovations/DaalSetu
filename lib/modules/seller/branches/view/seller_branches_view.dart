import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_branch_controller.dart';
import 'seller_join_branch_dialog.dart';
import 'seller_create_branch_dialog.dart';

class SellerBranchesView extends StatelessWidget {
  const SellerBranchesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerBranchController());
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Company Branches Network",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.plus, color: primaryColor),
            onPressed: () => Get.dialog(const SellerCreateBranchDialog()),
            tooltip: "Create Branch",
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        return RefreshIndicator(
          onRefresh: controller.fetchBranches,
          color: primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Join Branch Banner
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: primaryColor.withValues(alpha: 0.12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: primaryColor,
                          child: Icon(IconlyBold.work, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Join Existing Branch", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text("Connect via branch code", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Get.dialog(const SellerJoinBranchDialog()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("JOIN CODE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Primary Branch
                if (controller.primaryBranch.value != null) ...[
                  Text("Primary Branch", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                controller.primaryBranch.value!.locationName ?? 'Primary Branch',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(20)),
                                child: Text("PRIMARY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text("Branch Code: ${controller.primaryBranch.value!.branchCode ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          Text("Location: ${controller.primaryBranch.value!.city ?? ''}, ${controller.primaryBranch.value!.state ?? ''}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Pending Requests
                if (controller.pendingRequests.isNotEmpty) ...[
                  Text("Pending Join Requests", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.pendingRequests.length,
                    itemBuilder: (context, index) {
                      final req = controller.pendingRequests[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(req.locationName ?? "Branch Request", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Code: ${req.branchCode ?? 'N/A'} • Status: Pending Approval"),
                          trailing: TextButton(
                            onPressed: () => controller.cancelRequest(req.id!),
                            child: const Text("CANCEL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // My Branches List
                Text("My Warehouse Network", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                if (controller.myBranches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text("No secondary warehouse branches found", style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.myBranches.length,
                    itemBuilder: (context, index) {
                      final b = controller.myBranches[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(b.locationName ?? "Warehouse Branch", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Code: ${b.branchCode ?? 'N/A'} • ${b.city ?? ''}, ${b.state ?? ''}"),
                          trailing: IconButton(
                            icon: const Icon(IconlyLight.logout, color: Colors.red, size: 20),
                            onPressed: () => controller.leaveBranch(b.id!),
                            tooltip: "Leave Branch",
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
