import 'package:daalsetu/utils/input_validators.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vehicle number follows the Indian MH 12 AB 1234 structure', () {
    for (final ok in ['MH31AB1234', 'mh 12 ab 1234', 'MH12A1234', 'DL1CAB1234', 'MH31AB1243', '22BH1234AB']) {
      expect(InputValidators.vehicleNumber(ok), isNull, reason: ok);
    }
    for (final bad in ['1234', 'MHAB1234', 'MH12AB12', 'MH12AB12345', 'ABCDEFGH']) {
      expect(InputValidators.vehicleNumber(bad), isNotNull, reason: bad);
    }
    expect(InputValidators.vehicleNumber('', required: true), isNotNull);
    expect(InputValidators.compactVehicleNumber('mh 12-ab 1234'), 'MH12AB1234');
  });

  test('driving licence is 2 letters + 13 digits', () {
    expect(InputValidators.licenseNumber('MH1220110062821'), isNull);
    expect(InputValidators.licenseNumber('mh12 2011 0062821'), isNull);
    expect(InputValidators.licenseNumber('1234567890123456'), isNotNull);
    expect(InputValidators.licenseNumber('MH12201100628'), isNotNull);
    expect(InputValidators.licenseNumber('MH12201100628212'), isNotNull);
  });

  String typed(TextInputFormatter formatter, String text) {
    var current = TextEditingValue.empty;
    for (final char in text.split('')) {
      current = formatter.formatEditUpdate(
        current,
        TextEditingValue(text: current.text + char, selection: TextSelection.collapsed(offset: current.text.length + 1)),
      );
    }
    return current.text;
  }

  test('typing a vehicle number only lets a valid beginning through', () {
    expect(typed(IndianIdInputFormatter.vehicle(), 'mh12ab1234'), 'MH12AB1234');
    expect(typed(IndianIdInputFormatter.vehicle(), 'MH 31-AB 1234'), 'MH31AB1234');
    expect(typed(IndianIdInputFormatter.vehicle(), 'GSJABJABSUSB'), 'GS'); // digits are needed after the state
    expect(typed(IndianIdInputFormatter.vehicle(), 'M1H'), 'MH'); // a digit cannot sit inside the state letters
    expect(typed(IndianIdInputFormatter.vehicle(), 'MH12AB12345'), 'MH12AB1234'); // 4 digits at the end, no more
    expect(typed(IndianIdInputFormatter.vehicle(), 'MH123'), 'MH12'); // letters must follow the district
    expect(typed(IndianIdInputFormatter.vehicle(), '22BH1234AB'), '22BH1234AB');
  });

  test('typing a licence number: 2 letters, then up to 13 digits, nothing else', () {
    expect(typed(IndianIdInputFormatter.license(), 'mh1220110062821'), 'MH1220110062821');
    expect(typed(IndianIdInputFormatter.license(), 'HHNSNS27288283HDJ'), 'HH27288283'); // letters after the state are refused
    expect(typed(IndianIdInputFormatter.license(), 'MH12201100628219999'), 'MH1220110062821');
    expect(typed(IndianIdInputFormatter.license(), '1234'), '');
    expect(InputValidators.licenseNumber(typed(IndianIdInputFormatter.license(), 'MH1220110062821')), isNull);
  });

  test('the vehicle error message is short enough to read and does not repeat the label hint', () {
    final message = InputValidators.vehicleNumber('ABC', label: 'Vehicle number');
    expect(message, 'Enter a valid vehicle number, like MH12AB1234');
  });
}
