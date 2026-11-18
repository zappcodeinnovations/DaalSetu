/// The one date format of the app: dates are `dd/MM/yyyy`, date and time is `dd/MM/yyyy hh:mm a`
/// (e.g. 18/11/2026 and 18/11/2026 07:23 PM). Screens and PDFs show dates through here; the API
/// keeps using `yyyy-MM-dd` (see [apiDate]).
class AppDate {
  const AppDate._();

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Parses an API value: "2026-11-18", "2026-11-18T13:10:30+00:00", "2026-11-18 13:10:30" ...
  /// or an already shown "18/11/2026" / "18-11-2026". Null when it is not a date.
  static DateTime? parse(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return null;
    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;
    final day = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:[ T,]+(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])?)?$').firstMatch(text);
    if (day == null) return null;
    var hour = int.tryParse(day.group(4) ?? '') ?? 0;
    final period = day.group(6)?.toLowerCase();
    if (period == 'pm' && hour < 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;
    return DateTime(
      int.parse(day.group(3)!),
      int.parse(day.group(2)!),
      int.parse(day.group(1)!),
      hour,
      int.tryParse(day.group(5) ?? '') ?? 0,
    );
  }

  /// "18/11/2026"; [empty] when there is no date; an unreadable value is shown as it came.
  static String date(dynamic raw, {String empty = '-'}) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return empty;
    final parsed = parse(text);
    if (parsed == null) return text;
    // A plain date has no time zone: show it as it is. A full timestamp is shown in local time.
    final shown = _hasTime(text) && _hasZone(text) ? parsed.toLocal() : parsed;
    return '${_two(shown.day)}/${_two(shown.month)}/${shown.year}';
  }

  /// "18/11/2026 07:23 PM"; a value without a time part is shown as a date only.
  static String dateTime(dynamic raw, {String empty = '-'}) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return empty;
    final parsed = parse(text);
    if (parsed == null) return text;
    if (!_hasTime(text)) return date(text, empty: empty);
    final shown = _hasZone(text) ? parsed.toLocal() : parsed;
    final hour = shown.hour % 12 == 0 ? 12 : shown.hour % 12;
    return '${_two(shown.day)}/${_two(shown.month)}/${shown.year} ${_two(hour)}:${_two(shown.minute)} ${shown.hour >= 12 ? 'PM' : 'AM'}';
  }

  /// For a [DateTime] picked in a date picker: "18/11/2026".
  static String fromDateTime(DateTime value) => '${_two(value.day)}/${_two(value.month)}/${value.year}';

  /// What the API wants: "2026-11-18".
  static String apiDate(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${_two(value.month)}-${_two(value.day)}';

  static bool _hasTime(String text) => text.contains('T') || RegExp(r'\d{1,2}:\d{2}').hasMatch(text);

  static bool _hasZone(String text) => text.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(text);
}
