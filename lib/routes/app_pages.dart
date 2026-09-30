import 'package:agro_broker/bindings/auth_binding.dart';
import 'package:agro_broker/bindings/onboarding_binding.dart';
import 'package:agro_broker/bindings/splash_binding.dart';
import 'package:agro_broker/modules/Auth/change_password/view/change_password_page.dart';
import 'package:agro_broker/modules/Auth/forgot_password/view/forgot_password_page.dart';
import 'package:agro_broker/modules/Auth/login/view/login_screen.dart';
import 'package:agro_broker/modules/users/view/user_detail_screen.dart';
import 'package:agro_broker/modules/users/view/user_view.dart';
import 'package:agro_broker/modules/category/view/subcategory_page.dart';
import 'package:agro_broker/modules/dashboard/view/dashboard_page.dart';
import 'package:agro_broker/modules/nav_bar/view/nav_page.dart';
import 'package:agro_broker/modules/onboarding/view/onboarding_screen.dart';
import 'package:agro_broker/modules/Auth/register/view/register_page.dart';
import 'package:agro_broker/modules/profile/view/profile_page.dart';
import 'package:agro_broker/modules/profile/view/edit_profile_page.dart';
import 'package:agro_broker/modules/splashscreen/view/splash_screen.dart';
import 'package:agro_broker/modules/seller/dashboard/view/seller_dashboard_view.dart';
import 'package:agro_broker/modules/seller/company/view/seller_company_view.dart';
import 'package:agro_broker/modules/seller/categories/view/seller_category_view.dart';
import 'package:agro_broker/modules/admin_catalog/config/admin_module_config.dart';
import 'package:agro_broker/modules/admin_catalog/view/admin_module_list_screen.dart';
import 'package:agro_broker/modules/admin_catalog/view/admin_offers_list_screen.dart';
import 'package:agro_broker/modules/admin_catalog/view/admin_category_master_screen.dart';
import 'package:agro_broker/modules/products/view/add_product.dart';
import 'package:get/get.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = <GetPage>[
    /// SPLASH
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),

    /// ONBOARDING
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),

    /// AUTH
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      binding: AuthBinding(),
    ),

    GetPage(
      name: AppRoutes.login,
      page: () => LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.change_password,
      page: () => ChangePasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.forgot_password,
      page: () => ForgotPasswordScreen(),
    ),
    GetPage(name: AppRoutes.dashboard, page: () => AdminDashboardScreen()),
    GetPage(name: AppRoutes.profile_page, page: () => ProfileScreen()),
    GetPage(name: AppRoutes.editProfile, page: () => const EditProfileScreen()),
    GetPage(name: AppRoutes.mainNav, page: () => MainNavigationScreen()),
    GetPage(name: AppRoutes.subcategory, page: () => SubCategoryScreen()),
    GetPage(name: AppRoutes.users, page: () => UserScreen()),
    GetPage(name: AppRoutes.users_details, page: () => UserDetailScreen()),

    // SELLER PANEL
    GetPage(
      name: AppRoutes.sellerDashboard,
      page: () => const SellerDashboardView(),
    ),
    GetPage(
      name: AppRoutes.sellerCompany,
      page: () => const SellerCompanyView(),
    ),
    GetPage(
      name: AppRoutes.sellerCategory,
      page: () => const SellerCategoryView(),
    ),

    // ADMIN SIDEBAR MODULES
    ...AdminModules.all.keys.map(
      (key) => GetPage(
        name: AppRoutes.adminModule(key),
        page: () {
          if (key == 'offers') return const AdminOffersListScreen();
          if (key == 'categories') return const AdminCategoryMasterScreen();
          return AdminModuleListScreen(moduleKey: key);
        },
      ),
    ),
    GetPage(
      name: AppRoutes.adminCreateOffer,
      page: () => const AddProductScreen(),
    ),
  ];
}
