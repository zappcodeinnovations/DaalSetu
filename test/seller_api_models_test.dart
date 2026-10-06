import 'dart:convert';
import 'dart:io';

import 'package:daalsetu/modules/seller/branches/model/seller_branch_model.dart';
import 'package:daalsetu/modules/seller/contracts/model/seller_contract_model.dart';
import 'package:daalsetu/modules/seller/products/model/offer_interest_model.dart';
import 'package:daalsetu/modules/seller/products/model/seller_product_model.dart';
import 'package:daalsetu/modules/seller/rfq/model/seller_rfq_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Responses captured from the real backend APIs (test/fixtures/seller_api_samples.json).
Map<String, dynamic> _samples() =>
    jsonDecode(File('test/fixtures/seller_api_samples.json').readAsStringSync()) as Map<String, dynamic>;

void main() {
  final samples = _samples();

  test('parses incoming buyer requirement list rows', () {
    final row = (samples['rfq_list_incoming']['results'] as List).first as Map<String, dynamic>;
    final rfq = SellerRfqModel.fromJson(row);
    expect(rfq.rfqId, startsWith('RFQ-'));
    expect(rfq.title, 'Need Toor Daal');
    expect(rfq.canQuote, isTrue);
    expect(rfq.isQuoted, isFalse);
    expect(rfq.quotations, isEmpty);
  });

  test('parses requirement detail with only the seller\'s own quotation', () {
    final rfq = SellerRfqModel.fromJson(samples['rfq_detail_seller']['data'] as Map<String, dynamic>);
    expect(rfq.myQuotationId, isNotNull);
    expect(rfq.quotations, hasLength(1));
    expect(rfq.quotations.single.id, rfq.myQuotationId);
    expect(rfq.targetBranches, isNotEmpty);
  });

  test('parses the negotiation thread with permissions and messages', () {
    final thread = SellerQuotationModel.fromJson(samples['rfq_thread']['data'] as Map<String, dynamic>);
    expect(thread.messages, isNotEmpty);
    expect(thread.messages.first.senderRole, 'buyer');
    expect(thread.latestOfferBy, 'buyer');
    expect(thread.canAccept, isTrue);
    expect(thread.sellerDisplayId, startsWith('SEL'));
  });

  test('contract model tolerates buyer/seller sent as ids', () {
    final contract = SellerContractModel.fromJson({
      'id': 7,
      'contract_id': 'JBC2610058396',
      'buyer': 3,
      'seller': 'SEL-12',
      'display_buyer_id': 'BUY-3',
      'product_category_name': 'Toor Dal',
      'deal_amount': '1200.00',
      'deal_quantity': '1200.000',
      'status': 'active',
      'confirmed_at': '2026-10-05T19:23:00+05:30',
    });
    expect(contract.id, 7);
    expect(contract.buyerCompany, 'BUY-3');
    expect(contract.categoryName, 'Toor Dal');
  });

  test('offer interest model reads the field names the interests API sends', () {
    final interest = OfferInterestModel.fromJson({
      'id': 5,
      'buyer_unique_id': 'BUY-0003',
      'offered_amount': '1150.00',
      'required_quantity': '100.000',
      'remark': 'Need fast loading',
      'status': 'interested',
    });
    expect(interest.buyerName, 'BUY-0003');
    expect(interest.buyerOfferedAmount, '1150.00');
    expect(interest.buyerRequiredQuantity, '100.000');
    expect(interest.buyerRemark, 'Need fast loading');
  });

  test('pending branch request cancels by branch id, not request id', () {
    final pending = SellerBranchModel.fromJson({'id': 41, 'branch_id': 7, 'branch_code': 'PUN957M', 'status': 'pending'});
    final member = SellerBranchModel.fromJson({'id': 7, 'branch_code': 'PUN957M'});
    expect(pending.branchId, 7);
    expect(member.branchId, 7);
  });

  test('product model reads is_active for the activate/deactivate menu', () {
    final product = SellerProductModel.fromJson({
      'id': 1,
      'title': 'Toor Daal',
      'amount': '1200',
      'status': 'available',
      'is_active': false,
    });
    expect(product.isActive, isFalse);
  });
}
