import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../comman/api_url.dart';
import '../../../../network/api_client.dart';
import '../model/transporter_bid_model.dart';

class TransporterBiddingController extends GetxController {
  var isLoading = true.obs;
  var isSubmitting = false.obs;
  var availableLoads = <TransporterBidModel>[].obs;
  var myBids = <TransporterBidModel>[].obs;
  var selectedTab = 0.obs; // 0: Available Loadings, 1: My Active Bids, 2: Awarded Loads

  final bidPriceController = TextEditingController();
  final bidQuantityController = TextEditingController();
  final remarksController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  @override
  void onClose() {
    bidPriceController.dispose();
    bidQuantityController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> fetchAllData() async {
    try {
      isLoading(true);
      await Future.wait([
        fetchAvailableLoads(),
        fetchMyBids(),
      ]);
    } catch (e) {
      // Graceful error handle
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchAvailableLoads() async {
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.products,
        requireAuth: true,
      );

      if (response != null) {
        List<dynamic> list = [];
        if (response is List) {
          list = response;
        } else if (response is Map && response['results'] is List) {
          list = response['results'];
        } else if (response is Map && response['data'] is List) {
          list = response['data'];
        }
        availableLoads.value = list.map((e) => TransporterBidModel.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching available loads: $e");
    }
  }

  Future<void> fetchMyBids() async {
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.buyerMyInterests,
        requireAuth: true,
      );

      if (response != null) {
        List<dynamic> list = [];
        if (response is List) {
          list = response;
        } else if (response is Map && response['results'] is List) {
          list = response['results'];
        } else if (response is Map && response['data'] is List) {
          list = response['data'];
        }
        myBids.value = list.map((e) => TransporterBidModel.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching my bids: $e");
    }
  }

  Future<bool> submitBid(int productId) async {
    final price = bidPriceController.text.trim();
    final qty = bidQuantityController.text.trim();
    final remark = remarksController.text.trim();

    if (price.isEmpty || qty.isEmpty) {
      Get.snackbar("Required", "Please enter offered bid price and capacity quantity",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      return false;
    }

    try {
      isSubmitting(true);
      final body = {
        "requested_amount": price,
        "requested_quantity": qty,
        "remark": remark.isNotEmpty ? remark : "Transport Bid",
      };

      final response = await ApiClient.post(
        endpoint: "/api/offers/$productId/show-interest/",
        body: body,
        requireAuth: true,
      );

      if (response != null) {
        Get.back(); // Close modal
        Get.snackbar("Success", "Bid submitted successfully!",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        bidPriceController.clear();
        bidQuantityController.clear();
        remarksController.clear();
        await fetchAllData();
        return true;
      }
    } catch (e) {
      Get.snackbar("Error", "Could not submit bid: $e",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting(false);
    }
    return false;
  }
}
