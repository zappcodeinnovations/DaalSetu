import 'package:daalsetu/modules/contracts/model/contract_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// MoM 15: the contract list flags contracts that have new transport bids.
void main() {
  test('active bid count is read from the contract list API', () {
    final withBids = ContractModel.fromJson({'id': 1, 'contract_id': 'JBC1', 'status': 'active', 'active_bid_count': 2});
    final withoutField = ContractModel.fromJson({'id': 2, 'contract_id': 'JBC2', 'status': 'active'});
    expect(withBids.activeBidCount, 2);
    expect(withoutField.activeBidCount, 0);
  });
}
