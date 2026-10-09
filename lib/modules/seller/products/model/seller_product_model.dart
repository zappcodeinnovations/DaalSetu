class SellerProductModel {
  final int id;
  final String title;
  final String description;
  final int? categoryId;
  final String? categoryName;
  final String? brandName;
  final String amount;
  final String unit;
  final String status;
  final bool isActive;
  final bool isExpired;
  final int interestCount;
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
    this.brandName,
    required this.amount,
    required this.unit,
    required this.status,
    required this.isActive,
    required this.isExpired,
    required this.interestCount,
    required this.bagCount,
    required this.packingWeight,
    required this.loadingLocation,
    required this.imageUrls,
    required this.createdAt,
  });

  factory SellerProductModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final brand = json['brand'];
    final rawLocation = json['loading_location']?.toString() ?? '';
    return SellerProductModel(
      id: int.tryParse('${json['id']}') ?? 0,
      title: json['title'] ?? "",
      description: json['description'] ?? "",
      categoryId: int.tryParse(
        '${json['category_id'] ?? (category is Map ? category['id'] : category) ?? ''}',
      ),
      categoryName: json['category_name']?.toString().trim().isNotEmpty == true
          ? json['category_name'].toString().trim()
          : category is Map
          ? (category['category_name'] ?? category['name'])?.toString()
          : null,
      brandName: json['brand_name']?.toString().trim().isNotEmpty == true
          ? json['brand_name'].toString().trim()
          : brand is Map
          ? (brand['name'] ?? brand['brand_name'])?.toString()
          : brand?.toString(),
      amount: json['amount']?.toString() ?? "0",
      unit:
          json['amount_unit']?.toString() ?? json['unit']?.toString() ?? "qtl",
      status: json['status'] ?? "active",
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : (json['status'] ?? "active") == "active",
      isExpired: json['is_expired'] == true,
      interestCount:
          int.tryParse(
            '${json['interested_count'] ?? json['interest_count'] ?? 0}',
          ) ??
          0,
      bagCount:
          int.tryParse(
            '${json['remaining_bag_count'] ?? json['bag_count'] ?? json['original_bag_count'] ?? 0}',
          ) ??
          0,
      packingWeight:
          double.tryParse(json['packing_weight_kg']?.toString() ?? "0") ?? 0.0,
      loadingLocation: _displayLocation(rawLocation),
      imageUrls:
          (json['images'] as List?)
              ?.map((e) => e['image_url']?.toString() ?? "")
              .toList() ??
          [],
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Older offers can contain a server-generated date range when no location
  /// was supplied. A date range is not a location, so never show it on cards.
  static String _displayLocation(String value) {
    final location = value.trim();
    final dateRange = RegExp(
      r'^\d{4}[-/]\d{1,2}[-/]\d{1,2}\s*(?:->|to)\s*\d{4}[-/]\d{1,2}[-/]\d{1,2}$',
      caseSensitive: false,
    );
    return dateRange.hasMatch(location) ? '' : location;
  }
}
