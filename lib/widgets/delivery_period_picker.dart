import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

/// "Delivery Period" (MoM point 8): two date tiles, From and To.
/// Past dates cannot be picked and To never falls before From.
class DeliveryPeriodPicker extends StatelessWidget {
  const DeliveryPeriodPicker({
    super.key,
    required this.from,
    required this.to,
    required this.onChanged,
    this.label = 'Delivery Period *',
    this.hint,
  });

  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to) onChanged;
  final String label;

  /// Extra line under the tiles (e.g. the seller's offered period).
  final String? hint;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// yyyy-MM-dd, the format the API expects.
  static String apiDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  /// dd-MM-yyyy for display.
  static String displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';

  /// Parses an ISO date; past dates come back null so a stale period is not reused.
  static DateTime? parseUpcoming(String? iso) {
    final parsed = DateTime.tryParse(iso ?? '');
    if (parsed == null) return null;
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    return day.isBefore(_today) ? null : day;
  }

  /// "12-11-2026 to 15-11-2026" (or one date), '' when not set.
  static String periodText(String? fromIso, String? toIso) {
    final start = DateTime.tryParse(fromIso ?? '');
    final end = DateTime.tryParse(toIso ?? '') ?? start;
    if (start == null) return '';
    if (end == null || end == start) return displayDate(start);
    return '${displayDate(start)} to ${displayDate(end)}';
  }

  Future<void> _pick(BuildContext context, {required bool isFrom}) async {
    final first = isFrom ? _today : (from ?? _today);
    final current = isFrom ? from : (to ?? from);
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isBefore(first) ? current : first,
      firstDate: first,
      lastDate: _today.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    if (isFrom) {
      onChanged(picked, to == null || to!.isBefore(picked) ? picked : to);
    } else {
      onChanged(from ?? picked, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget tile(String caption, DateTime? value, bool isFrom) => Expanded(
          child: InkWell(
            onTap: () => _pick(context, isFrom: isFrom),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caption,
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value == null ? 'dd-mm-yyyy' : displayDate(value),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: value == null ? Colors.grey : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(IconlyLight.calendar, size: 18),
                ],
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            tile('From', from, true),
            const SizedBox(width: 10),
            tile('To', to, false),
          ],
        ),
        if (hint != null && hint!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(hint!, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ],
    );
  }
}
