import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../comman/api_url.dart';
import '../../../../network/api_client.dart';
import '../model/transporter_bid_model.dart';

/// Web "Active Shipment Offer's" + "My Deals" over the single API /api/transport-bids/.
class TransporterBiddingController extends GetxController {
  var isLoadingOffers = false.obs;
  var isLoadingBids = false.obs;
  var offers = <ShipmentOfferModel>[].obs;
  var myBids = <MyBidModel>[].obs;
  var vehicles = <FleetOption>[].obs;
  var drivers = <FleetOption>[].obs;
  var offerSearch = ''.obs;
  var bidStatus = 'all'.obs;
  var offersError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
    debounce(offerSearch, (_) => fetchOffers(), time: const Duration(milliseconds: 400));
  }

  Future<void> fetchAllData() => Future.wait([fetchOffers(), fetchMyBids()]);

  /// The server refuses bidding (403) until the company profile / KYC is complete.
  String _message(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '');
    if (text == 'Forbidden') return 'Complete your company profile and KYC to view and bid on shipments.';
    return text;
  }

  String _query(String view, Map<String, String> extra) {
    final params = {'view': view, ...extra}..removeWhere((_, v) => v.isEmpty);
    return "${ApiUrls.transportBids}?${Uri(queryParameters: params).query}";
  }

  Future<void> fetchOffers() async {
    try {
      isLoadingOffers(true);
      offersError('');
      final response = await ApiClient.get(endpoint: _query('open', {'search': offerSearch.value}), requireAuth: true);
      final list = response is Map ? response['contracts'] : null;
      offers.value = (list is List ? list : const []).whereType<Map<String, dynamic>>().map(ShipmentOfferModel.fromJson).toList();
    } catch (e) {
      offers.clear();
      offersError(_message(e));
    } finally {
      isLoadingOffers(false);
    }
  }

  Future<void> fetchMyBids() async {
    try {
      isLoadingBids(true);
      final response = await ApiClient.get(
        endpoint: _query('mine', {'status': bidStatus.value == 'all' ? '' : bidStatus.value}),
        requireAuth: true,
      );
      final data = response is Map ? response : const {};
      myBids.value = (data['results'] as List? ?? []).whereType<Map<String, dynamic>>().map(MyBidModel.fromJson).toList();
      vehicles.value = (data['vehicles'] as List? ?? [])
          .whereType<Map>()
          .map((v) => FleetOption(v['id'] as int, "${v['vehicle_number']} (${v['vehicle_status'] ?? ''})"))
          .toList();
      drivers.value = (data['drivers'] as List? ?? [])
          .whereType<Map>()
          .map((d) => FleetOption(d['id'] as int, "${d['driver_name']} • ${d['phone_number'] ?? ''}",
              linkedVehicleId: d['assigned_vehicle_id'] is int ? d['assigned_vehicle_id'] as int : null))
          .toList();
    } catch (e) {
      myBids.clear();
      _snack("Error", _message(e), Colors.red);
    } finally {
      isLoadingBids(false);
    }
  }

  void setBidStatus(String status) {
    bidStatus.value = status;
    fetchMyBids();
  }

  Future<bool> placeBid(ShipmentOfferModel offer, String amount) async {
    return _post(ApiUrls.transportBids, {"contract_id": offer.id, "bid_amount": amount});
  }

  Future<bool> assignDriver(MyBidModel bid, int vehicleId, int driverId) async {
    return _post(ApiUrls.transportBidDetail(bid.bidId), {"action": "assign_driver", "vehicle_id": vehicleId, "driver_id": driverId});
  }

  /// Anonymised competing bids for one contract (transporter view of the web bid table).
  Future<List<Map<String, dynamic>>> fetchContractBids(int contractPk) async {
    try {
      final response = await ApiClient.get(endpoint: "${ApiUrls.transportBids}?contract_id=$contractPk", requireAuth: true);
      final list = response is Map ? response['bids'] : null;
      return (list is List ? list : const []).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      _snack("Error", _message(e), Colors.red);
      return [];
    }
  }

  Future<bool> _post(String endpoint, Map<String, dynamic> body) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final response = await ApiClient.post(endpoint: endpoint, body: body, requireAuth: true);
      if (Get.isDialogOpen ?? false) Get.back();
      _snack("Success", '${response['message'] ?? 'Done'}', Colors.green);
      await fetchAllData();
      return true;
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _snack("Error", _message(e), Colors.red);
      return false;
    }
  }

  void _snack(String title, String message, Color color) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM, backgroundColor: color, colorText: Colors.white);
  }
}
