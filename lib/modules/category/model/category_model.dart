class CategoryModel {
  final int id;
  final String categoryName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? status;
  final String? description;

  CategoryModel({
    required this.id,
    required this.categoryName,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final catName = json["category_name"] ??
        json["name"] ??
        json["title"] ??
        json["category"]?["name"] ??
        json["category"]?["category_name"] ??
        "";
    final catId = json["id"] ?? json["category_id"] ?? json["category"]?["id"] ?? 0;

    return CategoryModel(
      id: catId is int ? catId : (int.tryParse(catId.toString()) ?? 0),
      categoryName: catName.toString(),
      status: json["status"]?.toString(),
      description: json["description"]?.toString(),
      createdAt: json["created_at"] != null
          ? DateTime.tryParse(json["created_at"].toString())
          : (json["date"] != null ? DateTime.tryParse(json["date"].toString()) : null),
      updatedAt: json["updated_at"] != null
          ? DateTime.tryParse(json["updated_at"].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "category_name": categoryName,
      "status": status,
      "description": description,
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }
}
