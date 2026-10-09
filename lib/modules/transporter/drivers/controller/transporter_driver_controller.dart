import 'package:flutter/material.dart';
import '../../../../comman/api_url.dart';
import '../model/driver_model.dart';
import '../../vehicles/model/vehicle_model.dart';
import '../../vehicles/controller/transporter_vehicle_controller.dart';
import '../../../../network/api_client.dart';
import '../../../../utils/app_preferences.dart';
import 'package:get/get.dart';

/// Drivers of the logged-in transporter (same actions as the web "Registered Drivers" page).
class TransporterDriverController extends GetxController {
  var drivers = <DriverModel>[].obs;
  var isLoading = false.obs;
  var selectedFilter = 'all'.obs;
  var searchQuery = ''.obs;

  /// Web filter: All / Active / Inactive; "unassigned" = active without a vehicle.
  static const Map<String, String> filterLabels = {
    'all': 'All',
    'active': 'Active',
    'unassigned': 'Unassigned',
    'inactive': 'Inactive',
  };

  bool _matchesFilter(DriverModel d, String filter) {
    final status = d.status.toLowerCase();
    switch (filter) {
      case 'active':
        return status == 'active';
      case 'inactive':
        return status == 'inactive';
      case 'unassigned':
        return status == 'active' && d.assignedVehicle == null;
      default:
        return true;
    }
  }

  List<DriverModel> get filteredDrivers {
    final query = searchQuery.value.trim().toLowerCase();
    return drivers.where((d) {
      if (!_matchesFilter(d, selectedFilter.value)) return false;
      if (query.isEmpty) return true;
      return [
        d.driverName,
        d.phoneNumber,
        d.licenseNumber,
        d.assignedVehicle?.vehicleNumber ?? '',
      ].any((field) => field.toLowerCase().contains(query));
    }).toList();
  }

  int getCount(String filter) =>
      drivers.where((d) => _matchesFilter(d, filter)).length;

  @override
  void onInit() {
    super.onInit();
    fetchDrivers();
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _snack(String title, String message, Color color) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color,
      colorText: Colors.white,
    );
  }

  List<dynamic> _listFrom(dynamic response) {
    if (response is List) return response;
    if (response is Map && response['results'] is List)
      return response['results'];
    if (response is Map && response['data'] is List) return response['data'];
    if (response is Map && response['body'] is List) return response['body'];
    return const [];
  }

  /// The web form always associates a new driver with the active transporter.
  /// Include that association explicitly as well: older deployed API builds
  /// require `transporter_id` even for a transporter-authenticated request.
  Future<Map<String, dynamic>> _createPayload(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    final selectedTransporter = payload['transporter_id']?.toString().trim();
    if (selectedTransporter?.isNotEmpty ?? false) return payload;

    final userId = (await AppPreferences.getUserId())?.trim() ?? '';
    if (int.tryParse(userId) != null) {
      payload['transporter_id'] = userId;
    }
    return payload;
  }

  /// Vehicle status/driver change when a driver's assignment changes; keep the Vehicles tab in sync.
  void _refreshVehicles() {
    if (Get.isRegistered<TransporterVehicleController>())
      Get.find<TransporterVehicleController>().fetchVehicles();
  }

  Future<void> fetchDrivers() async {
    try {
      isLoading(true);
      final response = await ApiClient.get(
        endpoint: ApiUrls.drivers,
        requireAuth: true,
      );
      drivers.value = _listFrom(
        response,
      ).whereType<Map<String, dynamic>>().map(DriverModel.fromJson).toList();
    } catch (e) {
      _snack('Error', 'Failed to load drivers: ${_message(e)}', Colors.red);
    } finally {
      isLoading(false);
    }
  }

  Future<DriverModel?> fetchDriverDetails(int id) async {
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.driverDetails(id),
        requireAuth: true,
      );
      final data = response is Map && response['body'] is Map
          ? response['body']
          : response;
      if (data is Map<String, dynamic> && data['id'] != null)
        return DriverModel.fromJson(data);
    } catch (e) {
      _snack(
        'Error',
        'Failed to load driver details: ${_message(e)}',
        Colors.red,
      );
    }
    return null;
  }

  /// Sends JSON, or multipart when a license file is attached (PATCH multipart for edits).
  Future<bool> saveDriver({
    int? id,
    required Map<String, dynamic> data,
    String? licenseFilePath,
  }) async {
    try {
      final payload = id == null ? await _createPayload(data) : data;
      if (licenseFilePath != null && licenseFilePath.isNotEmpty) {
        await ApiClient.postMultipart(
          endpoint: id == null ? ApiUrls.drivers : ApiUrls.driverDetails(id),
          method: id == null ? 'POST' : 'PATCH',
          fields: {
            for (final e in payload.entries)
              if (e.value != null) e.key: '${e.value}',
          },
          files: {'license_upload': licenseFilePath},
          requireAuth: true,
        );
      } else if (id == null) {
        await ApiClient.post(
          endpoint: ApiUrls.drivers,
          body: payload,
          requireAuth: true,
        );
      } else {
        await ApiClient.patch(
          endpoint: ApiUrls.driverDetails(id),
          data: data,
          requireAuth: true,
        );
      }
      _snack(
        'Success',
        id == null
            ? 'Driver registered successfully'
            : 'Driver updated successfully',
        Colors.green,
      );
      await fetchDrivers();
      _refreshVehicles();
      return true;
    } catch (e) {
      _snack('Error', _message(e), Colors.red);
      return false;
    }
  }

  Future<bool> deleteDriver(int id) async {
    try {
      await ApiClient.delete(
        endpoint: ApiUrls.driverDetails(id),
        requireAuth: true,
      );
      _snack('Success', 'Driver deleted successfully', Colors.green);
      await fetchDrivers();
      _refreshVehicles();
      return true;
    } catch (e) {
      _snack('Error', _message(e), Colors.red);
      return false;
    }
  }

  /// Backend only accepts available vehicles without another driver (plus the driver's current one).
  Future<List<VehicleModel>> fetchAssignableVehicles(DriverModel driver) async {
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.vehicles,
        requireAuth: true,
      );
      return _listFrom(response)
          .whereType<Map<String, dynamic>>()
          .map(VehicleModel.fromJson)
          .where(
            (v) =>
                v.id == driver.assignedVehicle?.id ||
                (v.vehicleStatus == 'available' && !v.hasDriver),
          )
          .toList();
    } catch (e) {
      _snack('Error', 'Unable to load vehicles: ${_message(e)}', Colors.red);
      return [];
    }
  }

  /// POST `/api/drivers/{id}/assign-vehicle/`; a null vehicleId unassigns.
  Future<bool> assignVehicle(int driverId, int? vehicleId) async {
    try {
      await ApiClient.post(
        endpoint: ApiUrls.assignVehicle(driverId),
        body: {'vehicle_id': vehicleId},
        requireAuth: true,
      );
      _snack(
        'Success',
        vehicleId == null
            ? 'Vehicle unassigned'
            : 'Vehicle assigned successfully',
        Colors.green,
      );
      await fetchDrivers();
      _refreshVehicles();
      return true;
    } catch (e) {
      _snack('Error', _message(e), Colors.red);
      return false;
    }
  }
}
