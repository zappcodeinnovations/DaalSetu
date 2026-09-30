import 'package:iconly/iconly.dart';
import '../model/user_model.dart';
import './add_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/user_controller.dart';
import 'package:daalsetu/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// USER MANAGEMENT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late final UserController controller;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(UserController());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'buyer':       return Colors.blue;
      case 'seller':      return Colors.purple;
      case 'transporter': return Colors.teal;
      case 'admin':
      case 'sub_admin':   return Colors.deepOrange;
      case 'salesman':    return Colors.indigo;
      default:            return Colors.grey;
    }
  }

  Color _kycColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return AppTheme.successGreen;
      case 'rejected': return AppTheme.errorRed;
      default:         return AppTheme.primaryGold;
    }
  }

  IconData _kycIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Icons.verified_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default:         return Icons.hourglass_top_rounded;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search by name, mobile, email…',
                  hintStyle: theme.textTheme.bodySmall,
                  border: InputBorder.none,
                ),
                onChanged: controller.setSearch,
              )
            : Text(
                'User Management',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(
                _showSearch ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchCtrl.clear();
                controller.clearSearch();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.fetchUsers,
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => AddUserScreen()),
        icon: const Icon(IconlyLight.add_user),
        label: const Text('Add User'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),

      // ── Body: single Obx wrapping everything that depends on Rx ─────────
      body: Obx(() {
        final isLoading = controller.isLoading.value;

        if (isLoading) {
          return Center(
            child: CircularProgressIndicator(
                color: theme.colorScheme.primary),
          );
        }

        final users = controller.filteredUsers;

        return RefreshIndicator(
          onRefresh: controller.fetchUsers,
          color: theme.colorScheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats Section ────────────────────────────────────────
              _buildStatsSection(context),

              // ── Role Filter Chips ─────────────────────────────────────
              _buildRoleFilters(context),

              // ── Results count ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  '${users.length} users found',
                  style: theme.textTheme.bodySmall,
                ),
              ),

              // ── User List ─────────────────────────────────────────────
              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 60,
                              color:
                                  theme.iconTheme.color?.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: users.length,
                        itemBuilder: (ctx, i) =>
                            _buildUserCard(ctx, users[i]),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── Stats Section ──────────────────────────────────────────────────────────
  Widget _buildStatsSection(BuildContext context) {
    final theme = Theme.of(context);
    final stats = [
      _StatData('Total', controller.totalCount.toString(),
          Icons.people_alt_rounded, theme.colorScheme.primary),
      _StatData('Buyers', controller.buyerCount.toString(),
          Icons.shopping_cart_outlined, Colors.blue),
      _StatData('Sellers', controller.sellerCount.toString(),
          Icons.storefront_outlined, Colors.purple),
      _StatData('KYC ✓', controller.kycApprovedCount.toString(),
          Icons.verified_rounded, Colors.green),
      _StatData('Pending', controller.kycPendingCount.toString(),
          Icons.hourglass_top_rounded, Colors.orange),
      _StatData('Active', controller.activeCount.toString(),
          Icons.online_prediction_rounded, Colors.teal),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) => _statCard(ctx, stats[i]),
      ),
    );
  }

  Widget _statCard(BuildContext context, _StatData s) {
    final theme = Theme.of(context);
    return Container(
      width: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: s.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(s.icon, color: s.color, size: 18),
          Text(
            s.value,
            style: TextStyle(
              color: s.color,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          Text(
            s.label,
            style:
                theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── Role Filter Chips ──────────────────────────────────────────────────────
  Widget _buildRoleFilters(BuildContext context) {
    final theme = Theme.of(context);
    final selectedRole = controller.selectedRole.value;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: UserController.roleFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final role = UserController.roleFilters[i];
          final isSelected = selectedRole == role;

          return GestureDetector(
            onTap: () => controller.setRole(role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                ),
              ),
              child: Text(
                role == 'all' ? 'All' : role.capitalizeFirst!,
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── User Card ──────────────────────────────────────────────────────────────
  Widget _buildUserCard(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final roleColor = _roleColor(user.role);
    final kycColor = _kycColor(user.kycStatus);

    final initials = (user.fullName.isNotEmpty
            ? user.fullName[0]
            : user.username.isNotEmpty
                ? user.username[0]
                : '?')
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Get.toNamed('/users-details', arguments: user),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Avatar ────────────────────────────────────────────────
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: roleColor.withOpacity(0.15),
                    backgroundImage: user.profileImage != null
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: user.profileImage == null
                        ? Text(
                            initials,
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  if (user.isActive)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.cardColor, width: 2),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // ── Info ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty
                          ? user.fullName
                          : user.username,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 12,
                            color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(user.mobile,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 12)),
                      ],
                    ),
                    if ((user.email ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.email_outlined,
                            size: 12,
                            color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.email!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 8),
                    Row(children: [
                      _badge(user.role.toUpperCase(), roleColor),
                      const SizedBox(width: 6),
                      _badge(
                        user.kycStatus.toUpperCase(),
                        kycColor,
                        icon: _kycIcon(user.kycStatus),
                      ),
                    ]),
                  ],
                ),
              ),

              // ── 3-dot menu ────────────────────────────────────────────
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: theme.iconTheme.color?.withOpacity(0.6),
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (val) => _handleAction(val, user),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('View Details'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'activate',
                    child: Row(children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Activate'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Row(children: [
                      Icon(Icons.block_rounded,
                          size: 18, color: Colors.orange),
                      SizedBox(width: 10),
                      Text('Deactivate'),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete User',
                          style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, {IconData? icon}) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 3),
            ],
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );

  void _handleAction(String action, UserModel user) {
    switch (action) {
      case 'view':
        Get.toNamed('/users-details', arguments: user);
        break;
      case 'activate':
        _showStatusDialog(user, 'active');
        break;
      case 'deactivate':
        _showStatusDialog(user, 'inactive');
        break;
      case 'delete':
        _showDeleteDialog(user);
        break;
    }
  }

  void _showStatusDialog(UserModel user, String newStatus) {
    final reasonCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(newStatus == 'active'
            ? 'Activate User'
            : 'Deactivate User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'User: ${user.fullName.isNotEmpty ? user.fullName : user.username}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.updateUserStatus(
                  user.id, newStatus, reasonCtrl.text.trim());
            },
            child: Text(
                newStatus == 'active' ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(UserModel user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete\n"${user.fullName.isNotEmpty ? user.fullName : user.username}"?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Get.back();
              controller.deleteUser(user.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Legacy alias — keeps old routes/code working ──────────────────────────────
// ignore: must_be_immutable
class UserScreen extends StatelessWidget {
  UserScreen({super.key});
  @override
  Widget build(BuildContext context) => const UserManagementScreen();
}

// ── Stat data helper ──────────────────────────────────────────────────────────
class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.value, this.icon, this.color);
}
