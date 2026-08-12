import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/buyer_services.dart';
import '../model/buyer_delivery_challan_model.dart';

class BuyerDeliveryChallanController extends GetxController {
  var isLoading = false.obs;
  var isDetailLoading = false.obs;
  var isReceiving = false.obs;
  var challans = <BuyerDeliveryChallanModel>[].obs;
  var currentChallan = Rxn<BuyerDeliveryChallanModel>();
  var errorMessage = "".obs;
  
  var isSearching = false.obs;
  var searchQuery = "".obs;
  
  int currentPage = 1;
  bool hasNextPage = false;
  var isFetchingMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChallans();
  }

  Future<void> fetchChallans({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 1;
      challans.clear();
      hasNextPage = false;
    }

    if (currentPage == 1) {
      isLoading.value = true;
    } else {
      isFetchingMore.value = true;
    }
    
    errorMessage.value = "";

    try {
      final response = await BuyerServices.getDeliveryChallans(
        page: currentPage, 
        query: searchQuery.value
      );
      
      if (response['success'] == true && response['results'] != null) {
        List<BuyerDeliveryChallanModel> newChallans = (response['results'] as List)
            .map((item) => BuyerDeliveryChallanModel.fromJson(item))
            .toList();
            
        if (currentPage == 1) {
          challans.assignAll(newChallans);
        } else {
          challans.addAll(newChallans);
        }

        if (response['pagination'] != null) {
          hasNextPage = response['pagination']['has_next'] ?? false;
        }
      } else {
        errorMessage.value = response['message'] ?? "Failed to fetch challans.";
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
      isFetchingMore.value = false;
    }
  }
  
  void fetchNextPage() {
    if (hasNextPage && !isFetchingMore.value && !isLoading.value) {
      currentPage++;
      fetchChallans();
    }
  }

  Future<void> fetchChallanDetails(int challanId) async {
    isDetailLoading.value = true;
    errorMessage.value = "";
    currentChallan.value = null;

    try {
      final response = await BuyerServices.getDeliveryChallanDetails(challanId);
      if (response['success'] == true && response['data'] != null) {
        currentChallan.value = BuyerDeliveryChallanModel.fromJson(response['data']);
      } else if (response['success'] == true) {
         // Fallback if data is not wrapped in 'data'
         currentChallan.value = BuyerDeliveryChallanModel.fromJson(response);
      } else {
        errorMessage.value = response['message'] ?? "Failed to fetch challan details.";
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isDetailLoading.value = false;
    }
  }

  Future<void> receiveChallan(int challanId, String remarks) async {
    isReceiving.value = true;
    try {
      final response = await BuyerServices.receiveDeliveryChallan(challanId, remarks);
      if (response['success'] == true) {
        Get.back(); // Go back from details page
        Get.snackbar(
          "Success",
          "Challan received successfully.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        fetchChallans(isRefresh: true); // Refresh list
      } else {
        Get.snackbar(
          "Error",
          response['message'] ?? "Failed to receive challan.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
       Get.snackbar(
          "Error",
          e.toString(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
    } finally {
      isReceiving.value = false;
    }
  }
}
