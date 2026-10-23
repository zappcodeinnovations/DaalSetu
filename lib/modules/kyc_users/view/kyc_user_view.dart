import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import '../../admin_catalog/view/admin_drawer.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/kyc_user_controller.dart';
import '../model/kyc_user_model.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import '../../../utils/app_snackbar.dart';

class KycUsersScreen extends StatelessWidget {
  KycUsersScreen({super.key});

  final KycController controller = Get.put(KycController());

  // Colors based on active theme
  Color get bgColor => Get.theme.scaffoldBackgroundColor;
  Color get cardColor => Get.theme.cardColor;
  Color get textDark => Get.theme.textTheme.bodyLarge?.color ?? Colors.black;
  Color get textLight => Get.theme.textTheme.bodySmall?.color ?? Colors.grey;
  
  // Status colors
  Color get colorPending => AppTheme.primaryGold; 
  Color get colorApproved => AppTheme.successGreen; 
  Color get colorRejected => AppTheme.errorRed; 
  Color get colorTotal => AppTheme.secondaryOrange; 

  final Color colorRoleBuyer = const Color(0xFF3B82F6);
  final Color colorRoleTransporter = const Color(0xFFA855F7);
  final Color colorRoleSeller = const Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      drawer: const AdminDrawer(activeKey: 'kyc'),
      appBar: AppBar(leading: const AppBarLeading(), leadingWidth: AppBarLeading.widthFor(context), 
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("KYC Users", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Manage KYC verification and approvals", style: TextStyle(color: textLight, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Get.theme.iconTheme.color),
            onPressed: () => controller.fetchUsers(),
          )
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          _buildSearchAndFilter(context),
          _buildTabs(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator(color: colorTotal));
              }

              final filteredUsers = controller.filteredUsers;

              if (filteredUsers.isEmpty) {
                return Center(child: Text("No users found.", style: TextStyle(color: textLight)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  return _buildUserCard(context, filteredUsers[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Obx(() => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Pending",
                  controller.pendingCount.toString(),
                  "Needs Review",
                  colorPending,
                  Icons.access_time_filled,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Approved",
                  controller.approvedCount.toString(),
                  "Verified Users",
                  colorApproved,
                  Icons.verified_user,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Rejected",
                  controller.rejectedCount.toString(),
                  "Need Attention",
                  colorRejected,
                  Icons.cancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Total Users",
                  controller.totalCount.toString(),
                  "All KYC Users",
                  colorTotal,
                  Icons.people,
                ),
              ),
            ],
          ),
        ],
      )),
    );
  }

  Widget _buildSummaryCard(String title, String count, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: textLight, fontSize: 10),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Obx(() {
        final hasActiveFilter = controller.selectedRole.value != 'all' || controller.selectedFilter.value != 'all';
        final hasSearch = controller.searchQuery.value.isNotEmpty;

        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.searchController,
                onChanged: (val) => controller.searchQuery.value = val,
                style: TextStyle(color: textDark),
                decoration: InputDecoration(
                  hintText: 'Search by name, email, phone, company...',
                  hintStyle: TextStyle(color: textLight, fontSize: 13),
                  prefixIcon: Icon(IconlyLight.search, color: textLight),
                  suffixIcon: hasSearch
                      ? IconButton(
                          icon: Icon(Icons.close, size: 18, color: textLight),
                          onPressed: () => controller.clearSearch(),
                        )
                      : null,
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: textLight.withOpacity(0.2))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: textLight.withOpacity(0.2))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorTotal)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _showFilterBottomSheet(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: hasActiveFilter ? colorTotal.withOpacity(0.12) : cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasActiveFilter ? colorTotal : textLight.withOpacity(0.2),
                    width: hasActiveFilter ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(IconlyLight.filter, color: hasActiveFilter ? colorTotal : textDark, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Filter',
                      style: TextStyle(
                        color: hasActiveFilter ? colorTotal : textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasActiveFilter) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colorTotal,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final tempRole = controller.selectedRole.value.obs;
    final tempStatus = controller.selectedFilter.value.obs;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Obx(() => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(IconlyLight.filter, color: colorTotal, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Filter KYC Users',
                        style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textLight),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'USER ROLE',
                style: TextStyle(color: textLight, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChoiceChip('All Roles', 'all', tempRole.value, (val) => tempRole.value = val),
                  _buildFilterChoiceChip('Buyer', 'buyer', tempRole.value, (val) => tempRole.value = val),
                  _buildFilterChoiceChip('Seller', 'seller', tempRole.value, (val) => tempRole.value = val),
                  _buildFilterChoiceChip('Transporter', 'transporter', tempRole.value, (val) => tempRole.value = val),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'KYC STATUS',
                style: TextStyle(color: textLight, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChoiceChip('All Statuses', 'all', tempStatus.value, (val) => tempStatus.value = val),
                  _buildFilterChoiceChip('Pending', 'pending', tempStatus.value, (val) => tempStatus.value = val, color: colorPending),
                  _buildFilterChoiceChip('Approved', 'approved', tempStatus.value, (val) => tempStatus.value = val, color: colorApproved),
                  _buildFilterChoiceChip('Rejected', 'rejected', tempStatus.value, (val) => tempStatus.value = val, color: colorRejected),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: textLight.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        controller.resetFilters();
                        Navigator.pop(ctx);
                      },
                      child: Text('Reset All', style: TextStyle(color: textLight, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorTotal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        controller.selectedRole.value = tempRole.value;
                        controller.selectedFilter.value = tempStatus.value;
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
      },
    );
  }

  Widget _buildFilterChoiceChip(String label, String value, String selectedValue, Function(String) onSelected, {Color? color}) {
    final isSelected = selectedValue.toLowerCase() == value.toLowerCase();
    final activeColor = color ?? colorTotal;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: activeColor.withOpacity(0.18),
      backgroundColor: bgColor,
      labelStyle: TextStyle(
        color: isSelected ? activeColor : textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? activeColor : textLight.withOpacity(0.2),
        width: isSelected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textLight.withOpacity(0.2)),
      ),
      child: Obx(() => Row(
        children: [
          _buildTabItem("All", "all", null, colorTotal),
          _buildTabItem("Pending", "pending", controller.pendingCount.toString(), colorPending),
          _buildTabItem("Approved", "approved", controller.approvedCount.toString(), colorApproved),
          _buildTabItem("Rejected", "rejected", controller.rejectedCount.toString(), colorRejected),
        ],
      )),
    );
  }

  Widget _buildTabItem(String title, String value, String? count, Color indicatorColor) {
    final isSelected = controller.selectedFilter.value == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? indicatorColor : Colors.transparent, width: 3)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: isSelected ? indicatorColor : textLight, fontWeight: FontWeight.bold, fontSize: 13)),
                if (count != null) ...[
                  const SizedBox(width: 4),
                  Text("($count)", style: TextStyle(color: textLight, fontSize: 11)),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, KycUserModel user) {
    final isPending = user.kycStatus.toLowerCase() == "pending";
    final isApproved = user.kycStatus.toLowerCase() == "approved";
    final isRejected = user.kycStatus.toLowerCase() == "rejected";

    Color statusColor = colorPending;
    if (isApproved) statusColor = colorApproved;
    if (isRejected) statusColor = colorRejected;

    Color roleColor = colorRoleBuyer;
    if (user.role.toLowerCase() == 'transporter') roleColor = colorRoleTransporter;
    if (user.role.toLowerCase() == 'seller') roleColor = colorRoleSeller;

    String initials = user.name.isNotEmpty
        ? (user.name.split(' ').length > 1
            ? '${user.name.split(' ')[0][0]}${user.name.split(' ')[1][0]}'
            : user.name.substring(0, user.name.length >= 2 ? 2 : 1))
            .toUpperCase()
        : "U";

    String submittedStr = user.kycSubmittedAt != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(user.kycSubmittedAt!))
        : "-";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textLight.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name/Role, Status Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFF78350F), // Dark orange/amber
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name & Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: roleColor.withOpacity(0.3), width: 0.8),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isApproved ? Icons.check_circle : (isRejected ? Icons.cancel : Icons.access_time_filled),
                        color: statusColor,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        user.kycStatus.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contact & Entity Details (Full Width to avoid any squeezing/overflow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: textLight.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: textLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.email.isNotEmpty ? user.email : "No Email Provided",
                          style: TextStyle(color: user.email.isNotEmpty ? textDark : textLight, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.phone_outlined, size: 14, color: textLight),
                      const SizedBox(width: 6),
                      Text(
                        "+91 ${user.mobile}",
                        style: TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.storefront_outlined, size: 14, color: textLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (user.branchName != null && user.branchName!.trim().isNotEmpty)
                              ? user.branchName!
                              : "Branch: General",
                          style: TextStyle(color: textDark, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.business_outlined, size: 14, color: textLight),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (user.companyName != null && user.companyName!.trim().isNotEmpty)
                              ? user.companyName!
                              : "Company: Individual",
                          style: TextStyle(color: textDark, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          Divider(color: textLight.withOpacity(0.15), height: 1),
          
          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("KYC Score", style: TextStyle(color: textLight, fontSize: 11)),
                      const SizedBox(width: 8),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              value: user.kycScore / 100,
                              color: colorApproved,
                              backgroundColor: colorApproved.withOpacity(0.2),
                              strokeWidth: 3,
                            ),
                          ),
                          Text(
                            "${user.kycScore}%",
                            style: TextStyle(color: textDark, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: textLight.withOpacity(0.2)),
                Expanded(
                  child: Column(
                    children: [
                      Text("Role", style: TextStyle(color: textLight, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        user.role.toUpperCase(),
                        style: TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: textLight.withOpacity(0.2)),
                Expanded(
                  child: Column(
                    children: [
                      Text("Submitted", style: TextStyle(color: textLight, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        submittedStr,
                        style: TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(color: textLight.withOpacity(0.15), height: 1),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _buildActionButton(IconlyLight.show, "View", colorTotal, () => _showViewDialog(context, user))),
                if (!isApproved) ...[
                  const SizedBox(width: 6),
                  Expanded(child: _buildActionButton(IconlyLight.tick_square, "Approve", colorApproved, () => _confirmApprove(user))),
                ],
                if (isPending || isRejected) ...[
                  const SizedBox(width: 6),
                  Expanded(child: _buildActionButton(IconlyLight.close_square, "Reject", colorRejected, () => _showRejectDialog(context, user.id))),
                ],
                const SizedBox(width: 6),
                Expanded(child: _buildActionButton(IconlyLight.time_circle, "History", colorRoleTransporter, () => _showHistoryDialog(context, user))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.05),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showViewDialog(BuildContext context, KycUserModel user) {
    String formatTimestamp(String? iso) {
      if (iso == null || iso.trim().isEmpty) return "N/A";
      try {
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(iso).toLocal());
      } catch (_) {
        return iso;
      }
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("User Details", style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow("Name", user.name),
                _detailRow("Email", user.email.isNotEmpty ? user.email : "N/A"),
                _detailRow("Mobile", user.mobile.isNotEmpty ? user.mobile : "N/A"),
                _detailRow("Role", user.role.isNotEmpty ? user.role : "N/A"),
                _detailRow("First Name", (user.firstName != null && user.firstName!.isNotEmpty) ? user.firstName! : "N/A"),
                _detailRow("Last Name", (user.lastName != null && user.lastName!.isNotEmpty) ? user.lastName! : "N/A"),
                _detailRow("PAN Number", user.panNumber != null && user.panNumber!.isNotEmpty ? user.panNumber! : "N/A"),
                _detailRow("GST Number", user.gstNumber != null && user.gstNumber!.isNotEmpty ? user.gstNumber! : "N/A"),
                _detailRow("Account Status", user.accountStatus.isNotEmpty ? user.accountStatus : "active"),
                _detailRow("KYC Status", user.kycStatus.isNotEmpty ? user.kycStatus : "pending"),
                _detailRow("Submitted At", formatTimestamp(user.kycSubmittedAt)),
                _detailRow("Approved At", formatTimestamp(user.kycApprovedAt)),
                _detailRow("Rejected At", formatTimestamp(user.kycRejectedAt)),
                _detailRow("Rejection Reason", (user.kycRejectionReason != null && user.kycRejectionReason!.isNotEmpty) ? user.kycRejectionReason! : "N/A"),
                _detailRow("Date Joined", formatTimestamp(user.dateJoined)),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTotal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Close",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: textLight, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, KycUserModel user) {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("KYC History", style: TextStyle(color: textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Submitted At", user.kycSubmittedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(user.kycSubmittedAt!).toLocal()) : "N/A"),
            if (user.kycApprovedAt != null)
              _detailRow("Approved At", DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(user.kycApprovedAt!).toLocal())),
            if (user.kycRejectedAt != null)
              _detailRow("Rejected At", DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(user.kycRejectedAt!).toLocal())),
            if (user.kycRejectionReason != null && user.kycRejectionReason!.isNotEmpty)
              _detailRow("Reject Reason", user.kycRejectionReason!),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTotal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Close",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      )
    );
  }

  void _confirmApprove(KycUserModel user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Approve KYC'),
        content: Text('Approve KYC for ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Get.back();
              controller.approve(user.id);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, int userId) {
    final TextEditingController reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(IconlyLight.danger, color: colorRejected),
            const SizedBox(width: 8),
            Text("Reject KYC", style: TextStyle(color: textDark)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: TextStyle(color: textDark),
              decoration: InputDecoration(
                hintText: "Enter rejection reason",
                hintStyle: TextStyle(color: textLight),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel", style: TextStyle(color: textLight))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorRejected, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                AppSnackbar.snackbar("Error", "Please enter rejection reason", backgroundColor: colorRejected, colorText: Colors.white);
                return;
              }
              Get.back(); // close dialog
              controller.reject(userId, reason);
            },
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
