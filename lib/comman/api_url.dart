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
}
