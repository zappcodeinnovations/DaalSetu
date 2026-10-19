import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared contract details avoid inaccessible consignment requests', () {
    final viewSource = File(
      'lib/modules/seller/contracts/view/seller_contract_detail_view.dart',
    ).readAsStringSync();
    final serviceSource = File(
      'lib/services/seller_services.dart',
    ).readAsStringSync();

    expect(viewSource, contains("AppPreferences.getRole()"));
    expect(viewSource, contains("'seller',"));
    expect(viewSource, isNot(contains("'transporter',")));
    expect(viewSource, contains('canAccessConsignments && isConsignmentStatus'));
    expect(
      viewSource,
      contains('getContractDetails(widget.contractId, silent: true)'),
    );
    expect(viewSource, contains('silent: true'));
    expect(serviceSource, contains('suppressErrorDialog: silent'));
  });
}
