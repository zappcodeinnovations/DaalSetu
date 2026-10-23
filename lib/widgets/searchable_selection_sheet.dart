import 'dart:math' as math;

import 'package:flutter/material.dart';

Future<T?> showSearchableSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T option) labelBuilder,
  T? selectedValue,
  String searchHint = 'Search...',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SearchableSelectionSheet<T>(
      title: title,
      options: options,
      labelBuilder: labelBuilder,
      selectedValue: selectedValue,
      searchHint: searchHint,
    ),
  );
}

class _SearchableSelectionSheet<T> extends StatefulWidget {
  const _SearchableSelectionSheet({
    required this.title,
    required this.options,
    required this.labelBuilder,
    required this.searchHint,
    this.selectedValue,
  });

  final String title;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final T? selectedValue;
  final String searchHint;

  @override
  State<_SearchableSelectionSheet<T>> createState() =>
      _SearchableSelectionSheetState<T>();
}

class _SearchableSelectionSheetState<T>
    extends State<_SearchableSelectionSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom;
    final sheetHeight = math.min(620.0, availableHeight * 0.82);
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredOptions = widget.options.where((option) {
      return widget
          .labelBuilder(option)
          .toLowerCase()
          .contains(normalizedQuery);
    }).toList();

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredOptions.isEmpty
                  ? Center(
                      child: Text(
                        'No matching options found.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: filteredOptions.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: theme.dividerColor.withValues(alpha: 0.55),
                      ),
                      itemBuilder: (context, index) {
                        final option = filteredOptions[index];
                        final selected = option == widget.selectedValue;
                        return ListTile(
                          minTileHeight: 52,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: selected,
                          selectedTileColor: theme.colorScheme.primary
                              .withValues(alpha: 0.12),
                          title: Text(
                            widget.labelBuilder(option),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(option),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
