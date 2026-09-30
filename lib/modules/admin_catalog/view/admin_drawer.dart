import 'package:daalsetu/modules/admin_catalog/model/drawer_menu_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/drawer_controller.dart' as admin;

import 'package:daalsetu/theme/app_theme.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key, this.activeKey});
  final String? activeKey;

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(admin.DrawerController());
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      width: MediaQuery.sizeOf(context).width >= 700 ? 340 : 306,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.grass_rounded, color: theme.scaffoldBackgroundColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DaalSetu',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text('ADMIN PANEL', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close menu',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Nav List ─────────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.hasError.value) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load menu.\n${controller.errorMessage.value}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final isAdmin = controller.userRole.value == 'admin' ||
                    controller.userRole.value == 'sub_admin';

                if (!isAdmin) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No admin menu permission'),
                    ),
                  );
                }

                if (controller.menuSections.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No menu items available'),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
                  children: [
                    // Iterate through sections dynamically
                    for (var section in controller.menuSections)
                      _buildSection(context, section, controller),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    DrawerMenuSection section,
    admin.DrawerController controller,
  ) {
    // Only filtering items allowed for the user
    final visibleItems = section.items
        .where((item) => item.isVisibleFor(controller.userRole.value))
        .toList();

    if (visibleItems.isEmpty) return const SizedBox.shrink();

    // Use specific toggle variables based on section title or keep it general
    // For simplicity, reusing masters/offers or creating a generalized mapping.
    // If we want it strictly driven by state, we can map it manually:
    final isExpanded = section.sectionTitle == 'MASTERS'
        ? controller.mastersExpanded.value
        : section.sectionTitle == 'OFFER'
            ? controller.offersExpanded.value
            : true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          onTap: () {
            if (section.sectionTitle == 'MASTERS') {
              controller.toggleMasters();
            } else if (section.sectionTitle == 'OFFER') {
              controller.toggleOffers();
            }
          },
          title: Text(
            section.sectionTitle,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: visibleItems
                .map((item) => _menuItem(context, item, controller))
                .toList(),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _menuItem(BuildContext context, DrawerMenuItem item,
      admin.DrawerController controller) {
    final active = activeKey == item.key;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: ListTile(
        selected: active,
        selectedTileColor: AppTheme.primaryGold.withValues(alpha: .13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          item.icon,
          size: 21,
          color: active ? AppTheme.primaryGold : theme.iconTheme.color,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            color: active ? AppTheme.primaryGold : theme.textTheme.bodyMedium?.color,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        trailing: active
            ? Container(
                width: 5,
                height: 22,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : null,
        onTap: () {
          Navigator.pop(context); // close drawer first
          controller.handleNavigation(item.route);
        },
      ),
    );
  }
}
