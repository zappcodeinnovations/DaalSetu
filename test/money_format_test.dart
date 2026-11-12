import 'package:daalsetu/utils/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rupee amounts use Indian grouping and two decimals', () {
    expect(formatInr('43637.967'), '₹43,637.97'); // admin GTV used to show "₹43637.967"
    expect(formatInr('4950.00000'), '₹4,950.00'); // seller consignment trade value
    expect(formatInr(1250000), '₹12,50,000.00');
    expect(formatInr(null), '-');
    expect(formatInr('n/a'), 'n/a');
  });

  test('chart axis labels stay readable for small values', () {
    expect(compactInr(850), '850'); // used to read "0k"
    expect(compactInr(2500), '2.5k');
    expect(compactInr(45000), '45k');
    expect(compactInr(250000), '2.5L');
  });
}
