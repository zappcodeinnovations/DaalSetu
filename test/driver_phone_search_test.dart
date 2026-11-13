import 'package:daalsetu/modules/transporter/bidding/model/transporter_bid_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// MoM 22: Assign Driver finds a driver by phone number.
void main() {
  const drivers = [
    FleetOption(1, 'Ramesh • 98765 01234', phone: '98765 01234', linkedVehicleId: 7,
        details: {'Name': 'Ramesh', 'License No.': 'MP09-LIC-22'}),
    FleetOption(2, 'Suresh • +91-9123400000', phone: '+91-9123400000'),
    FleetOption(3, 'Mahesh • 9123411111', phone: '9123411111'),
  ];

  test('full phone number finds one driver, ignoring spaces', () {
    final matches = FleetOption.matchByPhone(drivers, '9876501234');
    expect(matches.map((d) => d.id), [1]);
    expect(matches.first.linkedVehicleId, 7);
    expect(matches.first.details['License No.'], 'MP09-LIC-22');
  });

  test('+91 and dashes are ignored', () {
    expect(FleetOption.matchByPhone(drivers, '91234 00000').map((d) => d.id), [2]);
  });

  test('partial digits can match several drivers', () {
    expect(FleetOption.matchByPhone(drivers, '91234').map((d) => d.id), [2, 3]);
  });

  test('fewer than 4 digits or an unknown number match nothing', () {
    expect(FleetOption.matchByPhone(drivers, '912'), isEmpty);
    expect(FleetOption.matchByPhone(drivers, '7000000000'), isEmpty);
  });
}
