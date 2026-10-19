import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_actions.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/theme/app_theme.dart';
import '../../../utils/app_snackbar.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoadingSubAdmins = false;
  List<AdminOption> _subAdmins = [];
  String? _selectedSubAdminValue;
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
      List<AdminOption> loaded = await loadSubAdminOptions();
      if (loaded.isEmpty) {
        // Fallback to /api/users/?role=sub_admin if sub-admin-accounts endpoint returns empty
        final fallback = await ApiClient.get(
          endpoint: '/api/users/?role=sub_admin',
          requireAuth: true,
          suppressErrorDialog: true,
        );
        loaded = adminListFrom(fallback)
            .map((u) {
              final name = [u['first_name'], u['last_name']]
                  .where((p) => (p ?? '').toString().trim().isNotEmpty)
                  .join(' ');
              final display = name.isNotEmpty
                  ? name
                  : (u['username'] ?? u['name'] ?? '').toString();
              final mobile = (u['mobile'] ?? '').toString();
              final label = mobile.isEmpty ? display : '$display ($mobile)';
              return AdminOption('${u['id'] ?? ''}', label);
            })
            .where((o) => o.value.isNotEmpty)
            .toList();
      }

      if (mounted) {
        setState(() {
          _subAdmins = loaded;
          if (_subAdmins.isNotEmpty && _selectedSubAdminValue == null) {
            _selectedSubAdminValue = _subAdmins.first.value;
          }
          _isLoadingSubAdmins = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subAdminLoadError = _errorMessage(e);
          _isLoadingSubAdmins = false;
        });
      }
    }
  }

  String _errorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Could not load sub-admins' : message;
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
        child: Form(
          key: _formKey,
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

              // ── Sub-Admin Dropdown Field (Assign Contract Under Sub Admin) ─
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Assign Contract Under Sub Admin *",
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
              DropdownButtonFormField<String>(
                initialValue: _selectedSubAdminValue,
                isExpanded: true,
                dropdownColor: cardColor,
                style: TextStyle(color: textDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: _isLoadingSubAdmins
                      ? "Loading sub-admins..."
                      : (_subAdmins.isEmpty ? "No active sub-admins found" : "Select Sub Admin"),
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
                validator: (value) => value == null || value.isEmpty ? 'Please select a Sub Admin before approval' : null,
                items: _subAdmins.map((option) {
                  return DropdownMenuItem<String>(
                    value: option.value,
                    child: Text(
                      option.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textDark),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubAdminValue = value;
                  });
                },
              ),
              const SizedBox(height: 4),
              Text(
                "Only Sub Admins available under your admin account are listed. This field is required for accept/approve.",
                style: TextStyle(
                  color: textLight,
                  fontSize: 11,
                  height: 1.3,
                ),
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
                "Seller Remark",
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
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text("Cancel", style: TextStyle(color: textLight)),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final subAdminId = int.tryParse(_selectedSubAdminValue ?? '');
            if (subAdminId == null) {
              AppSnackbar.snackbar(
                'Sub Admin Required',
                'Please select a Sub Admin before approval.',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }
            final result = ApproveDealResult(
              remark: _remarkCtrl.text.trim(),
              subAdminId: subAdminId,
            );
            Navigator.pop(context, result);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC2410C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: const Text("Accept Interest", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
