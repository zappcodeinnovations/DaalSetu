import 'package:daalsetu/widgets/confirm_actions.dart';
import 'package:daalsetu/widgets/page_auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_branch_controller.dart';
import 'seller_join_branch_dialog.dart';
import '../../../../services/seller_services.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class SellerBranchesView extends StatelessWidget {
  const SellerBranchesView({super.key});

  /// Lists every active branch; joining reuses the request-by-code API.
  void _showBranchDirectory(SellerBranchController controller) {
    final joinedCodes = {
      ...controller.myBranches.map((b) => b.branchCode),
      ...controller.pendingRequests.map((b) => b.branchCode),
      controller.primaryBranch.value?.branchCode,
    }.whereType<String>().toSet();

    Get.bottomSheet(
      Container(
        height: Get.height * 0.75,
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: SellerServices.getPublicBranches(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFFB300)));
            }
            final branches = snapshot.data ?? [];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text("All Branches", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Expanded(
                  child: branches.isEmpty
                      ? const Center(child: Text("No branches found"))
                      : ListView.builder(
                          itemCount: branches.length,
                          itemBuilder: (context, index) {
                            final b = branches[index];
                            final code = b['branch_code']?.toString() ?? '';
                            final joined = joinedCodes.contains(code);
                            return ListTile(
                              leading: const Icon(IconlyLight.location),
                              title: Text(b['location_name']?.toString() ?? code),
                              subtitle: Text("$code • ${b['city'] ?? ''}, ${b['state'] ?? ''}"),
                              trailing: joined
                                  ? const Text("JOINED / REQUESTED", style: TextStyle(fontSize: 10, color: Colors.grey))
                                  : TextButton(
                                      onPressed: code.isEmpty
                                          ? null
                                          : () {
                                              Get.back();
                                              controller.joinBranchByCode(code);
                                            },
                                      child: const Text("REQUEST"),
                                    ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) => PageAutoRefresh(
    onRefresh: () => Get.find<SellerBranchController>().fetchBranches(silent: true),
    child: _buildPageContent(context),
  );

  Widget _buildPageContent(BuildContext context) {
    final controller = Get.put(SellerBranchController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "My Branches",
        subtitle: "Warehouse branches & network directory",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        trailing: IconButton(
          icon: const Icon(IconlyLight.search, color: Colors.white),
          onPressed: () => _showBranchDirectory(controller),
          tooltip: "Browse Branches",
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Join Branch Banner
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF2C2416), const Color(0xFF1E1E1E)]
                          : [const Color(0xFFFFF8E1), const Color(0xFFFFF3E0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(IconlyBold.work, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Join Existing Branch",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: theme.textTheme.titleMedium?.color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text("Connect via branch code", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Container(
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => Get.dialog(const SellerJoinBranchDialog()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            child: const Text("JOIN CODE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Primary Branch
                if (controller.primaryBranch.value != null) ...[
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
                      Text("Primary Branch", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  controller.primaryBranch.value!.locationName ?? 'Primary Branch',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.textTheme.titleMedium?.color,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1976D2).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  "PRIMARY",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.tag_rounded, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text("Branch Code: ", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              Text(
                                controller.primaryBranch.value!.branchCode ?? 'N/A',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Location: ${controller.primaryBranch.value!.city ?? ''}, ${controller.primaryBranch.value!.state ?? ''}",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Pending Requests
                if (controller.pendingRequests.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("Pending Join Requests", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.pendingRequests.length,
                    itemBuilder: (context, index) {
                      final req = controller.pendingRequests[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                          ),
                        ),
                        child: ListTile(
                          title: Text(req.locationName ?? "Branch Request", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text("Code: ${req.branchCode ?? 'N/A'} • Status: Pending Approval", style: const TextStyle(fontSize: 12)),
                          trailing: TextButton(
                            onPressed: () => controller.cancelRequest(req.branchId ?? req.id!),
                            child: const Text("CANCEL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // My Branches List
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
                    Text("My Warehouse Network", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                          ),
                        ),
                        child: ListTile(
                          title: Text(b.locationName ?? "Warehouse Branch", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text("Code: ${b.branchCode ?? 'N/A'} • ${b.city ?? ''}, ${b.state ?? ''}", style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (b.isPrimary != true)
                                IconButton(
                                  icon: const Icon(IconlyLight.star, color: Color(0xFFE65100), size: 20),
                                  onPressed: () => Get.defaultDialog(
                                    title: "Make Primary",
                                    middleText: "Make ${b.branchCode ?? 'this branch'} your primary branch?",
                                    actions: confirmActions(
                                      confirmText: "YES",
                                      onConfirm: () {
                                      Get.back();
                                      controller.makePrimaryBranch(b.branchId ?? b.id!);
                                    },
                                      cancelText: "CANCEL",
                                    ),
                                  ),
                                  tooltip: "Make Primary",
                                ),
                              IconButton(
                                icon: const Icon(IconlyLight.logout, color: Colors.red, size: 20),
                                onPressed: () => controller.leaveBranch(b.id!),
                                tooltip: "Leave Branch",
                              ),
                            ],
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
