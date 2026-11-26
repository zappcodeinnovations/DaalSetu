import 'dart:io';

import 'package:daalsetu/modules/admin_dc/model/admin_challan_model.dart';
import 'package:daalsetu/modules/buyer/delivery_challan/model/buyer_delivery_challan_model.dart';
import 'package:daalsetu/modules/buyer/delivery_challan/service/buyer_challan_pdf_service.dart';
import 'package:daalsetu/modules/dashboard/view/dashboard_page.dart';
import 'package:flutter_test/flutter_test.dart';

// The admin API payload (same serializer as the web challan page).
final _json = <String, dynamic>{
  'id': 3,
  'challan_number': 'DC-20261120-0003',
  'challan_date': '2026-11-20',
  'status': 'dispatched',
  'truck_number': 'MH31DC1234',
  'driver_name': 'billu',
  'driver_mobile': '9876525806',
  'seller_name': 'Agrofarm',
  'seller_company_name': 'shree balaji',
  'buyer_name': 'Mariegold farm',
  'buyer_company_name': 'Test company',
  'buyer_address': 'test address, Nagpur, Maharashtra, 400001, India',
  'transporter_name_display': 'Wildernest Test',
  'created_by_name': 'FARMLAND',
  'company': {
    'legal_name': 'FARMLAND',
    'gst_number': '23ABVSC1223F1Z4',
    'pan_number': 'ABVSC1223F',
  },
  'total_amount': '12000.00',
  'items': [
    {'product_name': 'til', 'quantity': '100.000', 'unit': 'QTL', 'bag_count': 200, 'packing_weight_kg': '50.000', 'rate': '120.00', 'amount': '12000.00'},
  ],
};

void main() {
  test('the admin challan keeps its server JSON for the web-format PDF', () {
    final challan = AdminChallanModel.fromJson(_json);
    expect(challan.raw['buyer_name'], 'Mariegold farm');
  });

  test('the web-format challan PDF builds from an admin challan', () async {
    final challan = AdminChallanModel.fromJson(_json);
    final bytes = await BuyerChallanPdfService.buildPdf(
      BuyerDeliveryChallanModel.fromJson(challan.raw),
      ownPhoneAsBuyerPhone: false,
    );
    expect(bytes.length, greaterThan(1000));
    final out = Platform.environment['CHALLAN_PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });

  test('a challan never shows its database id', () {
    final challan = AdminChallanModel.fromJson({'id': 57, 'order': 91, 'contract_id': 33});
    expect(challan.displayChallanNo, '-');
    expect(challan.displayContract, '-');
    expect(AdminChallanModel.fromJson(_json).displayChallanNo, 'DC-20261120-0003');
  });

  test('the Transporter SLA shows one decimal like the web', () {
    expect(slaPercentText(76.923), '76.9');
    expect(slaPercentText(100), '100');
    expect(slaPercentText(0), '0');
  });
}
