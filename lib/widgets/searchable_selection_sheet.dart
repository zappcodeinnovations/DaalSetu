import 'dart:math' as math;

import 'package:flutter/material.dart';

Future<T?> showSearchableSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T option) labelBuilder,
  T? selectedValue,
  String searchHint = 'Search...',
  T Function(String typed)? customOption,
}) {
  // A keyboard left open by the previous field would push the page and the list around.
  FocusManager.instance.primaryFocus?.unfocus();
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
      customOption: customOption,
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
    this.customOption,
  });

  final String title;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final T? selectedValue;
  final String searchHint;

  /// When set, a search with no exact match offers `Use "typed text"` (same as the web lists), so a name
  /// that is not in the list (a state or city) can still be picked.
  final T Function(String typed)? customOption;

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
    // A fixed height from the screen, not from the space above the keyboard: the sheet stays still
    // when the keyboard opens instead of jumping up (QA: State / City list "glitch").
    final sheetHeight = math.min(620.0, media.size.height * 0.82);
    final keyboard = media.viewInsets.bottom;
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredOptions = widget.options.where((option) {
      return widget
          .labelBuilder(option)
          .toLowerCase()
          .contains(normalizedQuery);
    }).toList();
    final typed = _query.trim();
    final offerTyped = widget.customOption != null &&
        typed.isNotEmpty &&
        !widget.options.any((o) => widget.labelBuilder(o).trim().toLowerCase() == normalizedQuery);

    return Align(
      alignment: Alignment.bottomCenter,
      // Material (not a coloured Container) so the list items show their tap highlight.
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: sheetHeight,
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
                  // The keyboard opens only when the user taps Search; picking from the list needs none.
                  autofocus: false,
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
                child: filteredOptions.isEmpty && !offerTyped
                    ? Center(
                        child: Text(
                          widget.customOption != null
                              ? 'No match. Type the name to add it.'
                              : 'No matching options found.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        // Room under the last items while the keyboard covers the bottom of the sheet.
                        padding: EdgeInsets.fromLTRB(12, 0, 12, 20 + keyboard),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: filteredOptions.length + (offerTyped ? 1 : 0),
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: theme.dividerColor.withValues(alpha: 0.55),
                        ),
                        itemBuilder: (context, index) {
                          if (index == filteredOptions.length) {
                            return ListTile(
                              key: const Key('searchable-sheet-use-typed'),
                              minTileHeight: 52,
                              leading: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
                              title: Text(
                                'Use "$typed"',
                                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                              ),
                              onTap: () => Navigator.of(context).pop(widget.customOption!(typed)),
                            );
                          }
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
      ),
    );
  }
}
