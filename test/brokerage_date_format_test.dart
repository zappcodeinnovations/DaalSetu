import 'package:daalsetu/modules/admin_catalog/view/admin_brokerage_bills_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('brokerage bill dates are shown as DD-MM-YYYY', () {
    expect(billingDateShown('2026-11-20'), '20-11-2026');
    expect(billingDateShown('2026-11-20T10:30:00Z'), '20-11-2026');
    expect(billingDateShown(null), '');
    expect(billingDateShown(''), '');
  });

  test('what the user types goes to the server as YYYY-MM-DD', () {
    expect(billingDateForApi('20-11-2026'), '2026-11-20');
    expect(billingDateForApi('20/11/2026'), '2026-11-20');
    expect(billingDateForApi('2026-11-20'), '2026-11-20');
    expect(billingDateForApi(''), '');
    expect(billingDateForApi('not a date'), 'not a date');
  });

  test('a shown date goes back to the server unchanged (round trip)', () {
    expect(billingDateForApi(billingDateShown('2026-01-05')), '2026-01-05');
  });
}
