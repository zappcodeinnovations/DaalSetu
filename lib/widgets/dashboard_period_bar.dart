import 'package:flutter/material.dart';

import '../utils/dashboard_filter.dart';

/// The date filter bar at the top of every dashboard (admin, seller, buyer, transporter): the active period,
/// a "Change" button (quick ranges, a month, or a custom range) and a clear (x). [onChanged] reloads the dashboard.
class DashboardPeriodBar extends StatelessWidget {
  const DashboardPeriodBar({
    super.key,
    required this.onChanged,
    this.margin,
  });

  final VoidCallback onChanged;
  final EdgeInsetsGeometry? margin;

  Future<void> _open(BuildContext context) async {
    final picked = await showPeriodSheet(context, DashboardFilter.current.value);
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
          margin: margin ?? const EdgeInsets.only(bottom: 14),
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

/// Opens the period sheet; returns the chosen value, or null when it was dismissed.
Future<DashboardFilterValue?> showPeriodSheet(BuildContext context, DashboardFilterValue current) {
  return showModalBottomSheet<DashboardFilterValue>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PeriodSheet(current: current),
  );
}

/// A list screen's own date bar (admin lists): the period, Change and clear. Does not touch the dashboards' filter.
class ListDateFilterBar extends StatelessWidget {
  const ListDateFilterBar({super.key, required this.value, required this.onChanged});

  final DashboardFilterValue value;
  final ValueChanged<DashboardFilterValue> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value.isActive ? color.withValues(alpha: 0.6) : theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value.isActive ? 'Date: ${value.label}' : 'Date: all dates',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (value.isActive)
              IconButton(
                tooltip: 'Clear the date filter',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onChanged(DashboardFilterValue.none),
              ),
            TextButton(
              onPressed: () async {
                final picked = await showPeriodSheet(context, value);
                if (picked != null) onChanged(picked);
              },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSheet extends StatelessWidget {
  const _PeriodSheet({required this.current});

  final DashboardFilterValue current;

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
