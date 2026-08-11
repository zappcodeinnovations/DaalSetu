class ApiUrls {
  static const String baseUrl = "https://daalsetu.zappcode.in";

  static const String register = "/api/auth/register/";
  static const String login = "/api/auth/login/";
  static const String token = "/api/token/";
  static const String refresh = "/api/token/refresh/";
  static const String verifyOtp = "/api/verify-otp/";
  static const String changePassword = "/api/auth/change-password/";
  static const String forgotPassword = "/api/auth/forgot-password/";

  //Dashboard
  static const String adminDashboard = "/api/admin/dashboard/";
  //profile
  static const profile = "/api/user/";
  //categories
  static const String categories = "/api/categories/";
  static const String subcategories = "/api/subcategories/";

  // Categories & Brands
  static const String createCategory = "/api/categories/";
  static String categoryBrands(int id) => "/api/categories/$id/brands/";

  //kyc-users
  static const String kycUsers = "/api/kyc/list/";
  //products
  static const String products = "/api/products/";
  //users
  static const String users = "/api/users/";
  static const String addUser = "/api/adduser/";
  static const String addTag = "/api/admin/tag/create/";
  static const String tagsList = "/api/admin/tag/list/";
  static const String productImages = "/api/product-images/";
  static const String contracts = "/api/mobile/contracts/";

  // Seller Panel
  static const String sellerDashboard = "/api/seller/dashboard/";
  static const String company = "/api/company/";
  static const String companyDropdown = "/api/company/dropdown/";
  static const String companyPrimary = "/api/company/primary/";
  static const String categoriesDashboard = "/api/categories/dashboard/";
  static const String categoriesTree = "/api/categories/tree/";

  // Transporter Panel
  static const String transporterDashboard = "/api/transporter/dashboard/";
  static const String transporterDashboardOverview = "/api/transporter/dashboard/overview/";
  static const String drivers = "/api/drivers/";
  static String driverDetails(int id) => "/api/drivers/$id/";
  static String assignVehicle(int id) => "/api/drivers/$id/assign-vehicle/";
  static const String vehicles = "/api/vehicles/";
  static String vehicleDetails(int id) => "/api/vehicles/$id/";
  static const String requestBranchByCode = "/api/seller/branches/request-by-code/";
  static const String publicBranches = "/api/public/branches/";

  // Buyer Panel
  static const String buyerDashboard = "/api/buyer/dashboard/";
  static const String buyerOffers = "/api/buyer-offers/";
  static const String buyerOffersCreate = "/api/buyer-offers/create/";
  static const String buyerDeliveryChallans = "/api/buyer/delivery-challans/";
  static String buyerDeliveryChallanDetails(int id) => "/api/buyer/delivery-challans/$id/";
  static String buyerDeliveryChallanReceive(int id) => "/api/buyer/delivery-challans/$id/receive/";
  static const String buyerMyInterests = "/api/offers/my-interests/list/";
  static const String buyerTodayOffers = "/api/offers/today/";
  static const String buyerPendingOffers = "/api/offers/pending/";
  static const String buyerPreviousOffers = "/api/offers/previous/";

  static String buyerApproveOffer(int productId) => "/api/offers/$productId/approve/";
  static String buyerConfirmOffer(int productId) => "/api/offers/$productId/confirm/";
  static String buyerRejectInterest(int productId) => "/api/offers/$productId/buyer-reject-interest/";
  static String buyerRejectOffer(int productId) => "/api/offers/$productId/reject/";

  static String companyDetails(int id) => "/api/company/$id/";
  static String setPrimaryCompany(int id) => "/api/company/$id/set-primary/";
  static String categoryDetails(int id) => "/api/categories/$id/";
  static String createSubCategory(int parentId) => "/api/categories/$parentId/sub-category/";
  static String categoryImage(int id) => "/api/categories/$id/image/";
}
