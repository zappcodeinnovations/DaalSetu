import '../../../../comman/api_url.dart';
import '../model/driver_model.dart';
import '../../../../network/api_client.dart';
import 'package:get/get.dart';

class TransporterDriverController extends GetxController {
  var drivers = <DriverModel>[].obs;
  var isLoading = false.obs;
  var selectedFilter = 'All'.obs;

  bool _isAssigned(DriverModel d) =>
      d.assignmentStatus.toLowerCase() == 'assigned' || d.assignedVehicle != null;

  List<DriverModel> get filteredDrivers {
    if (selectedFilter.value == 'All') return drivers;
    if (selectedFilter.value == 'Active') {
      return drivers
          .where((d) => d.status.toLowerCase() == 'active' && _isAssigned(d))
          .toList();
    }
    if (selectedFilter.value == 'Inactive') {
      return drivers.where((d) => d.status.toLowerCase() == 'inactive').toList();
    }
    if (selectedFilter.value == 'Unassigned') {
      return drivers
          .where((d) => d.status.toLowerCase() == 'active' && !_isAssigned(d))
          .toList();
    }
    return drivers;
  }

  int getCount(String filter) {
    if (filter == 'All') return drivers.length;
    if (filter == 'Active') {
      return drivers
          .where((d) => d.status.toLowerCase() == 'active' && _isAssigned(d))
          .length;
    }
    if (filter == 'Inactive') {
      return drivers.where((d) => d.status.toLowerCase() == 'inactive').length;
    }
    if (filter == 'Unassigned') {
      return drivers
          .where((d) => d.status.toLowerCase() == 'active' && !_isAssigned(d))
          .length;
    }
    return 0;
  }

  @override
  void onInit() {
    super.onInit();
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    try {
      isLoading(true);
      final response = await ApiClient.get(
        endpoint: ApiUrls.drivers,
        requireAuth: true,
      );

      // Assuming API returns a List directly or wrapped in a data/body key.
      if (response != null) {
        List<dynamic> dataList = [];
        if (response is List) {
          dataList = response;
        } else if (response is Map && response.containsKey('data')) {
          dataList = response['data'];
        } else if (response is Map && response.containsKey('body')) {
          dataList = response['body'];
        }

        drivers.value = dataList.map((json) => DriverModel.fromJson(json)).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load drivers: $e', snackPosition: SnackPosition.BOTTOM);
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

      if (response != null) {
        var data = response;
        if (response is Map && response.containsKey('body')) {
          data = response['body'];
        }
        if (data['id'] != null) {
          return DriverModel.fromJson(data);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load driver details: $e', snackPosition: SnackPosition.BOTTOM);
    }
    return null;
  }

  Future<bool> createDriver(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post(
        endpoint: ApiUrls.drivers,
        body: data,
        requireAuth: true,
      );

      if (response != null) {
        Get.snackbar('Success', 'Driver created successfully', snackPosition: SnackPosition.BOTTOM);
        await fetchDrivers();
        return true;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create driver: $e', snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }

  Future<bool> updateDriver(int id, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.patch(
        endpoint: ApiUrls.driverDetails(id),
        data: data,
        requireAuth: true,
      );

      if (response != null) {
        Get.snackbar('Success', 'Driver updated successfully', snackPosition: SnackPosition.BOTTOM);
        await fetchDrivers();
        return true;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update driver: $e', snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }

  Future<void> deleteDriver(int id) async {
    try {
      final response = await ApiClient.delete(
        endpoint: ApiUrls.driverDetails(id),
        requireAuth: true,
      );

      if (response != null) {
        Get.snackbar('Success', 'Driver deleted successfully', snackPosition: SnackPosition.BOTTOM);
        await fetchDrivers();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete driver: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<bool> assignVehicle(int driverId, int vehicleId) async {
    try {
      final response = await ApiClient.post(
        endpoint: ApiUrls.assignVehicle(driverId),
        body: {'vehicle_id': vehicleId},
        requireAuth: true,
      );

      if (response != null) {
        Get.snackbar('Success', 'Vehicle assigned successfully', snackPosition: SnackPosition.BOTTOM);
        await fetchDrivers();
        return true;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to assign vehicle: $e', snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }
}
