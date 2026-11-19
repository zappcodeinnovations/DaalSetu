import 'package:flutter/material.dart';

import '../utils/dashboard_filter.dart';

/// The date filter bar at the top of every dashboard (admin, seller, buyer, transporter): the active period,
/// a "Change" button (quick ranges, a month, or a custom range) and a clear (x). [onChanged] reloads the dashboard.
class DashboardPeriodBar extends StatelessWidget {
  const DashboardPeriodBar({super.key, required this.onChanged});

  final VoidCallback onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<DashboardFilterValue>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => const _PeriodSheet(),
    );
    if (picked == null) return;
    DashboardFilter.set(picked);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<DashboardFilterValue>(
      valueListenable: DashboardFilter.current,
      builder: (context, value, _) {
        final color = theme.colorScheme.primary;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: value.isActive ? color.withValues(alpha: 0.6) : theme.dividerColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Period', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                    Text(
                      value.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (value.isActive)
                IconButton(
                  tooltip: 'Clear the filter',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    DashboardFilter.clear();
                    onChanged();
                  },
                ),
              TextButton(onPressed: () => _open(context), child: const Text('Change')),
            ],
          ),
        );
      },
    );
  }
}

class _PeriodSheet extends StatelessWidget {
  const _PeriodSheet();

  List<String> get _recentMonths {
    final now = DateTime.now();
    return [
      for (var i = 0; i < 12; i++)
        () {
          final date = DateTime(now.year, now.month - i, 1);
          return '${date.year}-${date.month.toString().padLeft(2, '0')}';
        }(),
    ];
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (range != null && context.mounted) {
      Navigator.pop(context, DashboardFilterValue(from: range.start, to: range.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = DashboardFilter.current.value;
    Widget chip(String label, DashboardFilterValue value, {bool selected = false}) => ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => Navigator.pop(context, value),
        );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dashboard period', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                chip('All time', DashboardFilterValue.none, selected: !current.isActive),
                for (final entry in DashboardFilterValue.quickRanges.entries)
                  chip(entry.value, DashboardFilterValue(period: entry.key), selected: current.period == entry.key),
              ],
            ),
            const SizedBox(height: 18),
            Text('A month', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final month in _recentMonths)
                  chip(DashboardFilterValue(month: month).label, DashboardFilterValue(month: month), selected: current.month == month),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickRange(context),
                icon: const Icon(Icons.date_range_outlined),
                label: const Text('Custom date range'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
