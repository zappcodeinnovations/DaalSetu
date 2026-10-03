import 'package:get/get.dart';

import '../bindings/auth_binding.dart';
import '../bindings/onboarding_binding.dart';
import '../bindings/splash_binding.dart';
import '../modules/Auth/change_password/view/change_password_page.dart';
import '../modules/Auth/forgot_password/view/forgot_password_page.dart';
import '../modules/Auth/login/view/login_screen.dart';
import '../modules/Auth/register/view/register_page.dart';
import '../modules/admin_catalog/config/admin_module_config.dart';
import '../modules/admin_catalog/view/admin_category_master_screen.dart';
import '../modules/admin_catalog/view/admin_module_list_screen.dart';
import '../modules/admin_catalog/view/admin_offers_list_screen.dart';
import '../modules/buyer/dashboard/view/buyer_dashboard_view.dart';
import '../modules/buyer/delivery_challan/view/buyer_delivery_challan_detail_view.dart';
import '../modules/buyer/delivery_challan/view/buyer_delivery_challan_view.dart';
import '../modules/buyer/offers/view/buyer_my_interests_view.dart';
import '../modules/buyer/offers/view/buyer_offers_view.dart';
import '../modules/buyer/offers/view/buyer_pending_offers_view.dart';
import '../modules/buyer/offers/view/buyer_previous_offers_view.dart';
import '../modules/buyer/offers/view/buyer_today_offers_view.dart';
import '../modules/buyer/orders/view/buyer_orders_view.dart';
import '../modules/buyer/transport/view/buyer_transport_tracking_view.dart';
import '../modules/category/view/subcategory_page.dart';
import '../modules/dashboard/view/dashboard_page.dart';
import '../modules/nav_bar/view/nav_page.dart';
import '../modules/onboarding/view/onboarding_screen.dart';
import '../modules/products/view/add_product.dart';
import '../modules/profile/view/edit_profile_page.dart';
import '../modules/profile/view/profile_page.dart';
import '../modules/seller/branches/view/seller_branches_view.dart';
import '../modules/seller/categories/view/seller_category_view.dart';
import '../modules/seller/challans/view/seller_delivery_challan_view.dart';
import '../modules/seller/company/view/seller_company_view.dart';
import '../modules/seller/contracts/view/seller_contracts_view.dart';
import '../modules/seller/dashboard/view/seller_dashboard_view.dart';
import '../modules/seller/masters/view/seller_master_management_view.dart';
import '../modules/seller/notifications/view/seller_notification_view.dart';
import '../modules/seller/products/view/seller_media_gallery_view.dart';
import '../modules/seller/products/view/seller_offer_interests_view.dart';
import '../modules/seller/products/view/seller_product_view.dart';
import '../modules/seller/rfq/view/seller_rfq_list_view.dart';
import '../modules/splashscreen/view/splash_screen.dart';
import '../modules/transporter/branch/view/transporter_branch_view.dart';
import '../modules/transporter/brands/view/transporter_brands_view.dart';
import '../modules/transporter/categories/view/transporter_category_view.dart';
import '../modules/transporter/company/view/transporter_company_view.dart';
import '../modules/transporter/contracts/view/transporter_contracts_view.dart';
import '../modules/transporter/dashboard/view/transporter_dashboard_view.dart';
import '../modules/transporter/drivers/view/transporter_drivers_view.dart';
import '../modules/transporter/kyc/view/transporter_kyc_view.dart';
import '../modules/transporter/notifications/view/transporter_notifications_view.dart';
import '../modules/transporter/offers/view/transporter_offers_view.dart';
import '../modules/transporter/products/view/transporter_products_view.dart';
import '../modules/transporter/rfq/view/transporter_rfq_view.dart';
import '../modules/transporter/users/view/transporter_users_view.dart';
import '../modules/transporter/vehicles/view/transporter_vehicles_view.dart';
import '../modules/users/view/user_detail_screen.dart';
import '../modules/users/view/user_view.dart';
import '../modules/admin_dc/view/admin_dc_list_view.dart';
import '../modules/admin_dc/view/admin_create_dc_view.dart';
import '../modules/admin_dc/view/admin_dc_details_view.dart';
import '../modules/admin_dc/binding/admin_dc_binding.dart';
import '../modules/admin_reports/view/admin_branch_reports_view.dart';
import '../modules/admin_reports/binding/admin_reports_binding.dart';
import '../modules/admin_notifications/view/admin_notification_view.dart';
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
    GetPage(name: AppRoutes.sellerDashboard, page: () => SellerDashboardView()),
    GetPage(name: AppRoutes.sellerProducts, page: () => const SellerProductView()),
    GetPage(name: AppRoutes.sellerCompany, page: () => const SellerCompanyView()),
    GetPage(name: AppRoutes.sellerCategory, page: () => const SellerCategoryView()),
    GetPage(name: AppRoutes.sellerOfferInterests, page: () => const SellerOfferInterestsView()),
    GetPage(name: AppRoutes.sellerMediaGallery, page: () => const SellerMediaGalleryView()),
    GetPage(name: AppRoutes.sellerNotifications, page: () => const SellerNotificationView()),
    GetPage(name: AppRoutes.sellerRFQs, page: () => const SellerRfqListView()),
    GetPage(name: AppRoutes.sellerContracts, page: () => const SellerContractsView()),
    GetPage(name: AppRoutes.sellerDeliveryChallans, page: () => const SellerDeliveryChallanView()),
    GetPage(name: AppRoutes.sellerBranches, page: () => const SellerBranchesView()),
    GetPage(name: AppRoutes.sellerMasters, page: () => const SellerMasterManagementView()),

    // TRANSPORTER PANEL
    GetPage(name: AppRoutes.transporterDashboard, page: () => TransporterDashboardView()),
    GetPage(name: AppRoutes.transporterBranch, page: () => TransporterBranchView()),
    GetPage(name: AppRoutes.transporterBrands, page: () => const TransporterBrandsView()),
    GetPage(name: AppRoutes.transporterCategory, page: () => const TransporterCategoryView()),
    GetPage(name: AppRoutes.transporterCompany, page: () => TransporterCompanyView()),
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
    GetPage(name: AppRoutes.buyerDashboard, page: () => BuyerDashboardView()),
    GetPage(name: AppRoutes.buyerOffers, page: () => const BuyerOffersView()),
    GetPage(name: AppRoutes.buyerMyInterests, page: () => const BuyerMyInterestsView()),
    GetPage(name: AppRoutes.buyerTodayOffers, page: () => const BuyerTodayOffersView()),
    GetPage(name: AppRoutes.buyerPendingOffers, page: () => const BuyerPendingOffersView()),
    GetPage(name: AppRoutes.buyerPreviousOffers, page: () => const BuyerPreviousOffersView()),
    GetPage(name: AppRoutes.buyerDeliveryChallan, page: () => const BuyerDeliveryChallanView()),
    GetPage(name: AppRoutes.buyerDeliveryChallanDetails, page: () => BuyerDeliveryChallanDetailView()),
    GetPage(name: AppRoutes.buyerOrders, page: () => const BuyerOrdersView()),
    GetPage(name: AppRoutes.buyerTransportTracking, page: () => const BuyerTransportTrackingView()),

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

    // ADMIN DELIVERY CHALLANS
    GetPage(
      name: AppRoutes.adminDeliveryChallans,
      page: () => const AdminChallanListView(),
      binding: AdminDCBinding(),
    ),
    GetPage(
      name: AppRoutes.adminCreateDC,
      page: () => const AdminCreateChallanView(),
      binding: AdminDCBinding(),
    ),
    GetPage(
      name: AppRoutes.adminDCDetails,
      page: () => const AdminChallanDetailsView(),
      binding: AdminDCBinding(),
    ),

    // ADMIN REPORTS
    GetPage(
      name: AppRoutes.adminBranchReports,
      page: () => const AdminBranchReportsView(),
      binding: AdminReportsBinding(),
    ),

    // ADMIN NOTIFICATIONS
    GetPage(
      name: AppRoutes.notifications,
      page: () => const AdminNotificationView(),
    ),
    GetPage(
      name: AppRoutes.adminNotifications,
      page: () => const AdminNotificationView(),
    ),
  ];
}
