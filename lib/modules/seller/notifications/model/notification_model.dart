class AppNotificationModel {
  final int? id;
  final String? title;
  final String? message;
  final String? role;
  final String? type;
  final int? referenceId;
  final int? relatedProduct;
  final String? redirectUrl;
  final bool? isRead;
  final String? createdAt;
  final String? timeAgo;

  /// Interest references identify the interest, not its product. Prefer the
  /// explicit product relation/link before considering a product reference.
  int? get productTargetId {
    if (relatedProduct != null && relatedProduct! > 0) return relatedProduct;
    final url = redirectUrl ?? '';
    final match = RegExp(r'[?&]manage_product=(\d+)').firstMatch(url) ??
        RegExp(r'/(?:products|offers)/(\d+)(?:/|\?|#|$)').firstMatch(url);
    final linked = int.tryParse(match?.group(1) ?? '');
    if (linked != null && linked > 0) return linked;
    final kind = (type ?? '').toLowerCase();
    if (kind.contains('interest') || kind.contains('buyer_offer') ||
        kind.contains('rfq') || kind.contains('contract') || kind.contains('deal')) {
      return null;
    }
    if (kind.contains('product') || kind == 'offer') {
      return referenceId != null && referenceId! > 0 ? referenceId : null;
    }
    return null;
  }

  AppNotificationModel({
    this.id,
    this.title,
    this.message,
    this.role,
    this.type,
    this.referenceId,
    this.relatedProduct,
    this.redirectUrl,
    this.isRead,
    this.createdAt,
    this.timeAgo,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      title: json['title']?.toString(),
      message: json['message']?.toString(),
      role: json['role']?.toString(),
      type: json['type']?.toString(),
      referenceId: json['reference_id'] is int ? json['reference_id'] : int.tryParse(json['reference_id']?.toString() ?? ''),
      relatedProduct: json['related_product'] is int ? json['related_product'] : int.tryParse(json['related_product']?.toString() ?? ''),
      redirectUrl: json['redirect_url']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: json['created_at']?.toString(),
      timeAgo: json['time_ago']?.toString(),
    );
  }
}
