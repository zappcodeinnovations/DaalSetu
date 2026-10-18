import 'dart:async';

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

  // Parity state for Category Requests module ("Approval Queue" vs "All Buyers")
  int _activeCategoryRequestTab = 0; // 0 = Approval Queue, 1 = All Buyers
  List<Map<String, dynamic>> _buyers = [];
  bool _isLoadingBuyers = false;
  String _buyerSearch = '';

  @override
  void initState() {
    super.initState();
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
        builder: (_) => AdminRecordFormScreen(config: config, record: record),
      ),
    );
    if (changed == true) await controller.load(refresh: true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: widget.showAdminDrawer
        ? AdminDrawer(activeKey: widget.moduleKey)
        : null,
    appBar: AppBar(
      title: Text(
        widget.moduleKey == 'category_requests'
            ? 'Buyer Category Management'
            : config.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    floatingActionButton: config.canCreate &&
            (widget.moduleKey != 'category_requests' ||
                _activeCategoryRequestTab == 0)
        ? FloatingActionButton.extended(
            heroTag: null,
            onPressed: _openForm,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create'),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeCategoryRequestTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeCategoryRequestTab == 0
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
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
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _activeCategoryRequestTab = 1);
                  if (_buyers.isEmpty) _fetchBuyers();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeCategoryRequestTab == 1
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
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

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
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
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    mobile.isNotEmpty ? mobile : '-',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.category_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      assignedStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: assignedStr == 'No categories assigned'
                            ? Colors.grey
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
      final res = await ApiClient.get(
        endpoint: '/api/categories/',
        requireAuth: true,
      );
      if (res is List) {
        allCategories = res;
      } else if (res is Map && res['results'] is List) {
        allCategories = res['results'];
      } else if (res is Map && res['data'] is List) {
        allCategories = res['data'];
      }
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
                          Text('Buyer: $buyerName',
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
                                'Category $id';
                            final isChecked = selectedCategoryIds.contains(id);
                            return CheckboxListTile(
                              title: Text(catName.toString()),
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
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
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
                        Get.snackbar(
                          'Success',
                          'Buyer categories updated successfully',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 3),
                        );
                        _fetchBuyers();
                      } catch (e) {
                        Get.snackbar('Error', e.toString(),
                            backgroundColor: Colors.red,
                            colorText: Colors.white);
                      }
                    },
                    child: const Text('Save Categories'),
                  ),
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
    final title = _first(record, config.titleKeys);
    final subtitles = config.subtitleKeys
        .map((key) => MapEntry(key, _display(record[key], key: key)))
        .where((entry) => entry.value.isNotEmpty)
        .take(4)
        .toList();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _view(record),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: .13,
                    ),
                    child: Icon(config.icon, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title.isEmpty ? '${config.title} #${config.recordId(record)}' : title,
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
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: (entry.value == 'Active' || entry.value == 'Inactive')
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
                  if (config.canDelete)
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

  Future<void> _view(AdminRecord record) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AdminRecordDetailScreen(config: config, record: record),
    ),
  );

  Future<void> _delete(AdminRecord record) async {
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

  String _label(String key) => key
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
