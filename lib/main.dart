import 'package:flutter/material.dart';
import 'app.dart';
import 'utils/global_error_handler.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Push notifications (FCM): never blocks or crashes start-up.
  await PushNotificationService.init();
  // Track screen-off / resume from the start so network popups stay quiet around them.
  AppForeground.ensureTracking();
  runApp(const AgroBrokerApp());
}
