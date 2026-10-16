import '../../../../comman/api_url.dart';

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
  final List<String> videoUrls;
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
    this.videoUrls = const [],
    required this.createdAt,
  });

  String? get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;
  String? get primaryVideoUrl => videoUrls.isNotEmpty ? videoUrls.first : null;

  static String _resolveUrl(String? raw) {
    if (raw == null) return '';
    final url = raw.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = ApiUrls.baseUrl.endsWith('/')
        ? ApiUrls.baseUrl.substring(0, ApiUrls.baseUrl.length - 1)
        : ApiUrls.baseUrl;
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
  }

  factory SellerProductModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final brand = json['brand'];
    final rawLocation = json['loading_location']?.toString() ?? '';

    final parsedImages = <String>[];
    if (json['images'] is List) {
      for (final e in json['images'] as List) {
        String? itemUrl;
        if (e is Map) {
          itemUrl =
              e['image_url']?.toString() ??
              e['image']?.toString() ??
              e['file']?.toString() ??
              e['url']?.toString() ??
              e['download_url']?.toString();
        } else if (e is String) {
          itemUrl = e;
        }
        final resolved = _resolveUrl(itemUrl);
        if (resolved.isNotEmpty && !parsedImages.contains(resolved)) {
          parsedImages.add(resolved);
        }
      }
    }
    final primaryImg = _resolveUrl(
      json['primary_image_url']?.toString() ?? json['image_url']?.toString(),
    );
    if (primaryImg.isNotEmpty && !parsedImages.contains(primaryImg)) {
      parsedImages.insert(0, primaryImg);
    }

    final parsedVideos = <String>[];
    final rawVideoList =
        json['product_videos'] ?? json['videos'] ?? json['video'];
    if (rawVideoList is List) {
      for (final e in rawVideoList) {
        String? itemUrl;
        if (e is Map) {
          itemUrl =
              e['video_url']?.toString() ??
              e['video']?.toString() ??
              e['file']?.toString() ??
              e['url']?.toString() ??
              e['download_url']?.toString();
        } else if (e is String) {
          itemUrl = e;
        }
        final resolved = _resolveUrl(itemUrl);
        if (resolved.isNotEmpty && !parsedVideos.contains(resolved)) {
          parsedVideos.add(resolved);
        }
      }
    }
    final primaryVid = _resolveUrl(
      json['primary_video_url']?.toString() ?? json['video_url']?.toString(),
    );
    if (primaryVid.isNotEmpty && !parsedVideos.contains(primaryVid)) {
      parsedVideos.insert(0, primaryVid);
    }

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
      imageUrls: parsedImages,
      videoUrls: parsedVideos,
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
