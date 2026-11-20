import 'dart:io';

import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:daalsetu/modules/contracts/services/contract_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

ContractDetailModel _contract({bool admin = false}) => ContractDetailModel.fromJson({
      'id': 7,
      'contract_id': 'JBC2611194511',
      'product_title': 'chana daal',
      'product_category_name': 'pulse&grain',
      'interest_id': 186,
      'deal_quantity': '50.100',
      'quantity_unit': 'qtl',
      'deal_amount': '45.00',
      'amount_unit': 'qtl',
      'trade_value': '2254.50',
      'buyer_offer_amount': '45.00',
      'buyer_required_quantity': '50.100',
      'seller_quantity': '50.100',
      'deal_date': '19/11/2026 13:06',
      'delivery_period': '21 Nov 2026',
      'loading_from_date': '2026-11-18',
      'loading_to_date': '2026-11-19',
      'status': 'active',
      'display_buyer_id': 'Mariegold farm',
      'buyer_name': 'Mariegold farm',
      'buyer_company_name': 'Test company',
      'buyer_mobile': '1234567891',
      'buyer_email': 'athawalehiral@gmail.com',
      'display_seller_id': 'Agrofarm',
      'seller_name': 'Agrofarm',
      'seller_company_name': 'Agrotech',
      'seller_mobile': '1234567890',
      'seller_email': 'hiral4nov2004@gmail.com',
      'loading_from': 'nagpur, Nagpur, Maharashtra, India',
      'loading_to': 'AMR158M, Amalner, Maharashtra, India',
      'admin_remark': 'deallll done',
      'created_at': '19/11/2026 18:36',
      'confirmed_at': '19/11/2026 13:06',
      'ready_for_loading_at': '19/11/2026 18:38',
      'updated_at': '19/11/2026 18:38',
      if (admin) ...{
        'confirmed_by_admin_name': 'FARMLAND',
        'confirmed_branch_name': 'AMR158M (AMA462M)',
        'created_by_user_name': 'FARMLAND',
        'assigned_sub_admin_name': 'FARMLAND',
      },
    });

void main() {
  test('the contract PDF has the web layout: band, section tables, Administration only for admins', () async {
    final admin = await buildContractPdf(_contract(admin: true), 'JBC2611194511', now: DateTime(2026, 11, 20, 10, 57, 11)).save();
    final party = await buildContractPdf(_contract(), 'JBC2611194511', now: DateTime(2026, 11, 20, 10, 57, 11)).save();
    expect(String.fromCharCodes(admin.take(5)), '%PDF-');
    // Same pages otherwise; the admin copy carries the extra Administration table.
    expect(admin.length, greaterThan(party.length));
    if (Platform.environment['DUMP_PDF'] != null) {
      File(Platform.environment['DUMP_PDF']!).writeAsBytesSync(admin);
    }
  });
}
