import 'dart:async';
import 'dart:io';

import 'global_error_handler.dart';

/// Runs [refresh] every [every] while the app is in the foreground, so lists
/// (for example the interest-count badge on offer cards) stay current without
/// a manual pull-to-refresh. Returns null under `flutter test`, where an
/// unattended periodic timer would never be closed.
Timer? startLiveRefresh(
  void Function() refresh, {
  Duration every = const Duration(seconds: 15),
}) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
  return Timer.periodic(every, (_) {
    if (AppForeground.isActive) refresh();
  });
}
