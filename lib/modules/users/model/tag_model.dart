class TagListResponse {
  final bool success;
  final List<Tag> results;
  final Pagination pagination;

  TagListResponse({
    required this.success,
    required this.results,
    required this.pagination,
  });

  factory TagListResponse.fromJson(Map<String, dynamic> json) {
    return TagListResponse(
      success: json['success'] ?? false,
      results: (json['results'] as List? ?? [])
          .map((e) => Tag.fromJson(e))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Tag {
  final int id;
  final String tagName;
  final String createdAt;
  final String updatedAt;
  final int assignedUsersCount;

  Tag({
    required this.id,
    required this.tagName,
    required this.createdAt,
    required this.updatedAt,
    required this.assignedUsersCount,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] ?? 0,
      tagName: json['tag_name'] ?? "",
      createdAt: json['created_at'] ?? "",
      updatedAt: json['updated_at'] ?? "",
      assignedUsersCount: json['assigned_users_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "tag_name": tagName,
      "created_at": createdAt,
      "updated_at": updatedAt,
      "assigned_users_count": assignedUsersCount,
    };
  }
}

class Pagination {
  final int page;
  final int numPages;
  final int count;
  final bool hasNext;
  final bool hasPrevious;

  Pagination({
    required this.page,
    required this.numPages,
    required this.count,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      numPages: json['num_pages'] ?? 1,
      count: json['count'] ?? 0,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
    );
  }
}

class TagResponse {
  final bool success;
  final String message;
  final Tag tag;

  TagResponse({
    required this.success,
    required this.message,
    required this.tag,
  });

  factory TagResponse.fromJson(Map<String, dynamic> json) {
    return TagResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
      tag: Tag.fromJson(json['tag'] ?? {}),
    );
  }
}
