import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'services/realtime_notification_service.dart';

class AgroBrokerApp extends StatelessWidget {
  const AgroBrokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ThemeController());
    Get.put(RealtimeNotificationService(), permanent: true);

    return GetMaterialApp(
      title: 'Dal Broker Admin',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      themeMode: ThemeMode.light,

      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Stack(
          children: [
            if (child != null) child,
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: isDark ? 0.08 : 0.08,
                    child: Image.asset(
                      'assets/images/thumb_logo.png',
                      width: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
