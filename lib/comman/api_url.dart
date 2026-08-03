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

  // Brands
  static const String brandsDropdown = "/api/brands/dropdown/";

  // Buyer Panel
  static const String buyerDashboard = "/api/buyer/dashboard/";
  static const String buyerOffers = "/api/buyer-offers/";
  static const String buyerOffersCreate = "/api/buyer-offers/create/";
  static const String buyerDeliveryChallans = "/api/buyer/delivery-challans/";
  static const String buyerMyInterests = "/api/offers/my-interests/list/";
  static const String buyerTodayOffers = "/api/offers/today/";
  static const String buyerPendingOffers = "/api/offers/pending/";
  static const String buyerPreviousOffers = "/api/offers/previous/";

  static String companyDetails(int id) => "/api/company/$id/";
  static String setPrimaryCompany(int id) => "/api/company/$id/set-primary/";
  static String categoryDetails(int id) => "/api/categories/$id/";
  static String createSubCategory(int parentId) => "/api/categories/$parentId/sub-category/";
  static String categoryImage(int id) => "/api/categories/$id/image/";
}
