import 'package:daalsetu/bindings/auth_binding.dart';
import 'package:daalsetu/bindings/onboarding_binding.dart';
import 'package:daalsetu/bindings/splash_binding.dart';
import 'package:daalsetu/modules/Auth/change_password/view/change_password_page.dart';
import 'package:daalsetu/modules/Auth/forgot_password/view/forgot_password_page.dart';
import 'package:daalsetu/modules/Auth/login/view/login_screen.dart';
import 'package:daalsetu/modules/users/view/user_detail_screen.dart';
import 'package:daalsetu/modules/users/view/user_view.dart';
import 'package:daalsetu/modules/category/view/subcategory_page.dart';
import 'package:daalsetu/modules/dashboard/view/dashboard_page.dart';
import 'package:daalsetu/modules/nav_bar/view/nav_page.dart';
import 'package:daalsetu/modules/onboarding/view/onboarding_screen.dart';
import 'package:daalsetu/modules/Auth/register/view/register_page.dart';
import 'package:daalsetu/modules/profile/view/profile_page.dart';
import 'package:daalsetu/modules/splashscreen/view/splash_screen.dart';
import 'package:daalsetu/modules/seller/dashboard/view/seller_dashboard_view.dart';
import 'package:daalsetu/modules/seller/company/view/seller_company_view.dart';
import 'package:daalsetu/modules/seller/categories/view/seller_category_view.dart';
import 'package:daalsetu/modules/transporter/dashboard/view/transporter_dashboard_view.dart';
import 'package:daalsetu/modules/transporter/branch/view/transporter_branch_view.dart';
import 'package:daalsetu/modules/transporter/brands/view/transporter_brands_view.dart';
import 'package:daalsetu/modules/transporter/categories/view/transporter_category_view.dart';
import 'package:daalsetu/modules/transporter/company/view/transporter_company_view.dart';
import 'package:daalsetu/modules/transporter/kyc/view/transporter_kyc_view.dart';
import 'package:daalsetu/modules/transporter/contracts/view/transporter_contracts_view.dart';
import 'package:daalsetu/modules/transporter/notifications/view/transporter_notifications_view.dart';
import 'package:daalsetu/modules/transporter/offers/view/transporter_offers_view.dart';
import 'package:daalsetu/modules/transporter/products/view/transporter_products_view.dart';
import 'package:daalsetu/modules/transporter/rfq/view/transporter_rfq_view.dart';
import 'package:daalsetu/modules/transporter/users/view/transporter_users_view.dart';
import 'package:daalsetu/modules/transporter/drivers/view/transporter_drivers_view.dart';
import 'package:daalsetu/modules/transporter/vehicles/view/transporter_vehicles_view.dart';
import 'package:daalsetu/modules/buyer/dashboard/view/buyer_dashboard_view.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_offers_view.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_my_interests_view.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_today_offers_view.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_pending_offers_view.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_previous_offers_view.dart';
import 'package:daalsetu/modules/buyer/delivery_challan/view/buyer_delivery_challan_view.dart';
import 'package:daalsetu/modules/buyer/delivery_challan/view/buyer_delivery_challan_detail_view.dart';
import 'package:daalsetu/modules/buyer/orders/view/buyer_orders_view.dart';
import 'package:daalsetu/modules/buyer/transport/view/buyer_transport_tracking_view.dart';
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
    GetPage(name: AppRoutes.mainNav, page: () => MainNavigationScreen()),
    GetPage(name: AppRoutes.subcategory, page: () => SubCategoryScreen()),
    GetPage(name: AppRoutes.users, page: () => UserScreen()),
    GetPage(name: AppRoutes.users_details, page: () => UserDetailScreen()),

    // SELLER PANEL
    GetPage(name: AppRoutes.sellerDashboard, page: () =>  SellerDashboardView()),
    GetPage(name: AppRoutes.sellerCompany, page: () => const SellerCompanyView()),
    GetPage(name: AppRoutes.sellerCategory, page: () => const SellerCategoryView()),

    // TRANSPORTER PANEL
    GetPage(name: AppRoutes.transporterDashboard, page: () => TransporterDashboardView()),
    GetPage(name: AppRoutes.transporterBranch, page: () => TransporterBranchView()),
    GetPage(name: AppRoutes.transporterBrands, page: () => const TransporterBrandsView()),
    GetPage(name: AppRoutes.transporterCategory, page: () => const TransporterCategoryView()),
    GetPage(name: AppRoutes.transporterCompany, page: () =>  TransporterCompanyView()),
    GetPage(name: AppRoutes.transporterKyc, page: () => const TransporterKycView()),
    GetPage(name: AppRoutes.transporterContracts, page: () => const TransporterContractsView()),
    GetPage(name: AppRoutes.transporterNotifications, page: () => const TransporterNotificationsView()),
    GetPage(name: AppRoutes.transporterOffers, page: () => const TransporterOffersView()),
    GetPage(name: AppRoutes.transporterProducts, page: () => const TransporterProductsView()),
    GetPage(name: AppRoutes.transporterRfq, page: () => const TransporterRfqView()),
    GetPage(name: AppRoutes.transporterUsers, page: () => const TransporterUsersView()),
    GetPage(name: AppRoutes.transporterDrivers, page: () => TransporterDriversView()),
    GetPage(name: AppRoutes.transporterVehicles, page: () => TransporterVehiclesView()),

    // BUYER PANEL
    GetPage(name: AppRoutes.buyerDashboard, page: () =>  BuyerDashboardView()),
    GetPage(name: AppRoutes.buyerOffers, page: () => const BuyerOffersView()),
    GetPage(name: AppRoutes.buyerMyInterests, page: () => const BuyerMyInterestsView()),
    GetPage(name: AppRoutes.buyerTodayOffers, page: () => const BuyerTodayOffersView()),
    GetPage(name: AppRoutes.buyerPendingOffers, page: () => const BuyerPendingOffersView()),
    GetPage(name: AppRoutes.buyerPreviousOffers, page: () => const BuyerPreviousOffersView()),
    GetPage(name: AppRoutes.buyerDeliveryChallan, page: () => const BuyerDeliveryChallanView()),
    GetPage(name: AppRoutes.buyerDeliveryChallanDetails, page: () => BuyerDeliveryChallanDetailView()),
    GetPage(name: AppRoutes.buyerOrders, page: () => const BuyerOrdersView()),
    GetPage(name: AppRoutes.buyerTransportTracking, page: () => const BuyerTransportTrackingView()),
  ];
}
