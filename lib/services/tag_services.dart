import '../comman/api_url.dart';
import '../modules/users/model/tag_model.dart';
import '../network/api_client.dart';

class TagService {
  /// ===============================
  /// CREATE TAG
  /// ===============================
  static Future<TagResponse> createTag(String tagName) async {
    try {
      final dynamic response = await ApiClient.post(
        endpoint: ApiUrls.addTag,
        requireAuth: true,
        body: {"tag_name": tagName},
      );

      return TagResponse.fromJson(response);
    } catch (e) {
      print("Create Tag Error: $e");
      rethrow;
    }
  }

  /// UPDATE TAG
  static Future<TagResponse> updateTag(int tagId, String tagName) async {
    final response = await ApiClient.post(
      endpoint: "/api/admin/tag/$tagId/update/",
      requireAuth: true,
      body: {"tag_name": tagName},
    );

    return TagResponse.fromJson(response);
  }

  /// DELETE TAG
  static Future<Map<String, dynamic>> deleteTag(
    int tagId, {
    bool confirm = false,
  }) async {
    final response = await ApiClient.post(
      endpoint: "/api/admin/tag/$tagId/delete/",
      requireAuth: true,
      body: {"confirm": confirm},
    );

    return response;
  }

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
