abstract class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';

  // AUTH
  static const login = '/login';
  static const loginWithOtp = '/login-with-otp';
  static const verifyOtp = '/verify-otp';
  static const register = '/register';
  static const change_password = '/change-password';
  static const forgot_password = '/forgot-password';

  // PROFILE
  static const profile_page = '/profile-page';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const completeProfile = '/complete-profile';

  // DASHBOARD
  static const dashboard = '/dashboard';

  // CATEGORIES
  static const subcategory = "/subcategory";

  // MAIN APP
  static const mainNav = '/main-nav';
  static const home = '/home';

  // USERS
  static const users = '/users';
  static const users_details = '/users-details';

  // OTHER FEATURES
  static const notifications = '/notifications';
  static const search = '/search';
  static const subscription = '/subscription';
  static const documents = '/documents';
  static const settings = '/settings';
  static const support = '/support';
  static const about = '/about';

  // SELLER PANEL
  static const sellerDashboard = '/seller/dashboard';
  static const sellerCompany = '/seller/company';
  static const sellerCategory = '/seller/category';
  static const sellerBranches = '/seller/branches';
  static const sellerLogistics = '/seller/logistics';
  static const sellerProducts = '/seller/products';
  static const sellerContracts = '/seller/contracts';
  static const sellerOfferInterests = '/seller/offer-interests';
  static const sellerMediaGallery = '/seller/media-gallery';
  static const sellerNotifications = '/seller/notifications';
  static const sellerRFQs = '/seller/rfqs';
  static const sellerDeliveryChallans = '/seller/delivery-challans';
  static const sellerMasters = '/seller/masters';
  static const sellerWorkspace = '/seller/workspace';

  // TRANSPORTER PANEL
  static const transporterDashboard = '/transporter/dashboard';
  static const transporterBranch = '/transporter/branch';
  static const transporterBrands = '/transporter/brands';
  static const transporterCategory = '/transporter/category';
  static const transporterCompany = '/transporter/company';
  static const transporterKyc = '/transporter/kyc';
  static const transporterContracts = '/transporter/contracts';
  static const transporterNotifications = '/transporter/notifications';
  static const transporterOffers = '/transporter/offers';
  static const transporterProducts = '/transporter/products';
  static const transporterRfq = '/transporter/rfq';
  static const transporterUsers = '/transporter/users';
  static const transporterDrivers = '/transporter/drivers';
  static const transporterVehicles = '/transporter/vehicles';
  static const transporterBidding = '/transporter/bidding';

  // BUYER PANEL
  static const buyerDashboard = '/buyer/dashboard';
  static const buyerOffers = '/buyer/offers';
  static const buyerOffersCreate = '/buyer/offers/create';
  static const buyerMyInterests = '/buyer/offers/my-interests';
  static const buyerTodayOffers = '/buyer/offers/today';
  static const buyerPendingOffers = '/buyer/offers/pending';
  static const buyerPreviousOffers = '/buyer/offers/previous';
  static const buyerDeliveryChallan = '/buyer/delivery-challan';
  static const buyerDeliveryChallanDetails = '/buyer/delivery-challan-details';
  static const buyerOrders = '/buyer/orders';
  static const buyerTransportTracking = '/buyer/transport-tracking';

  // ADMIN SIDEBAR
  static String adminModule(String key) => '/admin/$key';
  static const adminCreateOffer = '/admin/create-offer';
  static const adminBranchSettings = '/admin/branches/settings';

  // ADMIN DELIVERY CHALLANS
  static const adminDeliveryChallans = '/admin/delivery-challans';
  static const adminCreateDC = '/admin/delivery-challans/create';
  static const adminDCDetails = '/admin/delivery-challans/details';

  // ADMIN REPORTS
  static const adminBranchReports = '/admin/reports/branches';

  // ADMIN NOTIFICATIONS
  static const adminNotifications = '/admin/notifications';
}
