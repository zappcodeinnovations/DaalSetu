import '../../../../comman/api_url.dart';
import '../model/vehicle_model.dart';
import '../../../../network/api_client.dart';
import 'package:get/get.dart';

class TransporterVehicleController extends GetxController {
  var vehicles = <VehicleModel>[].obs;
  var isLoading = false.obs;
  var selectedFilter = 'All'.obs;

  List<VehicleModel> get filteredVehicles {
    if (selectedFilter.value == 'All') return vehicles;
    if (selectedFilter.value == 'Active') return vehicles.where((v) => v.vehicleStatus.toLowerCase() == 'active').toList();
    if (selectedFilter.value == 'In Transit') return vehicles.where((v) => v.vehicleStatusDisplay.toLowerCase() == 'in transit').toList();
    if (selectedFilter.value == 'Maintenance') return vehicles.where((v) => v.vehicleStatusDisplay.toLowerCase() == 'maintenance').toList();
    return vehicles;
  }

  int getCount(String filter) {
    if (filter == 'All') return vehicles.length;
    if (filter == 'Active') return vehicles.where((v) => v.vehicleStatus.toLowerCase() == 'active').length;
    if (filter == 'In Transit') return vehicles.where((v) => v.vehicleStatusDisplay.toLowerCase() == 'in transit').length;
    if (filter == 'Maintenance') return vehicles.where((v) => v.vehicleStatusDisplay.toLowerCase() == 'maintenance').length;
    return 0;
  }

  @override
  void onInit() {
    super.onInit();
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    try {
      isLoading(true);
      final response = await ApiClient.get(
        endpoint: ApiUrls.vehicles,
        requireAuth: true,
      );

      if (response != null) {
        List<dynamic> dataList = [];
        if (response is List) {
          dataList = response;
        } else if (response is Map && response.containsKey('data')) {
          dataList = response['data'];
        } else if (response is Map && response.containsKey('body')) {
          dataList = response['body'];
        }

        vehicles.value = dataList.map((json) => VehicleModel.fromJson(json)).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load vehicles: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }

  Future<VehicleModel?> fetchVehicleDetails(int id) async {
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.vehicleDetails(id),
        requireAuth: true,
      );

      if (response != null) {
        var data = response;
        if (response is Map && response.containsKey('body')) {
          data = response['body'];
        }
        if (data['id'] != null) {
          return VehicleModel.fromJson(data);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load vehicle details: $e', snackPosition: SnackPosition.BOTTOM);
    }
    return null;
  }

  Future<bool> createVehicle(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post(
        endpoint: ApiUrls.vehicles,
        body: data,
        requireAuth: true,
      );

      if (response != null) {
        Get.snackbar('Success', 'Vehicle created successfully', snackPosition: SnackPosition.BOTTOM);
        await fetchVehicles();
        return true;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create vehicle: $e', snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }

  Future<bool> updateVehicle(int id, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.patch(
        endpoint: ApiUrls.vehicleDetails(id),
        data: data,
        requireAuth: true,
      );

      if (response != null) {
        Get.snackbar('Success', 'Vehicle updated successfully', snackPosition: SnackPosition.BOTTOM);
        await fetchVehicles();
        return true;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update vehicle: $e', snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }

  Future<void> deleteVehicle(int id) async {
    try {
      final response = await ApiClient.delete(
        endpoint: ApiUrls.vehicleDetails(id),
        requireAuth: true,
      );

      if (response != null) {
        Get.snackbar('Success', 'Vehicle deleted successfully', snackPosition: SnackPosition.BOTTOM);
        await fetchVehicles();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete vehicle: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
