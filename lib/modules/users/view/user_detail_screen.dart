import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/user_model.dart';
import '../../../services/users_services.dart';
import '../../../comman/api_url.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import '../../../utils/app_snackbar.dart';
import 'package:daalsetu/widgets/back_navigation.dart';
import 'package:daalsetu/utils/app_date.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel? initialUser;
  const UserDetailScreen({super.key, this.initialUser});

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
    // Initialize user from arguments or constructor
    final args = widget.initialUser ?? Get.arguments;
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

    if (widget.initialUser == null) {
      _fetchDetailedData();
    }
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        title: user.fullName.isNotEmpty
            ? user.fullName
            : (user.username.isNotEmpty ? user.username : "User Details"),
        subtitle: "Profile, permissions & KYC verification",
        trailing: _isLoadingDetails
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _fetchDetailedData,
                tooltip: "Refresh Details",
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            /// 🔥 HEADER CARD
            _buildHeaderCard(context, isDark: isDark),

            const SizedBox(height: 16),

            /// 🔥 BASIC INFO CARD
            _buildInfoCard(
              context,
              isDark: isDark,
              title: "Basic Information",
              icon: Icons.person_outline_rounded,
              children: [
                _infoRow("Full Name", user.fullName.isNotEmpty ? user.fullName : "-"),
                _infoRow("Username", user.username.isNotEmpty ? user.username : "-"),
                _infoRow("Mobile", user.mobile.isNotEmpty ? user.mobile : "-"),
                _infoRow("Email", user.email ?? "-"),
                _infoRow("Gender", user.gender ?? "-"),
                _infoRow("DOB", AppDate.date(user.dob)),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔥 COMPANY & ASSIGNMENT CARD
            _buildInfoCard(
              context,
              isDark: isDark,
              title: "Company & Assignment",
              icon: Icons.business_outlined,
              children: [
                _infoRow("Company Name", user.companyName ?? "-"),
                _infoRow("Brand", user.brand ?? "-"),
                _infoRow("Branch Codes", user.branchCodes ?? "-"),
                _infoRow("Parent Admin", user.parentAdmin ?? "-"),
                _infoRow("Custom Roles", user.customRoles ?? "-"),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔥 ACCOUNT & SECURITY DETAILS CARD
            _buildInfoCard(
              context,
              isDark: isDark,
              title: "Account & System Details",
              icon: Icons.security_rounded,
              children: [
                _passwordRow(context),
                _infoRow("Registration Reason", user.registrationReason ?? "-"),
                _infoRow("Date Joined", AppDate.dateTime(user.dateJoined)),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔥 TAGS CARD
            _buildTagsCard(context, isDark: isDark),

            const SizedBox(height: 16),

            /// 🔥 KYC INFO CARD
            _buildInfoCard(
              context,
              isDark: isDark,
              title: "KYC Details",
              icon: Icons.verified_user_outlined,
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

            const SizedBox(height: 16),

            /// 🔥 DOCUMENTS CARD (Always rendered for complete parity)
            _buildDocumentsCard(context, isDark: isDark),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// ================================
  /// HEADER CARD
  /// ================================
  Widget _buildHeaderCard(BuildContext context, {required bool isDark}) {
    final theme = Theme.of(context);

    Color kycColor;
    switch (user.kycStatus.toLowerCase()) {
      case "approved":
        kycColor = const Color(0xFF2E7D32);
        break;
      case "pending":
        kycColor = const Color(0xFFF57C00);
        break;
      case "rejected":
        kycColor = const Color(0xFFD32F2F);
        break;
      default:
        kycColor = Colors.grey;
    }

    final avatarUrl = _resolveUrl(user.profileImage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF57C00).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            user.fullName.isEmpty ? user.username : user.fullName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              /// ROLE CHIP
              if (user.role.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57C00).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFFF57C00).withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

              if (user.kycStatus.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: kycColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: kycColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "KYC ${user.kycStatus.toUpperCase()}",
                    style: TextStyle(
                      color: kycColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    final letter = user.fullName.isNotEmpty
        ? user.fullName[0].toUpperCase()
        : (user.username.isNotEmpty ? user.username[0].toUpperCase() : "?");
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// ================================
  /// INFO CARD
  /// ================================
  Widget _buildInfoCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    IconData? icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57C00).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: const Color(0xFFE65100)),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
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
                          AppSnackbar.snackbar(
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

  Widget _buildTagsCard(BuildContext context, {required bool isDark}) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF57C00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.label_outline_rounded, size: 16, color: Color(0xFFE65100)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Assigned Tags",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          if (user.tags.isEmpty)
            const Text(
              "No tags assigned",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.tags.map((tag) {
                final color = Colors.primaries[tag.id % Colors.primaries.length];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    tag.tagName,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
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
  Widget _buildDocumentsCard(BuildContext context, {required bool isDark}) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF57C00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder_shared_outlined, size: 16, color: Color(0xFFE65100)),
              ),
              const SizedBox(width: 10),
              Text(
                "Uploaded Documents",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          _documentRow(context, "PAN Card", user.panImage, isDark: isDark),
          _documentRow(context, "GST Certificate", user.gstImage, isDark: isDark),
          _documentRow(context, "Aadhaar Card (Front)", user.aadharFrontImage, isDark: isDark),
          _documentRow(context, "Aadhaar Card (Back)", user.aadharBackImage, isDark: isDark),
        ],
      ),
    );
  }

  Widget _documentRow(BuildContext context, String title, String? rawUrl, {required bool isDark}) {
    final theme = Theme.of(context);
    final resolvedUrl = _resolveUrl(rawUrl);
    final hasDoc = resolvedUrl != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasDoc
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasDoc ? "Uploaded" : "Not Uploaded",
                  style: TextStyle(
                    color: hasDoc ? const Color(0xFF2E7D32) : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (hasDoc) ...[
            const SizedBox(height: 10),
            // Tap the preview to open it full screen: pinch / double-tap to zoom, back button to close.
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openDocumentViewer(context, title, resolvedUrl),
              child: ClipRRect(
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
            ),
          ],
        ],
      ),
    );
  }

  void _openDocumentViewer(BuildContext context, String title, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _DocumentViewer(title: title, url: url),
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

/// Full-screen document preview with zoom and a back button.
class _DocumentViewer extends StatelessWidget {
  const _DocumentViewer({required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: InteractiveViewer(
        minScale: 0.8,
        maxScale: 6,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white, size: 60),
          ),
        ),
      ),
    );
  }
}
