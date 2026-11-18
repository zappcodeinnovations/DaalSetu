import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:daalsetu/modules/contracts/services/contract_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the contract PDF renders with the grid layout and Buyer / Seller cards', () async {
    final contract = ContractDetailModel.fromJson({
      'id': 7,
      'contract_id': 'JBC2611171685',
      'product_title': 'arhar daal',
      'deal_quantity': '80.000',
      'quantity_unit': 'qtl',
      'deal_amount': '81.00',
      'amount_unit': 'qtl',
      'status': 'active',
      'buyer_name': 'Mariegold farm',
      'buyer_company_name': 'Test company',
      'buyer_email': 'rajesh@gmail.com',
      'seller_name': 'Agrofarm',
      'seller_company_name': 'Agrotech',
      'seller_email': 'umesh@gmail.com',
      'loading_from': 'nagpur, Nagpur, Maharashtra, India',
      'loading_to': 'nagpur',
      'confirmed_at': '17-11-2026 13:54',
    });
    final bytes = await buildContractPdf(contract, 'JBC2611171685').save();
    // The body (deal grid, Buyer / Seller cards, route) is there, not just the header band:
    // a header-only PDF was ~2.3 KB and opened as a blank page.
    expect(bytes.length, greaterThan(4100));
    // A real PDF file.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('missing details print as a dash instead of failing', () async {
    final contract = ContractDetailModel.fromJson({'id': 1});
    final bytes = await buildContractPdf(contract, 'Contract_1').save();
    expect(bytes, isNotEmpty);
  });
}
