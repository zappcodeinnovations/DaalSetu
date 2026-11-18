import 'package:daalsetu/modules/buyer/consignment/view/buyer_consignment_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the API sends for every consignment: received_label is "Pending" until delivery, so the
/// card must be decided from the real stage, not from that label.
Map<String, dynamic> item({String status = 'active', bool dispatched = false, bool delivered = false, String? visibleAt}) => {
  'status': status,
  'is_dispatched': dispatched,
  'is_delivered': delivered,
  'transporter_visible_at': visibleAt,
  'ready_label': visibleAt == null ? 'Pending' : 'Ready',
  'received_label': delivered ? 'Received' : 'Pending',
};

void main() {
  test('each stage shows its own status, not Pending', () {
    expect(consignmentStageLabel(item()), 'Pending');
    expect(consignmentStageLabel(item(visibleAt: '2026-11-18T10:00:00')), 'Consignment Ready');
    expect(consignmentStageLabel(item(visibleAt: '2026-11-18T10:00:00', dispatched: true)), 'Dispatch');
    expect(consignmentStageLabel(item(status: 'received', delivered: true, dispatched: true)), 'Consignment Received');
    expect(consignmentStageLabel(item(delivered: true)), 'Consignment Received');
  });
}
