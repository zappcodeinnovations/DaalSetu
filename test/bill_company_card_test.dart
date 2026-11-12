import 'package:daalsetu/modules/contracts/view/contract_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// MoM 14: buyer / seller choose, once, the company printed on the bill.
void main() {
  Future<void> pump(WidgetTester tester, Map<String, dynamic> info) => tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: BillCompanyCard(contractId: 5, info: info, onSaved: () {}),
          ),
        ),
      );

  testWidgets('a party who has not chosen sees the companies and a one-time Save', (tester) async {
    await pump(tester, {
      'party': 'seller',
      'can_select': true,
      'selected': false,
      'current_company_id': 2,
      'options': [
        {'id': 1, 'legal_name': 'Main Traders', 'gst_number': '27AAA', 'city': 'Pune'},
        {'id': 2, 'legal_name': 'Branch Traders', 'gst_number': '', 'city': 'Nagpur'},
      ],
    });
    expect(find.text('Choose your company for the bill'), findsOneWidget);
    expect(find.byKey(const Key('bill-company-save')), findsOneWidget);
    expect(find.text('Save (one time)'), findsOneWidget);
    // the current default is preselected
    expect(find.textContaining('Branch Traders'), findsOneWidget);
  });

  testWidgets('after choosing, only the locked company is shown', (tester) async {
    await pump(tester, {
      'party': 'buyer',
      'can_select': false,
      'selected': true,
      'buyer_company_name': 'Buyer Foods LLP',
      'options': [],
    });
    expect(find.byKey(const Key('bill-company-card')), findsNothing);
    expect(find.text('Company on the bill'), findsOneWidget);
    expect(find.text('Buyer Foods LLP'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('admins and transporters (no party) see nothing', (tester) async {
    await pump(tester, {'party': null, 'can_select': false});
    expect(find.byType(Card), findsNothing);
  });
}
