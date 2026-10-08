import 'dart:io';

import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      : _billingText(value['username'] ?? value['name'] ?? value['id']);
}

String _billingMessage(Object error) =>
    error.toString().replaceFirst('Exception: ', '');

String _dateValue(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _money(Object? value) {
  final text = _billingText(value);
  return text.isEmpty ? '—' : '₹$text';
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
  List<Map<String, dynamic>> _records = const [];
  List<Map<String, dynamic>> _statuses = const [];
  List<Map<String, dynamic>> _sellers = const [];
  List<Map<String, dynamic>> _buyers = const [];
  List<Map<String, dynamic>> _companies = const [];

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

  Future<void> _loadInitial() async {
    await Future.wait([_loadOptions(), _loadBills()]);
  }

  Future<void> _loadOptions() async {
    try {
      final response = await ApiClient.get(
        endpoint: '$_billingEndpoint?view=options',
        requireAuth: true,
      );
      final data = response is Map ? response['data'] : null;
      if (!mounted || data is! Map) return;
      setState(() {
        _statuses = _billingMaps(data['statuses']);
        _sellers = _billingMaps(data['sellers']);
        _buyers = _billingMaps(data['buyers']);
        _companies = _billingMaps(data['billing_companies']);
      });
    } catch (_) {
      // The bill list remains usable when optional filter choices cannot load.
    }
  }

  Future<void> _loadBills() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final query = <String, String>{
      if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
      if (_status.isNotEmpty) 'status': _status,
      if (_seller.isNotEmpty) 'seller': _seller,
      if (_buyer.isNotEmpty) 'buyer': _buyer,
      if (_billingCompany.isNotEmpty) 'billing_company': _billingCompany,
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
      setState(() => _records = _billingMaps(response['results']));
    } catch (error) {
      if (mounted) setState(() => _error = _billingMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminCreateBrokerageBillScreen()),
    );
    if (changed == true) await _loadBills();
  }

  Future<void> _openDetail(Map<String, dynamic> record) async {
    final id = record['id'];
    if (id == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminBrokerageBillDetailScreen(billId: id.toString()),
      ),
    );
    await _loadBills();
  }

  Future<void> _resetFilters() async {
    setState(() {
      _search.clear();
      _status = '';
      _seller = '';
      _buyer = '';
      _billingCompany = '';
    });
    await _loadBills();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const AdminDrawer(activeKey: 'brokerage_bills'),
    appBar: AppBar(
      title: const Text('Brokerage Bills'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loading ? null : _loadInitial,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _openCreate,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Create Bill'),
    ),
    body: _loading && _records.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadInitial,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _loadBills(),
                  decoration: InputDecoration(
                    labelText: 'Search bill, seller or challan',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Search',
                      onPressed: _loadBills,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                _filters(),
                const SizedBox(height: 18),
                Text(
                  'Bills',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (_error != null) _errorCard(),
                if (_error == null && _records.isEmpty) _emptyCard(),
                ..._records.map(_billCard),
              ],
            ),
          ),
  );

  Widget _filters() => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.tune_rounded),
      title: const Text(
        'Filters',
        style: TextStyle(fontWeight: FontWeight.w700),
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
          valueOf: (item) => _billingText(item['id']),
          labelOf: (item) =>
              _billingText(item['label'] ?? item['company_name']),
          onChanged: (value) => setState(() => _billingCompany = value),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: _resetFilters, child: const Text('Clear')),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _loadBills,
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
    final validValue = options.any((option) => valueOf(option) == value)
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
        ...options.map(
          (item) => DropdownMenuItem(
            value: valueOf(item),
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
            onPressed: _loadBills,
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

  Widget _billCard(Map<String, dynamic> bill) {
    final status = _billingText(bill['status']).toUpperCase();
    final statusColor = switch (status) {
      'ISSUED' => Colors.green,
      'CANCELLED' => Colors.red,
      _ => Colors.orange,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                          ? 'Draft bill #${bill['id']}'
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
                'Bill date: ${_billingText(bill['bill_date'])}',
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
  final _billDate = TextEditingController(text: _dateValue(DateTime.now()));
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

  Future<void> _pickDate(TextEditingController controller) async {
    final parsed = DateTime.tryParse(controller.text.trim());
    final selected = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (selected != null) controller.text = _dateValue(selected);
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
          if (_billDate.text.trim().isNotEmpty)
            'bill_date': _billDate.text.trim(),
          if (_periodFrom.text.trim().isNotEmpty)
            'period_from': _periodFrom.text.trim(),
          if (_periodTo.text.trim().isNotEmpty)
            'period_to': _periodTo.text.trim(),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Brokerage Bill')),
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
        _dateInput(_billDate, 'Bill date *'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _dateInput(_periodFrom, 'Period from (optional)')),
            const SizedBox(width: 12),
            Expanded(child: _dateInput(_periodTo, 'Period to (optional)')),
          ],
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
                    ? 'Delivery challan #$id'
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
                padding: const EdgeInsets.only(left: 10, top: 4),
                child: _input(
                  rate,
                  'Line brokerage rate (optional)',
                  numeric: true,
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
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: validator,
    onChanged: onChanged,
  );

  Widget _dateInput(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _pickDate(controller),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
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
    ScaffoldMessenger.of(context).showSnackBar(
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () {
              if (needsReason && reason.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, true);
            },
            child: Text(confirmLabel),
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
      _snack(
        _billingText(response['message']).isEmpty
            ? 'Bill updated.'
            : _billingText(response['message']),
      );
      await _load();
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
      text: _billingText(current['bill_date']),
    );
    final periodFrom = TextEditingController(
      text: _billingText(current['period_from']),
    );
    final periodTo = TextEditingController(
      text: _billingText(current['period_to']),
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
                _dialogInput(billDate, 'Bill date (YYYY-MM-DD)'),
                const SizedBox(height: 10),
                _dialogInput(periodFrom, 'Period from (YYYY-MM-DD)'),
                const SizedBox(height: 10),
                _dialogInput(periodTo, 'Period to (YYYY-MM-DD)'),
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
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                if (billingCompany.isNotEmpty)
                  'billing_company': billingCompany,
                'assigned_sub_admin': assignedSubAdmin,
                'bill_date': billDate.text.trim(),
                'period_from': periodFrom.text.trim(),
                'period_to': periodTo.text.trim(),
                'remarks': remarks.text.trim(),
                'commission_type': commission,
                'default_brokerage_rate': rate.text.trim(),
              }),
              child: const Text('Save'),
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
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );

  Future<void> _editLine(Map<String, dynamic> line) async {
    final deliveryDate = TextEditingController(
      text: _billingText(line['delivery_date']),
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
                  _dialogInput(deliveryDate, 'Delivery date (YYYY-MM-DD)'),
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
                        'delivery_date': deliveryDate.text.trim(),
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
                                    ? 'Challan #$id'
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
      final file = File(
        '${Directory.systemTemp.path}/${number.isEmpty ? 'brokerage_bill_${widget.billId}' : number}.pdf',
      );
      await file.writeAsBytes(response.bodyBytes, flush: true);
      if (mounted) _snack('PDF downloaded to ${file.path}');
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
        appBar: AppBar(
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

  Widget _content(Map<String, dynamic> bill) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _summary(bill),
        const SizedBox(height: 12),
        _actions(bill),
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
                        ? 'Draft Bill #${widget.billId}'
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
            _summaryRow('Bill date', _billingText(bill['bill_date'])),
            _summaryRow(
              'Period',
              '${_billingText(bill['period_from'])} — ${_billingText(bill['period_to'])}',
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

  Widget _actions(Map<String, dynamic> bill) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_isDraft) ...[
            OutlinedButton.icon(
              onPressed: _editHeader,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Header'),
            ),
            OutlinedButton.icon(
              onPressed: _addChallans,
              icon: const Icon(Icons.add_link_outlined),
              label: const Text('Add Challans'),
            ),
            FilledButton.icon(
              onPressed: () => _runAction('issue'),
              icon: const Icon(Icons.publish_outlined),
              label: const Text('Issue Bill'),
            ),
            OutlinedButton.icon(
              onPressed: _deleteDraft,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
          if (_isIssued) ...[
            OutlinedButton.icon(
              onPressed: () => _runAction('generate_pdf'),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Generate PDF'),
            ),
            if (bill['has_pdf'] == true)
              OutlinedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download PDF'),
              ),
            FilledButton.tonalIcon(
              onPressed: () => _confirm(
                title: 'Cancel issued bill',
                message: 'The bill will be cancelled. Please record why.',
                confirmLabel: 'Cancel Bill',
                needsReason: true,
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Bill'),
            ),
          ],
          if (!_isDraft && bill['has_pdf'] == true && !_isIssued)
            OutlinedButton.icon(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download PDF'),
            ),
        ],
      ),
    ),
  );

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
                      ? 'Challan #${line['delivery_challan']}'
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
