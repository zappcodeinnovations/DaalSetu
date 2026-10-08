import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class AdminNotificationModel {
  final int id;
  final String title;
  final String message;
  final String role;
  final String type;
  final int? referenceId;
  final int? relatedProduct;
  final String? redirectUrl;
  bool isRead;
  final String createdAt;
  final String timeAgo;

  AdminNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.role = 'admin',
    this.type = 'general',
    this.referenceId,
    this.relatedProduct,
    this.redirectUrl,
    this.isRead = false,
    this.createdAt = '',
    this.timeAgo = 'Just now',
  });

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : (int.tryParse(rawId?.toString() ?? '0') ?? 0);
    final rawRef = json['reference_id'];
    final referenceId = rawRef is int ? rawRef : int.tryParse(rawRef?.toString() ?? '');
    final rawProd = json['related_product'];
    final relatedProduct = rawProd is int ? rawProd : int.tryParse(rawProd?.toString() ?? '');

    return AdminNotificationModel(
      id: id,
      title: json['title']?.toString() ?? 'New Notification',
      message: json['message']?.toString() ?? '',
      role: json['role']?.toString() ?? 'admin',
      type: json['type']?.toString().toLowerCase() ?? 'general',
      referenceId: referenceId,
      relatedProduct: relatedProduct,
      redirectUrl: json['redirect_url']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: json['created_at']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
    );
  }

  /// Visual Icon based on notification category
  IconData get iconData {
    final t = type.toLowerCase();
    if (t.contains('contract') || t.contains('deal')) {
      return IconlyBold.paper;
    } else if (t.contains('challan') || t.contains('dispatch') || t.contains('transport')) {
      return Icons.local_shipping_rounded;
    } else if (t.contains('kyc')) {
      return IconlyBold.profile;
    } else if (t.contains('product') || t.contains('offer')) {
      return IconlyBold.bag;
    } else if (t.contains('rfq') || t.contains('quote')) {
      return IconlyBold.document;
    }
    return IconlyBold.notification;
  }

  /// Brand-friendly Accent Color for each type
  Color get accentColor {
    final t = type.toLowerCase();
    if (t.contains('contract') || t.contains('deal')) {
      return const Color(0xFF059669); // Green
    } else if (t.contains('challan') || t.contains('dispatch') || t.contains('transport')) {
      return const Color(0xFF2563EB); // Blue
    } else if (t.contains('kyc')) {
      return const Color(0xFFD97706); // Amber / Gold
    } else if (t.contains('product') || t.contains('offer')) {
      return const Color(0xFF7C3AED); // Purple
    }
    return const Color(0xFFE11D48); // Rose
  }

  /// Clean readable formatted time
  String get displayTime {
    if (timeAgo.isNotEmpty) return timeAgo;
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 1) return "Just now";
        if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
        if (diff.inHours < 24) return "${diff.inHours}h ago";
        if (diff.inDays < 7) return "${diff.inDays}d ago";
        return "${dt.day}/${dt.month}/${dt.year}";
      } catch (_) {}
    }
    return "";
  }
}
