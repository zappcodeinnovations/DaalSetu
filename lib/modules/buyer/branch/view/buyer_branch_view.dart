import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/buyer_branch_controller.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';

class BuyerBranchView extends StatefulWidget {
  const BuyerBranchView({super.key});

  @override
  State<BuyerBranchView> createState() => _BuyerBranchViewState();
}

class _BuyerBranchViewState extends State<BuyerBranchView> with WidgetsBindingObserver {
  late final BuyerBranchController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.isRegistered<BuyerBranchController>()
        ? Get.find<BuyerBranchController>()
        : Get.put(BuyerBranchController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchBranches(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.fetchBranches(silent: true);
    }
  }

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
          IconButton(
            onPressed: () => _showRequestBranchDialog(context),
            icon: Icon(IconlyLight.password, color: primaryColor),
            tooltip: "Enter Ref Code",
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
                    color: primaryColor.withValues(alpha: 0.5),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                          color: primaryColor.withValues(alpha: 0.12),
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
                const SizedBox(height: 20),

                // Search & Filter Card matching Buyer web panel
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Search",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(IconlyLight.search, size: 18, color: Colors.grey),
                            ),
                            Expanded(
                              child: TextField(
                                controller: controller.searchTextController,
                                onChanged: (val) => controller.setSearchQuery(val),
                                onSubmitted: (_) => controller.applyFilter(),
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: "Branch code, location, city, area, admin, user",
                                  hintStyle: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                              ),
                            ),
                            if (controller.searchQuery.value.isNotEmpty || controller.searchTextController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                onPressed: () {
                                  controller.searchTextController.clear();
                                  controller.setSearchQuery('');
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                controller.applyFilter();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: Text(
                                "Apply",
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                controller.resetFilter();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.textTheme.bodyMedium?.color,
                                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                "Reset",
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(context, label: "All", value: "all"),
                            const SizedBox(width: 8),
                            _buildFilterChip(context, label: "Primary", value: "primary"),
                            const SizedBox(width: 8),
                            _buildFilterChip(context, label: "Additional", value: "additional"),
                            const SizedBox(width: 8),
                            _buildFilterChip(context, label: "Pending", value: "pending"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Empty search result notice if active
                if (controller.isFilterActive && !controller.hasFilteredResults) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconlyLight.search,
                            size: 52,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No Branches Found",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            controller.searchQuery.value.isNotEmpty
                                ? "No branch matches \"${controller.searchQuery.value}\""
                                : "No branches found for selected type filter",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: controller.resetFilter,
                            child: const Text("Reset Filter"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Primary Branch
                if (controller.filteredPrimaryBranch != null) ...[
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
                              controller.filteredPrimaryBranch!.locationName ?? 'Primary Branch',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            _buildBranchTypeBadge(isPrimary: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Branch Code: ${controller.filteredPrimaryBranch!.branchCode ?? 'N/A'}",
                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          "Location: ${controller.filteredPrimaryBranch!.city ?? ''}, ${controller.filteredPrimaryBranch!.state ?? ''}",
                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Pending Requests
                if (controller.filteredPendingRequests.isNotEmpty) ...[
                  Text(
                    "Pending Join Requests",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: controller.filteredPendingRequests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final req = controller.filteredPendingRequests[index];
                      return GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.12),
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
                                onPressed: () => controller.cancelRequest(
                                  req.id!,
                                  branchId: req.branchId,
                                  branchCode: req.branchCode,
                                ),
                                child: const Text("CANCEL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // My Branches List
                if (controller.filteredMyBranches.isNotEmpty) ...[
                  Text(
                    "My Branches",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: controller.filteredMyBranches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final branch = controller.filteredMyBranches[index];
                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(IconlyLight.location, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        branch.locationName ?? "Branch",
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      _buildBranchTypeBadge(isPrimary: branch.isPrimary == true),
                                    ],
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
                            if (branch.id != null && branch.isPrimary != true) ...[
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _showLeaveBranchDialog(
                                  context,
                                  branch.id!,
                                  branchCode: branch.branchCode,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                child: const Text("LEAVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ],
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
          child: SingleChildScrollView(
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
                  const SizedBox(height: 20),
                  GlassTextField(
                    controller: codeCtrl,
                    hintText: "Branch Code (e.g. NAG622M)",
                    prefixIcon: IconlyLight.password,
                  ),
                  const SizedBox(height: 20),
                  Obx(() => GlassButton(
                    isLoading: isSubmitting.value,
                    onPressed: () async {
                      if (codeCtrl.text.trim().isEmpty) {
                        AppSnackbar.showWarning(title: 'Required', message: 'Please enter a branch code');
                        return;
                      }
                      isSubmitting.value = true;
                      Navigator.of(dialogContext).pop(); // close dialog cleanly
                      await controller.joinBranchByCode(codeCtrl.text.trim());
                      isSubmitting.value = false;
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
          ),
        );
      },
    );
  }

  void _showLeaveBranchDialog(BuildContext context, int branchId, {String? branchCode}) {
    Get.defaultDialog(
      title: "Leave Branch",
      middleText: "Are you sure you want to leave this branch?",
      textConfirm: "YES, LEAVE",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        controller.leaveBranch(branchId, branchCode: branchCode);
      },
      textCancel: "CANCEL",
    );
  }

  Widget _buildFilterChip(BuildContext context, {required String label, required String value}) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isSelected = controller.selectedTypeFilter.value == value;

    return InkWell(
      onTap: () => controller.setTypeFilter(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.15) : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primaryColor : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildBranchTypeBadge({required bool isPrimary}) {
    final color = isPrimary ? Colors.blue : Colors.green;
    final label = isPrimary ? "Primary" : "Additional";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
