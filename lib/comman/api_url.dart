class ApiUrls {
  static const String baseUrl = "https://daalsetu.zappcode.in";

  static const String register = "/api/auth/register/";
  static const String login = "/api/auth/login/";
  static const String token = "/api/token/";
  static const String refresh = "/api/token/refresh/";
  static const String verifyOtp = "/api/auth/login/"; // Old OTP endpoint removed, mapped to login as a safe fallback
  static const String changePassword = "/api/auth/change-password/";
  static const String forgotPassword = "/api/auth/forgot-password/";

  //Dashboard
  static const String adminDashboard = "/api/admin/dashboard/";
  //profile
  static const profile = "/api/user/";
  //categories
  static const String categories = "/api/categories/";
  static const String subcategories = "/api/categories/{id}/sub-category/";

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
  static const String addTag = "/api/tags/dropdown/"; // Tag CRUD removed in backend
  static const String tagsList = "/api/tags/dropdown/";
  static const String productImages = "/api/product-images/";
  static const String productVideos = "/api/product-videos/";
  static const String parentCategories = "/api/categories/parent-dropdown/";
  static const String sellerBranches = "/api/seller/branches/";
  static const String contracts = "/api/mobile/contracts/";

  // Seller Panel
  static const String sellerDashboard = "/api/seller/dashboard/";
  static const String company = "/api/company/";
  static const String companyDropdown = "/api/company/dropdown/";
  static const String companyPrimary = "/api/company/primary/";
  static const String categoriesDashboard = "/api/categories/dashboard/";
  static const String categoriesTree = "/api/categories/tree/";
  static const String branchRequestByCode = "/api/seller/branches/request-by-code/";
  static const String sellerChallans = "/api/seller/delivery-challans/";

  // Brands
  static const String brandsDropdown = "/api/brands/dropdown/";

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
  static String buyerConfirmOffer(int productId) => "/api/offers/$productId/buyer-confirm/";
  static String buyerRejectInterest(int productId) => "/api/offers/$productId/buyer-reject-interest/";
  static String buyerRejectOffer(int productId) => "/api/offers/$productId/reject/";

  static String companyDetails(int id) => "/api/company/$id/";
  static String setPrimaryCompany(int id) => "/api/company/$id/set-primary/";
  static String categoryDetails(int id) => "/api/categories/$id/";
  static String createSubCategory(int parentId) => "/api/categories/$parentId/sub-category/";
  static String categoryImage(int id) => "/api/categories/$id/image/";

  static const String createBranch = "/api/branch/create/";
  static String branchDetails(int id) => "/api/seller/branches/$id/";
  static String cancelBranchRequest(int id) => "/api/seller/branches/$id/cancel-request/";
  static String leaveBranch(int id) => "/api/seller/branches/$id/leave/";
  static String challanDetails(int id) => "/api/seller/delivery-challans/$id/";
  static String buyerChallanDetails(int id) => "/api/buyer/delivery-challans/$id/";
  static String buyerOfferDetails(int id) => "/api/buyer-offers/$id/";
  static String buyerOfferAction(int id) => "/api/buyer-offers/$id/action/";
  static String dispatchChallan(int id) => "/api/seller/delivery-challans/$id/dispatch/";

  // Media
  static String productImageDetail(int id) => "/api/product-images/$id/";
  static String productVideoDetail(int id) => "/api/product-videos/$id/";
  static const String offerImagesCreate = "/api/offer-images/create/";
  static String offerImageDelete(int id) => "/api/offer-images/$id/delete/";

  // Offer Interests, Negotiation, Stock & Status
  static String offerInterests(int productId) => "/api/offers/$productId/interests/";
  static String offerNegotiationMessage(int productId, int interestId) => "/api/offers/$productId/interests/$interestId/message/";
  static String offerUpdateStock(int productId) => "/api/offers/$productId/update-stock/";
  static String offerConfirmDeal(int productId) => "/api/offers/$productId/confirm-deal/";
  static String offerToggle(int productId) => "/api/offers/$productId/toggle/";

  // Notifications
  static const String notifications = "/api/notifications/";
  static const String notificationsReadAll = "/api/notifications/read-all/";
  static String notificationsRead(int id) => "/api/notifications/read/$id/";
  static const String notificationsUnreadCount = "/api/notifications/unread-count/";

  // Tags & Masters
  static const String brands = "/api/brands/";
  static const String brandsCreate = "/api/brands/create/";
  static const String tags = "/api/tags/";
  static const String tagsCreate = "/api/tags/create/";
  static const String tagsDropdown = "/api/tags/dropdown/";

  // Buyer Requirements / RFQs
  static const String sellerRFQs = "/api/rfqs/";
  static String rfqDetails(dynamic id) => "/api/rfqs/$id/";
  static String submitRFQQuote(dynamic rfqId) => "/api/rfqs/$rfqId/quote/";

  // Contracts & Delivery Challans
  static const String mobileContracts = "/api/mobile/contracts/";
  static String mobileContractDetails(dynamic id) => "/api/mobile/contracts/$id/";
  static const String sellerDeliveryChallans = "/api/seller/delivery-challans/";
  static String sellerDeliveryChallanDetails(dynamic id) => "/api/seller/delivery-challans/$id/";
  static String sellerDispatchChallan(dynamic id) => "/api/seller/delivery-challans/$id/dispatch/";
}
