import 'package:agro_broker/modules/contracts/model/contract_details_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves all admin contract detail fields', () {
    final contract = ContractDetailModel.fromJson({
      'id': 68,
      'contract_id': 'JBC2607288709',
      'product_title': 'Rice',
      'product_category_name': 'Basmati Rice +',
      'buyer_name': '9699828570',
      'buyer_unique_id': 'BUY-1',
      'seller_name': '8524567913',
      'seller_mapped_id': 'SEL-1',
      'display_seller_id': 'Seller',
      'display_buyer_id': 'Buyer',
      'quantity_qtl': '900.000',
      'bags': '600.000',
      'deal_amount': '45.00',
      'deal_quantity': '900.000',
      'amount_unit': 'ton',
      'quantity_unit': 'qtl',
      'bag_count': 600,
      'packing_weight_kg': '150.000',
      'loading_from': 'Pune',
      'loading_to': 'Nagpur',
      'buyer_remark': 'Good quality',
      'seller_remark': '',
      'admin_remark': '',
      'confirmed_at': '2026-07-28T17:35:30+05:30',
      'transporter_visible_at': '2026-07-28T17:35:44+05:30',
      'transporter_visibility_reason': 'seller_ready',
      'ready_for_loading_at': '2026-07-28T17:35:44+05:30',
      'created_at': '2026-07-28T17:35:30+05:30',
      'updated_at': '2026-07-28T17:35:44+05:30',
      'status': 'active',
      'interest': 105,
      'product': 105,
      'buyer': 112,
      'seller': 111,
      'confirmed_by_admin': 84,
      'confirmed_branch': 22,
      'created_by_user': 84,
      'assigned_sub_admin': 117,
      'ready_for_loading_by': 84,
    });

    expect(contract.contractId, 'JBC2607288709');
    expect(contract.bagCount, 600);
    expect(contract.confirmedBranchId, 22);
    expect(contract.transporterVisibilityReason, 'seller_ready');
    expect(contract.assignedSubAdminId, 117);
  });
}
