import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/users/model/user_model.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/services/users_services.dart';
import 'package:daalsetu/theme/app_theme.dart';

class ApproveDealResult {
  final String remark;
  final int? subAdminId;

  ApproveDealResult({
    required this.remark,
    this.subAdminId,
  });
}

class ApproveDealDialog extends StatefulWidget {
  final String? buyerName;
  final String? offerTitle;

  const ApproveDealDialog({
    super.key,
    this.buyerName,
    this.offerTitle,
  });

  @override
  State<ApproveDealDialog> createState() => _ApproveDealDialogState();
}

class _ApproveDealDialogState extends State<ApproveDealDialog> {
  final TextEditingController _remarkCtrl = TextEditingController();
  bool _isLoadingSubAdmins = false;
  List<UserModel> _subAdmins = [];
  int? _selectedSubAdminId;
  String? _subAdminLoadError;

  Color get cardColor => Get.theme.cardColor;
  Color get textDark => Get.theme.textTheme.bodyLarge?.color ?? Colors.black;
  Color get textLight => Get.theme.textTheme.bodySmall?.color ?? Colors.grey;

  @override
  void initState() {
    super.initState();
    _fetchSubAdmins();
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSubAdmins() async {
    setState(() {
      _isLoadingSubAdmins = true;
      _subAdminLoadError = null;
    });

    try {
      // 1. Try RBAC endpoint first
      List<UserModel> loaded = [];
      try {
        final rbacRes = await ApiClient.get(
          endpoint: '/rbac/sub-admins/',
          requireAuth: true,
        );
        final list = rbacRes is Map ? (rbacRes['results'] ?? rbacRes['data'] ?? rbacRes['value']) : rbacRes;
        if (list is List && list.isNotEmpty) {
          loaded = list
              .whereType<Map<String, dynamic>>()
              .map((e) => UserModel.fromJson(e))
              .toList();
        }
      } catch (_) {
        // Fallback silently to UserService.getUsers()
      }

      // 2. If RBAC had no items, fallback to global user directory filtered by role
      if (loaded.isEmpty) {
        final allUsers = await UserService.getUsers();
        loaded = allUsers.where((u) {
          final r = u.role.toLowerCase().trim();
          return r == 'sub_admin' ||
              r == 'subadmin' ||
              r == 'admin' ||
              r == 'salesman';
        }).toList();
      }

      if (mounted) {
        setState(() {
          _subAdmins = loaded;
          _isLoadingSubAdmins = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subAdminLoadError = "Could not load sub-admins";
          _isLoadingSubAdmins = false;
        });
      }
    }
  }

  String _getUserDisplayName(UserModel user) {
    final names = [user.firstName, user.lastName]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(' ');
    final name = names.isNotEmpty ? names : user.username;
    final role = user.role.isNotEmpty ? " (${user.role})" : "";
    return "$name$role";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            "Approve Deal",
            style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Confirm and approve deal with ${widget.buyerName ?? 'Buyer'}?",
              style: TextStyle(color: textDark, fontSize: 14),
            ),
            if (widget.offerTitle != null && widget.offerTitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                "Offer: ${widget.offerTitle}",
                style: TextStyle(color: textLight, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 18),

            // ── Sub-Admin Dropdown Field ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Assign Sub-Admin",
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isLoadingSubAdmins)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<int?>(
              value: _selectedSubAdminId,
              isExpanded: true,
              dropdownColor: cardColor,
              style: TextStyle(color: textDark, fontSize: 14),
              decoration: InputDecoration(
                hintText: _isLoadingSubAdmins
                    ? "Loading sub-admins..."
                    : (_subAdmins.isEmpty ? "No sub-admins found (Optional)" : "Select Sub-Admin (Optional)"),
                hintStyle: TextStyle(color: textLight, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: textLight.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
                ),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    "-- None / Do not assign --",
                    style: TextStyle(color: textLight, fontStyle: FontStyle.italic),
                  ),
                ),
                ..._subAdmins.map((user) {
                  return DropdownMenuItem<int?>(
                    value: user.id,
                    child: Text(
                      _getUserDisplayName(user),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textDark),
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSubAdminId = value;
                });
              },
            ),
            if (_subAdminLoadError != null) ...[
              const SizedBox(height: 4),
              Text(
                _subAdminLoadError!,
                style: const TextStyle(color: Colors.orange, fontSize: 11),
              ),
            ],

            const SizedBox(height: 16),

            // ── Admin Remark Field ────────────────────────────────────────
            Text(
              "Admin Remark",
              style: TextStyle(
                color: textDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _remarkCtrl,
              style: TextStyle(color: textDark),
              decoration: InputDecoration(
                hintText: "Enter remarks or instructions (Optional)",
                hintStyle: TextStyle(color: textLight, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: textLight.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text("Cancel", style: TextStyle(color: textLight)),
        ),
        FilledButton(
          onPressed: () {
            final result = ApproveDealResult(
              remark: _remarkCtrl.text.trim(),
              subAdminId: _selectedSubAdminId,
            );
            Navigator.pop(context, result);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.successGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: const Text("Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
