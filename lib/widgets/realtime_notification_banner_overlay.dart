import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import '../modules/seller/notifications/model/notification_model.dart';
import '../services/realtime_notification_service.dart';

/// Floating real-time pop-up notification banner displayed over the top of the app.
/// Allows users to view and interact with new notifications and products instantly.
class RealtimeNotificationBannerOverlay extends StatefulWidget {
  const RealtimeNotificationBannerOverlay({super.key});

  @override
  State<RealtimeNotificationBannerOverlay> createState() =>
      _RealtimeNotificationBannerOverlayState();
}

class _RealtimeNotificationBannerOverlayState
    extends State<RealtimeNotificationBannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  StreamSubscription? _bannerSubscription;
  Timer? _autoDismissTimer;
  AppNotificationModel? _currentNotification;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _subscribeToService();
  }

  void _subscribeToService() {
    if (!Get.isRegistered<RealtimeNotificationService>()) {
      // Retry subscription after first frame if service is not yet registered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Get.isRegistered<RealtimeNotificationService>()) {
          _listenToService();
        }
      });
      return;
    }
    _listenToService();
  }

  void _listenToService() {
    final service = RealtimeNotificationService.to;
    // Initial check
    if (service.activeBannerNotification.value != null) {
      _showBanner(service.activeBannerNotification.value!);
    }

    _bannerSubscription = service.activeBannerNotification.listen((notif) {
      if (!mounted) return;
      if (notif != null) {
        _showBanner(notif);
      } else {
        _dismiss();
      }
    });
  }

  void _showBanner(AppNotificationModel notif) {
    _autoDismissTimer?.cancel();
    setState(() {
      _currentNotification = notif;
      _isDismissing = false;
    });

    _animController.forward(from: 0.0);

    // Auto-dismiss after 5.5 seconds
    _autoDismissTimer = Timer(const Duration(milliseconds: 5500), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _autoDismissTimer?.cancel();

    try {
      await _animController.reverse();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _currentNotification = null;
        _isDismissing = false;
      });
    }

    if (Get.isRegistered<RealtimeNotificationService>()) {
      RealtimeNotificationService.to.dismissCurrentBanner();
    }
  }

  Future<void> _handleTap() async {
    final notif = _currentNotification;
    if (notif == null) return;
    _autoDismissTimer?.cancel();

    // Smoothly animate out and navigate
    try {
      await _animController.reverse();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _currentNotification = null;
        _isDismissing = false;
      });
    }

    if (Get.isRegistered<RealtimeNotificationService>()) {
      RealtimeNotificationService.to.onBannerTapped(notif);
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _bannerSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  IconData _resolveIcon(AppNotificationModel notification) {
    final title = (notification.title ?? '').toLowerCase();
    final type = (notification.type ?? '').toLowerCase();
    final message = (notification.message ?? '').toLowerCase();

    if (title.contains('product') || type.contains('product') || message.contains('product')) {
      return IconlyBold.bag;
    }
    if (title.contains('branch') || type.contains('branch')) {
      return IconlyBold.location;
    }
    if (title.contains('challan') || type.contains('challan') || title.contains('transport')) {
      return Icons.local_shipping_rounded;
    }
    if (title.contains('contract') || title.contains('negotiation') || title.contains('deal')) {
      return IconlyBold.document;
    }
    return IconlyBold.notification;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentNotification == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notif = _currentNotification!;
    final title = (notif.title ?? 'New Notification').trim();
    final message = (notif.message ?? '').trim();
    final timeAgo = (notif.timeAgo ?? 'Just now').trim();
    final iconData = _resolveIcon(notif);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _handleTap,
              onVerticalDragEnd: (details) {
                // Swipe up to dismiss instantly
                if ((details.primaryVelocity ?? 0) < -120) {
                  _dismiss();
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2C2213), const Color(0xFF1D170D)]
                        : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : const Color(0xFFF59E0B))
                          .withValues(alpha: isDark ? 0.5 : 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _handleTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Notification icon avatar
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              color: const Color(0xFFD97706),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Content: Title & Message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: isDark
                                              ? const Color(0xFFFDE68A)
                                              : const Color(0xFF78350F),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      timeAgo,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.amber.shade200
                                            : const Color(0xFF92400E).withValues(alpha: 0.72),
                                      ),
                                    ),
                                  ],
                                ),
                                if (message.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    message,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      height: 1.3,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : const Color(0xFF451A03).withValues(alpha: 0.88),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Interactive "View" chip
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "View",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 9,
                                    color: isDark
                                        ? const Color(0xFFFDE68A)
                                        : const Color(0xFF92400E),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Dismiss (X) button
                          InkWell(
                            onTap: _dismiss,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF92400E).withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
