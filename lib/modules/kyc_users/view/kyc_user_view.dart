import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import '../../admin_catalog/view/admin_drawer.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/kyc_user_controller.dart';
import '../model/kyc_user_model.dart';
import 'package:agro_broker/theme/app_theme.dart';

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
      appBar: AppBar(
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
          _buildSearchAndFilter(),
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
      padding: const EdgeInsets.all(16.0),
      child: Obx(() => Row(
        children: [
          Expanded(child: _buildSummaryCard("Pending", controller.pendingCount.toString(), "Needs Review", colorPending, Icons.access_time_filled)),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard("Approved", controller.approvedCount.toString(), "Verified Users", colorApproved, Icons.verified_user)),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard("Rejected", controller.rejectedCount.toString(), "Need Attention", colorRejected, Icons.cancel)),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard("Total Users", controller.totalCount.toString(), "All KYC Users", colorTotal, Icons.people)),
        ],
      )),
    );
  }

  Widget _buildSummaryCard(String title, String count, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(count, style: TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: textLight, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => controller.searchQuery.value = val,
              style: TextStyle(color: textDark),
              decoration: InputDecoration(
                hintText: 'Search by name, email, phone, company...',
                hintStyle: TextStyle(color: textLight, fontSize: 13),
                prefixIcon: Icon(IconlyLight.search, color: textLight),
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: textLight.withOpacity(0.2))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: textLight.withOpacity(0.2))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorTotal)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textLight.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(IconlyLight.filter, color: textDark, size: 18),
                const SizedBox(width: 8),
                Text('Filter', style: TextStyle(color: textDark, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Container(width: 6, height: 6, decoration: BoxDecoration(color: colorPending, shape: BoxShape.circle)),
              ],
            ),
          )
        ],
      ),
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

    String initials = user.name.isNotEmpty ? (user.name.split(' ').length > 1 ? '${user.name.split(' ')[0][0]}${user.name.split(' ')[1][0]}' : user.name.substring(0, 2)).toUpperCase() : "U";

    String submittedStr = user.kycSubmittedAt != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(user.kycSubmittedAt!)) : "-";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textLight.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF78350F), // Dark orange/brown
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: roleColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text(user.role.toUpperCase(), style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      Text(user.email.isEmpty ? "No Email" : user.email, style: TextStyle(color: textLight, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: textLight),
                          const SizedBox(width: 4),
                          Text("+91 ${user.mobile}", style: TextStyle(color: textLight, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.business, size: 12, color: textLight),
                          const SizedBox(width: 4),
                          Text(user.branchName ?? "Not Available", style: TextStyle(color: textLight, fontSize: 12)),
                          const SizedBox(width: 12),
                          Icon(Icons.work, size: 12, color: textLight),
                          const SizedBox(width: 4),
                          Expanded(child: Text(user.companyName ?? "Not Available", style: TextStyle(color: textLight, fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ],
                      )
                    ],
                  ),
                ),
                // Right side: Status and Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withOpacity(0.3))),
                      child: Row(
                        children: [
                          Icon(isApproved ? Icons.check_circle : (isRejected ? Icons.cancel : Icons.info), color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(user.kycStatus.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Submitted", style: TextStyle(color: textLight, fontSize: 10)),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 10, color: textLight),
                        const SizedBox(width: 4),
                        Text(submittedStr, style: TextStyle(color: textDark, fontSize: 11)),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          
          Divider(color: textLight.withOpacity(0.15), height: 1),
          
          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text("KYC Score", style: TextStyle(color: textLight, fontSize: 11)),
                      const SizedBox(width: 8),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(width: 32, height: 32, child: CircularProgressIndicator(value: user.kycScore / 100, color: colorApproved, backgroundColor: colorApproved.withOpacity(0.2), strokeWidth: 3)),
                          Text("${user.kycScore}%", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: textLight.withOpacity(0.2)),
                Expanded(
                  child: Column(
                    children: [
                      Text("Role", style: TextStyle(color: textLight, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(user.role.toUpperCase(), style: TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: textLight.withOpacity(0.2)),
                Expanded(
                  child: Column(
                    children: [
                      Text("User Since", style: TextStyle(color: textLight, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(submittedStr, style: TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(color: textLight.withOpacity(0.15), height: 1),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _buildActionButton(IconlyLight.show, "View", colorTotal, () => _showViewDialog(context, user))),
                if (isPending) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _buildActionButton(IconlyLight.tick_square, "Approve", colorApproved, () => controller.approve(user.id))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildActionButton(IconlyLight.close_square, "Reject", colorRejected, () => _showRejectDialog(context, user.id))),
                ],
                const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showViewDialog(BuildContext context, KycUserModel user) {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("User Details", style: TextStyle(color: textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Name", user.name),
            _detailRow("Email", user.email),
            _detailRow("Mobile", user.mobile),
            _detailRow("PAN Number", user.panNumber ?? "N/A"),
            _detailRow("GST Number", user.gstNumber ?? "N/A"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Close", style: TextStyle(color: colorTotal))),
        ],
      )
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
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Close", style: TextStyle(color: colorTotal))),
        ],
      )
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
                Get.snackbar("Error", "Please enter rejection reason", backgroundColor: colorRejected, colorText: Colors.white);
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
