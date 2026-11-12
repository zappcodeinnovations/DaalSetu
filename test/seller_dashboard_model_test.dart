import 'package:daalsetu/modules/seller/dashboard/model/seller_dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seller dashboard accepts decimal strings returned by the API', () {
    final dashboard = SellerDashboardModel.fromJson({
      'header': {'profile_completion': '75'},
      'kpis': [],
      'charts': {
        'commodity_mix': [
          {
            'product__category__category_name': 'Pulses',
            'volume': '12.50',
          },
        ],
        'deal_pipeline': {'Requested': 2},
      },
      'recent_contracts': [
        {
          'id': '7',
          'deal_quantity': '20.25',
          'deal_amount': '4050.75',
        },
      ],
      'recent_deals': [
        {
          'id': '9',
          'requested_amount': '210.50',
          'requested_quantity': '15.75',
        },
      ],
    });

    expect(dashboard.header.profileCompletion, 75);
    expect(dashboard.charts.commodityMix.single.volume, 12.5);
    expect(dashboard.recentContracts.single.id, 7);
    expect(dashboard.recentContracts.single.dealQuantity, 20.25);
    expect(dashboard.recentContracts.single.dealAmount, 4050.75);
    expect(dashboard.recentDeals.single.requestedAmount, 210.5);
    expect(dashboard.recentDeals.single.requestedQuantity, 15.75);
  });
}
