import 'package:flutter/material.dart';
import 'app.dart';
import 'utils/global_error_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Track screen-off / resume from the start so network popups stay quiet around them.
  AppForeground.ensureTracking();
  runApp(const AgroBrokerApp());
}
