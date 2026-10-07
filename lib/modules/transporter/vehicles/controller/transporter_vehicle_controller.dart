import 'package:flutter/material.dart';
import '../../../../comman/api_url.dart';
import '../model/vehicle_model.dart';
import '../../drivers/model/driver_model.dart';
import '../../drivers/controller/transporter_driver_controller.dart';
import '../../../../network/api_client.dart';
import 'package:get/get.dart';

/// Vehicles of the logged-in transporter (same actions as the web "Registered Vehicles" page).
class TransporterVehicleController extends GetxController {
  var vehicles = <VehicleModel>[].obs;
  var isLoading = false.obs;
  var selectedFilter = 'all'.obs;
  var searchQuery = ''.obs;

  /// Backend statuses: available / busy / maintenance / inactive.
  static const Map<String, String> statusLabels = {
    'available': 'Available',
    'busy': 'Busy',
    'maintenance': 'Maintenance',
    'inactive': 'Inactive',
  };

  List<VehicleModel> get filteredVehicles {
    final query = searchQuery.value.trim().toLowerCase();
    return vehicles.where((v) {
      if (selectedFilter.value != 'all' && v.vehicleStatus.toLowerCase() != selectedFilter.value) return false;
      if (query.isEmpty) return true;
      return [v.vehicleNumber, v.vehicleBrandDisplay, v.modelName ?? '', v.assignedDriverName ?? '', v.vehicleType]
          .any((field) => field.toLowerCase().contains(query));
    }).toList();
  }

  int getCount(String filter) =>
      filter == 'all' ? vehicles.length : vehicles.where((v) => v.vehicleStatus.toLowerCase() == filter).length;

  @override
  void onInit() {
    super.onInit();
    fetchVehicles();
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _snack(String title, String message, Color color) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM, backgroundColor: color, colorText: Colors.white);
  }

  List<dynamic> _listFrom(dynamic response) {
    if (response is List) return response;
    if (response is Map && response['results'] is List) return response['results'];
    if (response is Map && response['data'] is List) return response['data'];
    if (response is Map && response['body'] is List) return response['body'];
    return const [];
  }

  /// Driver assignments change when vehicles change; keep the Drivers tab in sync.
  void _refreshDrivers() {
    if (Get.isRegistered<TransporterDriverController>()) Get.find<TransporterDriverController>().fetchDrivers();
  }

  Future<void> fetchVehicles() async {
    try {
      isLoading(true);
      final response = await ApiClient.get(endpoint: ApiUrls.vehicles, requireAuth: true);
      vehicles.value = _listFrom(response).whereType<Map<String, dynamic>>().map(VehicleModel.fromJson).toList();
    } catch (e) {
      _snack('Error', 'Failed to load vehicles: ${_message(e)}', Colors.red);
    } finally {
      isLoading(false);
    }
  }

  Future<VehicleModel?> fetchVehicleDetails(int id) async {
    try {
      final response = await ApiClient.get(endpoint: ApiUrls.vehicleDetails(id), requireAuth: true);
      final data = response is Map && response['body'] is Map ? response['body'] : response;
      if (data is Map<String, dynamic> && data['id'] != null) return VehicleModel.fromJson(data);
    } catch (e) {
      _snack('Error', 'Failed to load vehicle details: ${_message(e)}', Colors.red);
    }
    return null;
  }

  /// Sends JSON, or multipart when an RC file is attached (PATCH multipart for edits).
  Future<bool> saveVehicle({int? id, required Map<String, dynamic> data, String? rcFilePath}) async {
    try {
      if (rcFilePath != null && rcFilePath.isNotEmpty) {
        await ApiClient.postMultipart(
          endpoint: id == null ? ApiUrls.vehicles : ApiUrls.vehicleDetails(id),
          method: id == null ? 'POST' : 'PATCH',
          fields: {
            for (final e in data.entries)
              if (e.value != null) e.key: '${e.value}',
          },
          files: {'rc_upload': rcFilePath},
          requireAuth: true,
        );
      } else if (id == null) {
        await ApiClient.post(endpoint: ApiUrls.vehicles, body: data, requireAuth: true);
      } else {
        await ApiClient.patch(endpoint: ApiUrls.vehicleDetails(id), data: data, requireAuth: true);
      }
      _snack('Success', id == null ? 'Vehicle registered successfully' : 'Vehicle updated successfully', Colors.green);
      await fetchVehicles();
      return true;
    } catch (e) {
      _snack('Error', _message(e), Colors.red);
      return false;
    }
  }

  Future<bool> deleteVehicle(int id) async {
    try {
      await ApiClient.delete(endpoint: ApiUrls.vehicleDetails(id), requireAuth: true);
      _snack('Success', 'Vehicle deleted successfully', Colors.green);
      await fetchVehicles();
      _refreshDrivers();
      return true;
    } catch (e) {
      _snack('Error', _message(e), Colors.red);
      return false;
    }
  }

  Future<void> changeStatus(VehicleModel vehicle, String status) async {
    try {
      await ApiClient.patch(endpoint: ApiUrls.vehicleDetails(vehicle.id), data: {'vehicle_status': status}, requireAuth: true);
      _snack('Success', 'Status changed to ${statusLabels[status] ?? status}', Colors.green);
      await fetchVehicles();
    } catch (e) {
      _snack('Error', _message(e), Colors.red);
    }
  }

  /// Active drivers that are free or already on this vehicle (web "Assign Driver" list).
  Future<List<DriverModel>> fetchAssignableDrivers(VehicleModel vehicle) async {
    try {
      final response = await ApiClient.get(endpoint: "${ApiUrls.drivers}?status=active", requireAuth: true);
      return _listFrom(response)
          .whereType<Map<String, dynamic>>()
          .map(DriverModel.fromJson)
          .where((d) => d.status == 'active' && (d.assignedVehicle == null || d.assignedVehicle!.id == vehicle.id))
          .toList();
    } catch (e) {
      _snack('Error', 'Unable to load drivers: ${_message(e)}', Colors.red);
      return [];
    }
  }

  /// Same as the web form: PATCH driver_profile_id (null unassigns).
  Future<void> assignDriver(VehicleModel vehicle, int? driverId) async {
    try {
      await ApiClient.patch(
        endpoint: ApiUrls.vehicleDetails(vehicle.id),
        data: {'driver_profile_id': driverId},
        requireAuth: true,
      );
      _snack('Success', driverId == null ? 'Driver unassigned' : 'Driver assigned successfully', Colors.green);
      await fetchVehicles();
      _refreshDrivers();
    } catch (e) {
      _snack('Error', _message(e), Colors.red);
    }
  }
}
