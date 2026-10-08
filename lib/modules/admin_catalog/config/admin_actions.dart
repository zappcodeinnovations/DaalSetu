import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A choice for a dropdown field: what is sent ([value]) and what is shown ([label]).
class AdminOption {
  const AdminOption(this.value, this.label);

  final String value;
  final String label;
}

/// Readable text for any API value: nested objects show their name, lists are joined.
String adminDisplayValue(Object? value) {
  if (value == null) return '';
  if (value is Map) {
    for (final key in const [
      'name', 'title', 'category_name', 'brand_name', 'legal_name', 'location_name',
      'vehicle_number', 'driver_name', 'username', 'id',
    ]) {
      final text = (value[key] ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
  if (value is List) {
    return value.map(adminDisplayValue).where((text) => text.isNotEmpty).join(', ');
  }
  return value.toString().trim();
}

String _message(Object error) => error.toString().replaceFirst('Exception: ', '');

List<Map<String, dynamic>> adminListFrom(dynamic response) {
  if (response is List) return response.whereType<Map>().map(Map<String, dynamic>.from).toList();
  if (response is Map) {
    for (final key in const ['results', 'data', 'items', 'buyer_offers', 'contracts', 'bids']) {
      final raw = response[key];
      if (raw is List) return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
      if (raw is Map) {
        final nested = adminListFrom(raw);
        if (nested.isNotEmpty) return nested;
      }
    }
  }
  return const [];
}

Future<List<AdminOption>> _load(String endpoint, AdminOption Function(Map<String, dynamic>) map) async {
  final response = await ApiClient.get(endpoint: endpoint, requireAuth: true);
  return adminListFrom(response).map(map).where((option) => option.value.isNotEmpty).toList();
}

String _userLabel(Map<String, dynamic> user) {
  final name = [user['first_name'], user['last_name']]
      .where((part) => (part ?? '').toString().trim().isNotEmpty)
      .join(' ');
  final display = name.isNotEmpty ? name : (user['username'] ?? user['name'] ?? '').toString();
  final mobile = (user['mobile'] ?? '').toString();
  return mobile.isEmpty ? display : '$display ($mobile)';
}

/// Dropdown sources. Top-level functions so field configs can stay `const`.
Future<List<AdminOption>> loadTransporterOptions() =>
    _load('/api/users/?role=transporter', (u) => AdminOption('${u['id'] ?? ''}', _userLabel(u)));

Future<List<AdminOption>> loadCategoryOptions() => _load(
      '/api/categories/',
      (c) => AdminOption('${c['id'] ?? ''}', (c['full_path'] ?? c['category_name'] ?? c['name'] ?? '').toString()),
    );

Future<List<AdminOption>> loadParentCategoryOptions() => _load(
      '/api/categories/',
      (c) => c['parent'] == null
          ? AdminOption('${c['id'] ?? ''}', (c['category_name'] ?? c['name'] ?? '').toString())
          : const AdminOption('', ''),
    );

Future<List<AdminOption>> loadOfferOptions() => _load(
      '/api/products/',
      (o) => AdminOption('${o['id'] ?? ''}', '#${o['id']} ${(o['title'] ?? 'Offer').toString()}'),
    );

Future<List<AdminOption>> loadSubAdminOptions() =>
    _load('/api/admin/sub-admin-accounts/?status=active', (u) => AdminOption('${u['id'] ?? ''}', _userLabel(u)));

/// Dropdown data for the sub admin (web "Salesman") form, fetched once per form.
Future<Map<String, dynamic>> _subAdminFormOptions() async {
  final response = await ApiClient.get(endpoint: '/api/admin/sub-admin-accounts/?view=options', requireAuth: true);
  final data = response is Map ? response['data'] : null;
  return data is Map ? Map<String, dynamic>.from(data) : const {};
}

Future<List<AdminOption>> _fromOptions(String key, String Function(Map<String, dynamic>) label) async {
  final raw = (await _subAdminFormOptions())[key];
  return (raw is List ? raw : const [])
      .whereType<Map>()
      .map((item) => AdminOption('${item['id']}', label(Map<String, dynamic>.from(item))))
      .toList();
}

Future<List<AdminOption>> loadSubAdminCompanyOptions() =>
    _fromOptions('companies', (c) => (c['legal_name'] ?? 'Company').toString());

Future<List<AdminOption>> loadSubAdminRoleOptions() => _fromOptions('roles', (r) => (r['name'] ?? 'Role').toString());

/// Filled only for Super Admin; a normal admin always creates sub admins under themselves.
Future<List<AdminOption>> loadParentAdminOptions() => _fromOptions('parent_admins', _userLabel);

/// Web "Change Status" on a user: Active, Deactivated or Suspended (suspension needs a reason).
AdminCustomAction userStatusAction() => AdminCustomAction(
      title: 'Change Status',
      icon: Icons.manage_accounts_outlined,
      onPressed: (context, record) async {
        const labels = {'active': 'Active', 'deactivated': 'Deactivated', 'suspended': 'Suspended'};
        var selected = (record['account_status'] ?? record['status'] ?? 'active').toString().toLowerCase();
        if (!labels.containsKey(selected)) selected = 'active';
        final reason = TextEditingController(text: (record['suspension_reason'] ?? '').toString());
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setState) => AlertDialog(
              title: const Text('Change Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in labels.entries)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.value),
                      value: entry.key,
                      groupValue: selected,
                      onChanged: (value) => setState(() => selected = value ?? selected),
                    ),
                  if (selected == 'suspended')
                    TextField(
                      controller: reason,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Suspension reason *', border: OutlineInputBorder()),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
              ],
            ),
          ),
        );
        final note = reason.text.trim();
        reason.dispose();
        if (confirmed != true) return false;
        if (selected == 'suspended' && note.isEmpty) {
          Get.snackbar('Error', 'Suspension reason is required.', snackPosition: SnackPosition.BOTTOM);
          return false;
        }
        try {
          final response = await ApiClient.post(
            endpoint: '/api/users/${record['id']}/status/',
            body: {'status': selected, if (selected == 'suspended') 'suspension_reason': note},
            requireAuth: true,
          );
          Get.snackbar('Success', (response['message'] ?? 'Status updated').toString(), snackPosition: SnackPosition.BOTTOM);
          return true;
        } catch (error) {
          Get.snackbar('Error', _message(error), snackPosition: SnackPosition.BOTTOM);
          return false;
        }
      },
    );

/// Asks for confirmation (and optionally a note), then runs [request]. Returns true when it succeeded.
Future<bool> adminConfirmAndRun(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  required Future<dynamic> Function(String note) request,
  String? noteLabel,
  bool noteRequired = false,
  bool destructive = false,
}) async {
  final noteController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      var showError = false;
      return StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (noteLabel != null) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: noteRequired ? '$noteLabel *' : noteLabel,
                    errorText: showError ? '$noteLabel is required' : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              style: destructive ? FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error) : null,
              onPressed: () {
                if (noteRequired && noteController.text.trim().isEmpty) {
                  setState(() => showError = true);
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(confirmText),
            ),
          ],
        ),
      );
    },
  );
  final note = noteController.text.trim();
  noteController.dispose();
  if (confirmed != true) return false;
  try {
    final response = await request(note);
    final text = response is Map ? (response['message'] ?? '').toString() : '';
    Get.snackbar('Success', text.isEmpty ? 'Done' : text, snackPosition: SnackPosition.BOTTOM);
    return true;
  } catch (error) {
    Get.snackbar('Error', _message(error), snackPosition: SnackPosition.BOTTOM);
    return false;
  }
}

/// A card button that POSTs `{"action": action, noteKey: note}` to [endpoint] after confirming.
AdminCustomAction adminPostAction({
  required String title,
  required IconData icon,
  required String Function(Map<String, dynamic> record) endpoint,
  required String action,
  required String confirmMessage,
  bool Function(Map<String, dynamic> record)? isVisible,
  String? noteKey,
  String? noteLabel,
  bool noteRequired = false,
  bool destructive = false,
  Map<String, dynamic> extra = const {},
}) {
  return AdminCustomAction(
    title: title,
    icon: icon,
    isVisible: isVisible,
    onPressed: (context, record) => adminConfirmAndRun(
      context,
      title: title,
      message: confirmMessage,
      confirmText: title,
      noteLabel: noteLabel,
      noteRequired: noteRequired,
      destructive: destructive,
      request: (note) => ApiClient.post(
        endpoint: endpoint(record),
        body: {'action': action, ...extra, if (noteKey != null && note.isNotEmpty) noteKey: note},
        requireAuth: true,
      ),
    ),
  );
}

String recordStatus(Map<String, dynamic> record) => (record['status'] ?? '').toString().toLowerCase();

/// Web "Final Confirm" on a buyer offer: pick the sub admin who will handle the contract.
/// The backend only accepts sub admins under the seller's branch admin and buyer-confirmed offers.
Future<bool> confirmBuyerOffer(BuildContext context, Map<String, dynamic> record) async {
  final options = loadSubAdminOptions();
  String? subAdminId;
  final remark = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Confirm Deal'),
      content: FutureBuilder<List<AdminOption>>(
        future: options,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
          }
          final subAdmins = snapshot.data ?? const <AdminOption>[];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Create the contract for "${record['title'] ?? 'this offer'}".'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Assign Sub Admin *', border: OutlineInputBorder()),
                items: subAdmins
                    .map((option) => DropdownMenuItem(value: option.value, child: Text(option.label, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (value) => subAdminId = value,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remark,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Remark', border: OutlineInputBorder()),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirm Deal')),
      ],
    ),
  );
  final note = remark.text.trim();
  remark.dispose();
  if (confirmed != true) return false;
  if (subAdminId == null) {
    Get.snackbar('Error', 'Select a sub admin to confirm the deal.', snackPosition: SnackPosition.BOTTOM);
    return false;
  }
  try {
    final response = await ApiClient.post(
      endpoint: '/api/buyer-offers/${record['id']}/action/',
      body: {
        'action': 'admin_confirm',
        'assigned_sub_admin_id': int.tryParse(subAdminId!) ?? subAdminId,
        if (note.isNotEmpty) 'superadmin_remark': note,
      },
      requireAuth: true,
    );
    Get.snackbar('Success', (response['message'] ?? 'Deal confirmed').toString(), snackPosition: SnackPosition.BOTTOM);
    return true;
  } catch (error) {
    Get.snackbar('Error', _message(error), snackPosition: SnackPosition.BOTTOM);
    return false;
  }
}
