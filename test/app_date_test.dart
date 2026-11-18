import 'package:daalsetu/utils/app_date.dart';
import 'package:flutter_test/flutter_test.dart';

/// One date format everywhere: dd/MM/yyyy, and dd/MM/yyyy hh:mm a with a time.
void main() {
  test('a plain API date is shown as dd/MM/yyyy (the delivery challan date)', () {
    expect(AppDate.date('2026-11-18'), '18/11/2026');
    expect(AppDate.date('2026-11-05'), '05/11/2026');
    expect(AppDate.date(null), '-');
    expect(AppDate.date(''), '-');
    expect(AppDate.date(null, empty: 'N/A'), 'N/A');
  });

  test('a date with a time keeps the time in 12-hour form', () {
    expect(AppDate.dateTime('2026-11-18T19:23:00'), '18/11/2026 07:23 PM');
    expect(AppDate.dateTime('2026-11-18 00:05:00'), '18/11/2026 12:05 AM');
    expect(AppDate.dateTime('2026-11-18'), '18/11/2026'); // no time given: date only
  });

  test('a timestamp with a zone is shown in local time', () {
    final shown = AppDate.dateTime('2026-11-18T13:10:30+00:00');
    final local = DateTime.parse('2026-11-18T13:10:30+00:00').toLocal();
    expect(shown.startsWith('${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}'), isTrue);
  });

  test('older dd-MM-yyyy and dd/MM/yyyy strings from the server are normalised', () {
    expect(AppDate.date('18-11-2026'), '18/11/2026');
    expect(AppDate.date('18/11/2026'), '18/11/2026');
    expect(AppDate.dateTime('18-11-2026 13:33'), '18/11/2026 01:33 PM');
    expect(AppDate.dateTime('18/11/2026 07:19 PM'), '18/11/2026 07:19 PM');
  });

  test('something that is not a date is shown as it came; the API date stays yyyy-MM-dd', () {
    expect(AppDate.date('soon'), 'soon');
    expect(AppDate.apiDate(DateTime(2026, 3, 5)), '2026-03-05');
    expect(AppDate.fromDateTime(DateTime(2026, 3, 5)), '05/03/2026');
  });
}
