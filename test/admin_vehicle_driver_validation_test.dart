import 'package:daalsetu/utils/input_validators.dart';
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
}
