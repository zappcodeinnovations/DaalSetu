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

  //profile
  static const profile_page = '/profile-page';

  //Dashboard
  static const dashboard = '/dashboard';

  //categories
  static const subcategory = "/subcategory";

  // MAIN APP
  static const mainNav = '/main-nav';
  static const home = '/home';
  //usersss
  static const users = '/users';
  static const users_details = '/users-details';
  // PROFILE
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const completeProfile = '/complete-profile';

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
}
