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

  static int? parseId(dynamic val) {
    if (val is int) return val;
    return int.tryParse(val?.toString().trim() ?? '');
  }

  static int? parseProductId(Map<String, dynamic> json) {
    final raw = json['product'] ??
        json['product_id'] ??
        json['offer'] ??
        json['offer_id'];
    if (raw is int) return raw;
    if (raw is Map) {
      final nested = raw['id'] ?? raw['product_id'] ?? raw['offer_id'];
      if (nested is int) return nested;
      return int.tryParse(nested?.toString().trim() ?? '');
    }
    if (raw != null) {
      return int.tryParse(raw.toString().trim());
    }
    return null;
  }

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: parseId(json['id']),
      productId: parseProductId(json),
      productTitle: json['product_title']?.toString() ??
          (json['product'] is Map ? json['product']['title']?.toString() : null),
      imageUrl: json['image_url']?.toString() ??
          json['image']?.toString() ??
          json['file']?.toString(),
      downloadUrl: json['download_url']?.toString(),
      isPrimary: json['is_primary'] == true ||
          json['is_primary'] == 'true' ||
          json['is_primary'] == 1,
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
      id: ProductImageModel.parseId(json['id']),
      productId: ProductImageModel.parseProductId(json),
      productTitle: json['product_title']?.toString() ??
          (json['product'] is Map ? json['product']['title']?.toString() : null),
      videoUrl: json['video_url']?.toString() ??
          json['video']?.toString() ??
          json['file']?.toString() ??
          json['url']?.toString(),
      downloadUrl: json['download_url']?.toString(),
      title: json['title']?.toString(),
      isPrimary: json['is_primary'] == true ||
          json['is_primary'] == 'true' ||
          json['is_primary'] == 1,
      createdAt: json['created_at']?.toString(),
    );
  }
}
