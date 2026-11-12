import '../modules/dashboard/model/dashboard_model.dart';
import '../network/api_client.dart';
import '../comman/api_url.dart';

class DashboardService {

  static Future<DashboardModel> fetchDashboard({String? period}) async {

   try {
    String endpoint = ApiUrls.adminDashboard;
    if (period != null && period.isNotEmpty) {
      String slug = '1m';
      final pLower = period.toLowerCase();
      if (pLower.contains('7') || pLower.contains('week')) {
        slug = '7d';
      } else if (pLower.contains('3') || pLower.contains('quarter')) {
        slug = '3m';
      } else if (pLower.contains('year') || pLower.contains('1y')) {
        slug = '1y';
      } else if (pLower.contains('month') || pLower.contains('1m')) {
        slug = '1m';
      }
      endpoint = '$endpoint?period=$slug&timeframe=$slug&range=$slug';
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
