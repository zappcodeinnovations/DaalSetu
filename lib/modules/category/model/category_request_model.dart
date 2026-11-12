class CategoryRequestModel {
  final int id;
  final String status;
  final List<String> categoryNames;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? requestNote;
  final String? adminComment;
  final String? reviewerName;

  CategoryRequestModel({
    required this.id,
    required this.status,
    required this.categoryNames,
    this.requestedAt,
    this.reviewedAt,
    this.requestNote,
    this.adminComment,
    this.reviewerName,
  });

  factory CategoryRequestModel.fromJson(Map<String, dynamic> json) {
    final catList = (json["categories"] is List) ? (json["categories"] as List) : [];
    final names = catList
        .map((c) => (c is Map ? (c["category_name"] ?? c["name"] ?? "").toString() : c.toString()))
        .where((n) => n.trim().isNotEmpty)
        .toList();

    String? reviewer;
    if (json["reviewed_by"] is Map) {
      reviewer = json["reviewed_by"]["name"]?.toString();
    } else if (json["reviewed_by"] != null) {
      reviewer = json["reviewed_by"].toString();
    }

    return CategoryRequestModel(
      id: json["id"] is int ? json["id"] : (int.tryParse(json["id"]?.toString() ?? "0") ?? 0),
      status: (json["status"] ?? "pending").toString(),
      categoryNames: names,
      requestedAt: json["requested_at"] != null
          ? DateTime.tryParse(json["requested_at"].toString())
          : (json["created_at"] != null ? DateTime.tryParse(json["created_at"].toString()) : null),
      reviewedAt: json["reviewed_at"] != null
          ? DateTime.tryParse(json["reviewed_at"].toString())
          : null,
      requestNote: json["request_note"]?.toString(),
      adminComment: json["admin_comment"]?.toString(),
      reviewerName: reviewer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "status": status,
      "category_names": categoryNames,
      "requested_at": requestedAt?.toIso8601String(),
      "reviewed_at": reviewedAt?.toIso8601String(),
      "request_note": requestNote,
      "admin_comment": adminComment,
      "reviewer_name": reviewerName,
    };
  }
}
