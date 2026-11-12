import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/utils/money_format.dart';
import 'package:flutter/material.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import '../../../utils/app_snackbar.dart';

/// "My Analytics" (MoM point 30): the web /contracts/history/ page for every role.
/// The server scopes it: admins see their branch/team, sellers the contracts they
/// sold, buyers the ones they bought, transporters the ones they carry.
class MyAnalyticsScreen extends StatefulWidget {
  const MyAnalyticsScreen({super.key});

  @override
  State<MyAnalyticsScreen> createState() => _MyAnalyticsScreenState();
}

class _MyAnalyticsScreenState extends State<MyAnalyticsScreen> {
  static const _endpoint = '/api/contracts/history/';

  final searchController = TextEditingController();
  final contractController = TextEditingController();
  final buyerController = TextEditingController();
  final sellerController = TextEditingController();

  bool loading = true;
  bool loadingMore = false;
  bool hasNext = false;
  String? error;
  int page = 1;
  String status = '';
  String brand = '';
  String category = '';
  String branch = '';
  String subAdmin = '';
  DateTime? dateFrom;
  DateTime? dateTo;

  /// 'admin' or 'party' (seller / buyer / transporter), as the server reports it.
  String roleView = 'party';
  List<Map<String, dynamic>> records = const [];
  List<Map<String, dynamic>> kpis = const [];
  List<Map<String, dynamic>> brandWise = const [];
  List<Map<String, dynamic>> categoryWise = const [];
  List<Map<String, dynamic>> productWise = const [];
  List<Map<String, dynamic>> statuses = const [];
  List<Map<String, dynamic>> brands = const [];
  List<Map<String, dynamic>> categories = const [];
  List<Map<String, dynamic>> branches = const [];
  List<Map<String, dynamic>> subAdmins = const [];

  bool get isAdminView => roleView == 'admin';

  @override
  void initState() {
    super.initState();
    loadInitial();
  }

  @override
  void dispose() {
    searchController.dispose();
    contractController.dispose();
    buyerController.dispose();
    sellerController.dispose();
    super.dispose();
  }

  String _message(Object value) =>
      value.toString().replaceFirst('Exception: ', '');

  List<Map<String, dynamic>> _maps(dynamic value) =>
      (value is List ? value : const [])
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList();

  Future<void> loadInitial() async {
    await Future.wait([loadOptions(), load(reset: true)]);
  }

  Future<void> loadOptions() async {
    try {
      final response = await ApiClient.get(
        endpoint: '$_endpoint?view=options',
        requireAuth: true,
      );
      final data = response is Map ? response['data'] : null;
      if (!mounted || data is! Map) return;
      setState(() {
        statuses = _maps(data['statuses']);
        brands = _maps(data['brands']);
        categories = _maps(data['categories']);
        branches = _maps(data['branches']);
        subAdmins = _maps(data['sub_admins']);
      });
    } catch (_) {
      // The analytics remain useful even if filter choices cannot be loaded.
    }
  }

  Future<void> load({required bool reset}) async {
    if (reset) {
      setState(() {
        loading = true;
        error = null;
        page = 1;
      });
    } else {
      if (loadingMore || !hasNext) {
        return;
      }
      setState(() => loadingMore = true);
    }
    final requestedPage = reset ? 1 : page + 1;
    final query = <String, String>{
      'page': '$requestedPage',
      if (searchController.text.trim().isNotEmpty)
        'search': searchController.text.trim(),
      if (contractController.text.trim().isNotEmpty)
        'contract_id': contractController.text.trim(),
      if (buyerController.text.trim().isNotEmpty)
        'buyer': buyerController.text.trim(),
      if (sellerController.text.trim().isNotEmpty)
        'seller': sellerController.text.trim(),
      if (status.isNotEmpty) 'status': status,
      if (brand.isNotEmpty) 'brand': brand,
      if (category.isNotEmpty) 'category': category,
      if (branch.isNotEmpty) 'branch': branch,
      if (subAdmin.isNotEmpty) 'sub_admin': subAdmin,
      if (dateFrom != null) 'date_from': _date(dateFrom!),
      if (dateTo != null) 'date_to': _date(dateTo!),
    };
    try {
      final endpoint = Uri(path: _endpoint, queryParameters: query).toString();
      final response = await ApiClient.get(
        endpoint: endpoint,
        requireAuth: true,
      );
      if (!mounted || response is! Map) return;
      final pagination = response['pagination'] is Map
          ? response['pagination'] as Map
          : const {};
      final freshRows = _maps(response['results']);
      setState(() {
        records = reset ? freshRows : [...records, ...freshRows];
        if (reset) {
          roleView = '${response['role_view'] ?? 'party'}';
          kpis = _maps(response['kpis']);
          brandWise = _maps(response['brand_wise']);
          categoryWise = _maps(response['category_wise']);
          productWise = _maps(response['product_wise']);
        }
        page = requestedPage;
        hasNext = pagination['has_next'] == true;
      });
    } catch (exception) {
      if (!mounted) return;
      if (reset) {
        setState(() => error = _message(exception));
      } else {
        AppSnackbar.showSnackBar(
          context,
          SnackBar(
            content: Text(_message(exception)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          loadingMore = false;
        });
      }
    }
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> pickDate(bool isFrom) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: (isFrom ? dateFrom : dateTo) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );
    if (selected != null && mounted) {
      setState(() {
        if (isFrom) {
          dateFrom = selected;
        } else {
          dateTo = selected;
        }
      });
    }
  }

  Future<void> resetFilters() async {
    setState(() {
      searchController.clear();
      contractController.clear();
      buyerController.clear();
      sellerController.clear();
      status = '';
      brand = '';
      category = '';
      branch = '';
      subAdmin = '';
      dateFrom = null;
      dateTo = null;
    });
    await load(reset: true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const AdminDrawer(activeKey: 'my_analytics'),
    appBar: AppBar(
      leading: const AppBarLeading(),
      leadingWidth: AppBarLeading.widthFor(context),
      title: const Text(
        'My Analytics',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: loading ? null : () => load(reset: true),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: loading && records.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => load(reset: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                _search(),
                const SizedBox(height: 10),
                _filters(),
                if (kpis.isNotEmpty) ...[
                  _heading('Overview'),
                  _kpiCards(),
                ],
                if (brandWise.isNotEmpty) ...[
                  _heading('Brand-wise Trade'),
                  _tradeCard(brandWise, Icons.sell_outlined),
                ],
                if (categoryWise.isNotEmpty) ...[
                  _heading('Category-wise Trade'),
                  _tradeCard(categoryWise, Icons.category_outlined),
                ],
                if (productWise.isNotEmpty) ...[
                  _heading('Product-wise Trade'),
                  _tradeCard(productWise, Icons.inventory_2_outlined),
                ],
                _heading('Contracts'),
                if (error != null) _errorCard(),
                if (error == null && records.isEmpty) _emptyCard(),
                ...records.map(_recordCard),
                if (hasNext) _loadMoreButton(),
              ],
            ),
          ),
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _search() => TextField(
    controller: searchController,
    textInputAction: TextInputAction.search,
    onSubmitted: (_) => load(reset: true),
    decoration: InputDecoration(
      hintText: 'Search contract, product or party',
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: IconButton(
        tooltip: 'Search',
        onPressed: () => load(reset: true),
        icon: const Icon(Icons.arrow_forward_rounded),
      ),
      border: const OutlineInputBorder(),
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
        const SizedBox(height: 6),
        _dropdown(
          label: 'Brand',
          value: brand,
          options: brands,
          valueOf: (item) => '${item['id'] ?? ''}',
          labelOf: (item) => '${item['name'] ?? ''}',
          onChanged: (value) => setState(() => brand = value),
        ),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Category',
          value: category,
          options: categories,
          valueOf: (item) => '${item['id'] ?? ''}',
          // Sub-categories are indented under their main category.
          labelOf: (item) =>
              '${item['is_main'] == false ? '   ' : ''}${item['name'] ?? ''}',
          onChanged: (value) => setState(() => category = value),
        ),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Status',
          value: status,
          options: statuses,
          valueOf: (item) => '${item['value'] ?? ''}',
          labelOf: (item) => '${item['label'] ?? item['value'] ?? ''}',
          onChanged: (value) => setState(() => status = value),
        ),
        if (branches.length > 1 || isAdminView) ...[
          const SizedBox(height: 12),
          _dropdown(
            label: 'Branch',
            value: branch,
            options: branches,
            valueOf: (item) => '${item['id'] ?? ''}',
            labelOf: (item) => '${item['name'] ?? ''}',
            onChanged: (value) => setState(() => branch = value),
          ),
        ],
        if (isAdminView) ...[
          const SizedBox(height: 12),
          _dropdown(
            label: 'Sub admin',
            value: subAdmin,
            options: subAdmins,
            valueOf: (item) => '${item['id'] ?? ''}',
            labelOf: _userLabel,
            onChanged: (value) => setState(() => subAdmin = value),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: contractController,
          decoration: const InputDecoration(
            labelText: 'Contract ID',
            border: OutlineInputBorder(),
          ),
        ),
        if (isAdminView) ...[
          const SizedBox(height: 12),
          TextField(
            controller: buyerController,
            decoration: const InputDecoration(
              labelText: 'Buyer',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: sellerController,
            decoration: const InputDecoration(
              labelText: 'Seller',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _dateButton('From date', dateFrom, () => pickDate(true)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dateButton('To date', dateTo, () => pickDate(false)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: resetFilters,
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => load(reset: true),
                child: const Text('Apply Filters'),
              ),
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
  }) => DropdownButtonFormField<String>(
    key: ValueKey('$label:$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: [
      const DropdownMenuItem(value: '', child: Text('All')),
      ...options.map(
        (option) => DropdownMenuItem(
          value: valueOf(option),
          child: Text(labelOf(option), overflow: TextOverflow.ellipsis),
        ),
      ),
    ],
    onChanged: (next) => onChanged(next ?? ''),
  );

  String _userLabel(Map<String, dynamic> user) {
    final name = '${user['name'] ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    final first = '${user['first_name'] ?? ''}'.trim();
    final last = '${user['last_name'] ?? ''}'.trim();
    final display = '$first $last'.trim();
    return display.isEmpty
        ? '${user['username'] ?? user['id'] ?? ''}'
        : display;
  }

  Widget _dateButton(String label, DateTime? value, VoidCallback onPressed) =>
      OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.calendar_month_outlined, size: 18),
        label: Text(value == null ? label : _date(value)),
      );

  Widget _kpiCards() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: kpis
        .map(
          (kpi) => SizedBox(
            width: (MediaQuery.sizeOf(context).width - 42) / 2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${kpi['label'] ?? 'Metric'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${kpi['value'] ?? '—'}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList(),
  );

  /// One row per brand / category / product with a bar sized by trade value.
  Widget _tradeCard(List<Map<String, dynamic>> rows, IconData icon) {
    final values = rows
        .map((row) => double.tryParse('${row['trade_value'] ?? 0}') ?? 0)
        .toList();
    final maxValue = values.fold<double>(0, (max, value) => value > max ? value : max);
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++)
              Padding(
                padding: EdgeInsets.only(bottom: index == rows.length - 1 ? 0 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 16, color: color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${rows[index]['name'] ?? '—'}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          formatInr(values[index]),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: maxValue > 0 ? values[index] / maxValue : 0,
                        minHeight: 8,
                        color: color,
                        backgroundColor: color.withValues(alpha: .12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rows[index]['contracts'] ?? 0} contract(s)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _errorCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 44),
          const SizedBox(height: 10),
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => load(reset: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
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
          Icon(Icons.insights_outlined, size: 44),
          SizedBox(height: 10),
          Text(
            'No contracts found for these filters.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _recordCard(Map<String, dynamic> record) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${record['contract_id'] ?? 'Contract'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _status('${record['status'] ?? ''}'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${record['product_title'] ?? '—'}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const Divider(height: 20),
          _line('Brand', record['brand']),
          _line('Category', _categoryText(record)),
          // Company names instead of people/IDs for sellers, buyers and transporters (MoM 24).
          if (isAdminView) ...[
            _line('Buyer', record['buyer_id_display']),
            _line('Seller', record['seller_id_display']),
          ] else ...[
            _line('Buyer', record['buyer_company']),
            _line('Seller', record['seller_company']),
          ],
          _line(
            'Rate',
            '₹${record['deal_amount'] ?? '—'} / ${record['amount_unit'] ?? ''}',
          ),
          _line(
            'Quantity',
            '${record['deal_quantity'] ?? '—'} ${record['quantity_unit'] ?? ''}',
          ),
          _line('Trade value', formatInr(record['trade_value'])),
          _line('Branch', record['branch']),
          if (isAdminView) ...[
            _line('Sub admin', record['sub_admin']),
            _line('Confirmed', record['confirmed_at']),
          ],
        ],
      ),
    ),
  );

  String _categoryText(Map<String, dynamic> record) {
    final main = '${record['category'] ?? ''}'.trim();
    final sub = '${record['product_category'] ?? ''}'.trim();
    if (sub.isEmpty || sub == main) return main.isEmpty ? '—' : main;
    return '$main › $sub';
  }

  Widget _line(String label, Object? value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            '${(value == null || '$value'.isEmpty) ? '—' : value}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _status(String value) {
    final color = switch (value.toLowerCase()) {
      'received' || 'completed' => Colors.green,
      'cancelled' || 'rejected' => Colors.red,
      'active' || 'confirmed' => Colors.blue,
      _ => Colors.orange,
    };
    return Chip(
      label: Text(
        value.isEmpty ? '—' : '${value[0].toUpperCase()}${value.substring(1)}',
      ),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      side: BorderSide(color: color.withValues(alpha: .35)),
      backgroundColor: color.withValues(alpha: .10),
    );
  }

  Widget _loadMoreButton() => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: OutlinedButton.icon(
      onPressed: loadingMore ? null : () => load(reset: false),
      icon: loadingMore
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.expand_more_rounded),
      label: Text(loadingMore ? 'Loading...' : 'Load more'),
    ),
  );
}
