import 'dart:io';

import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:daalsetu/utils/app_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:daalsetu/modules/downloads/service/downloads_service.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:share_plus/share_plus.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import '../../../utils/app_snackbar.dart';
import 'package:intl/intl.dart';

const _billingEndpoint = '/api/admin/brokerage-bills/';

List<Map<String, dynamic>> _billingMaps(dynamic value) =>
    (value is List ? value : const [])
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList();

String _billingText(Object? value) {
  if (value == null) return '';
  if (value is Map) {
    for (final key in const [
      'label',
      'name',
      'legal_name',
      'company_name',
      'username',
      'title',
      'value',
      'id',
    ]) {
      final text = (value[key] ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
  return value.toString().trim();
}

String _billingUser(Object? value) {
  if (value is! Map) return _billingText(value);
  final first = (value['first_name'] ?? '').toString().trim();
  final last = (value['last_name'] ?? '').toString().trim();
  final fullName = '$first $last'.trim();
  return fullName.isNotEmpty
      ? fullName
      : _billingText(value['username'] ?? value['name']);
}

String _billingMessage(Object error) =>
    error.toString().replaceFirst('Exception: ', '');

String _dateValue(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _formatDateDisplay(DateTime? value) {
  if (value == null) return '';
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

DateTime? _tryParseAnyDate(String? text) {
  if (text == null || text.trim().isEmpty) return null;
  final trimmed = text.trim();
  final iso = DateTime.tryParse(trimmed);
  if (iso != null) return iso;
  final parts = trimmed.split('/');
  if (parts.length == 3) {
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }
  return null;
}

String _money(Object? value) {
  final text = _billingText(value);
  return text.isEmpty ? '—' : '₹$text';
}

String _formatDate(dynamic dateStr) {
  if (dateStr == null) return '—';
  final str = dateStr.toString().trim();
  if (str.isEmpty || str == '—') return '—';
  try {
    final parsed = DateTime.tryParse(str);
    if (parsed != null) {
      return DateFormat('dd/MM/yyyy').format(parsed);
    }
  } catch (_) {}
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(str);
  if (match != null) {
    return '${match.group(3)}/${match.group(2)}/${match.group(1)}';
  }
  return str;
}

class AdminBrokerageBillsScreen extends StatefulWidget {
  const AdminBrokerageBillsScreen({super.key});

  @override
  State<AdminBrokerageBillsScreen> createState() =>
      _AdminBrokerageBillsScreenState();
}

class _AdminBrokerageBillsScreenState extends State<AdminBrokerageBillsScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  String _status = '';
  String _seller = '';
  String _buyer = '';
  String _billingCompany = '';
  String _assignedSubAdmin = '';
  DateTime? _billDateFrom;
  DateTime? _billDateTo;
  int _page = 1;
  bool _hasNext = false;
  bool _loadingMore = false;
  List<Map<String, dynamic>> _records = const [];
  List<Map<String, dynamic>> _statuses = const [];
  List<Map<String, dynamic>> _sellers = const [];
  List<Map<String, dynamic>> _buyers = const [];
  List<Map<String, dynamic>> _companies = const [];
  List<Map<String, dynamic>> _subAdmins = const [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadInitial({bool clearFilters = false}) async {
    if (clearFilters && mounted) {
      setState(() {
        _search.clear();
        _status = '';
        _seller = '';
        _buyer = '';
        _billingCompany = '';
        _assignedSubAdmin = '';
        _billDateFrom = null;
        _billDateTo = null;
      });
    }
    await Future.wait([_loadOptions(), _loadBills(reset: true)]);
  }

  Future<void> _loadOptions() async {
    try {
      final response = await ApiClient.get(
        endpoint: '$_billingEndpoint?view=options',
        requireAuth: true,
      );
      final data = response is Map ? response['data'] : null;
      if (data is Map) {
        _statuses = _billingMaps(data['statuses']);
        _sellers = _billingMaps(data['sellers']);
        _buyers = _billingMaps(data['buyers']);
        _companies = _billingMaps(data['billing_companies']);
        _subAdmins = _billingMaps(data['sub_admins']);
      }
    } catch (_) {
      // The bill list remains usable when optional filter choices cannot load.
    }

    if (_subAdmins.isEmpty) {
      try {
        final subResponse = await ApiClient.get(
          endpoint: '/api/admin/salesmen/',
          requireAuth: true,
        );
        if (subResponse is Map) {
          final subList = subResponse['results'] ?? subResponse['data'];
          if (subList is List && subList.isNotEmpty) {
            _subAdmins = _billingMaps(subList);
          }
        }
      } catch (_) {}
    }

    if (_companies.isEmpty) {
      try {
        final compResponse = await ApiClient.get(
          endpoint: '/api/admin/billing-companies/',
          requireAuth: true,
        );
        if (compResponse is Map) {
          final compList = compResponse['results'] ?? compResponse['data'];
          if (compList is List && compList.isNotEmpty) {
            _companies = _billingMaps(compList);
          }
        }
      } catch (_) {}
    }

    if (mounted) setState(() {});
  }

  Future<void> _loadBills({bool reset = true}) async {
    if (!reset && (_loadingMore || !_hasNext)) return;
    if (mounted && reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else if (mounted) {
      setState(() => _loadingMore = true);
    }
    final requestedPage = reset ? 1 : _page + 1;
    final query = <String, String>{
      'page': '$requestedPage',
      if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
      if (_status.isNotEmpty) 'status': _status,
      if (_seller.isNotEmpty) 'seller': _seller,
      if (_buyer.isNotEmpty) 'buyer': _buyer,
      if (_billingCompany.isNotEmpty) 'billing_company': _billingCompany,
      if (_assignedSubAdmin.isNotEmpty) 'assigned_sub_admin': _assignedSubAdmin,
      if (_billDateFrom != null) 'bill_date_from': _dateValue(_billDateFrom!),
      if (_billDateTo != null) 'bill_date_to': _dateValue(_billDateTo!),
    };
    try {
      final endpoint = Uri(
        path: _billingEndpoint,
        queryParameters: query,
      ).toString();
      final response = await ApiClient.get(
        endpoint: endpoint,
        requireAuth: true,
      );
      if (!mounted || response is! Map) return;
      final pagination = response['pagination'] is Map
          ? response['pagination'] as Map
          : const {};
      final freshRecords = _billingMaps(response['results']);
      setState(() {
        _records = reset ? freshRecords : [..._records, ...freshRecords];
        _page = requestedPage;
        _hasNext = pagination['has_next'] == true;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _billingMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _openCreate() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminCreateBrokerageBillScreen()),
    );
    if (changed == true) await _loadBills(reset: true);
  }

  Future<void> _openDetail(Map<String, dynamic> record) async {
    final id = record['id'];
    if (id == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminBrokerageBillDetailScreen(billId: id.toString()),
      ),
    );
    await _loadBills(reset: true);
  }

  Future<void> _resetFilters() async {
    setState(() {
      _search.clear();
      _status = '';
      _seller = '';
      _buyer = '';
      _billingCompany = '';
      _assignedSubAdmin = '';
      _billDateFrom = null;
      _billDateTo = null;
    });
    await _loadBills(reset: true);
  }

  Future<void> _pickBillDate(bool isFrom) async {
    final current = isFrom ? _billDateFrom : _billDateTo;
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _billDateFrom = selected;
      } else {
        _billDateTo = selected;
      }
    });
  }

  List<Map<String, dynamic>> get _visibleRecords {
    if (_billingCompany.isEmpty) return _records;
    final selectedOption = _companies.firstWhere(
      (opt) => _billingText(opt['value'] ?? opt['id']) == _billingCompany,
      orElse: () => <String, dynamic>{},
    );
    final selectedLabel = _billingText(selectedOption['label'] ?? selectedOption['name'] ?? selectedOption['company_name']).trim().toLowerCase();
    final cleanId = _billingCompany.replaceAll(RegExp(r'[^0-9]'), '');

    return _records.where((bill) {
      final billCompName = _billingText(bill['billing_company_name']).trim().toLowerCase();
      final billCompId = _billingText(bill['billing_company_id'] ?? bill['billing_company']).trim();
      final cleanBillCompId = billCompId.replaceAll(RegExp(r'[^0-9]'), '');

      if (billCompName.isEmpty && billCompId.isEmpty) return false;

      if (selectedLabel.isNotEmpty && billCompName.isNotEmpty) {
        if (billCompName == selectedLabel || billCompName.contains(selectedLabel) || selectedLabel.contains(billCompName)) {
          return true;
        }
      }
      if (cleanId.isNotEmpty && cleanBillCompId.isNotEmpty && cleanId == cleanBillCompId) {
        return true;
      }
      if (_billingCompany.isNotEmpty && billCompName == _billingCompany.toLowerCase()) {
        return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleRecords;
    return Scaffold(
      drawer: const AdminDrawer(activeKey: 'brokerage_bills'),
      appBar: HeroHeader(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Open navigation menu',
            onPressed: () => AppShell.openDrawer(activeKey: 'brokerage_bills'),
          ),
        ),
        title: 'Brokerage Bills',
        subtitle: 'Commercial brokerage settlement invoices',
        trailing: IconButton(
          tooltip: 'Refresh',
          onPressed: _loading ? null : () => _loadInitial(clearFilters: true),
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE65100),
              Color(0xFFF57C00),
              Color(0xFFFFA000),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE65100).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: _openCreate,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Create Bill',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    body: _loading && visible.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => _loadInitial(clearFilters: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _loadBills(reset: true),
                  decoration: InputDecoration(
                    labelText: 'Search bill, seller or challan',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Search',
                      onPressed: () => _loadBills(reset: true),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                _filters(),
                if (_activeFilterCount > 0) ...[
                  const SizedBox(height: 8),
                  _activeFilterChips(),
                ],
                const SizedBox(height: 18),
                Text(
                  'Bills',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (_error != null) _errorCard(),
                if (_error == null && visible.isEmpty) _emptyCard(),
                ...visible.map(_billCard),
                if (_hasNext) _loadMoreButton(),
              ],
            ),
          ),
  );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_status.isNotEmpty) count++;
    if (_seller.isNotEmpty) count++;
    if (_buyer.isNotEmpty) count++;
    if (_billingCompany.isNotEmpty) count++;
    if (_assignedSubAdmin.isNotEmpty) count++;
    if (_billDateFrom != null) count++;
    if (_billDateTo != null) count++;
    return count;
  }

  String _subAdminName(String id) {
    final found = _subAdmins.firstWhere(
      (s) => _billingText(s['id'] ?? s['value']) == id,
      orElse: () => const {},
    );
    final user = _billingUser(found);
    return user.isNotEmpty
        ? user
        : (_billingText(found['name'] ?? found['label']).isNotEmpty
            ? _billingText(found['name'] ?? found['label'])
            : '-');
  }

  String _sellerName(String id) {
    final found = _sellers.firstWhere(
      (s) => _billingText(s['id']) == id,
      orElse: () => const {},
    );
    final user = _billingUser(found);
    return user.isNotEmpty ? user : '-';
  }

  String _buyerName(String id) {
    final found = _buyers.firstWhere(
      (b) => _billingText(b['id']) == id,
      orElse: () => const {},
    );
    final user = _billingUser(found);
    return user.isNotEmpty ? user : '-';
  }

  String _companyName(String id) {
    final found = _companies.firstWhere(
      (c) => _billingText(c['id'] ?? c['value']) == id,
      orElse: () => const {},
    );
    final name = _billingText(
        found['label'] ?? found['company_name'] ?? found['name'] ?? found['legal_name']);
    return name.isNotEmpty ? name : '-';
  }

  Widget _activeFilterChips() {
    final chips = <Widget>[];

    if (_status.isNotEmpty) {
      chips.add(_filterChip(
        label: 'Status: ${_status.toUpperCase()}',
        onDeleted: () {
          setState(() => _status = '');
          _loadBills(reset: true);
        },
      ));
    }
    if (_seller.isNotEmpty) {
      chips.add(_filterChip(
        label: 'Seller: ${_sellerName(_seller)}',
        onDeleted: () {
          setState(() => _seller = '');
          _loadBills(reset: true);
        },
      ));
    }
    if (_buyer.isNotEmpty) {
      chips.add(_filterChip(
        label: 'Buyer: ${_buyerName(_buyer)}',
        onDeleted: () {
          setState(() => _buyer = '');
          _loadBills(reset: true);
        },
      ));
    }
    if (_billingCompany.isNotEmpty) {
      chips.add(_filterChip(
        label: 'Billing: ${_companyName(_billingCompany)}',
        onDeleted: () {
          setState(() => _billingCompany = '');
          _loadBills(reset: true);
        },
      ));
    }
    if (_assignedSubAdmin.isNotEmpty) {
      chips.add(_filterChip(
        label: 'Sub Admin: ${_subAdminName(_assignedSubAdmin)}',
        onDeleted: () {
          setState(() => _assignedSubAdmin = '');
          _loadBills(reset: true);
        },
      ));
    }
    if (_billDateFrom != null) {
      chips.add(_filterChip(
        label: 'From: ${_formatDate(_billDateFrom)}',
        onDeleted: () {
          setState(() => _billDateFrom = null);
          _loadBills(reset: true);
        },
      ));
    }
    if (_billDateTo != null) {
      chips.add(_filterChip(
        label: 'To: ${_formatDate(_billDateTo)}',
        onDeleted: () {
          setState(() => _billDateTo = null);
          _loadBills(reset: true);
        },
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...chips,
          InkWell(
            onTap: _resetFilters,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'Clear all',
                style: TextStyle(
                  color: Color(0xFFFF7A00),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required VoidCallback onDeleted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFFE65100),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(10),
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.tune_rounded),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          if (_activeFilterCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A00),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_activeFilterCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const SizedBox(height: 8),
        _dropdown(
          label: 'Status',
          value: _status,
          options: _statuses,
          valueOf: (item) => _billingText(item['value']),
          labelOf: (item) => _billingText(item['label'] ?? item['value']),
          onChanged: (value) => setState(() => _status = value),
        ),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Seller',
          value: _seller,
          options: _sellers,
          valueOf: (item) => _billingText(item['id']),
          labelOf: _billingUser,
          onChanged: (value) => setState(() => _seller = value),
        ),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Buyer',
          value: _buyer,
          options: _buyers,
          valueOf: (item) => _billingText(item['id']),
          labelOf: _billingUser,
          onChanged: (value) => setState(() => _buyer = value),
        ),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Billing company',
          value: _billingCompany,
          options: _companies,
          valueOf: (item) => _billingText(item['id'] ?? item['value']),
          labelOf: (item) =>
              _billingText(item['label'] ?? item['company_name'] ?? item['name'] ?? item['legal_name']),
          onChanged: (value) => setState(() => _billingCompany = value),
        ),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Assigned Sub Admin',
          value: _assignedSubAdmin,
          options: _subAdmins,
          valueOf: (item) => _billingText(item['id'] ?? item['value']),
          labelOf: (item) {
            final user = _billingUser(item);
            return user.isNotEmpty
                ? user
                : _billingText(item['name'] ?? item['label'] ?? item['username']);
          },
          onChanged: (value) => setState(() => _assignedSubAdmin = value),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isVerySmall = constraints.maxWidth < 280;
            if (isVerySmall) {
              return Column(
                children: [
                  _dateButton(
                    'Bill date from',
                    _billDateFrom,
                    () => _pickBillDate(true),
                  ),
                  const SizedBox(height: 8),
                  _dateButton(
                    'Bill date to',
                    _billDateTo,
                    () => _pickBillDate(false),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _dateButton(
                    'Bill date from',
                    _billDateFrom,
                    () => _pickBillDate(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dateButton(
                    'Bill date to',
                    _billDateTo,
                    () => _pickBillDate(false),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: _resetFilters, child: const Text('Clear')),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _loadBills(reset: true),
              icon: const Icon(Icons.filter_alt_rounded),
              label: const Text('Apply'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _dropdown({
    required String label,
    required String value,
    required List<Map<String, dynamic>> options,
    required String Function(Map<String, dynamic>) valueOf,
    required String Function(Map<String, dynamic>) labelOf,
    required ValueChanged<String> onChanged,
  }) {
    final seenValues = <String>{};
    final menuOptions = options.where((option) {
      final optionValue = valueOf(option).trim();
      return optionValue.isNotEmpty && seenValues.add(optionValue);
    }).toList();
    final validValue = menuOptions.any((option) => valueOf(option).trim() == value)
        ? value
        : '';
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$validValue'),
      isExpanded: true,
      initialValue: validValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('All')),
        ...menuOptions.map(
          (item) => DropdownMenuItem(
            value: valueOf(item).trim(),
            child: Text(labelOf(item), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (next) => onChanged(next ?? ''),
    );
  }

  Widget _errorCard() => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error ?? 'Could not load brokerage bills.'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _loadBills(reset: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _emptyCard() => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 42),
          SizedBox(height: 8),
          Text('No brokerage bills found.'),
        ],
      ),
    ),
  );

  Widget _dateButton(String label, DateTime? value, VoidCallback onPressed) {
    final hasValue = value != null;
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasValue
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: hasValue
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  hasValue ? _formatDateDisplay(value) : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    color: hasValue
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadMoreButton() => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: OutlinedButton.icon(
          onPressed: _loadingMore ? null : () => _loadBills(reset: false),
          icon: _loadingMore
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more_rounded),
          label: Text(_loadingMore ? 'Loading...' : 'Load more'),
        ),
      );

  Widget _billCard(Map<String, dynamic> bill) {
    final status = _billingText(bill['status']).toUpperCase();
    final statusColor = switch (status) {
      'ISSUED' => Colors.green,
      'CANCELLED' => Colors.red,
      _ => Colors.orange,
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDetail(bill),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _billingText(bill['bill_number']).isEmpty
                          ? 'Draft bill'
                          : _billingText(bill['bill_number']),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(status.isEmpty ? 'DRAFT' : status),
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: statusColor.withValues(alpha: .10),
                    side: BorderSide(color: statusColor.withValues(alpha: .35)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _billLine(
                Icons.person_outline_rounded,
                _billingUser(bill['seller']),
              ),
              _billLine(
                Icons.account_balance_outlined,
                _billingText(bill['billing_company_name']),
              ),
              _billLine(
                Icons.calendar_today_outlined,
                'Bill date: ${_formatDate(bill['bill_date'])}',
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _amount(
                      'Brokerage',
                      _money(bill['total_brokerage_amount']),
                    ),
                  ),
                  Expanded(
                    child: _amount('Lines', _billingText(bill['line_count'])),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _billLine(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(value.isEmpty ? '—' : value)),
      ],
    ),
  );

  Widget _amount(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 2),
      Text(
        value.isEmpty ? '—' : value,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class AdminCreateBrokerageBillScreen extends StatefulWidget {
  const AdminCreateBrokerageBillScreen({super.key});

  @override
  State<AdminCreateBrokerageBillScreen> createState() =>
      _AdminCreateBrokerageBillScreenState();
}

class _AdminCreateBrokerageBillScreenState
    extends State<AdminCreateBrokerageBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rate = TextEditingController(text: '0');
  DateTime? _billDateVal = DateTime.now();
  DateTime? _periodFromVal;
  DateTime? _periodToVal;
  final _billDate = TextEditingController(text: _formatDateDisplay(DateTime.now()));
  final _periodFrom = TextEditingController();
  final _periodTo = TextEditingController();
  final _remarks = TextEditingController();
  final Map<String, TextEditingController> _lineRates = {};

  bool _loading = true;
  bool _loadingChallans = false;
  bool _saving = false;
  String? _error;
  String _basis = 'seller';
  String _party = '';
  String _company = '';
  String _subAdmin = '';
  String _commissionType = '';
  List<Map<String, dynamic>> _companies = const [];
  List<Map<String, dynamic>> _sellers = const [];
  List<Map<String, dynamic>> _buyers = const [];
  List<Map<String, dynamic>> _subAdmins = const [];
  List<Map<String, dynamic>> _commissionTypes = const [];
  List<Map<String, dynamic>> _challans = const [];
  Set<String> _selectedChallans = <String>{};

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _rate.dispose();
    _billDate.dispose();
    _periodFrom.dispose();
    _periodTo.dispose();
    _remarks.dispose();
    for (final controller in _lineRates.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get(
        endpoint: '$_billingEndpoint?view=options',
        requireAuth: true,
      );
      final data = response is Map ? response['data'] : null;
      if (data is! Map) {
        throw Exception('Billing form options were not returned.');
      }
      final commissionTypes = _billingMaps(data['commission_types']);
      if (!mounted) return;
      setState(() {
        _companies = _billingMaps(data['billing_companies']);
        _sellers = _billingMaps(data['sellers']);
        _buyers = _billingMaps(data['buyers']);
        _subAdmins = _billingMaps(data['sub_admins']);
        _commissionTypes = commissionTypes;
        _commissionType = commissionTypes.isEmpty
            ? ''
            : _billingText(commissionTypes.first['value']);
      });
    } catch (error) {
      if (mounted) setState(() => _error = _billingMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _parties =>
      _basis == 'seller' ? _sellers : _buyers;

  Future<void> _loadChallans() async {
    if (_party.isEmpty) return;
    setState(() => _loadingChallans = true);
    final query = <String, String>{
      'view': 'eligible_challans',
      'billing_basis': _basis,
      _basis: _party,
      if (_commissionType.isNotEmpty) 'commission_type': _commissionType,
      if (_rate.text.trim().isNotEmpty)
        'default_brokerage_rate': _rate.text.trim(),
    };
    try {
      final endpoint = Uri(
        path: _billingEndpoint,
        queryParameters: query,
      ).toString();
      final response = await ApiClient.get(
        endpoint: endpoint,
        requireAuth: true,
      );
      if (!mounted || response is! Map) return;
      final next = _billingMaps(response['results']);
      final ids = next
          .map((item) => _billingText(item['delivery_challan']))
          .toSet();
      for (final entry in _lineRates.entries.toList()) {
        if (!ids.contains(entry.key)) {
          entry.value.dispose();
          _lineRates.remove(entry.key);
        }
      }
      for (final item in next) {
        final id = _billingText(item['delivery_challan']);
        if (id.isNotEmpty && !_lineRates.containsKey(id)) {
          _lineRates[id] = TextEditingController(
            text: _billingText(item['brokerage_rate'] ?? _rate.text),
          );
        }
      }
      setState(() {
        _challans = next;
        _selectedChallans = _selectedChallans.intersection(ids);
      });
      final note = _billingText(response['message']);
      if (note.isNotEmpty) _showMessage(note);
    } catch (error) {
      if (mounted) _showMessage(_billingMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _loadingChallans = false);
    }
  }

  Future<void> _pickDate(
    TextEditingController controller, {
    required DateTime? currentValue,
    required ValueChanged<DateTime?> onSelected,
  }) async {
    final parsed = currentValue ?? _tryParseAnyDate(controller.text.trim());
    final selected = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (selected != null) {
      onSelected(selected);
      controller.text = _formatDateDisplay(selected);
    }
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_party.isEmpty || _company.isEmpty) {
      _showMessage(
        'Select the billing party and billing company.',
        error: true,
      );
      return;
    }
    if (_selectedChallans.isEmpty) {
      _showMessage(
        'Select at least one eligible delivery challan.',
        error: true,
      );
      return;
    }
    setState(() => _saving = true);
    final overrides = <String, Map<String, dynamic>>{};
    for (final challanId in _selectedChallans) {
      final rate = _lineRates[challanId]?.text.trim() ?? '';
      if (rate.isNotEmpty) overrides[challanId] = {'brokerage_rate': rate};
    }
    try {
      final response = await ApiClient.post(
        endpoint: _billingEndpoint,
        requireAuth: true,
        body: {
          'billing_basis': _basis,
          _basis: _party,
          'billing_company': _company,
          'delivery_challan_ids': _selectedChallans.toList(),
          if (_subAdmin.isNotEmpty) 'assigned_sub_admin': _subAdmin,
          if (_billDateVal != null)
            'bill_date': _dateValue(_billDateVal!)
          else if (_billDate.text.trim().isNotEmpty)
            'bill_date': _dateValue(
              _tryParseAnyDate(_billDate.text.trim()) ?? DateTime.now(),
            ),
          if (_periodFromVal != null)
            'period_from': _dateValue(_periodFromVal!)
          else if (_periodFrom.text.trim().isNotEmpty &&
              _tryParseAnyDate(_periodFrom.text.trim()) != null)
            'period_from': _dateValue(
              _tryParseAnyDate(_periodFrom.text.trim())!,
            ),
          if (_periodToVal != null)
            'period_to': _dateValue(_periodToVal!)
          else if (_periodTo.text.trim().isNotEmpty &&
              _tryParseAnyDate(_periodTo.text.trim()) != null)
            'period_to': _dateValue(
              _tryParseAnyDate(_periodTo.text.trim())!,
            ),
          'remarks': _remarks.text.trim(),
          'commission_type': _commissionType,
          'default_brokerage_rate': _rate.text.trim(),
          'line_overrides': overrides,
        },
      );
      if (!mounted) return;
      _showMessage(
        _billingText(
          response['message'],
        ).replaceAll(RegExp(r'^$'), 'Brokerage bill draft created.'),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showMessage(_billingMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    AppSnackbar.showSnackBar(context, 
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const AppBarLeading(), leadingWidth: AppBarLeading.widthFor(context), title: const Text('Create Brokerage Bill')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _loadError()
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  children: [
                    _basisSection(),
                    const SizedBox(height: 12),
                    _billDetailsSection(),
                    const SizedBox(height: 12),
                    _challanSection(),
                  ],
                ),
              ),
        bottomNavigationBar: _loading || _error != null
            ? null
            : SafeArea(
                minimum: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _create,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Creating…' : 'Create Draft Bill'),
                  ),
                ),
              ),
      );

  Widget _loadError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error ?? 'Could not load billing options.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadOptions,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _basisSection() => _section(
    title: 'Billing Basis',
    child: Column(
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'seller',
              label: Text('Seller'),
              icon: Icon(Icons.storefront_outlined),
            ),
            ButtonSegment(
              value: 'buyer',
              label: Text('Buyer'),
              icon: Icon(Icons.shopping_bag_outlined),
            ),
          ],
          selected: {_basis},
          onSelectionChanged: (selected) {
            setState(() {
              _basis = selected.first;
              _party = '';
              _challans = const [];
              _selectedChallans = <String>{};
            });
          },
        ),
        const SizedBox(height: 14),
        _optionDropdown(
          label: _basis == 'seller' ? 'Seller *' : 'Buyer *',
          value: _party,
          options: _parties,
          valueOf: (item) => _billingText(item['id']),
          labelOf: _billingUser,
          onChanged: (value) {
            setState(() {
              _party = value;
              _challans = const [];
              _selectedChallans = <String>{};
            });
            _loadChallans();
          },
        ),
      ],
    ),
  );

  Widget _billDetailsSection() => _section(
    title: 'Bill Details',
    child: Column(
      children: [
        _optionDropdown(
          label: 'Billing company *',
          value: _company,
          options: _companies,
          valueOf: (item) => _billingText(item['value'] ?? item['id']),
          labelOf: (item) =>
              _billingText(item['label'] ?? item['company_name']),
          onChanged: (value) => setState(() => _company = value),
        ),
        const SizedBox(height: 12),
        _optionDropdown(
          label: 'Assigned sub admin (optional)',
          value: _subAdmin,
          options: _subAdmins,
          valueOf: (item) => _billingText(item['id']),
          labelOf: _billingUser,
          onChanged: (value) => setState(() => _subAdmin = value),
        ),
        const SizedBox(height: 12),
        _optionDropdown(
          label: 'Commission type *',
          value: _commissionType,
          options: _commissionTypes,
          valueOf: (item) => _billingText(item['value']),
          labelOf: (item) => _billingText(item['label'] ?? item['value']),
          onChanged: (value) {
            setState(() => _commissionType = value);
            _loadChallans();
          },
        ),
        const SizedBox(height: 12),
        _input(
          _rate,
          'Default brokerage rate *',
          numeric: true,
          validator: (value) {
            if ((value ?? '').trim().isEmpty ||
                num.tryParse(value!.trim()) == null) {
              return 'Enter a valid brokerage rate';
            }
            return null;
          },
          onChanged: (_) {},
        ),
        const SizedBox(height: 12),
        _dateInput(
          controller: _billDate,
          label: 'Bill date *',
          value: _billDateVal,
          onSelected: (dt) => setState(() => _billDateVal = dt),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 320;
            if (isSmall) {
              return Column(
                children: [
                  _dateInput(
                    controller: _periodFrom,
                    label: 'Period From',
                    value: _periodFromVal,
                    onSelected: (dt) => setState(() => _periodFromVal = dt),
                    canClear: true,
                  ),
                  const SizedBox(height: 12),
                  _dateInput(
                    controller: _periodTo,
                    label: 'Period To',
                    value: _periodToVal,
                    onSelected: (dt) => setState(() => _periodToVal = dt),
                    canClear: true,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _dateInput(
                    controller: _periodFrom,
                    label: 'Period From',
                    value: _periodFromVal,
                    onSelected: (dt) => setState(() => _periodFromVal = dt),
                    canClear: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dateInput(
                    controller: _periodTo,
                    label: 'Period To',
                    value: _periodToVal,
                    onSelected: (dt) => setState(() => _periodToVal = dt),
                    canClear: true,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _input(_remarks, 'Remarks (optional)', lines: 3),
      ],
    ),
  );

  Widget _challanSection() => _section(
    title: 'Eligible Delivery Challans',
    trailing: IconButton(
      tooltip: 'Reload eligible challans',
      onPressed: _party.isEmpty || _loadingChallans ? null : _loadChallans,
      icon: const Icon(Icons.refresh_rounded),
    ),
    child: _party.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Choose a billing party to load eligible delivered challans.',
            ),
          )
        : _loadingChallans
        ? const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        : _challans.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No eligible delivery challans were found.'),
          )
        : Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose challans. A line rate can override the default rate.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              ..._challans.map(_challanTile),
            ],
          ),
  );

  Widget _challanTile(Map<String, dynamic> challan) {
    final id = _billingText(challan['delivery_challan']);
    final selected = _selectedChallans.contains(id);
    final rate = _lineRates[id] ??= TextEditingController(text: _rate.text);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: .35)
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: selected,
              title: Text(
                _billingText(challan['challan_number']).isEmpty
                    ? 'Delivery challan'
                    : _billingText(challan['challan_number']),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${_billingText(challan['product_name'])} • ${_billingText(challan['quantity'])} ${_billingText(challan['quantity_unit'])}\n'
                '${_billingText(challan['buyer_name'])} • ${_billingText(challan['delivery_date'])}',
              ),
              onChanged: id.isEmpty
                  ? null
                  : (checked) => setState(() {
                      if (checked == true) {
                        _selectedChallans.add(id);
                      } else {
                        _selectedChallans.remove(id);
                      }
                    }),
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Line brokerage rate (optional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: rate,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Enter line rate',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    Widget? trailing,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );

  Widget _optionDropdown({
    required String label,
    required String value,
    required List<Map<String, dynamic>> options,
    required String Function(Map<String, dynamic>) valueOf,
    required String Function(Map<String, dynamic>) labelOf,
    required ValueChanged<String> onChanged,
  }) {
    final validValue = options.any((item) => valueOf(item) == value)
        ? value
        : '';
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$validValue'),
      isExpanded: true,
      initialValue: validValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Select')),
        ...options.map(
          (item) => DropdownMenuItem(
            value: valueOf(item),
            child: Text(labelOf(item), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) => onChanged(value ?? ''),
      validator: label.contains('*')
          ? (value) => (value ?? '').isEmpty ? 'Required' : null
          : null,
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    int lines = 1,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: controller,
    minLines: lines,
    maxLines: lines,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    inputFormatters: numeric
        ? [
            LengthLimitingTextInputFormatter(10),
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ]
        : null,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      counterText: '',
      counter: const SizedBox.shrink(),
    ),
    validator: validator,
    onChanged: onChanged,
  );

  Widget _dateInput({
    required TextEditingController controller,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onSelected,
    bool canClear = false,
  }) =>
      TextFormField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        onTap: () => _pickDate(
          controller,
          currentValue: value,
          onSelected: onSelected,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          border: const OutlineInputBorder(),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 32, minHeight: 32),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: canClear && controller.text.isNotEmpty
                ? InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      onSelected(null);
                      controller.clear();
                    },
                    child: const Icon(Icons.close_rounded, size: 18),
                  )
                : const Icon(Icons.calendar_today_outlined, size: 18),
          ),
        ),
      );
}

class AdminBrokerageBillDetailScreen extends StatefulWidget {
  const AdminBrokerageBillDetailScreen({super.key, required this.billId});

  final String billId;

  @override
  State<AdminBrokerageBillDetailScreen> createState() =>
      _AdminBrokerageBillDetailScreenState();
}

class _AdminBrokerageBillDetailScreenState
    extends State<AdminBrokerageBillDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _bill;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get(
        endpoint: '$_billingEndpoint${widget.billId}/',
        requireAuth: true,
      );
      final data = response is Map ? response['data'] : null;
      if (data is! Map) throw Exception('Brokerage bill was not returned.');
      if (mounted) setState(() => _bill = Map<String, dynamic>.from(data));
    } catch (error) {
      if (mounted) setState(() => _error = _billingMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    AppSnackbar.showSnackBar(context, 
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  bool get _isDraft => _billingText(_bill?['status']).toLowerCase() == 'draft';
  bool get _isIssued =>
      _billingText(_bill?['status']).toLowerCase() == 'issued';

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool needsReason = false,
  }) async {
    final reason = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (needsReason) ...[
              const SizedBox(height: 14),
              TextField(
                controller: reason,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Cancellation reason *',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
            ),
            onPressed: () {
              if (needsReason && reason.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, true);
            },
            child: Text(
              confirmLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.0,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Back'),
          ),
        ],
      ),
    );
    final value = reason.text.trim();
    reason.dispose();
    if (result == true && needsReason) {
      await _runAction('cancel', extra: {'reason': value}, confirmed: true);
      return false;
    }
    return result == true;
  }

  Future<void> _runAction(
    String action, {
    Map<String, dynamic> extra = const {},
    bool confirmed = false,
  }) async {
    if (!confirmed) {
      final labels = {
        'issue': (
          'Issue bill',
          'Issue this draft bill? It can no longer be edited.',
          'Issue',
        ),
        'generate_pdf': (
          'Generate PDF',
          'Generate a PDF for this issued bill?',
          'Generate',
        ),
      };
      final prompt = labels[action];
      if (prompt != null) {
        final okay = await _confirm(
          title: prompt.$1,
          message: prompt.$2,
          confirmLabel: prompt.$3,
        );
        if (!okay) return;
      }
    }
    try {
      final response = await ApiClient.post(
        endpoint: '$_billingEndpoint${widget.billId}/',
        requireAuth: true,
        body: {'action': action, ...extra},
      );
      final msg = _billingText(response['message']);
      _snack(
        msg.isEmpty
            ? (action == 'generate_pdf' ? 'PDF generated successfully.' : 'Bill updated.')
            : msg,
      );
      await _load();
      if (action == 'generate_pdf') {
        await _downloadPdf();
      }
    } catch (error) {
      if (mounted) _snack(_billingMessage(error), error: true);
    }
  }

  Future<void> _deleteDraft() async {
    final okay = await _confirm(
      title: 'Delete draft bill',
      message: 'This will permanently remove this draft bill and its lines.',
      confirmLabel: 'Delete',
    );
    if (!okay) return;
    try {
      final response = await ApiClient.delete(
        endpoint: '$_billingEndpoint${widget.billId}/',
        requireAuth: true,
      );
      if (!mounted) return;
      _snack(
        _billingText(response['message']).isEmpty
            ? 'Draft bill deleted.'
            : _billingText(response['message']),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _snack(_billingMessage(error), error: true);
    }
  }

  Future<void> _editHeader() async {
    final current = _bill;
    if (current == null) return;
    List<Map<String, dynamic>> companies = const [];
    List<Map<String, dynamic>> subAdmins = const [];
    try {
      final response = await ApiClient.get(
        endpoint: '$_billingEndpoint?view=options',
        requireAuth: true,
      );
      final data = response is Map ? response['data'] : null;
      if (data is Map) {
        companies = _billingMaps(data['billing_companies']);
        subAdmins = _billingMaps(data['sub_admins']);
      }
    } catch (_) {
      // Header dates and rates can still be edited if choice lists are unavailable.
    }
    if (!mounted) return;
    final billDate = TextEditingController(
      text: billingDateShown(current['bill_date']),
    );
    final periodFrom = TextEditingController(
      text: billingDateShown(current['period_from']),
    );
    final periodTo = TextEditingController(
      text: billingDateShown(current['period_to']),
    );
    final remarks = TextEditingController(
      text: _billingText(current['remarks']),
    );
    final rate = TextEditingController(
      text: _billingText(current['default_brokerage_rate']),
    );
    String commission = _billingText(current['commission_type']);
    String billingCompany = current['billing_company'] == null
        ? ''
        : 'settings:${_billingText(current['billing_company'])}';
    final assigned = current['assigned_sub_admin'];
    String assignedSubAdmin = assigned is Map
        ? _billingText(assigned['id'])
        : '';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Draft Header'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (companies.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey('header-company-$billingCompany'),
                    isExpanded: true,
                    initialValue:
                        companies.any(
                          (item) =>
                              _billingText(item['value']) == billingCompany,
                        )
                        ? billingCompany
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Billing company',
                      border: OutlineInputBorder(),
                    ),
                    items: companies
                        .map(
                          (item) => DropdownMenuItem(
                            value: _billingText(item['value']),
                            child: Text(
                              _billingText(item['label']),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setDialogState(
                      () => billingCompany = value ?? billingCompany,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (subAdmins.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey('header-admin-$assignedSubAdmin'),
                    isExpanded: true,
                    initialValue:
                        subAdmins.any(
                          (item) =>
                              _billingText(item['id']) == assignedSubAdmin,
                        )
                        ? assignedSubAdmin
                        : '',
                    decoration: const InputDecoration(
                      labelText: 'Assigned sub admin',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Not assigned'),
                      ),
                      ...subAdmins.map(
                        (item) => DropdownMenuItem(
                          value: _billingText(item['id']),
                          child: Text(
                            _billingUser(item),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) => setDialogState(
                      () => assignedSubAdmin = value ?? assignedSubAdmin,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _dateInput(billDate, 'Bill date (DD-MM-YYYY)'),
                const SizedBox(height: 10),
                _dateInput(periodFrom, 'Period from (DD-MM-YYYY)'),
                const SizedBox(height: 10),
                _dateInput(periodTo, 'Period to (DD-MM-YYYY)'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('header-commission-$commission'),
                  initialValue:
                      const [
                        'per_quantity',
                        'percentage',
                        'fixed',
                      ].contains(commission)
                      ? commission
                      : 'per_quantity',
                  decoration: const InputDecoration(
                    labelText: 'Commission type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'per_quantity',
                      child: Text('Per Quantity'),
                    ),
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Percentage of Trade Value'),
                    ),
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text('Fixed Amount'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => commission = value ?? commission),
                ),
                const SizedBox(height: 10),
                _dialogInput(rate, 'Default brokerage rate', numeric: true),
                const SizedBox(height: 10),
                _dialogInput(remarks, 'Remarks', lines: 3),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                if (billingCompany.isNotEmpty)
                  'billing_company': billingCompany,
                'assigned_sub_admin': assignedSubAdmin,
                'bill_date': billingDateForApi(billDate.text),
                'period_from': billingDateForApi(periodFrom.text),
                'period_to': billingDateForApi(periodTo.text),
                'remarks': remarks.text.trim(),
                'commission_type': commission,
                'default_brokerage_rate': rate.text.trim(),
              }),
              child: const Text('Save'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
    billDate.dispose();
    periodFrom.dispose();
    periodTo.dispose();
    remarks.dispose();
    rate.dispose();
    if (result == null) return;
    try {
      final response = await ApiClient.patch(
        endpoint: '$_billingEndpoint${widget.billId}/',
        requireAuth: true,
        data: result,
      );
      _snack(
        _billingText(response['message']).isEmpty
            ? 'Draft header updated.'
            : _billingText(response['message']),
      );
      await _load();
    } catch (error) {
      if (mounted) _snack(_billingMessage(error), error: true);
    }
  }

  /// A date field that reads and shows DD-MM-YYYY; tapping the calendar picks a day. The server still gets YYYY-MM-DD.
  Widget _dateInput(TextEditingController controller, String label) => TextField(
    controller: controller,
    keyboardType: TextInputType.datetime,
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\-/]')), LengthLimitingTextInputFormatter(10)],
    decoration: InputDecoration(
      labelText: label,
      hintText: 'DD-MM-YYYY',
      border: const OutlineInputBorder(),
      suffixIcon: IconButton(
        tooltip: 'Pick a date',
        icon: const Icon(Icons.calendar_month_outlined),
        onPressed: () async {
          final current = AppDate.parse(controller.text) ?? DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: current,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) controller.text = billingDateShown(AppDate.apiDate(picked));
        },
      ),
    ),
  );

  Widget _dialogInput(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    int lines = 1,
  }) => TextField(
    controller: controller,
    minLines: lines,
    maxLines: lines,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : null,
    maxLength: numeric ? 10 : null,
    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      counterText: '',
    ),
  );

  Future<void> _editLine(Map<String, dynamic> line) async {
    final deliveryDate = TextEditingController(
      text: billingDateShown(line['delivery_date']),
    );
    final buyer = TextEditingController(text: _billingText(line['buyer_name']));
    final product = TextEditingController(
      text: _billingText(line['product_name']),
    );
    final bags = TextEditingController(text: _billingText(line['bag_count']));
    final packing = TextEditingController(
      text: _billingText(line['packing_weight_kg']),
    );
    final quantity = TextEditingController(
      text: _billingText(line['quantity']),
    );
    final rate = TextEditingController(text: _billingText(line['rate']));
    final brokerageRate = TextEditingController(
      text: _billingText(line['brokerage_rate']),
    );
    String quantityUnit = _billingText(line['quantity_unit']);
    String rateUnit = _billingText(line['rate_unit']);
    String commission = _billingText(line['commission_type']);
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              18,
              16,
              MediaQuery.viewInsetsOf(context).bottom + 18,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit ${_billingText(line['challan_number'])}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _dateInput(deliveryDate, 'Delivery date (DD-MM-YYYY)'),
                  const SizedBox(height: 10),
                  _dialogInput(buyer, 'Buyer name'),
                  const SizedBox(height: 10),
                  _dialogInput(product, 'Product name'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogInput(bags, 'Bags', numeric: true),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dialogInput(
                          packing,
                          'Packing KG',
                          numeric: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogInput(
                          quantity,
                          'Quantity',
                          numeric: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _unitDropdown(
                          'Quantity unit',
                          quantityUnit,
                          (value) => setSheetState(() => quantityUnit = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogInput(rate, 'Rate', numeric: true),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _unitDropdown(
                          'Rate unit',
                          rateUnit,
                          (value) => setSheetState(() => rateUnit = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: ValueKey('line-commission-$commission'),
                    initialValue:
                        const [
                          'per_quantity',
                          'percentage',
                          'fixed',
                        ].contains(commission)
                        ? commission
                        : 'per_quantity',
                    decoration: const InputDecoration(
                      labelText: 'Commission type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'per_quantity',
                        child: Text('Per Quantity'),
                      ),
                      DropdownMenuItem(
                        value: 'percentage',
                        child: Text('Percentage of Trade Value'),
                      ),
                      DropdownMenuItem(
                        value: 'fixed',
                        child: Text('Fixed Amount'),
                      ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => commission = value ?? commission),
                  ),
                  const SizedBox(height: 10),
                  _dialogInput(brokerageRate, 'Brokerage rate', numeric: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, {
                        'delivery_date': billingDateForApi(deliveryDate.text),
                        'buyer_name': buyer.text.trim(),
                        'product_name': product.text.trim(),
                        'bag_count': bags.text.trim(),
                        'packing_weight_kg': packing.text.trim(),
                        'quantity': quantity.text.trim(),
                        'quantity_unit': quantityUnit,
                        'rate': rate.text.trim(),
                        'rate_unit': rateUnit,
                        'commission_type': commission,
                        'brokerage_rate': brokerageRate.text.trim(),
                      }),
                      child: const Text('Update Line'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (final controller in [
      deliveryDate,
      buyer,
      product,
      bags,
      packing,
      quantity,
      rate,
      brokerageRate,
    ]) {
      controller.dispose();
    }
    if (result == null) return;
    await _runAction(
      'update_line',
      extra: {'line_id': line['id'], ...result},
      confirmed: true,
    );
  }

  Widget _unitDropdown(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    const units = ['QTL', 'KG', 'TON', 'BAG', 'Per QTL', 'Per KG', 'Per Ton'];
    final current = units.contains(value) ? value : 'QTL';
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$current'),
      initialValue: current,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: units
          .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
          .toList(),
      onChanged: (next) => onChanged(next ?? current),
    );
  }

  Future<void> _removeLine(Map<String, dynamic> line) async {
    final okay = await _confirm(
      title: 'Remove challan',
      message:
          'Remove ${_billingText(line['challan_number'])} from this draft bill?',
      confirmLabel: 'Remove',
    );
    if (okay) {
      await _runAction(
        'remove_line',
        extra: {'line_id': line['id']},
        confirmed: true,
      );
    }
  }

  Future<void> _addChallans() async {
    final seller = _bill?['seller'];
    final sellerId = seller is Map ? _billingText(seller['id']) : '';
    if (sellerId.isEmpty) {
      _snack('The seller could not be determined for this bill.', error: true);
      return;
    }
    List<Map<String, dynamic>> sources;
    try {
      final response = await ApiClient.get(
        endpoint:
            '$_billingEndpoint?view=eligible_challans&billing_basis=seller&seller=$sellerId',
        requireAuth: true,
      );
      sources = response is Map ? _billingMaps(response['results']) : const [];
    } catch (error) {
      _snack(_billingMessage(error), error: true);
      return;
    }
    if (!mounted) return;
    final selected = <String>{};
    final ids = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .78,
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    'Add Eligible Challans',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Only delivered challans for this seller are listed.',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: sources.isEmpty
                      ? const Center(
                          child: Text('No additional eligible challans found.'),
                        )
                      : ListView.builder(
                          itemCount: sources.length,
                          itemBuilder: (context, index) {
                            final source = sources[index];
                            final id = _billingText(source['delivery_challan']);
                            return CheckboxListTile(
                              value: selected.contains(id),
                              title: Text(
                                _billingText(source['challan_number']).isEmpty
                                    ? 'Challan'
                                    : _billingText(source['challan_number']),
                              ),
                              subtitle: Text(
                                '${_billingText(source['product_name'])} • ${_billingText(source['quantity'])} ${_billingText(source['quantity_unit'])}',
                              ),
                              onChanged: id.isEmpty
                                  ? null
                                  : (checked) => setSheetState(() {
                                      if (checked == true) {
                                        selected.add(id);
                                      } else {
                                        selected.remove(id);
                                      }
                                    }),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () =>
                                Navigator.pop(sheetContext, selected.toList()),
                      child: Text(
                        'Add ${selected.length} Challan${selected.length == 1 ? '' : 's'}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ids != null && ids.isNotEmpty) {
      await _runAction(
        'add_challans',
        extra: {'delivery_challan_ids': ids},
        confirmed: true,
      );
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final token = await AppPreferences.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Please log in again.');
      }
      final response = await http.get(
        Uri.parse(
          '${ApiUrls.baseUrl}$_billingEndpoint${widget.billId}/?download=pdf',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Could not download the bill PDF (${response.statusCode}).',
        );
      }
      final number = _billingText(
        _bill?['bill_number'],
      ).replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final fileName = '${number.isEmpty ? 'brokerage_bill_${widget.billId}' : number}.pdf';
      final file = File('${Directory.systemTemp.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      await DownloadsService.saveBytes(
        fileName: fileName,
        bytes: response.bodyBytes,
        mimeType: 'application/pdf',
      );
      if (mounted) _snack('PDF downloaded successfully.');
      try {
        final result = await OpenFilex.open(file.path, type: 'application/pdf');
        if (result.type != ResultType.done) {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'application/pdf')],
              subject: 'Brokerage Bill $number',
            ),
          );
        }
      } catch (_) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/pdf')],
            subject: 'Brokerage Bill $number',
          ),
        );
      }
    } catch (error) {
      if (mounted) _snack(_billingMessage(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = _bill;
    return PopScope(
      canPop: !_loading,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        appBar: AppBar(leading: const AppBarLeading(), leadingWidth: AppBarLeading.widthFor(context), 
          title: Text(
            _billingText(bill?['bill_number']).isEmpty
                ? 'Brokerage Bill'
                : _billingText(bill?['bill_number']),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _loading && bill == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: Text(_error!),
                  ),
                ),
              )
            : bill == null
            ? const SizedBox.shrink()
            : _content(bill),
      ),
    );
  }

  String _formatAuditTimestamp(dynamic dateStr) {
    if (dateStr == null) return '—';
    final str = dateStr.toString().trim();
    if (str.isEmpty || str == '—') return '—';
    try {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) {
        return DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
      }
    } catch (_) {}
    return str;
  }

  Widget _content(Map<String, dynamic> bill) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _summary(bill),
        const SizedBox(height: 12),
        _actions(bill),
        _auditTrailCard(bill),
        const SizedBox(height: 18),
        Text(
          'Bill Lines',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ..._billingMaps(bill['lines']).map(_lineCard),
      ],
    ),
  );

  Widget _summary(Map<String, dynamic> bill) {
    final status = _billingText(bill['status']).toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _billingText(bill['bill_number']).isEmpty
                        ? 'Draft Bill'
                        : _billingText(bill['bill_number']),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Chip(label: Text(status.isEmpty ? 'DRAFT' : status)),
              ],
            ),
            const Divider(height: 24),
            _summaryRow('Seller', _billingUser(bill['seller'])),
            _summaryRow(
              'Billing company',
              _billingText(bill['billing_company_name']),
            ),
            _summaryRow(
              'Assigned sub admin',
              _billingUser(bill['assigned_sub_admin']),
            ),
            _summaryRow('Bill date', _formatDate(bill['bill_date'])),
            _summaryRow(
              'Period',
              '${_formatDate(bill['period_from'])} — ${_formatDate(bill['period_to'])}',
            ),
            _summaryRow(
              'Commission',
              '${_billingText(bill['commission_type'])} • ${_billingText(bill['default_brokerage_rate'])}',
            ),
            _summaryRow('Trade value', _money(bill['total_trade_value'])),
            _summaryRow(
              'Total brokerage',
              _money(bill['total_brokerage_amount']),
              prominent: true,
            ),
            if (_billingText(bill['remarks']).isNotEmpty)
              _summaryRow('Remarks', _billingText(bill['remarks'])),
            if (_billingText(bill['cancellation_reason']).isNotEmpty)
              _summaryRow(
                'Cancelled because',
                _billingText(bill['cancellation_reason']),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool prominent = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 126,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(
              child: Text(
                value.isEmpty || value == ' — ' ? '—' : value,
                style: TextStyle(
                  fontWeight: prominent ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  /// One full-width action: same height, same corners, same spacing.
  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool filled = false,
    bool destructive = false,
  }) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const size = Size.fromHeight(48);
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(minimumSize: size, shape: shape),
      );
    }
    if (destructive) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: size,
          shape: shape,
          foregroundColor: const Color(0xFFD32F2F),
          side: const BorderSide(color: Color(0xFFD32F2F)),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(minimumSize: size, shape: shape),
    );
  }

  Widget _actions(Map<String, dynamic> bill) {
    final primary = <Widget>[
      if (_isDraft) ...[
        _action(icon: Icons.edit_outlined, label: 'Edit Header', onPressed: _editHeader),
        _action(icon: Icons.add_link_outlined, label: 'Add Challans', onPressed: _addChallans),
        _action(icon: Icons.publish_outlined, label: 'Issue Bill', onPressed: () => _runAction('issue'), filled: true),
      ],
      if (_isIssued)
        if (bill['has_pdf'] == true) ...[
          _action(icon: Icons.picture_as_pdf_outlined, label: 'Download / View PDF', onPressed: _downloadPdf),
          _action(icon: Icons.refresh_rounded, label: 'Re-generate PDF', onPressed: () => _runAction('generate_pdf')),
        ] else
          _action(icon: Icons.picture_as_pdf_outlined, label: 'Generate PDF', onPressed: () => _runAction('generate_pdf')),
      if (!_isDraft && bill['has_pdf'] == true && !_isIssued)
        _action(icon: Icons.download_outlined, label: 'Download PDF', onPressed: _downloadPdf),
    ];
    // Destructive actions sit apart, below the normal ones.
    final destructive = <Widget>[
      if (_isDraft) _action(icon: Icons.delete_outline, label: 'Delete', onPressed: _deleteDraft, destructive: true),
      if (_isIssued)
        _action(
          icon: Icons.cancel_outlined,
          label: 'Cancel Bill',
          destructive: true,
          onPressed: () => _confirm(
            title: 'Cancel issued bill',
            message: 'The bill will be cancelled. Please record why.',
            confirmLabel: 'Cancel Bill',
            needsReason: true,
          ),
        ),
    ];
    final children = <Widget>[];
    for (final button in primary) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 10));
      children.add(button);
    }
    if (destructive.isNotEmpty) {
      if (children.isNotEmpty) {
        children
          ..add(const SizedBox(height: 14))
          ..add(const Divider(height: 1))
          ..add(const SizedBox(height: 14));
      }
      for (var i = 0; i < destructive.length; i++) {
        if (i > 0) children.add(const SizedBox(height: 10));
        children.add(destructive[i]);
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }

  Widget _auditTrailCard(Map<String, dynamic> bill) {
    final createdAt = bill['created_at']?.toString();
    final issuedAt = bill['issued_at']?.toString();
    final defaultAuthor = _billingText(bill['billing_company_name']).isNotEmpty
        ? _billingText(bill['billing_company_name'])
        : _billingUser(bill['assigned_sub_admin']);
    final createdBy = _billingUser(bill['created_by']).isNotEmpty
        ? _billingUser(bill['created_by'])
        : defaultAuthor;
    final issuedBy = _billingUser(bill['issued_by']).isNotEmpty
        ? _billingUser(bill['issued_by'])
        : defaultAuthor;

    final auditList =
        bill['audit_trail'] is List ? (bill['audit_trail'] as List) : null;

    if (createdAt == null &&
        issuedAt == null &&
        (auditList == null || auditList.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Trail',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Divider(height: 20),
            if (auditList != null && auditList.isNotEmpty) ...[
              for (final entry in auditList)
                if (entry is Map)
                  _auditEntry(
                    title: _billingText(
                        entry['action'] ?? entry['title'] ?? 'Action'),
                    timestamp: _formatAuditTimestamp(
                        entry['timestamp'] ?? entry['created_at']),
                    author:
                        _billingText(entry['by'] ?? entry['user'] ?? defaultAuthor),
                  ),
            ] else ...[
              if (createdAt != null && createdAt.isNotEmpty)
                _auditEntry(
                  title: 'Created',
                  timestamp: _formatAuditTimestamp(createdAt),
                  author: createdBy,
                ),
              if (issuedAt != null && issuedAt.isNotEmpty)
                _auditEntry(
                  title: 'Issued',
                  timestamp: _formatAuditTimestamp(issuedAt),
                  author: issuedBy,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _auditEntry({
    required String title,
    required String timestamp,
    required String author,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            timestamp,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              'by $author',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lineCard(Map<String, dynamic> line) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _billingText(line['challan_number']).isEmpty
                      ? 'Challan'
                      : _billingText(line['challan_number']),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (_isDraft) ...[
                IconButton(
                  tooltip: 'Edit line',
                  onPressed: () => _editLine(line),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Remove line',
                  onPressed: () => _removeLine(line),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          Text(
            '${_billingText(line['product_name'])} • ${_billingText(line['buyer_name'])}',
          ),
          const SizedBox(height: 8),
          _lineInfo(
            'Quantity',
            '${_billingText(line['quantity'])} ${_billingText(line['quantity_unit'])}',
          ),
          _lineInfo(
            'Rate',
            '${_money(line['rate'])}/${_billingText(line['rate_unit'])}',
          ),
          _lineInfo(
            'Bags / packing',
            '${_billingText(line['bag_count'])} / ${_billingText(line['packing_weight_kg'])} KG',
          ),
          _lineInfo(
            'Commission',
            '${_billingText(line['commission_type'])} • ${_billingText(line['brokerage_rate'])}',
          ),
          const Divider(height: 18),
          _lineInfo('Brokerage', _money(line['brokerage_amount']), bold: true),
        ],
      ),
    ),
  );

  Widget _lineInfo(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
          width: 116,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A stored date (YYYY-MM-DD or a timestamp) as the screen shows it: DD-MM-YYYY, e.g. 20-11-2026. Empty stays empty.
String billingDateShown(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty || text == 'null') return '';
  final parsed = AppDate.parse(text);
  if (parsed == null) return text;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(parsed.day)}-${two(parsed.month)}-${parsed.year}';
}

/// What the user typed (DD-MM-YYYY, DD/MM/YYYY or YYYY-MM-DD) as the YYYY-MM-DD the server expects.
/// Text that is not a date is sent as typed, so the server's own validation message still shows.
String billingDateForApi(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return '';
  final parsed = AppDate.parse(trimmed);
  return parsed == null ? trimmed : AppDate.apiDate(parsed);
}
