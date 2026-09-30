class ProductModel {
  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.rootCategory,
    required this.brand,
    required this.seller,
    required this.amount,
    required this.amountUnit,
    required this.originalQuantity,
    required this.remainingQuantity,
    required this.availableQuantity,
    required this.quantityQtl,
    required this.stockStatus,
    required this.packingWeightKg,
    required this.originalBagCount,
    required this.remainingBagCount,
    required this.quantityUnit,
    required this.loadingFrom,
    required this.loadingTo,
    required this.dealExpiryDatetime,
    required this.loadingLocation,
    required this.remark,
    required this.isExpired,
    required this.isActive,
    required this.status,
    required this.dealStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.interestCount,
    required this.images,
    required this.videos,
  });

  final int id;
  final String title;
  final String description;
  final Category? category;
  final Category? rootCategory;
  final Brand? brand;
  final Seller? seller;
  final String amount;
  final String amountUnit;
  final String originalQuantity;
  final String remainingQuantity;
  final String availableQuantity;
  final String quantityQtl;
  final String stockStatus;
  final String packingWeightKg;
  final int? originalBagCount;
  final int? remainingBagCount;
  final String quantityUnit;
  final String loadingFrom;
  final String loadingTo;
  final String dealExpiryDatetime;
  final String loadingLocation;
  final String remark;
  final bool isExpired;
  final bool isActive;
  final String status;
  final String dealStatus;
  final String createdAt;
  final String updatedAt;
  final int interestCount;
  final List<ProductImage> images;
  final List<ProductVideo> videos;

  ProductModel copyWith({
    int? id,
    String? title,
    String? description,
    Category? category,
    Category? rootCategory,
    Brand? brand,
    Seller? seller,
    String? amount,
    String? amountUnit,
    String? originalQuantity,
    String? remainingQuantity,
    String? availableQuantity,
    String? quantityQtl,
    String? stockStatus,
    String? packingWeightKg,
    int? originalBagCount,
    int? remainingBagCount,
    String? quantityUnit,
    String? loadingFrom,
    String? loadingTo,
    String? dealExpiryDatetime,
    String? loadingLocation,
    String? remark,
    bool? isExpired,
    bool? isActive,
    String? status,
    String? dealStatus,
    String? createdAt,
    String? updatedAt,
    int? interestCount,
    List<ProductImage>? images,
    List<ProductVideo>? videos,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      rootCategory: rootCategory ?? this.rootCategory,
      brand: brand ?? this.brand,
      seller: seller ?? this.seller,
      amount: amount ?? this.amount,
      amountUnit: amountUnit ?? this.amountUnit,
      originalQuantity: originalQuantity ?? this.originalQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      quantityQtl: quantityQtl ?? this.quantityQtl,
      stockStatus: stockStatus ?? this.stockStatus,
      packingWeightKg: packingWeightKg ?? this.packingWeightKg,
      originalBagCount: originalBagCount ?? this.originalBagCount,
      remainingBagCount: remainingBagCount ?? this.remainingBagCount,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      loadingFrom: loadingFrom ?? this.loadingFrom,
      loadingTo: loadingTo ?? this.loadingTo,
      dealExpiryDatetime: dealExpiryDatetime ?? this.dealExpiryDatetime,
      loadingLocation: loadingLocation ?? this.loadingLocation,
      remark: remark ?? this.remark,
      isExpired: isExpired ?? this.isExpired,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      dealStatus: dealStatus ?? this.dealStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      interestCount: interestCount ?? this.interestCount,
      images: images ?? this.images,
      videos: videos ?? this.videos,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String text(String key, [String fallback = ""]) =>
        json[key]?.toString() ?? fallback;
    int? number(String key) => json[key] is int
        ? json[key] as int
        : int.tryParse(json[key]?.toString() ?? "");
    return ProductModel(
      id: number("id") ?? 0,
      title: text("title"),
      description: text("description"),
      category: json["category"] is Map
          ? Category.fromJson(Map<String, dynamic>.from(json["category"]))
          : null,
      rootCategory: json["root_category"] is Map
          ? Category.fromJson(Map<String, dynamic>.from(json["root_category"]))
          : null,
      brand: json["brand"] is Map
          ? Brand.fromJson(Map<String, dynamic>.from(json["brand"]))
          : null,
      seller: json["seller"] is Map
          ? Seller.fromJson(Map<String, dynamic>.from(json["seller"]))
          : null,
      amount: text("amount", "0"),
      amountUnit: text("amount_unit"),
      originalQuantity: text("original_quantity"),
      remainingQuantity: text("remaining_quantity"),
      availableQuantity: text("available_quantity"),
      quantityQtl: text("quantity_qtl"),
      stockStatus: text("stock_status"),
      packingWeightKg: text("packing_weight_kg"),
      originalBagCount: number("original_bag_count"),
      remainingBagCount: number("remaining_bag_count"),
      quantityUnit: text("quantity_unit"),
      loadingFrom: text("loading_from"),
      loadingTo: text("loading_to"),
      dealExpiryDatetime: text("deal_expiry_datetime"),
      loadingLocation: text("loading_location"),
      remark: text("remark"),
      isExpired: json["is_expired"] == true,
      isActive: json["is_active"] == true,
      status: text("status"),
      dealStatus: text("deal_status"),
      createdAt: text("created_at"),
      updatedAt: text("updated_at"),
      interestCount: number("interest_count") ?? 0,
      images: (json["images"] as List? ?? [])
          .map((item) => ProductImage.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      videos: (json["video"] as List? ?? [])
          .map((item) => ProductVideo.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class Category {
  const Category({required this.id, required this.name});
  final int id;
  final String name;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json["id"] as int? ?? 0,
    name: json["name"]?.toString() ?? "",
  );
}

class Brand {
  const Brand({required this.id, required this.name, required this.uniqueId});
  final int id;
  final String name;
  final String uniqueId;

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: json["id"] as int? ?? 0,
    name: json["name"]?.toString() ?? "",
    uniqueId: json["unique_id"]?.toString() ?? "",
  );
}

class Seller {
  const Seller({
    required this.id,
    required this.username,
    required this.fullName,
    required this.loginUsername,
  });
  final int id;
  final String username;
  final String fullName;
  final String loginUsername;

  factory Seller.fromJson(Map<String, dynamic> json) => Seller(
    id: json["id"] as int? ?? 0,
    username: json["username"]?.toString() ?? "",
    fullName: json["full_name"]?.toString() ?? "",
    loginUsername: json["login_username"]?.toString() ?? "",
  );
}

class ProductImage {
  const ProductImage({
    required this.id,
    required this.imageUrl,
    required this.downloadUrl,
    required this.isPrimary,
  });
  final int id;
  final String imageUrl;
  final String downloadUrl;
  final bool isPrimary;

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
    id: json["id"] as int? ?? 0,
    imageUrl: json["image_url"]?.toString() ?? "",
    downloadUrl: json["download_url"]?.toString() ?? "",
    isPrimary: json["is_primary"] == true,
  );
}

class ProductVideo {
  const ProductVideo({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.downloadUrl,
    required this.isPrimary,
  });
  final int id;
  final String title;
  final String videoUrl;
  final String downloadUrl;
  final bool isPrimary;

  factory ProductVideo.fromJson(Map<String, dynamic> json) => ProductVideo(
    id: json["id"] as int? ?? 0,
    title: json["title"]?.toString() ?? "Product video",
    videoUrl: json["url"]?.toString() ?? "",
    downloadUrl: json["download_url"]?.toString() ?? "",
    isPrimary: json["is_primary"] == true,
  );
}
