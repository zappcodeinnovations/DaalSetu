import 'package:daalsetu/utils/pdf_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the rupee sign becomes Rs. so the PDF font never shows a crossed box', () {
    expect(pdfSafeText('Deal Amount: ₹25.00'), 'Deal Amount: Rs. 25.00');
    expect(pdfSafeText('Bid: ₹ 1250'), 'Bid: Rs. 1250');
    expect(pdfSafeText('No symbol here'), 'No symbol here');
    expect(pdfSafeText(null), '');
  });
}
