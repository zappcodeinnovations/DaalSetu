import '../comman/api_url.dart';
import '../modules/users/model/tag_model.dart';
import '../network/api_client.dart';

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

      // The API wraps the list as {success, message, data: {results|list}}.
      final body = Map<String, dynamic>.from(response);
      final data = body['data'];
      final List<dynamic> rows;
      if (data is List) {
        rows = data;
      } else if (data is Map && data['results'] is List) {
        rows = data['results'] as List;
      } else if (body['results'] is List) {
        rows = body['results'] as List;
      } else {
        rows = const [];
      }
      return rows
          .whereType<Map>()
          .map((e) => Tag.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print("❌ Fetch Tags Error: $e");
      rethrow;
    }
  }
}
