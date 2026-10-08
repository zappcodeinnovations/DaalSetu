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
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    config = AdminModules.byKey(widget.moduleKey);
    controller = Get.put(
      AdminCatalogController(AdminCatalogRepository(config)),
      tag: 'admin_${widget.moduleKey}_${identityHashCode(this)}',
    );
    scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    debounce?.cancel();
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
        config.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => controller.load(refresh: true),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    floatingActionButton: config.canCreate
        ? FloatingActionButton.extended(
            heroTag: null,
            onPressed: _openForm,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create'),
          )
        : null,
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: AdminSearchBar(
            hint: 'Search ${config.title}',
            onChanged: _onSearch,
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
              onRefresh: () => controller.load(refresh: true),
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
    ),
  );

  Widget _recordCard(AdminRecord record) {
    final theme = Theme.of(context);
    final title = _first(record, config.titleKeys);
    final subtitles = config.subtitleKeys
        .map((key) => MapEntry(key, _display(record[key])))
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
                        child: Text(
                          entry.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  ...config.customActions
                      .where((action) => action.isVisible?.call(record.data) ?? true)
                      .map(
                        (action) => TextButton.icon(
                          onPressed: () async {
                            final success =
                                await action.onPressed(context, record.data);
                            if (success) controller.load(refresh: true);
                          },
                          icon: Icon(action.icon, size: 18),
                          label: Text(action.title),
                        ),
                      ),
                  TextButton.icon(
                    onPressed: () => _view(record),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View'),
                  ),
                  if (config.canEdit)
                    TextButton.icon(
                      onPressed: () => _openForm(record),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  if (config.canDelete)
                    TextButton.icon(
                      onPressed: () => _delete(record),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
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
      final value = _display(record[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _display(Object? value) => adminDisplayValue(value);

  String _label(String key) => key
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
