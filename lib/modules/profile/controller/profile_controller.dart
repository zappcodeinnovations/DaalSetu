import '../../../services/profile_services.dart';
import '../../../services/buyer_services.dart';
import '../../../comman/api_url.dart';
import 'package:get/get.dart';
import '../model/profile_model.dart';
import '../../../utils/app_snackbar.dart';

class ProfileController extends GetxController {
  var isLoading = true.obs;
  var profile = Rxn<ProfileModel>();
  var loadError = ''.obs;
  var imageRevision = DateTime.now().millisecondsSinceEpoch.obs;
  bool _fetchingProfile = false;

  String profileImageUrl(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';
    final absolute = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : '${ApiUrls.baseUrl}${raw.startsWith('/') ? '' : '/'}$raw';
    final uri = Uri.parse(absolute);
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            'v': '${imageRevision.value}',
          },
        )
        .toString();
  }

  @override
  void onInit() {
    fetchProfile();
    super.onInit();
  }

  var isUpdating = false.obs;
  final isSubmittingKycApproval = false.obs;

  Future<bool> requestKycApproval() async {
    final user = profile.value;
    if (user == null || !user.canRequestKycApproval || isSubmittingKycApproval.value) return false;
    isSubmittingKycApproval.value = true;
    try {
      final response = await BuyerServices.requestKycApproval();
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Unable to submit KYC for approval.');
      }
      if (!isClosed && profile.value?.id == user.id) {
        profile.value = profile.value!.copyWith(hasPendingKycRequest: true);
        return true;
      }
      return false;
    } finally {
      if (!isClosed) isSubmittingKycApproval.value = false;
    }
  }

  Future<void> fetchProfile({bool showError = false, bool silent = false}) async {
    if (_fetchingProfile || isUpdating.value || isSubmittingKycApproval.value || isClosed) return;
    _fetchingProfile = true;
    try {
      if (!silent) isLoading.value = true;

      final data = await ProfileService.getProfile(silent: !showError);
      if (isClosed) return;
      profile.value = data;
      loadError.value = '';
      if (!silent) imageRevision.value = DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      if (silent || isClosed) return;
      loadError.value = e.toString();
      if (showError) {
        AppSnackbar.snackbar("Unable to refresh profile", "Please try again.");
      }
    } finally {
      _fetchingProfile = false;
      if (!isClosed && !silent) isLoading.value = false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      isUpdating.value = true;
      final updatedData = await ProfileService.updateProfile(data);
      profile.value = updatedData;
      imageRevision.value = DateTime.now().millisecondsSinceEpoch;
      AppSnackbar.snackbar("Success", "Profile updated successfully");
      return true;
    } catch (e) {
      AppSnackbar.snackbar("Error", e.toString());
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> updateProfileWithFiles({
    required Map<String, String> fields,
    required Map<String, String> files,
  }) async {
    try {
      isUpdating.value = true;
      profile.value = await ProfileService.updateProfileMultipart(
        fields: fields,
        files: files,
      );
      imageRevision.value = DateTime.now().millisecondsSinceEpoch;
      AppSnackbar.snackbar("Success", "Profile updated successfully");
      return true;
    } catch (e) {
      AppSnackbar.snackbar("Error", e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
