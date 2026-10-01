class SellerProductModel {
  final int id;
  final String title;
  final String description;
  final int? categoryId;
  final String? categoryName;
  final String amount;
  final String unit;
  final String status;
  final int bagCount;
  final double packingWeight;
  final String loadingLocation;
  final List<String> imageUrls;
  final DateTime createdAt;

  SellerProductModel({
    required this.id,
    required this.title,
    required this.description,
    this.categoryId,
    this.categoryName,
    required this.amount,
    required this.unit,
    required this.status,
    required this.bagCount,
    required this.packingWeight,
    required this.loadingLocation,
    required this.imageUrls,
    required this.createdAt,
  });

  factory SellerProductModel.fromJson(Map<String, dynamic> json) {
    return SellerProductModel(
      id: json['id'],
      title: json['title'] ?? "",
      description: json['description'] ?? "",
      categoryId: json['category'] is Map ? json['category']['id'] : json['category'],
      categoryName: json['category'] is Map ? json['category']['category_name'] : null,
      amount: json['amount']?.toString() ?? "0",
      unit: json['unit'] ?? "qtl",
      status: json['status'] ?? "active",
      bagCount: json['bag_count'] ?? 0,
      packingWeight: double.tryParse(json['packing_weight_kg']?.toString() ?? "0") ?? 0.0,
      loadingLocation: json['loading_location'] ?? "",
      imageUrls: (json['images'] as List?)?.map((e) => e['image_url']?.toString() ?? "").toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
