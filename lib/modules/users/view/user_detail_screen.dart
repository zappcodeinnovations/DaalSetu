import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/user_model.dart';
import '../../../services/users_services.dart';
import '../../../comman/api_url.dart';
import 'package:daalsetu/widgets/app_shell.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late UserModel user;
  bool _obscurePassword = true;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    // Initialize user from arguments
    final args = Get.arguments;
    if (args is UserModel) {
      user = args;
    } else if (args is Map<String, dynamic>) {
      user = UserModel.fromJson(args);
    } else {
      user = UserModel(
        id: 0,
        username: "Unknown",
        mobile: "",
        tags: [],
        role: "",
        kycStatus: "",
        accountStatus: "",
        isActive: false,
      );
    }

    _fetchDetailedData();
  }

  Future<void> _fetchDetailedData() async {
    if (user.id == 0) return;
    try {
      setState(() => _isLoadingDetails = true);
      final detailed = await UserService.getUserById(user.id);
      if (mounted) {
        setState(() {
          user = detailed;
          _isLoadingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(leading: const AppBarLeading(), leadingWidth: AppBarLeading.widthFor(context), 
        elevation: 0,
        title: const Text("User Details"),
        centerTitle: true,
        actions: [
          if (_isLoadingDetails)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetchDetailedData,
              tooltip: "Refresh Details",
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 🔥 HEADER CARD
            _buildHeaderCard(context),

            const SizedBox(height: 24),

            /// 🔥 BASIC INFO CARD
            _buildInfoCard(
              context,
              title: "Basic Information",
              children: [
                _infoRow("Full Name", user.fullName.isNotEmpty ? user.fullName : "-"),
                _infoRow("Username", user.username.isNotEmpty ? user.username : "-"),
                _infoRow("Mobile", user.mobile.isNotEmpty ? user.mobile : "-"),
                _infoRow("Email", user.email ?? "-"),
                _infoRow("Gender", user.gender ?? "-"),
                _infoRow("DOB", user.dob ?? "-"),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 COMPANY & ASSIGNMENT CARD
            _buildInfoCard(
              context,
              title: "Company & Assignment",
              children: [
                _infoRow("Company Name", user.companyName ?? "-"),
                _infoRow("Brand", user.brand ?? "-"),
                _infoRow("Branch Codes", user.branchCodes ?? "-"),
                _infoRow("Parent Admin", user.parentAdmin ?? "-"),
                _infoRow("Custom Roles", user.customRoles ?? "-"),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 ACCOUNT & SECURITY DETAILS CARD
            _buildInfoCard(
              context,
              title: "Account & System Details",
              children: [
                _passwordRow(context),
                _infoRow("Registration Reason", user.registrationReason ?? "-"),
                _infoRow("Date Joined", user.dateJoined ?? "-"),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 TAGS CARD
            _buildTagsCard(context),

            const SizedBox(height: 20),

            /// 🔥 KYC INFO CARD
            _buildInfoCard(
              context,
              title: "KYC Details",
              children: [
                _infoRow("PAN Number", user.panNumber ?? "-"),
                _infoRow("GST Number", user.gstNumber ?? "-"),
                _infoRow("KYC Status", user.kycStatus.isNotEmpty ? user.kycStatus : "-"),
                _infoRow("Account Status", user.accountStatus.isNotEmpty ? user.accountStatus : "-"),
                _infoRow("Active", user.isActive ? "Yes" : "No"),
                if ((user.kycRejectionReason ?? "").isNotEmpty)
                  _infoRow("Rejection Reason", user.kycRejectionReason!),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 DOCUMENTS CARD (Always rendered for complete parity)
            _buildDocumentsCard(context),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// ================================
  /// HEADER CARD
  /// ================================
  Widget _buildHeaderCard(BuildContext context) {
    final theme = Theme.of(context);

    Color kycColor;
    switch (user.kycStatus.toLowerCase()) {
      case "approved":
        kycColor = Colors.green;
        break;
      case "pending":
        kycColor = Colors.orange;
        break;
      case "rejected":
        kycColor = Colors.red;
        break;
      default:
        kycColor = Colors.grey;
    }

    final avatarUrl = _resolveUrl(user.profileImage);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : (user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : "?"),
                    style: theme.textTheme.headlineMedium,
                  )
                : null,
          ),
          const SizedBox(height: 16),

          Text(
            user.fullName.isEmpty ? user.username : user.fullName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          /// ROLE CHIP
          if (user.role.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

          if (user.kycStatus.isNotEmpty) ...[
            const SizedBox(height: 8),
            /// KYC BADGE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kycColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "KYC ${user.kycStatus.toUpperCase()}",
                style: TextStyle(
                  color: kycColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ================================
  /// INFO CARD
  /// ================================
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordRow(BuildContext context) {
    final password = user.plainPassword;
    final hasPassword = password != null && password.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 130,
            child: Text(
              "Plain Password",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: hasPassword
                ? Row(
                    children: [
                      Text(
                        _obscurePassword ? "••••••••" : password,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: password));
                          Get.snackbar(
                            "Copied",
                            "Password copied to clipboard",
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 1),
                          );
                        },
                        child: const Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : const Text("-", style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tags",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (user.tags.isEmpty)
            const Text(
              "No tags assigned",
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.tags.map((tag) {
                final color = Colors.primaries[tag.id % Colors.primaries.length];
                return Chip(
                  label: Text(tag.tagName),
                  backgroundColor: color.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// ================================
  /// DOCUMENTS CARD (Full Web Parity)
  /// ================================
  Widget _buildDocumentsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Uploaded Documents",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.folder_shared_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _documentRow(context, "PAN Card", user.panImage),
          _documentRow(context, "GST Certificate", user.gstImage),
          _documentRow(context, "Aadhaar Card (Front)", user.aadharFrontImage),
          _documentRow(context, "Aadhaar Card (Back)", user.aadharBackImage),
        ],
      ),
    );
  }

  Widget _documentRow(BuildContext context, String title, String? rawUrl) {
    final theme = Theme.of(context);
    final resolvedUrl = _resolveUrl(rawUrl);
    final hasDoc = resolvedUrl != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasDoc
                      ? Colors.green.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasDoc ? "Uploaded" : "Not Uploaded",
                  style: TextStyle(
                    color: hasDoc ? Colors.green : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (hasDoc) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                resolvedUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 60,
                  alignment: Alignment.center,
                  color: theme.cardColor,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 20, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        "Document attached (preview unavailable)",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _resolveUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed == 'null') return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '${ApiUrls.baseUrl}${trimmed.startsWith('/') ? '' : '/'}$trimmed';
  }
}
