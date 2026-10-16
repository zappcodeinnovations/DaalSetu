import '../../../../comman/api_url.dart';

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

  static String? resolveUrl(String? raw) {
    if (raw == null) return null;
    final url = raw.trim();
    if (url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = ApiUrls.baseUrl.endsWith('/')
        ? ApiUrls.baseUrl.substring(0, ApiUrls.baseUrl.length - 1)
        : ApiUrls.baseUrl;
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
  }

  static int? parseId(dynamic val) {
    if (val is int) return val;
    return int.tryParse(val?.toString().trim() ?? '');
  }

  static int? parseProductId(
    Map<String, dynamic> json, {
    int? defaultProductId,
  }) {
    final raw =
        json['product'] ??
        json['product_id'] ??
        json['offer'] ??
        json['offer_id'];
    if (raw is int) return raw;
    if (raw is Map) {
      final nested = raw['id'] ?? raw['product_id'] ?? raw['offer_id'];
      if (nested is int) return nested;
      return int.tryParse(nested?.toString().trim() ?? '') ?? defaultProductId;
    }
    if (raw != null) {
      return int.tryParse(raw.toString().trim()) ?? defaultProductId;
    }
    return defaultProductId;
  }

  factory ProductImageModel.fromJson(
    Map<String, dynamic> json, {
    int? defaultProductId,
  }) {
    final rawImageUrl =
        json['image_url']?.toString() ??
        json['image']?.toString() ??
        json['file']?.toString() ??
        json['url']?.toString();
    final rawDownloadUrl = json['download_url']?.toString();

    return ProductImageModel(
      id: parseId(json['id']),
      productId: parseProductId(json, defaultProductId: defaultProductId),
      productTitle:
          json['product_title']?.toString() ??
          (json['product'] is Map
              ? json['product']['title']?.toString()
              : null),
      imageUrl: resolveUrl(rawImageUrl) ?? rawImageUrl,
      downloadUrl: resolveUrl(rawDownloadUrl) ?? rawDownloadUrl,
      isPrimary:
          json['is_primary'] == true ||
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

  factory ProductVideoModel.fromJson(
    Map<String, dynamic> json, {
    int? defaultProductId,
  }) {
    final rawVideoUrl =
        json['video_url']?.toString() ??
        json['video']?.toString() ??
        json['file']?.toString() ??
        json['url']?.toString();
    final rawDownloadUrl = json['download_url']?.toString();

    return ProductVideoModel(
      id: ProductImageModel.parseId(json['id']),
      productId: ProductImageModel.parseProductId(
        json,
        defaultProductId: defaultProductId,
      ),
      productTitle:
          json['product_title']?.toString() ??
          (json['product'] is Map
              ? json['product']['title']?.toString()
              : null),
      videoUrl: ProductImageModel.resolveUrl(rawVideoUrl) ?? rawVideoUrl,
      downloadUrl:
          ProductImageModel.resolveUrl(rawDownloadUrl) ?? rawDownloadUrl,
      title: json['title']?.toString(),
      isPrimary:
          json['is_primary'] == true ||
          json['is_primary'] == 'true' ||
          json['is_primary'] == 1,
      createdAt: json['created_at']?.toString(),
    );
  }
}
