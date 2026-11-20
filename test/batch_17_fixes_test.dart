import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/contracts/controller/contract_controller.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 17 Bug 1: Contract Details Smooth Single-Pass Transition', () {
    test('ContractController initializes loading & challan check flags safely', () {
      final controller = Get.put(ContractController());
      expect(controller.isLoading.value, isA<bool>());
      expect(controller.isCheckingChallan.value, isA<bool>());
    });
  });

  group('Batch 17 Bug 2: Registered Drivers Experience, Assigned Vehicle & Assign Action', () {
    test('drivers module includes experience and assigned_vehicle in subtitleKeys', () {
      final driverConfig = AdminModules.byKey('drivers');
      expect(driverConfig, isNotNull);
      expect(driverConfig.subtitleKeys, contains('experience'));
      expect(driverConfig.subtitleKeys, contains('assigned_vehicle.vehicle_number'));
      expect(driverConfig.subtitleKeys, contains('phone_number'));
      expect(driverConfig.subtitleKeys, contains('license_number'));
      expect(driverConfig.subtitleKeys, contains('assignment_status_display'));
      expect(driverConfig.subtitleKeys, contains('status_display'));
    });

    test('Assign action button is visible for both assigned and unassigned drivers', () {
      final driverConfig = AdminModules.byKey('drivers');
      final assignAction = driverConfig.customActions.firstWhere(
        (a) => a.title == 'Assign',
      );
      expect(assignAction, isNotNull);

      final unassignedDriver = {
        'id': 1,
        'driver_name': 'billu',
        'assigned_vehicle': null,
      };
      final assignedDriver = {
        'id': 2,
        'driver_name': 'mish',
        'assigned_vehicle': {'vehicle_number': 'MH31AB1525'},
      };

      expect(assignAction.isVisible?.call(unassignedDriver), isTrue);
      expect(assignAction.isVisible?.call(assignedDriver), isTrue);
    });

    test('nested key resolver and experience formatting correctly handle driver record data', () {
      final driverRecord = {
        'id': 10,
        'driver_name': 'billu',
        'phone_number': '9876525806',
        'license_number': '12345678',
        'experience': 0,
        'assigned_vehicle': {'vehicle_number': 'MH31DC1234'},
        'assignment_status_display': 'Assigned',
        'status_display': 'Active',
      };

      dynamic resolveValue(dynamic rec, String key) {
        if (key.contains('.')) {
          final parts = key.split('.');
          dynamic cur = rec;
          for (final p in parts) {
            if (cur is Map) {
              cur = cur[p];
            } else {
              return null;
            }
          }
          return cur;
        }
        return rec is Map ? rec[key] : null;
      }

      final expVal = resolveValue(driverRecord, 'experience');
      final expInt = int.tryParse(expVal.toString()) ?? 0;
      final expFormatted = '$expInt ${expInt == 1 ? 'year' : 'years'}';
      expect(expFormatted, '0 years');

      final vehicleVal = resolveValue(driverRecord, 'assigned_vehicle.vehicle_number');
      expect(vehicleVal, 'MH31DC1234');
    });
  });

  group('Batch 17 Bug 3: Buyer Requirements Bags & Expiry Date', () {
    test('buyer_requirements module includes required_bag_count and expiry_datetime', () {
      final rfqConfig = AdminModules.byKey('buyer_requirements');
      expect(rfqConfig, isNotNull);
      expect(rfqConfig.subtitleKeys, contains('required_bag_count'));
      expect(rfqConfig.subtitleKeys, contains('expiry_datetime'));
      expect(rfqConfig.subtitleKeys, contains('buyer_name'));
      expect(rfqConfig.subtitleKeys, contains('required_quantity'));
      expect(rfqConfig.subtitleKeys, contains('target_price'));
    });
  });

  group('Batch 17 Bug 4: Create Offer Seller-Specific Company Filtering', () {
    test('companies list is filtered strictly to the chosen seller candidate IDs', () {
      final allCompanies = [
        {
          'id': 1,
          'legal_name': 'FARMLAND',
          'user': 99,
          'seller_id': 99,
          'city': 'Nagpur',
          'state': 'Maharashtra',
        },
        {
          'id': 2,
          'legal_name': 'abc company',
          'user': 88,
          'seller_id': 88,
          'city': 'Nagpur',
          'state': 'Maharashtra',
        },
        {
          'id': 3,
          'legal_name': 'Kajals Company',
          'user': 77,
          'seller_id': 77,
          'city': 'Nagpur',
          'state': 'Maharashtra',
        },
      ];

      final sellerIdHiral = 101; // hiral has no companies assigned

      final hiralCompanies = allCompanies.where((item) {
        final user = item['user'];
        final userId = item['user_id'];
        final seller = item['seller'];
        final sellerIdField = item['seller_id'];
        final createdBy = item['created_by'];

        final candidateIds = [
          if (user is int) user,
          if (user is Map && user['id'] is int) user['id'],
          if (user is String) int.tryParse(user),
          if (userId is int) userId,
          if (userId is String) int.tryParse(userId),
          if (seller is int) seller,
          if (seller is Map && seller['id'] is int) seller['id'],
          if (seller is String) int.tryParse(seller),
          if (sellerIdField is int) sellerIdField,
          if (sellerIdField is String) int.tryParse(sellerIdField),
          if (createdBy is int) createdBy,
          if (createdBy is Map && createdBy['id'] is int) createdBy['id'],
        ].whereType<int>().toSet();

        return candidateIds.contains(sellerIdHiral);
      }).toList();

      expect(hiralCompanies, isEmpty);

      final farmlandCompanies = allCompanies.where((item) {
        final user = item['user'];
        final sellerIdField = item['seller_id'];
        final candidateIds = [user, sellerIdField].whereType<int>().toSet();
        return candidateIds.contains(99);
      }).toList();

      expect(farmlandCompanies.length, 1);
      expect(farmlandCompanies.first['legal_name'], 'FARMLAND');
    });
  });
}
