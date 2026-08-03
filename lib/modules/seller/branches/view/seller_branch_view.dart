import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_branch_controller.dart';
import '../model/seller_branch_model.dart';
import 'dart:ui';

class SellerBranchView extends StatelessWidget {
  const SellerBranchView({super.key});

  static const Color primaryColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerBranchController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "My Branches",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => _showJoinBranchDialog(context),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                "Join Branch",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchBranches,
        color: primaryColor,
        child: Obx(() {
          if (controller.isLoading.value && controller.branchData.value == null) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final data = controller.branchData.value;
          if (data == null) return const Center(child: Text("No Data Found"));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (data.primaryBranch != null) ...[
                _sectionTitle(context, "Primary Branch"),
                _buildBranchCard(context, data.primaryBranch!, isPrimary: true),
                const SizedBox(height: 24),
              ],
              if (data.otherBranches.isNotEmpty) ...[
                _sectionTitle(context, "Active Branches"),
                ...data.otherBranches.map((b) => _buildBranchCard(context, b)),
                const SizedBox(height: 24),
              ],
              if (data.pendingRequests.isNotEmpty) ...[
                _sectionTitle(context, "Pending Requests"),
                ...data.pendingRequests.map((r) => _buildRequestCard(context, r)),
              ],
              if (data.primaryBranch == null && data.otherBranches.isEmpty && data.pendingRequests.isEmpty)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(IconlyLight.location, size: 64, color: theme.disabledColor),
                        const SizedBox(height: 16),
                        Text("Not associated with any branches", style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBranchCard(BuildContext context, SellerBranch branch, {bool isPrimary = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = Get.find<SellerBranchController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  branch.branchName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "PRIMARY",
                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text("Code: ${branch.branchCode}", style: theme.textTheme.bodySmall),
          const Divider(height: 24),
          _infoRow(
            IconlyLight.location,
            branch.area != null && branch.area!.isNotEmpty ? "${branch.area}, ${branch.city}" : branch.city,
            theme,
          ),
          _infoRow(IconlyLight.discovery, branch.state, theme),
          if (!isPrimary) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showLeaveConfirm(context, branch),
                icon: const Icon(IconlyLight.logout, size: 16, color: Colors.red),
                label: const Text("Leave Branch", style: TextStyle(color: Colors.red)),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, BranchRequest request) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = Get.find<SellerBranchController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request.branchName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("Code: ${request.branchCode}", style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Requested on: ${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}",
                style: theme.textTheme.bodySmall,
              ),
              TextButton(
                onPressed: () => controller.cancelRequest(request.id),
                child: const Text("Cancel", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinBranchDialog(BuildContext context) {
    final controller = Get.find<SellerBranchController>();
    controller.branchCodeController.clear();

    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Theme.of(context).cardColor.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Join New Branch", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: controller.branchCodeController,
                  decoration: InputDecoration(
                    hintText: "Enter Branch Code",
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(IconlyLight.ticket),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: controller.joinBranch,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text("REQUEST", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLeaveConfirm(BuildContext context, SellerBranch branch) {
    Get.defaultDialog(
      title: "Leave Branch",
      middleText: "Are you sure you want to leave ${branch.branchName}?",
      textConfirm: "LEAVE",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        Get.find<SellerBranchController>().leaveBranch(branch.id);
      },
      textCancel: "CANCEL",
    );
  }
}
