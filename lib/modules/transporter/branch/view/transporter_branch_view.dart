import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/transporter_branch_controller.dart';
import '../../../../theme/glass_widgets.dart';

class TransporterBranchView extends StatelessWidget {
  TransporterBranchView({super.key});

  final TransporterBranchController controller = Get.put(TransporterBranchController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Branches",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton.extended(
          onPressed: () => _showRequestBranchDialog(context),
          icon: const Icon(IconlyLight.message),
          label: const Text("Enter Ref Code"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.branches.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.branches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Builder(
                  builder: (context) => Icon(
                    IconlyLight.location, 
                    size: 80, 
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5)
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No branches found",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tap 'Enter Ref Code' to request access to a branch.",
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchBranches(),
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
            itemCount: controller.branches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final branch = controller.branches[index];
              return GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(IconlyLight.location, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch.locationName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${branch.area}, ${branch.city}, ${branch.state}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (branch.branchCode != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              "Code: ${branch.branchCode}",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: branch.isActive 
                            ? Colors.green.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        branch.isActive ? "ACTIVE" : "PENDING",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: branch.isActive ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
                    final success = await controller.requestBranchByCode(codeCtrl.text);
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
      }
    );
  }
}
