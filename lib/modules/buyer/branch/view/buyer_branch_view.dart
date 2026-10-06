import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/buyer_branch_controller.dart';
import '../../../../theme/glass_widgets.dart';

class BuyerBranchView extends StatelessWidget {
  BuyerBranchView({super.key});

  final BuyerBranchController controller = Get.put(BuyerBranchController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Branches Network",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showRequestBranchDialog(context),
            icon: Icon(IconlyLight.password, color: primaryColor, size: 18),
            label: Text(
              "Enter Ref Code",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.primaryBranch.value == null &&
            controller.myBranches.isEmpty &&
            controller.pendingRequests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasNoData = controller.primaryBranch.value == null &&
            controller.myBranches.isEmpty &&
            controller.pendingRequests.isEmpty;

        if (hasNoData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    IconlyLight.location,
                    size: 70,
                    color: primaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No Branches Found",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap 'Enter Ref Code' to join a branch using your reference code.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showRequestBranchDialog(context),
                    icon: const Icon(IconlyLight.password),
                    label: const Text("Enter Ref Code"),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchBranches,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Join Branch Quick Action Card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(IconlyBold.work, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Join Branch",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              "Connect via branch code",
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showRequestBranchDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("JOIN CODE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Primary Branch
                if (controller.primaryBranch.value != null) ...[
                  Text(
                    "Primary Branch",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  GlassCard(
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
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "PRIMARY",
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Branch Code: ${controller.primaryBranch.value!.branchCode ?? 'N/A'}",
                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          "Location: ${controller.primaryBranch.value!.city ?? ''}, ${controller.primaryBranch.value!.state ?? ''}",
                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Pending Requests
                if (controller.pendingRequests.isNotEmpty) ...[
                  Text(
                    "Pending Join Requests",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.pendingRequests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final req = controller.pendingRequests[index];
                      return GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(IconlyLight.time_circle, color: Colors.orange, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    req.locationName ?? "Branch Request",
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    "Code: ${req.branchCode ?? 'N/A'} • Pending Approval",
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            if (req.id != null)
                              TextButton(
                                onPressed: () => controller.cancelRequest(req.id!),
                                child: const Text("CANCEL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // My Branches List
                if (controller.myBranches.isNotEmpty) ...[
                  Text(
                    "My Branches",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.myBranches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final branch = controller.myBranches[index];
                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(IconlyLight.location, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    branch.locationName ?? "Branch",
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${branch.city ?? ''}, ${branch.state ?? ''}",
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                  ),
                                  if (branch.branchCode != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      "Code: ${branch.branchCode}",
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (branch.id != null)
                              OutlinedButton(
                                onPressed: () => _showLeaveBranchDialog(context, branch.id!),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                child: const Text("LEAVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showRequestBranchDialog(BuildContext context) {
    final TextEditingController codeCtrl = TextEditingController();
    final isSubmitting = false.obs;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GlassIconBox(
                    icon: IconlyLight.document,
                    size: 56,
                    iconSize: 28,
                    color: Theme.of(dialogContext).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Request Branch",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter the reference code to request branch access from the Super Admin.",
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GlassTextField(
                  controller: codeCtrl,
                  hintText: "Branch Code (e.g. NAG622M)",
                  prefixIcon: IconlyLight.password,
                ),
                const SizedBox(height: 24),
                Obx(() => GlassButton(
                  isLoading: isSubmitting.value,
                  onPressed: () async {
                    if (codeCtrl.text.trim().isEmpty) {
                      Get.snackbar('Required', 'Please enter a branch code', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    isSubmitting.value = true;
                    final success = await controller.joinBranchByCode(codeCtrl.text.trim());
                    isSubmitting.value = false;
                    if (success) {
                      Get.back(); // close dialog
                    }
                  },
                  child: Text(
                    "Submit Request",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLeaveBranchDialog(BuildContext context, int branchId) {
    Get.defaultDialog(
      title: "Leave Branch",
      middleText: "Are you sure you want to leave this branch?",
      textConfirm: "YES, LEAVE",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        controller.leaveBranch(branchId);
      },
      textCancel: "CANCEL",
    );
  }
}
