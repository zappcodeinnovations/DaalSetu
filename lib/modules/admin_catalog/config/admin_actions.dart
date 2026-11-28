import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_snackbar.dart';

/// A choice for a dropdown field: what is sent ([value]) and what is shown ([label]).
class AdminOption {
  const AdminOption(this.value, this.label, {this.extras = const {}});

  final String value;
  final String label;

  /// Extra details that other (read-only) fields of the form show once this option is picked,
  /// e.g. a driver's phone number and licence number.
  final Map<String, String> extras;
}

/// Readable text for any API value: nested objects show their name, lists are joined.
String adminDisplayValue(Object? value, {String? key}) {
  if (value == null) return '';
  if (value is bool) {
    return value ? 'Active' : 'Inactive';
  }
  if (value is Map) {
    for (final k in const [
      'name', 'title', 'category_name', 'brand_name', 'legal_name', 'location_name',
      'vehicle_number', 'driver_name', 'username', 'id',
    ]) {
      final text = (value[k] ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
  if (value is List) {
    return value.map((item) => adminDisplayValue(item, key: key)).where((text) => text.isNotEmpty).join(', ');
  }
  final text = value.toString().trim();
  if (text.toLowerCase() == 'true') return 'Active';
  if (text.toLowerCase() == 'false') return 'Inactive';

  // Format date / timestamp values nicely (e.g. 2026-07-25T10:13:26.684876+05:30 -> 25 Jul 2026, 10:13 AM)
  final formattedDate = formatAdminDateValue(text, key: key);
  if (formattedDate != null) {
    return formattedDate;
  }

  return text;
}

/// Formats raw ISO date-time strings into user-friendly text like "25 Jul 2026, 10:13 AM"
String? formatAdminDateValue(String text, {String? key}) {
  if (text.isEmpty) return null;

  final isIsoDateTime = RegExp(r'^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}').hasMatch(text);
  final isDateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text);
  final isKeyDate = key != null && (
    key.toLowerCase().contains('created_at') ||
    key.toLowerCase().contains('updated_at') ||
    key.toLowerCase().contains('date')
  );

  if (!isIsoDateTime && !isDateOnly && !isKeyDate) {
    return null;
  }

  try {
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    final date = parsed.toLocal();

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');

    if (isDateOnly || (!text.contains(':') && !text.contains('T'))) {
      return "$day $month ${date.year}";
    }

    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return "$day $month ${date.year}, $hour:$min $amPm";
  } catch (_) {
    return null;
  }
}

void _showAdminToast(String title, String message, {bool isError = false}) {
  AppSnackbar.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    borderRadius: 12,
    duration: const Duration(seconds: 3),
    backgroundColor: isError ? const Color(0xFFB00020) : const Color(0xFF1E2638),
    colorText: Colors.white,
    icon: Icon(
      isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
      color: Colors.white,
    ),
  );
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

/// Party pickers (transporters) show the company, not the person (MoM point 24).
String _partyLabel(Map<String, dynamic> user) {
  final company = (user['company_display_name'] ?? user['company_name'] ?? '').toString().trim();
  if (company.isEmpty) return _userLabel(user);
  final mobile = (user['mobile'] ?? '').toString();
  return mobile.isEmpty ? company : '$company ($mobile)';
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
///
/// The API is role-filtered, and this local check protects the picker from old
/// deployments that ignored the query parameter.  It matches the web panel:
/// active, KYC-approved transporters only.
List<AdminOption> transporterOptionsFromUsers(Iterable<Map<String, dynamic>> users) => users
    .where((user) {
      final role = (user['role'] ?? '').toString().trim().toLowerCase();
      final kycStatus = (user['kyc_status'] ?? '').toString().trim().toLowerCase();
      return role == 'transporter' && user['is_active'] != false && kycStatus == 'approved';
    })
    .map((user) => AdminOption('${user['id'] ?? ''}', _userLabel(user)))
    .where((option) => option.value.isNotEmpty)
    .toList();

Future<List<AdminOption>> loadTransporterOptions() async {
  final response = await ApiClient.get(endpoint: '/api/users/?role=transporter', requireAuth: true);
  return transporterOptionsFromUsers(adminListFrom(response));
}

/// Drivers a vehicle can be assigned to (Assign Driver on Create / Edit Registered Vehicle). The server
/// only accepts drivers of the vehicle's own transporter.
Future<List<AdminOption>> loadDriverOptions() => _load('/api/drivers/', _driverOption);

/// A vehicle's driver picker: the chosen transporter's active drivers that are free (or already on this
/// vehicle when editing), as the web Register Vehicle form offers. No transporter chosen means no drivers.
Future<List<AdminOption>> loadTransporterDriverOptions(String transporterId, String? vehicleId) async {
  if (transporterId.trim().isEmpty) return const [];
  final query = {
    'status': 'active',
    'exclude_assigned': '1',
    'transporter_id': transporterId.trim(),
    'page_size': '500',
    if (vehicleId != null && vehicleId.isNotEmpty) 'current_vehicle_id': vehicleId,
  };
  return _load(Uri(path: '/api/drivers/', queryParameters: query).toString(), _driverOption);
}

AdminOption _driverOption(Map<String, dynamic> d) {
        final name = (d['driver_name'] ?? d['name'] ?? '').toString().trim();
        final license = (d['license_number'] ?? '').toString().trim();
        final phone = (d['phone_number'] ?? '').toString().trim();
        return AdminOption(
          '${d['id'] ?? ''}',
          // The web shows "Name (phone)"; the other details fill their own fields below.
          phone.isEmpty ? name : '$name ($phone)',
          extras: {'phone': phone, 'license': license},
        );
}

/// Product tags (offers / brands) and User tags (buyers and sellers) for the tag pickers.
Future<List<AdminOption>> loadProductTagOptions() => _load(
      '/api/tags/dropdown/?tag_type=product',
      (t) => AdminOption('${t['id'] ?? ''}', (t['tag_name'] ?? t['name'] ?? '').toString()),
    );

Future<List<AdminOption>> loadUserTagOptions() => _load(
      '/api/tags/dropdown/?tag_type=user',
      (t) => AdminOption('${t['id'] ?? ''}', (t['tag_name'] ?? t['name'] ?? '').toString()),
    );

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

Future<List<AdminOption>> loadBrandOptions() => _load(
      '/api/brands/',
      (b) => AdminOption(
        '${b['id'] ?? ''}',
        (b['brand_name'] ?? b['name'] ?? 'Brand').toString(),
      ),
    );

/// Brand names for a user's Brand (the web stores the name, not the brand id).
Future<List<AdminOption>> loadBrandNameOptions() async {
  final brands = await _load('/api/brands/', (b) {
    final name = (b['brand_name'] ?? b['name'] ?? '').toString().trim();
    return AdminOption(name, name);
  });
  final seen = <String>{};
  return [for (final b in brands) if (seen.add(b.value.toLowerCase())) b];
}

Future<List<AdminOption>> loadOfferOptions() => _load(
      '/api/products/',
      (o) => AdminOption('${o['id'] ?? ''}', (o['title'] ?? 'Offer').toString()),
    );

Future<List<AdminOption>> loadSubAdminOptions() =>
    _load('/api/admin/sub-admin-accounts/?status=active', (u) => AdminOption('${u['id'] ?? ''}', _userLabel(u)));

Future<List<AdminOption>> loadAdminOptions() =>
    _load('/api/users/?role=admin', (u) => AdminOption('${u['id'] ?? ''}', _userLabel(u)));

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

/// The signed-in user's own branch code (primary branch first): the web pre-fills it on the sub admin / salesman
/// form, so the app does too. Null when the user is in no branch.
Future<String?> loadOwnBranchCode() async {
  final response = await ApiClient.get(endpoint: '/api/seller/branches/', requireAuth: true);
  final data = response is Map ? response['data'] : null;
  if (data is! Map) return null;
  final primary = data['primary_branch'];
  if (primary is Map && (primary['branch_code'] ?? '').toString().isNotEmpty) return primary['branch_code'].toString();
  final others = data['my_branches'];
  if (others is List) {
    for (final item in others) {
      if (item is Map && (item['branch_code'] ?? '').toString().isNotEmpty) return item['branch_code'].toString();
    }
  }
  return null;
}

Future<List<AdminOption>> loadSubAdminCompanyOptions() =>
    _fromOptions('companies', (c) => (c['legal_name'] ?? 'Company').toString());

Future<List<AdminOption>> loadSubAdminRoleOptions() => _fromOptions('roles', (r) => (r['name'] ?? 'Role').toString());

/// Filled only for Super Admin; a normal admin always creates sub admins under themselves.
Future<List<AdminOption>> loadParentAdminOptions() => _fromOptions('parent_admins', _userLabel);

/// Companies which can be selected as the legal entity on a brokerage bill.
/// The billing endpoint exposes these separately from the saved billing profiles.
Future<List<AdminOption>> loadAvailableBillingCompanyOptions() async {
  final response = await ApiClient.get(
    endpoint: '/api/admin/billing-companies/',
    requireAuth: true,
  );
  final raw = response is Map ? response['available_companies'] : null;
  return (raw is List ? raw : const [])
      .whereType<Map>()
      .map((item) {
        final company = Map<String, dynamic>.from(item);
        return AdminOption(
          '${company['id'] ?? ''}',
          (company['legal_name'] ?? company['company_name'] ?? 'Company').toString(),
        );
      })
      .where((option) => option.value.isNotEmpty)
      .toList();
}

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
                FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
                OutlinedButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              ],
            ),
          ),
        );
        final note = reason.text.trim();
        reason.dispose();
        if (confirmed != true) return false;
        if (selected == 'suspended' && note.isEmpty) {
          _showAdminToast('Error', 'Suspension reason is required.', isError: true);
          return false;
        }
        try {
          final response = await ApiClient.post(
            endpoint: '/api/users/${record['id']}/status/',
            body: {'status': selected, if (selected == 'suspended') 'suspension_reason': note},
            requireAuth: true,
          );
          _showAdminToast('Success', (response['message'] ?? 'Status updated').toString());
          return true;
        } catch (error) {
          _showAdminToast('Error', _message(error), isError: true);
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
      final theme = Theme.of(dialogContext);
      final isReject = title.toLowerCase().contains('reject') || destructive;

      return StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          titlePadding: EdgeInsets.zero,
          title: isReject
              ? Container(
                  color: const Color(0xFFEA580C),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(dialogContext, false),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Text(title),
                ),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isNotEmpty && (!isReject || noteLabel == null)) ...[
                Text(message),
                const SizedBox(height: 12),
              ],
              if (noteLabel != null) ...[
                Text(
                  noteLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter ${noteLabel.toLowerCase()}',
                    errorText: showError ? '$noteLabel is required' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            if (isReject)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (noteRequired && noteController.text.trim().isEmpty) {
                    setState(() => showError = true);
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: Text(confirmText),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (noteRequired && noteController.text.trim().isEmpty) {
                    setState(() => showError = true);
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: Text(confirmText),
              ),
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel'),
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
    _showAdminToast('Success', text.isEmpty ? 'Done' : text);
    return true;
  } catch (error) {
    _showAdminToast('Error', _message(error), isError: true);
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
      request: (note) {
        final ep = endpoint(record);
        if (ep.contains('/api/kyc/')) {
          if (noteKey != null && note.isNotEmpty) {
            return ApiClient.post(
              endpoint: ep,
              body: {noteKey: note},
              requireAuth: true,
            );
          } else {
            return ApiClient.post(
              endpoint: ep,
              body: {},
              requireAuth: true,
            );
          }
        }
        return ApiClient.post(
          endpoint: ep,
          body: {'action': action, ...extra, if (noteKey != null && note.isNotEmpty) noteKey: note},
          requireAuth: true,
        );
      },
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
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirm Deal')),
        OutlinedButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
      ],
    ),
  );
  final note = remark.text.trim();
  remark.dispose();
  if (confirmed != true) return false;
  if (subAdminId == null) {
    _showAdminToast('Error', 'Select a sub admin to confirm the deal.', isError: true);
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
    _showAdminToast('Success', (response['message'] ?? 'Deal confirmed').toString());
    return true;
  } catch (error) {
    _showAdminToast('Error', _message(error), isError: true);
    return false;
  }
}
