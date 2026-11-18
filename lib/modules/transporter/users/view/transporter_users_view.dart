import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../users/controller/user_controller.dart';
import '../../../../theme/app_theme.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class TransporterUsersView extends StatelessWidget {
  const TransporterUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final searchCtrl = TextEditingController(text: controller.searchQuery.value);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Network Users",
        subtitle: "Associated team & staff directory",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: "Refresh",
          onPressed: controller.fetchUsers,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/images/thumb_logo.png',
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              // Search & Filter Controls
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: searchCtrl,
                      onChanged: (val) => controller.setSearch(val),
                      decoration: InputDecoration(
                        hintText: "Search by name, mobile, or email...",
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                        prefixIcon: const Icon(IconlyLight.search, color: Color(0xFFFF9800), size: 20),
                        suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchCtrl.clear();
                                  controller.clearSearch();
                                },
                              )
                            : const SizedBox.shrink()),
                        filled: true,
                        fillColor: isDark ? AppTheme.cardColor : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFFF9800), width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Role Filter Pills
                    SizedBox(
                      height: 36,
                      child: Obx(() {
                        final currentRole = controller.selectedRole.value;
                        const roles = [
                          {'key': 'all', 'label': 'All'},
                          {'key': 'transporter', 'label': 'Transporters'},
                          {'key': 'salesman', 'label': 'Salesmen'},
                          {'key': 'buyer', 'label': 'Buyers'},
                          {'key': 'seller', 'label': 'Sellers'},
                          {'key': 'admin', 'label': 'Admins'},
                        ];

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: roles.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final roleKey = roles[i]['key']!;
                            final roleLabel = roles[i]['label']!;
                            final isSelected = currentRole == roleKey;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => controller.setRole(roleKey),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : (isDark ? AppTheme.cardColor : Colors.white),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : (isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2)),
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      roleLabel,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Users List View
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.users.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)));
                  }

                  if (controller.users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(IconlyLight.user_1, size: 56, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No users found",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Associated team and network users will appear here.",
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(IconlyLight.search, size: 48, color: Color(0xFFFF9800)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No matching users",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Try adjusting your search query or role filter.",
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.fetchUsers,
                    color: primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: controller.filteredUsers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = controller.filteredUsers[index];
                        final displayName = "${user.firstName ?? ''} ${user.lastName ?? ''}".trim();
                        final name = displayName.isNotEmpty
                            ? displayName
                            : (user.username.isNotEmpty ? user.username : 'User');
                        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
                        final role = user.role.toUpperCase();

                        // Role-specific badge color
                        Color roleBadgeColor;
                        switch (user.role.toLowerCase().trim()) {
                          case 'transporter':
                            roleBadgeColor = const Color(0xFFE65100);
                            break;
                          case 'salesman':
                          case 'sub_admin':
                            roleBadgeColor = Colors.teal;
                            break;
                          case 'buyer':
                            roleBadgeColor = Colors.blue.shade700;
                            break;
                          case 'seller':
                            roleBadgeColor = Colors.green.shade700;
                            break;
                          case 'admin':
                            roleBadgeColor = Colors.purple;
                            break;
                          default:
                            roleBadgeColor = Colors.blueGrey;
                        }

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardColor : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFF9800).withValues(alpha: 0.2),
                                      const Color(0xFFF57C00).withValues(alpha: 0.3),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFF9800).withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: const Color(0xFFE65100),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: theme.textTheme.bodyLarge?.color,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: roleBadgeColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: roleBadgeColor.withValues(alpha: 0.3),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            role,
                                            style: TextStyle(
                                              color: roleBadgeColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          IconlyLight.call,
                                          size: 13,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user.mobile.isNotEmpty
                                              ? user.mobile
                                              : (user.email != null && user.email!.isNotEmpty
                                                  ? user.email!
                                                  : "No contact info"),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (user.isActive) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF4CAF50),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Active",
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: const Color(0xFF4CAF50),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
