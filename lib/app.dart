import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

// class AgroBrokerApp extends StatelessWidget {
//   const AgroBrokerApp({super.key});

//   @override
//   Widget build(BuildContext context) {

//     // Register controller once
//     Get.put(ThemeController());

//     return GetMaterialApp(
//       title: 'Dal Broker Admin',
//       debugShowCheckedModeBanner: false,

//       theme: AppTheme.lightTheme,
//       darkTheme: AppTheme.darkTheme,
//       themeMode: ThemeMode.system,

//       initialRoute: AppRoutes.splash,
//       getPages: AppPages.routes,
//     );
//   }
// }

class AgroBrokerApp extends StatelessWidget {
  const AgroBrokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.put(ThemeController());

    return Obx(
      () => GetMaterialApp(
        title: 'Dal Broker Admin',
        debugShowCheckedModeBanner: false,

        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,

        themeMode: themeController.themeMode.value,

        initialRoute: AppRoutes.splash,
        getPages: AppPages.routes,
      ),
    );
  }
}
