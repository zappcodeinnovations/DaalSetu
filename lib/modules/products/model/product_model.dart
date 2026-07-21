class ProductModel {
  final int id;
  final String title;
  final String description;
  final Category? category;
  final Seller? seller;
  final String amount;
  final String loadingLocation;
  final String status;
  final int interestCount;
  final List<ProductImage> images;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.seller,
    required this.amount,
    required this.loadingLocation,
    required this.status,
    required this.interestCount,
    required this.images,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json["id"],
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      category: json["category"] != null
          ? Category.fromJson(json["category"])
          : null,
      seller: json["seller"] != null
          ? Seller.fromJson(json["seller"])
          : null,
      amount: json["amount"] ?? "0",
      loadingLocation: json["loading_location"] ?? "",
      status: json["status"] ?? "",
      interestCount: json["interest_count"] ?? 0,
      images: (json["images"] as List? ?? [])
          .map((e) => ProductImage.fromJson(e))
          .toList(),
    );
  }
}

class Category {
  final int id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json["id"],
      name: json["name"] ?? "",
    );
  }
}

class Seller {
  final int id;
  final String username;

  Seller({
    required this.id,
    required this.username,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json["id"],
      username: json["username"] ?? "",
    );
  }
}

class ProductImage {
  final int id;
  final String imageUrl;
  final bool isPrimary;

  ProductImage({
    required this.id,
    required this.imageUrl,
    required this.isPrimary,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json["id"],
      imageUrl: json["image_url"] ?? "",
      isPrimary: json["is_primary"] ?? false,
    );
  }
}
