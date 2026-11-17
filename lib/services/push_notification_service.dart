import 'dart:async';
import 'dart:io';

import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/modules/seller/notifications/model/notification_model.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/routes/app_routes.dart';
import 'package:daalsetu/services/realtime_notification_service.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Runs in its own isolate when a push arrives while the app is closed.
/// The system shows the notification itself; nothing else is needed here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

/// Push notifications (Firebase Cloud Messaging) for Android and iOS.
///
/// The server pushes every notification, so users are alerted even when the
/// app is closed or the phone is locked. While the app is open the in-app
/// banner already shows it, so no second alert is raised.
class PushNotificationService {
  PushNotificationService._();

  static bool _ready = false;
  static bool _listening = false;
  static String? _sentKey; // token + user already sent to the server
  static RemoteMessage? _launchMessage;

  static bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Call once from main(), before runApp. Never throws.
  static Future<void> init() async {
    if (!_supported || _ready) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // The in-app banner covers the open-app case: do not also show a system alert.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      FirebaseMessaging.onMessageOpenedApp.listen(_openFromPush);
      _launchMessage = await FirebaseMessaging.instance.getInitialMessage();
      _ready = true;
    } catch (error) {
      debugPrint('Push notifications unavailable: $error');
    }
  }

  /// Ask permission, fetch this phone's token and tell the server who it belongs to.
  /// Safe to call often (after login and at every app start); it only sends when something changed.
  static Future<void> registerForCurrentUser() async {
    if (!_supported || !_ready) return;
    try {
      final access = await AppPreferences.getAccessToken();
      if (access == null || access.isEmpty) return;

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      if (!_listening) {
        _listening = true;
        messaging.onTokenRefresh.listen((token) => _sendToken(token));
      }

      var apnsReady = !Platform.isIOS;
      for (var attempt = 0; attempt < 5 && !apnsReady; attempt++) {
        apnsReady = await messaging.getAPNSToken() != null;
        if (!apnsReady) await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (!apnsReady) return; // iOS: APNs not set up on this build / simulator

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) await _sendToken(token);
      _openLaunchMessageWhenReady();
    } catch (error) {
      debugPrint('Push registration failed: $error');
    }
  }

  static Future<void> _sendToken(String token) async {
    try {
      final userId = await AppPreferences.getUserId() ?? '';
      final key = '$userId|$token';
      if (key == _sentKey) return;
      final access = await AppPreferences.getAccessToken();
      if (access == null || access.isEmpty) return;
      await ApiClient.post(
        endpoint: ApiUrls.deviceTokenRegister,
        body: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
        requireAuth: true,
        suppressErrorDialog: true,
      );
      _sentKey = key;
    } catch (error) {
      debugPrint('Could not register the push token: $error');
    }
  }

  /// Logout: stop pushes for this user on this phone. Never throws, never blocks long.
  static Future<void> unregister() async {
    if (!_supported || !_ready) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken().timeout(const Duration(seconds: 3));
      if (token != null && token.isNotEmpty) {
        await ApiClient.post(
          endpoint: ApiUrls.deviceTokenRemove,
          body: {'token': token},
          requireAuth: true,
          suppressErrorDialog: true,
        ).timeout(const Duration(seconds: 4));
      }
      await messaging.deleteToken().timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint('Push unregister skipped: $error');
    } finally {
      _sentKey = null;
    }
  }

  /// A notification tapped while the app was closed: open it once the home screen is up.
  static void _openLaunchMessageWhenReady() {
    final message = _launchMessage;
    if (message == null) return;
    _launchMessage = null;
    unawaited(() async {
      for (var i = 0; i < 40; i++) {
        if (Get.currentRoute == AppRoutes.mainNav) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      await _openFromPush(message);
    }());
  }

  static Future<void> _openFromPush(RemoteMessage message) async {
    try {
      await RealtimeNotificationService.navigateToTarget(notificationFromPush(message.data, message.notification));
    } catch (error) {
      debugPrint('Could not open the notification: $error');
    }
  }
}

/// Turns the push payload into the same model the in-app notification list uses,
/// so a tap opens exactly the screen the in-app tap would.
@visibleForTesting
AppNotificationModel notificationFromPush(Map<String, dynamic> data, [RemoteNotification? shown]) {
  int? number(dynamic value) => int.tryParse(value?.toString() ?? '');
  return AppNotificationModel(
    title: (data['title'] ?? shown?.title)?.toString(),
    message: (data['message'] ?? shown?.body)?.toString(),
    type: data['type']?.toString(),
    referenceId: number(data['reference_id']),
    relatedProduct: number(data['related_product_id']),
    redirectUrl: data['redirect_url']?.toString(),
    isRead: false,
  );
}
