import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Name is the person, Company stays the company', () {
    // buyer_name is the company display name; the person comes separately.
    expect(contractPersonName('Rajesh Kumar', 'Mariegold farm'), 'Rajesh Kumar');
    expect(contractCompanyName('Test company', 'Mariegold farm', 'Rajesh Kumar'),
        'Test company');
  });

  test('no person from the API falls back to the display name', () {
    expect(contractPersonName(null, 'Mariegold farm'), 'Mariegold farm');
    expect(contractPersonName('  ', 'Mariegold farm'), 'Mariegold farm');
  });

  test('company falls back to the display name unless that is only the person', () {
    expect(contractCompanyName(null, 'Mariegold farm', 'Rajesh Kumar'), 'Mariegold farm');
    expect(contractCompanyName('', 'Rajesh Kumar', 'Rajesh Kumar'), '');
  });
}
