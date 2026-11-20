import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('User KYCs: Approve and Reject are offered for every KYC status (like the web review page)', () {
    final actions = AdminModules.byKey('kyc').customActions;
    final titles = actions.map((a) => a.title).toList();
    expect(titles, containsAll(['Approve', 'Reject']));
    for (final status in ['pending', 'approved', 'rejected']) {
      for (final action in actions.where((a) => a.title == 'Approve' || a.title == 'Reject')) {
        final visible = action.isVisible?.call({'id': 1, 'kyc_status': status}) ?? true;
        expect(visible, isTrue, reason: '${action.title} for $status');
      }
    }
  });
}
