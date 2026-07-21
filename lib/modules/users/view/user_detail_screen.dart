import 'package:agro_broker/modules/users/model/tag_model.dart';
import 'package:agro_broker/services/tag_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/user_model.dart';

class UserDetailScreen extends StatelessWidget {
  UserDetailScreen({super.key});

  late final UserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Convert Get.arguments to UserModel if it's a Map
    if (Get.arguments is UserModel) {
      user = Get.arguments;
    } else if (Get.arguments is Map<String, dynamic>) {
      user = UserModel.fromJson(Get.arguments as Map<String, dynamic>);
    } else {
      throw Exception("Invalid argument type for UserDetailScreen");
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text("User Details"),
        centerTitle: true,
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
                _infoRow("Username", user.username),
                _infoRow("Mobile", user.mobile),
                _infoRow("Email", user.email ?? "-"),
                _infoRow("Gender", user.gender ?? "-"),
                _infoRow("DOB", user.dob ?? "-"),
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
                _infoRow("KYC Status", user.kycStatus),
                _infoRow("Account Status", user.accountStatus),
                _infoRow("Active", user.isActive ? "Yes" : "No"),
                if ((user.kycRejectionReason ?? "").isNotEmpty)
                  _infoRow("Rejection Reason", user.kycRejectionReason!),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 DOCUMENTS CARD
            if (user.panImage != null || user.gstImage != null)
              _buildDocumentsCard(context),
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
            radius: 50,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: user.profileImage != null
                ? NetworkImage(user.profileImage!)
                : null,
            child: user.profileImage == null
                ? Text(
                    user.username.substring(0, 1).toUpperCase(),
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
          ),

          const SizedBox(height: 6),

          /// ROLE CHIP
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
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// KYC BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kycColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              "KYC ${user.kycStatus.toUpperCase()}",
              style: TextStyle(color: kycColor, fontWeight: FontWeight.bold),
            ),
          ),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
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
          /// TITLE
          Text(
            "Tags",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          /// TAG LIST
          if (user.tags.isEmpty)
            const Text("No tags assigned")
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.tags.map((tag) {
                final color =
                    Colors.primaries[tag.id % Colors.primaries.length];

                return GestureDetector(
                  onLongPress: () {
                    _updateTag(context, tag);
                  },
                  child: Chip(
                    label: Text(tag.tagName),
                    backgroundColor: color.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () {
                      _removeTag(tag.id);
                    },
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _removeTag(int tagId) {
    Get.dialog(
      AlertDialog(
        title: const Text("Remove Tag"),
        content: const Text("Do you want to remove this tag?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),

          ElevatedButton(
            onPressed: () async {
              /// TODO: call delete tag API
              Get.back();

              Get.snackbar(
                "Removed",
                "Tag removed successfully",
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  void _updateTag(BuildContext context, Tag tag) {
    final TextEditingController controller = TextEditingController(
      text: tag.tagName,
    );

    Get.dialog(
      AlertDialog(
        title: const Text("Update Tag"),

        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Tag Name"),
        ),

        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),

          ElevatedButton(
            onPressed: () async {
              final newTag = controller.text.trim();

              if (newTag.isEmpty) {
                Get.snackbar("Error", "Tag name required");
                return;
              }

              try {
                final response = await TagService.updateTag(tag.id, newTag);

                Get.back();

                Get.snackbar(
                  "Success",
                  response.message,
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar("Error", e.toString());
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  /// ================================
  /// DOCUMENTS CARD
  /// ================================
  Widget _buildDocumentsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
            "Documents",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (user.panImage != null) _imagePreview("PAN Image", user.panImage!),

          if (user.gstImage != null) _imagePreview("GST Image", user.gstImage!),
        ],
      ),
    );
  }

  Widget _imagePreview(String title, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
