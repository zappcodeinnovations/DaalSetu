import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

String formatNegotiationTimestamp(String? raw) {
  if (raw == null || raw.trim().isEmpty || raw == '-') return '';
  final trimmed = raw.trim();

  DateTime? dt;

  // 1. Try standard ISO 8601 parsing
  dt = DateTime.tryParse(trimmed);

  // 2. If it contains a space between date and time (e.g. "2026-10-17 05:19:28")
  if (dt == null && trimmed.contains(' ')) {
    final isoCandidate = trimmed.replaceFirst(' ', 'T');
    dt = DateTime.tryParse(isoCandidate);
  }

  // 3. If ISO parsed as naive (isUtc == false) and had no explicit timezone offset,
  // backend timestamps are UTC by contract in Django (USE_TZ = True).
  // An ISO string without 'Z', '+', or '-' (after time) must be treated as UTC.
  if (dt != null && !dt.isUtc) {
    final hasTz = RegExp(r'(Z|[+-]\d{2}:?\d{2})$', caseSensitive: false).hasMatch(trimmed);
    if (!hasTz) {
      dt = DateTime.utc(
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
        dt.second,
        dt.millisecond,
        dt.microsecond,
      );
    }
  }

  // 4. Try parsing common formats like "Jul 29, 2026 10:48 AM" or "29 Jul 2026, 10:48 AM"
  if (dt == null) {
    final formats = [
      DateFormat('MMM d, yyyy h:mm a'),
      DateFormat('MMM dd, yyyy h:mm a'),
      DateFormat('MMM d, yyyy hh:mm a'),
      DateFormat('MMM dd, yyyy hh:mm a'),
      DateFormat('d MMM yyyy, h:mm a'),
      DateFormat('dd MMM yyyy, h:mm a'),
      DateFormat('d MMM yyyy, hh:mm a'),
      DateFormat('dd MMM yyyy, hh:mm a'),
      DateFormat('dd-MM-yyyy hh:mm a'),
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('yyyy-MM-dd HH:mm'),
      DateFormat('dd-MM-yyyy HH:mm'),
    ];
    for (final fmt in formats) {
      try {
        final parsed = fmt.parseLoose(trimmed);
        dt = DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
        );
        break;
      } catch (_) {}
    }
  }

  if (dt != null) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  return trimmed;
}

void main() {
  group('Negotiation Timestamp Formatting Tests', () {
    test('Empty and null values return empty string', () {
      expect(formatNegotiationTimestamp(null), '');
      expect(formatNegotiationTimestamp(''), '');
      expect(formatNegotiationTimestamp('   '), '');
      expect(formatNegotiationTimestamp('-'), '');
    });

    test('Parses ISO 8601 with +00:00 UTC offset correctly', () {
      const raw = '2026-10-17T05:19:28.000838+00:00';
      final formatted = formatNegotiationTimestamp(raw);
      final expected = DateFormat('dd MMM yyyy, hh:mm a').format(
        DateTime.parse(raw).toLocal(),
      );
      expect(formatted, expected);
      expect(formatted.contains('AM') || formatted.contains('PM'), isTrue);
    });

    test('Parses ISO 8601 with Z suffix correctly', () {
      const raw = '2026-10-17T05:19:28Z';
      final formatted = formatNegotiationTimestamp(raw);
      final expected = DateFormat('dd MMM yyyy, hh:mm a').format(
        DateTime.parse(raw).toLocal(),
      );
      expect(formatted, expected);
    });

    test('Parses space-separated naive ISO string as UTC and converts to local', () {
      const raw = '2026-10-17 05:19:28';
      final formatted = formatNegotiationTimestamp(raw);
      final expected = DateFormat('dd MMM yyyy, hh:mm a').format(
        DateTime.utc(2026, 10, 17, 5, 19, 28).toLocal(),
      );
      expect(formatted, expected);
    });

    test('Parses pre-formatted backend string "Jul 29, 2026 10:48 AM"', () {
      const raw = 'Jul 29, 2026 10:48 AM';
      final formatted = formatNegotiationTimestamp(raw);
      final expected = DateFormat('dd MMM yyyy, hh:mm a').format(
        DateTime.utc(2026, 7, 29, 10, 48).toLocal(),
      );
      expect(formatted, expected);
    });

    test('Handles timestamps near midnight transitioning across dates', () {
      const rawLateNight = '2026-10-16T23:45:00+00:00';
      final formatted = formatNegotiationTimestamp(rawLateNight);
      final expected = DateFormat('dd MMM yyyy, hh:mm a').format(
        DateTime.parse(rawLateNight).toLocal(),
      );
      expect(formatted, expected);
    });

    test('Preserves unknown text without throwing exception', () {
      expect(formatNegotiationTimestamp('Not A Date'), 'Not A Date');
    });
  });
}
