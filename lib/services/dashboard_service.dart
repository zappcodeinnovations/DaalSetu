import '../modules/dashboard/model/dashboard_model.dart';
import '../network/api_client.dart';
import '../comman/api_url.dart';

class DashboardService {

  static Future<DashboardModel> fetchDashboard({String? period}) async {

   try {
    String endpoint = ApiUrls.adminDashboard;
    if (period != null && period.isNotEmpty && period != 'This Month') {
      final slug = period.toLowerCase().replaceAll(' ', '_');
      endpoint = '$endpoint?period=$slug&timeframe=$slug';
    }
    final response = await ApiClient.get(
      endpoint: endpoint,
      requireAuth: true,
      suppressErrorDialog: true,
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
