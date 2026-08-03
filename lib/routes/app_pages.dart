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
import 'package:agro_broker/modules/splashscreen/view/splash_screen.dart';
import 'package:agro_broker/modules/seller/dashboard/view/seller_dashboard_view.dart';
import 'package:agro_broker/modules/seller/company/view/seller_company_view.dart';
import 'package:agro_broker/modules/seller/categories/view/seller_category_view.dart';
import 'package:agro_broker/modules/seller/branches/view/seller_branch_view.dart';
import 'package:agro_broker/modules/seller/delivery/view/seller_delivery_view.dart';
import 'package:agro_broker/modules/seller/products/view/seller_product_view.dart';
import 'package:agro_broker/modules/seller/contracts/view/seller_contract_view.dart';
import 'package:agro_broker/modules/transporter/dashboard/view/transporter_dashboard_view.dart';
import 'package:agro_broker/modules/transporter/branch/view/transporter_branch_view.dart';
import 'package:agro_broker/modules/transporter/brands/view/transporter_brands_view.dart';
import 'package:agro_broker/modules/transporter/categories/view/transporter_category_view.dart';
import 'package:agro_broker/modules/transporter/company/view/transporter_company_view.dart';
import 'package:agro_broker/modules/transporter/kyc/view/transporter_kyc_view.dart';
import 'package:agro_broker/modules/transporter/contracts/view/transporter_contracts_view.dart';
import 'package:agro_broker/modules/transporter/notifications/view/transporter_notifications_view.dart';
import 'package:agro_broker/modules/transporter/offers/view/transporter_offers_view.dart';
import 'package:agro_broker/modules/transporter/products/view/transporter_products_view.dart';
import 'package:agro_broker/modules/transporter/rfq/view/transporter_rfq_view.dart';
import 'package:agro_broker/modules/transporter/users/view/transporter_users_view.dart';
import 'package:agro_broker/modules/transporter/drivers/view/transporter_drivers_view.dart';
import 'package:agro_broker/modules/transporter/vehicles/view/transporter_vehicles_view.dart';
import 'package:agro_broker/modules/buyer/dashboard/view/buyer_dashboard_view.dart';
import 'package:agro_broker/modules/buyer/offers/view/buyer_offers_view.dart';
import 'package:agro_broker/modules/buyer/offers/view/buyer_my_interests_view.dart';
import 'package:agro_broker/modules/buyer/offers/view/buyer_today_offers_view.dart';
import 'package:agro_broker/modules/buyer/offers/view/buyer_pending_offers_view.dart';
import 'package:agro_broker/modules/buyer/offers/view/buyer_previous_offers_view.dart';
import 'package:agro_broker/modules/buyer/delivery_challan/view/buyer_delivery_challan_view.dart';
import 'package:agro_broker/modules/buyer/orders/view/buyer_orders_view.dart';
import 'package:agro_broker/modules/buyer/transport/view/buyer_transport_tracking_view.dart';
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
    GetPage(name: AppRoutes.sellerDashboard, page: () => const SellerDashboardView()),
    GetPage(name: AppRoutes.sellerCompany, page: () => const SellerCompanyView()),
    GetPage(name: AppRoutes.sellerCategory, page: () => const SellerCategoryView()),
    GetPage(name: AppRoutes.sellerBranches, page: () => const SellerBranchView()),
    GetPage(name: AppRoutes.sellerLogistics, page: () => const SellerDeliveryView()),
    GetPage(name: AppRoutes.sellerProducts, page: () => const SellerProductView()),
    GetPage(name: AppRoutes.sellerContracts, page: () => const SellerContractView()),

    // TRANSPORTER PANEL
    GetPage(name: AppRoutes.transporterDashboard, page: () => const TransporterDashboardView()),
    GetPage(name: AppRoutes.transporterBranch, page: () => const TransporterBranchView()),
    GetPage(name: AppRoutes.transporterBrands, page: () => const TransporterBrandsView()),
    GetPage(name: AppRoutes.transporterCategory, page: () => const TransporterCategoryView()),
    GetPage(name: AppRoutes.transporterCompany, page: () => const TransporterCompanyView()),
    GetPage(name: AppRoutes.transporterKyc, page: () => const TransporterKycView()),
    GetPage(name: AppRoutes.transporterContracts, page: () => const TransporterContractsView()),
    GetPage(name: AppRoutes.transporterNotifications, page: () => const TransporterNotificationsView()),
    GetPage(name: AppRoutes.transporterOffers, page: () => const TransporterOffersView()),
    GetPage(name: AppRoutes.transporterProducts, page: () => const TransporterProductsView()),
    GetPage(name: AppRoutes.transporterRfq, page: () => const TransporterRfqView()),
    GetPage(name: AppRoutes.transporterUsers, page: () => const TransporterUsersView()),
    GetPage(name: AppRoutes.transporterDrivers, page: () => const TransporterDriversView()),
    GetPage(name: AppRoutes.transporterVehicles, page: () => const TransporterVehiclesView()),

    // BUYER PANEL
    GetPage(name: AppRoutes.buyerDashboard, page: () => const BuyerDashboardView()),
    GetPage(name: AppRoutes.buyerOffers, page: () => const BuyerOffersView()),
    GetPage(name: AppRoutes.buyerMyInterests, page: () => const BuyerMyInterestsView()),
    GetPage(name: AppRoutes.buyerTodayOffers, page: () => const BuyerTodayOffersView()),
    GetPage(name: AppRoutes.buyerPendingOffers, page: () => const BuyerPendingOffersView()),
    GetPage(name: AppRoutes.buyerPreviousOffers, page: () => const BuyerPreviousOffersView()),
    GetPage(name: AppRoutes.buyerDeliveryChallan, page: () => const BuyerDeliveryChallanView()),
    GetPage(name: AppRoutes.buyerOrders, page: () => const BuyerOrdersView()),
    GetPage(name: AppRoutes.buyerTransportTracking, page: () => const BuyerTransportTrackingView()),
  ];
}
