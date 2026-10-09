class ProductImageModel {
  final int? id;
  final int? productId;
  final String? productTitle;
  final String? imageUrl;
  final String? downloadUrl;
  final bool? isPrimary;
  final String? createdAt;

  ProductImageModel({
    this.id,
    this.productId,
    this.productTitle,
    this.imageUrl,
    this.downloadUrl,
    this.isPrimary,
    this.createdAt,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      productId: json['product'] is int
          ? json['product']
          : (json['product_id'] is int
                ? json['product_id']
                : int.tryParse(json['product_id']?.toString() ?? '')),
      productTitle: json['product_title']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
      downloadUrl: json['download_url']?.toString(),
      isPrimary: json['is_primary'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }
}

class ProductVideoModel {
  final int? id;
  final int? productId;
  final String? productTitle;
  final String? videoUrl;
  final String? downloadUrl;
  final String? title;
  final bool? isPrimary;
  final String? createdAt;

  ProductVideoModel({
    this.id,
    this.productId,
    this.productTitle,
    this.videoUrl,
    this.downloadUrl,
    this.title,
    this.isPrimary,
    this.createdAt,
  });

  factory ProductVideoModel.fromJson(Map<String, dynamic> json) {
    return ProductVideoModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      productId: json['product'] is int
          ? json['product']
          : (json['product_id'] is int
                ? json['product_id']
                : int.tryParse(json['product_id']?.toString() ?? '')),
      productTitle: json['product_title']?.toString(),
      videoUrl: json['video_url']?.toString() ?? json['video']?.toString(),
      downloadUrl: json['download_url']?.toString(),
      title: json['title']?.toString(),
      isPrimary: json['is_primary'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }
}
