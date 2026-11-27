import 'package:daalsetu/utils/mobile_number_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a mobile is 10 digits; an autofilled +91 / 0 is dropped, not cut into a wrong number', () {
    expect(cleanMobileNumber('07999840591'), '7999840591');
    expect(cleanMobileNumber('+91 79998 40591'), '7999840591');
    expect(cleanMobileNumber('917999840591'), '7999840591');
    expect(cleanMobileNumber('7999840591'), '7999840591');
    expect(cleanMobileNumber('79998'), '79998'); // still typing
    expect(mobileNumberError('7999840591'), isNull);
    expect(mobileNumberError('0799984059'), isNotNull);
    expect(mobileNumberError('799984059'), isNotNull);
  });
}
