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
    int? parseId(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is Map && val['id'] != null) return parseId(val['id']);
      return int.tryParse(val.toString());
    }

    final dataMap = json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null;

    final refId = parseId(
      json['reference_id'] ??
          json['ref_id'] ??
          json['target_id'] ??
          json['object_id'] ??
          json['item_id'] ??
          dataMap?['reference_id'] ??
          dataMap?['id'],
    );

    final relProduct = parseId(
      json['related_product'] ??
          json['product_id'] ??
          json['offer_id'] ??
          json['product'] ??
          json['offer'] ??
          dataMap?['related_product'] ??
          dataMap?['product_id'] ??
          dataMap?['offer_id'] ??
          dataMap?['product'] ??
          dataMap?['offer'],
    );

    return AppNotificationModel(
      id: parseId(json['id']),
      title: json['title']?.toString(),
      message: json['message']?.toString(),
      role: json['role']?.toString(),
      type: json['type']?.toString() ??
          json['notification_type']?.toString() ??
          json['action']?.toString() ??
          dataMap?['type']?.toString(),
      referenceId: refId,
      relatedProduct: relProduct,
      redirectUrl: json['redirect_url']?.toString() ??
          json['url']?.toString() ??
          json['link']?.toString() ??
          dataMap?['redirect_url']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: json['created_at']?.toString(),
      timeAgo: json['time_ago']?.toString(),
    );
  }
}
