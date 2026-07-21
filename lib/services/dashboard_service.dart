import 'package:agro_broker/modules/dashboard/model/dashboard_model.dart';
import 'package:agro_broker/network/api_client.dart';
import 'package:agro_broker/comman/api_url.dart';

class DashboardService {

  static Future<DashboardModel> fetchDashboard() async {

   try {
    final response = await ApiClient.get(
      endpoint: ApiUrls.adminDashboard,
      requireAuth: true,
    );

    print("📥 RAW RESPONSE: $response");

    if (response == null) {
      throw Exception("Response is null");
    }

    return DashboardModel.fromJson(response);

  } catch (e, stackTrace) {
    print("❌ Service Error: $e");
    print("STACK: $stackTrace");
    rethrow;
  }
  }

}