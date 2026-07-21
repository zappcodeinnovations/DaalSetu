import 'category_model.dart';

class SubCategoryModel {
  final int id;
  final String subcategoryName;
  final CategoryModel? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubCategoryModel({
    required this.id,
    required this.subcategoryName,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: json["id"] ?? 0,
      subcategoryName: json["subcategory_name"] ?? "",
      category: json["category"] != null
          ? CategoryModel.fromJson(json["category"])
          : null,
      createdAt: json["created_at"] != null
          ? DateTime.tryParse(json["created_at"])
          : null,
      updatedAt: json["updated_at"] != null
          ? DateTime.tryParse(json["updated_at"])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "subcategory_name": subcategoryName,
      "category": category?.toJson(),
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }
}
