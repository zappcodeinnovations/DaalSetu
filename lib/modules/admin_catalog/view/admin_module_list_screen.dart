import 'package:daalsetu/widgets/dashboard_period_bar.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'dart:async';

import 'package:daalsetu/services/category_services.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_actions.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/controller/admin_catalog_controller.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/repository/admin_catalog_repository.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_detail_screen.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_form_screen.dart';
import 'package:daalsetu/widgets/admin_common_widgets.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import '../../../utils/app_snackbar.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class AdminModuleListScreen extends StatefulWidget {
  const AdminModuleListScreen({
    super.key,
    required this.moduleKey,
    this.showAdminDrawer = true,
  });

  final String moduleKey;
  final bool showAdminDrawer;

  @override
  State<AdminModuleListScreen> createState() => _AdminModuleListScreenState();
}

class _AdminModuleListScreenState extends State<AdminModuleListScreen> {
  late final AdminModuleConfig config;
  late final AdminCatalogController controller;
  late final ScrollController scrollController;
  late final TextEditingController _searchController;
  Timer? debounce;

  // Only a super admin creates branches (the server refuses everybody else), so the + stays hidden until we know.
  bool _isSuperAdmin = false;

  // Parity state for Category Requests module ("Approval Queue" vs "All Buyers")
  int _activeCategoryRequestTab = 0; // 0 = Approval Queue, 1 = All Buyers
  List<Map<String, dynamic>> _buyers = [];
  bool _isLoadingBuyers = false;
  String _buyerSearch = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _searchController = TextEditingController();
    config = AdminModules.byKey(widget.moduleKey);
    controller = Get.put(
      AdminCatalogController(AdminCatalogRepository(config)),
      tag: 'admin_${widget.moduleKey}_${identityHashCode(this)}',
    );
    controller.resetSearch();
    scrollController = ScrollController()..addListener(_onScroll);
    if (widget.moduleKey == 'category_requests') {
      _fetchBuyers();
    }
    if (widget.moduleKey == 'branches') {
      AppPreferences.getRole().then((role) {
        if (mounted) setState(() => _isSuperAdmin = (role ?? '').toLowerCase() == 'super_admin');
      });
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await AppPreferences.getRole();
      if (mounted) {
        setState(() {
          _userRole = (role ?? '').trim().toLowerCase();
          _isSuperAdmin = _userRole == 'super_admin';
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchBuyers() async {
    setState(() => _isLoadingBuyers = true);
    try {
      dynamic res;
      try {
        res = await ApiClient.get(
          endpoint: '/api/buyer-categories/?tab=buyers',
          requireAuth: true,
          suppressErrorDialog: true,
        );
      } catch (_) {}

      if (res == null || (res is List && res.isEmpty)) {
        res = await ApiClient.get(
          endpoint: '/api/users/?role=buyer',
          requireAuth: true,
          suppressErrorDialog: true,
        );
      }

      if (res is List) {
        if (mounted) {
          setState(() {
            _buyers = List<Map<String, dynamic>>.from(res);
            _isLoadingBuyers = false;
          });
        }
      } else if (res is Map && res['results'] is List) {
        if (mounted) {
          setState(() {
            _buyers = List<Map<String, dynamic>>.from(res['results']);
            _isLoadingBuyers = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingBuyers = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBuyers = false);
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    _searchController.dispose();
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    Get.delete<AdminCatalogController>(
      tag: 'admin_${widget.moduleKey}_${identityHashCode(this)}',
      force: true,
    );
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.extentAfter < 300) controller.loadMore();
  }

  void _onSearch(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 450), () {
      controller.search.value = value.trim();
      controller.load(refresh: true);
    });
  }

  Future<void> _refresh() async {
    debounce?.cancel();
    _searchController.clear();
    controller.resetSearch();
    await controller.load(refresh: true);
    if (widget.moduleKey == 'category_requests') {
      _fetchBuyers();
    }
  }

  Future<void> _openForm([AdminRecord? record]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminRecordFormScreen(
          config: config,
          record: record,
          userRole: _userRole,
        ),
      ),
    );
    if (changed == true) await controller.load(refresh: true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: widget.showAdminDrawer
        ? AdminDrawer(activeKey: widget.moduleKey)
        : null,
    appBar: HeroHeader(
      // Screens reached from the side menu show the menu button itself (it opens the menu every time);
      // system back still returns to the previous page.
      leading: widget.showAdminDrawer
          ? IconButton(
              tooltip: 'Open menu',
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => AppShell.openDrawer(activeKey: widget.moduleKey),
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => goBackOrHome(context),
            ),
      title: widget.moduleKey == 'category_requests'
          ? 'Category Requests'
          : config.title,
      subtitle: 'Directory & operational management',
      trailing: IconButton(
        tooltip: 'Refresh',
        onPressed: _refresh,
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
      ),
    ),
    // Only sellers add brands now (MoM point 26); admins review and edit them.
    floatingActionButton: config.canCreate &&
            widget.moduleKey != 'brands' &&
            (widget.moduleKey != 'branches' || _isSuperAdmin) &&
            (widget.moduleKey != 'category_requests' ||
                _activeCategoryRequestTab == 0)
        ? Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF57C00).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _openForm,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Create',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : null,
    body: Column(
      children: [
        if (widget.moduleKey == 'category_requests')
          _buildCategoryRequestsSegment(),
        if (widget.moduleKey == 'category_requests' &&
            _activeCategoryRequestTab == 1)
          Expanded(child: _buildAllBuyersView())
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: AdminSearchBar(
              controller: _searchController,
              hint: 'Search ${config.title}',
              onChanged: _onSearch,
              onClear: () {
                debounce?.cancel();
                controller.resetSearch();
                controller.load(refresh: true);
              },
            ),
          ),
          // One date filter (From - To / presets) on every list panel.
          Obx(() => ListDateFilterBar(
                value: controller.dateFilter.value,
                onChanged: controller.setDateFilter,
              )),
          if (config.filterOptions.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: config.filterOptions.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final value = index == 0
                      ? ''
                      : config.filterOptions[index - 1];
                  return Obx(() => ChoiceChip(
                    label: Text(value.isEmpty ? 'All' : _label(value)),
                    selected: controller.selectedFilter.value == value,
                    onSelected: (_) {
                      controller.selectedFilter.value = value;
                      controller.load(refresh: true);
                    },
                  ));
                },
              ),
            ),
          if (config.filterOptions.isNotEmpty) const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.records.isEmpty) {
                return const AdminLoadingWidget();
              }
              if (controller.error.value != null && controller.records.isEmpty) {
                return AdminErrorWidget(
                  message: controller.error.value!,
                  onRetry: () => controller.load(refresh: true),
                );
              }
              if (controller.records.isEmpty) {
                return AdminEmptyWidget(title: config.title);
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1050
                        ? 3
                        : constraints.maxWidth >= 700
                        ? 2
                        : 1;
                    if (columns == 1) {
                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: controller.records.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) =>
                            index == controller.records.length
                            ? _loadMoreIndicator()
                            : _recordCard(controller.records[index]),
                      );
                    }
                    return GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 230,
                      ),
                      itemCount: controller.records.length,
                      itemBuilder: (_, index) =>
                          _recordCard(controller.records[index]),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ],
    ),
  );

  Widget _buildCategoryRequestsSegment() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE0B2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeCategoryRequestTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: _activeCategoryRequestTab == 0
                        ? const LinearGradient(
                            colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: _activeCategoryRequestTab == 0
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Approval Queue',
                        style: TextStyle(
                          color: _activeCategoryRequestTab == 0
                              ? Colors.white
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _activeCategoryRequestTab = 1);
                  if (_buyers.isEmpty) _fetchBuyers();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: _activeCategoryRequestTab == 1
                        ? const LinearGradient(
                            colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 16,
                        color: _activeCategoryRequestTab == 1
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'All Buyers',
                        style: TextStyle(
                          color: _activeCategoryRequestTab == 1
                              ? Colors.white
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllBuyersView() {
    final theme = Theme.of(context);
    final q = _buyerSearch.toLowerCase();
    final filtered = _buyers.where((b) {
      if (q.isEmpty) return true;
      final name = (b['name'] ??
              b['first_name'] ??
              b['username'] ??
              '')
          .toString()
          .toLowerCase();
      final mobile = (b['mobile'] ?? '').toString().toLowerCase();
      final email = (b['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || mobile.contains(q) || email.contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: AdminSearchBar(
            hint: 'Search buyer or category…',
            onChanged: (v) =>
                setState(() => _buyerSearch = v.trim().toLowerCase()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} buyers found',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingBuyers && _buyers.isEmpty
              ? const AdminLoadingWidget()
              : RefreshIndicator(
                  onRefresh: _fetchBuyers,
                  child: filtered.isEmpty
                      ? const AdminEmptyWidget(title: 'Buyers')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) => _buyerCard(filtered[i]),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buyerCard(Map<String, dynamic> buyer) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rawName = (buyer['name'] ?? '').toString().trim();
    final firstLast = '${buyer['first_name'] ?? ''} ${buyer['last_name'] ?? ''}'.trim();
    final username = (buyer['username'] ?? '').toString().trim();
    final name = rawName.isNotEmpty
        ? rawName
        : (firstLast.isNotEmpty
            ? firstLast
            : (username.isNotEmpty ? username : 'Buyer'));
    final email = (buyer['email'] ?? '').toString();
    final mobile = (buyer['mobile'] ?? '').toString();

    dynamic catData = buyer['assigned_categories'] ?? buyer['categories'];
    String assignedStr = 'No categories assigned';
    if (catData is List && catData.isNotEmpty) {
      assignedStr = catData
          .map((c) =>
              c is Map ? (c['name'] ?? c['category_name'] ?? '') : c.toString())
          .where((s) => s.isNotEmpty)
          .join(', ');
      if (assignedStr.isEmpty) assignedStr = 'No categories assigned';
    } else if (catData is String && catData.isNotEmpty) {
      assignedStr = catData;
    }

    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
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
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFF57C00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF57C00).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openManageBuyerCategories(buyer),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Manage'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF57C00),
                    side: const BorderSide(color: Color(0xFFF57C00)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFE0B2).withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 14, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Text(
                        mobile.isNotEmpty ? mobile : '-',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.category_outlined,
                            size: 14, color: Color(0xFFEA580C)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          assignedStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: assignedStr == 'No categories assigned'
                                ? Colors.grey
                                : const Color(0xFFEA580C),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openManageBuyerCategories(Map<String, dynamic> buyer) async {
    final buyerId = buyer['id'];
    final buyerName = buyer['name'] ?? buyer['username'] ?? 'Buyer';

    List<dynamic> allCategories = [];
    try {
      // 1. First fetch authoritative system categories from buyer category data
      final catResult = await CategoryService.fetchBuyerCategoryData();
      if (catResult.systemCategories.isNotEmpty) {
        allCategories = catResult.systemCategories.map((c) => {
          'id': c.id,
          'name': c.categoryName,
          'category_name': c.categoryName,
          'parent': null,
          'level': 0,
          'status': 'active',
        }).toList();
      }

      // 2. Fallback to /api/categories/ if systemCategories was empty
      if (allCategories.isEmpty) {
        dynamic res = await ApiClient.get(
          endpoint: '/api/categories/',
          requireAuth: true,
          suppressErrorDialog: true,
        );
        List raw = [];
        if (res is List) {
          raw = res;
        } else if (res is Map && res['results'] is List) {
          raw = res['results'];
        } else if (res is Map && res['data'] is List) {
          raw = res['data'];
        }
        allCategories = raw;
      }

      // 3. Strictly isolate root/parent categories and exclude pending/child subcategories
      final Set<int> seenIds = {};
      final List<Map<String, dynamic>> filteredCategories = [];

      for (var item in allCategories) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = map['id'] is int
            ? map['id']
            : int.tryParse(map['id']?.toString() ?? '0') ?? 0;
        if (id <= 0 || seenIds.contains(id)) continue;

        final parent = map['parent'];
        final level = map['level'];
        final status = (map['status'] ?? '').toString().trim().toLowerCase();
        final isSub = map['is_sub'] == true ||
            map['is_subcategory'] == true ||
            map['is_sub_category'] == true;

        final hasParent = parent != null &&
            parent.toString().isNotEmpty &&
            parent.toString() != 'null' &&
            parent.toString() != '0';
        final hasLevel = level != null &&
            level.toString().isNotEmpty &&
            level.toString() != 'null' &&
            level.toString() != '0';

        // Root/parent check: Must have no parent and level 0
        if (isSub || hasParent || hasLevel) continue;

        // Status check: Exclude pending, inactive, rejected categories
        if (status == 'pending' || status == 'inactive' || status == 'rejected') {
          continue;
        }

        seenIds.add(id);
        filteredCategories.add(map);
      }

      // 4. Sort alphabetically by category name matching the web portal format
      filteredCategories.sort((a, b) {
        final nameA = (a['category_name'] ?? a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['category_name'] ?? b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      allCategories = filteredCategories;
    } catch (_) {}

    final dynamic assigned =
        buyer['assigned_categories'] ?? buyer['categories'];
    final Set<int> selectedCategoryIds = (assigned is List ? assigned : [])
        .map((c) => c is Map ? int.tryParse('${c['id']}') : int.tryParse(c.toString()))
        .whereType<int>()
        .toSet();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(ctx);
          final isDark = theme.brightness == Brightness.dark;
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manage Categories',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Update assigned categories for $buyerName.',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: allCategories.isEmpty
                      ? const Center(
                          child: Text('No categories available'))
                      : ListView.builder(
                          itemCount: allCategories.length,
                          itemBuilder: (ctx, i) {
                            final cat = allCategories[i];
                            final id = cat['id'] is int
                                ? cat['id']
                                : int.tryParse(cat['id']?.toString() ?? '0') ??
                                    0;
                            final catName = cat['category_name'] ??
                                cat['name'] ??
                                cat['label'] ??
                                cat['title'] ??
                                'Category $id';
                            final isChecked = selectedCategoryIds.contains(id);
                            return CheckboxListTile(
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              side: BorderSide(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                width: 1.5,
                              ),
                              activeColor: const Color(0xFFEA580C),
                              checkColor: Colors.white,
                              title: Row(
                                children: [
                                  const Icon(
                                    Icons.eco_outlined,
                                    size: 16,
                                    color: Color(0xFFEA580C),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      catName.toString(),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              value: isChecked,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    selectedCategoryIds.add(id);
                                  } else {
                                    selectedCategoryIds.remove(id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            await ApiClient.post(
                              endpoint: '/api/buyer-categories/',
                              body: {
                                'buyer_id': buyerId,
                                'category_ids': selectedCategoryIds.toList(),
                              },
                              requireAuth: true,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            AppSnackbar.snackbar(
                              'Success',
                              'Buyer categories updated successfully',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 3),
                            );
                            _fetchBuyers();
                          } catch (e) {
                            AppSnackbar.snackbar('Error', e.toString(),
                                backgroundColor: Colors.red,
                                colorText: Colors.white);
                          }
                        },
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _recordCard(AdminRecord record) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = _first(record, config.titleKeys);

    dynamic resolveValue(dynamic rec, String key) {
      if (key.contains('.')) {
        final parts = key.split('.');
        dynamic cur = rec;
        for (final p in parts) {
          if (cur is Map) {
            cur = cur[p];
          } else {
            return null;
          }
        }
        return cur;
      }
      return rec is Map ? rec[key] : null;
    }

    final subtitles = config.subtitleKeys
        .map((key) {
          final rawVal = resolveValue(record.data, key);
          String displayVal = '';
          if (key == 'experience' && rawVal != null && rawVal.toString().trim().isNotEmpty) {
            final exp = int.tryParse(rawVal.toString()) ?? 0;
            displayVal = '$exp ${exp == 1 ? 'year' : 'years'}';
          } else if (key == 'assigned_vehicle.vehicle_number') {
            displayVal = (rawVal == null || rawVal.toString().trim().isEmpty || rawVal.toString().toLowerCase() == 'null')
                ? '-'
                : rawVal.toString();
          } else {
            displayVal = _display(rawVal, key: key);
          }
          return MapEntry(key, displayVal);
        })
        .where((entry) => entry.value.isNotEmpty)
        .take(8)
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _view(record),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE0B2)),
                      ),
                      child: Icon(config.icon, color: const Color(0xFFEA580C), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title.isEmpty ? config.title : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              ...subtitles.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(
                          _label(entry.key),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: _isStatusKey(entry.key)
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: _statusChip(entry.value),
                              )
                            : (entry.value == 'Active' || entry.value == 'Inactive')
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (entry.value == 'Active'
                                            ? Colors.green
                                            : Colors.red)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: (entry.value == 'Active'
                                              ? Colors.green
                                              : Colors.red)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      color: entry.value == 'Active'
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                entry.value,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...config.customActions
                      .where((action) => action.isVisible?.call(record.data) ?? true)
                      .map(
                        (action) => OutlinedButton.icon(
                          onPressed: () async {
                            final success =
                                await action.onPressed(context, record.data);
                            if (success) controller.load(refresh: true);
                          },
                          icon: Icon(action.icon, size: 16),
                          label: Text(action.title),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(
                              color: theme.colorScheme.primary.withValues(alpha: 0.35),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                  OutlinedButton.icon(
                    onPressed: () => _view(record),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text(
                      'View',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (config.canEdit)
                    OutlinedButton.icon(
                      onPressed: () => _openForm(record),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(
                          color: Colors.orange.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (config.canDelete && (widget.moduleKey != 'salesman' || _isSuperAdmin))
                    OutlinedButton.icon(
                      onPressed: () => _delete(record),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _loadMoreIndicator() => Obx(
    () => controller.isLoadingMore.value
        ? const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          )
        : const SizedBox(height: 1),
  );

  Future<void> _view(AdminRecord record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminRecordDetailScreen(config: config, record: record),
      ),
    );
    if (mounted) {
      controller.load(refresh: true);
    }
  }

  Future<void> _delete(AdminRecord record) async {
    if (widget.moduleKey == 'salesman' && !_isSuperAdmin) {
      AppSnackbar.showError(message: 'Only Super Admin can delete sub admins.');
      return;
    }
    if (await showAdminDeleteDialog(context)) {
      await controller.delete(record);
    }
  }

  String _first(AdminRecord record, List<String> keys) {
    for (final key in keys) {
      final value = _display(record[key], key: key);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _display(Object? value, {String? key}) => adminDisplayValue(value, key: key);

  /// Short card labels so every row stays on one line and lines up.
  static const Map<String, String> _shortLabels = {
    'kyc_status': 'KYC',
    'is_active': 'Active',
    'parent_name': 'Parent',
    'created_by_name': 'Created By',
    'created_at': 'Created',
    'updated_at': 'Updated',
    'requested_at': 'Requested',
    'phone_number': 'Phone',
    'license_number': 'License',
    'assignment_status_display': 'Assignment',
    'status_display': 'Status',
    'vehicle_status_display': 'Status',
    'vehicle_type': 'Type',
    'load_capacity_tons': 'Capacity (t)',
    'driver_name': 'Driver',
    'product_title': 'Product',
    'deal_quantity': 'Quantity',
    'loading_from': 'From',
    'loading_to': 'To',
    'branch_code': 'Code',
    'bill_prefix': 'Prefix',
    'billing_email': 'Email',
    'billing_phone': 'Phone',
    'request_note': 'Note',
    'seller_name': 'Seller',
    'buyer_name': 'Buyer',
    'category_name': 'Category',
    'required_quantity': 'Quantity',
    'target_price': 'Target',
    'quotation_count': 'Quotes',
    'requested_amount': 'Amount',
    'requested_quantity': 'Quantity',
    'page_label': 'Page',
    'is_primary': 'Primary',
    'both_sellerandbuyer': 'Buyer & Seller',
    'experience': 'Experience',
    'assigned_vehicle.vehicle_number': 'Assigned Vehicle',
    'required_bag_count': 'Bags',
    'expiry_datetime': 'Expiry',
  };

  String _label(String key) => _shortLabels[key] ?? key
      .replaceAll(RegExp(r'_display$'), '')
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');

  /// Status-like rows (status, kyc_status, is_active, ...) render as one chip style.
  static bool _isStatusKey(String key) =>
      key == 'is_active' || key.contains('status');

  static String _titleCase(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');

  static Color _statusColor(String value) {
    final v = value.toLowerCase();
    if (RegExp(r'reject|inactive|cancel|expired|suspend|deactivat|fail|block|unverified').hasMatch(v)) {
      return Colors.red;
    }
    if (RegExp(r'pending|progress|review|requested|draft|busy|maintenance|unassigned|open').hasMatch(v)) {
      return const Color(0xFFF59E0B);
    }
    return Colors.green;
  }

  Widget _statusChip(String raw) {
    final text = _titleCase(raw);
    final color = _statusColor(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
