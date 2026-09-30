import 'package:agro_broker/comman/api_url.dart';
import 'package:agro_broker/modules/users/model/tag_model.dart';
import 'package:agro_broker/network/api_client.dart';

class TagService {

  /// ===============================
  /// FETCH TAG LIST
  /// ===============================
  static Future<List<Tag>> fetchTags() async {
    try {
      final dynamic response = await ApiClient.get(
        endpoint: ApiUrls.tagsList,
        requireAuth: true,
      );

      if (response == null) {
        throw Exception("Invalid Tag List response");
      }

      final tagListResponse = TagListResponse.fromJson(
        Map<String, dynamic>.from(response),
      );

      return tagListResponse.results;
    } catch (e) {
      print("❌ Fetch Tags Error: $e");
      rethrow;
    }
  }
}
