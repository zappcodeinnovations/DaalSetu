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
