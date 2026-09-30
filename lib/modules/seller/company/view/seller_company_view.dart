import 'package:agro_broker/services/seller_services.dart';
import 'package:agro_broker/theme/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agro_broker/theme/app_theme.dart';

class SellerCompanyView extends StatefulWidget {
  const SellerCompanyView({super.key});

  @override
  State<SellerCompanyView> createState() => _SellerCompanyViewState();
}

class _SellerCompanyViewState extends State<SellerCompanyView> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _companies = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await SellerServices.getCompanies();
      if (!mounted) return;
      setState(() {
        _companies = result
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _cleanError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  Future<void> _openForm([Map<String, dynamic>? company]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _CompanyFormPage(company: company)),
    );
    if (changed == true) await _loadCompanies();
  }

  Future<void> _setPrimary(Map<String, dynamic> company) async {
    final id = company['id']?.toString();
    if (id == null) return;
    try {
      final message = await SellerServices.setPrimaryCompany(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _loadCompanies();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'My Companies',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadCompanies,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Register Company'),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _loadCompanies)
            : RefreshIndicator(
                onRefresh: _loadCompanies,
                child: _companies.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 90),
                          Icon(
                            Icons.business_outlined,
                            size: 72,
                            color: AppTheme.primaryGold.withValues(
                              alpha: 0.55,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'No company registered',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Register your company to manage business details from your profile.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                        itemCount: _companies.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, index) =>
                            _companyCard(_companies[index]),
                      ),
              ),
      ),
    );
  }

  Widget _companyCard(Map<String, dynamic> company) {
    final theme = Theme.of(context);
    final primary = company['is_primary'] == true;
    final verified = company['is_verified'] == true;
    final address =
        [
              company['address_line_1'],
              company['address_line_2'],
              company['city'],
              company['state'],
              company['pincode'],
              company['country'],
            ]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .join(', ');

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderColor: primary
          ? AppTheme.primaryGold.withValues(alpha: 0.55)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: AppTheme.primaryGold.withValues(
                  alpha: 0.13,
                ),
                child: Icon(
                  Icons.apartment_rounded,
                  color: AppTheme.primaryGold,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company['legal_name']?.toString() ?? 'Company',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((company['company_type'] ?? '').toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(company['company_type'].toString()),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit company',
                onPressed: () => _openForm(company),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (primary) _badge('Primary', Icons.star_rounded, AppTheme.primaryGold),
              _badge(
                verified ? 'Verified' : 'Verification pending',
                verified ? Icons.verified_rounded : Icons.schedule_rounded,
                verified ? AppTheme.successGreen : AppTheme.secondaryOrange,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if ((company['gst_number'] ?? '').toString().isNotEmpty)
            _detail(
              Icons.receipt_long_outlined,
              'GST',
              company['gst_number'].toString(),
            ),
          if ((company['pan_number'] ?? '').toString().isNotEmpty)
            _detail(
              Icons.badge_outlined,
              'PAN',
              company['pan_number'].toString(),
            ),
          if (address.isNotEmpty)
            _detail(Icons.location_on_outlined, 'Address', address),
          if (!primary) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _setPrimary(company),
                icon: const Icon(Icons.star_outline_rounded),
                label: const Text('Set as primary'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _detail(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGold),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}

class _CompanyFormPage extends StatefulWidget {
  const _CompanyFormPage({this.company});

  final Map<String, dynamic>? company;

  @override
  State<_CompanyFormPage> createState() => _CompanyFormPageState();
}

class _CompanyFormPageState extends State<_CompanyFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  bool _saving = false;

  bool get _editing => widget.company != null;

  @override
  void initState() {
    super.initState();
    String value(String key) => widget.company?[key]?.toString() ?? '';
    _fields = {
      'legal_name': TextEditingController(text: value('legal_name')),
      'company_type': TextEditingController(text: value('company_type')),
      'year_of_establishment': TextEditingController(
        text: value('year_of_establishment'),
      ),
      'number_of_employees': TextEditingController(
        text: value('number_of_employees'),
      ),
      'gst_number': TextEditingController(text: value('gst_number')),
      'pan_number': TextEditingController(text: value('pan_number')),
      'address_line_1': TextEditingController(text: value('address_line_1')),
      'address_line_2': TextEditingController(text: value('address_line_2')),
      'state': TextEditingController(text: value('state')),
      'city': TextEditingController(text: value('city')),
      'pincode': TextEditingController(text: value('pincode')),
      'country': TextEditingController(
        text: value('country').isEmpty ? 'India' : value('country'),
      ),
      'landmark': TextEditingController(text: value('landmark')),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = <String, dynamic>{
      for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
    };
    for (final key in ['year_of_establishment', 'number_of_employees']) {
      final value = body[key] as String;
      body[key] = value.isEmpty ? null : int.tryParse(value);
    }

    try {
      if (_editing) {
        await SellerServices.editCompany(
          widget.company!['id'].toString(),
          body,
        );
      } else {
        await SellerServices.createCompany(body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Company updated successfully.'
                : 'Company registered successfully.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _editing ? 'Edit Company' : 'Register Company',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: [
            _section('Business Information', Icons.business_center_outlined, [
              _input('legal_name', 'Legal company name', required: true),
              _input(
                'company_type',
                'Company type',
                hint: 'e.g. Private Limited, Proprietorship',
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _input(
                      'year_of_establishment',
                      'Established year',
                      numeric: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _input(
                      'number_of_employees',
                      'Employees',
                      numeric: true,
                    ),
                  ),
                ],
              ),
              _input(
                'gst_number',
                'GST number',
                capitalization: TextCapitalization.characters,
              ),
              _input(
                'pan_number',
                'PAN number',
                capitalization: TextCapitalization.characters,
              ),
            ]),
            const SizedBox(height: 16),
            _section('Registered Address', Icons.location_on_outlined, [
              _input('address_line_1', 'Address line 1', required: true),
              _input('address_line_2', 'Address line 2'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _input('city', 'City', required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _input('state', 'State', required: true)),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _input(
                      'pincode',
                      'Pincode',
                      required: true,
                      numeric: true,
                      maxLength: 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _input('country', 'Country', required: true)),
                ],
              ),
              _input('landmark', 'Landmark'),
            ]),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _editing
                            ? Icons.save_outlined
                            : Icons.add_business_rounded,
                      ),
                label: Text(_editing ? 'Save Changes' : 'Register Company'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGold),
              const SizedBox(width: 9),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _input(
    String key,
    String label, {
    String? hint,
    bool required = false,
    bool numeric = false,
    int? maxLength,
    TextCapitalization capitalization = TextCapitalization.words,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _fields[key],
        textCapitalization: capitalization,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        inputFormatters: numeric
            ? [
                FilteringTextInputFormatter.digitsOnly,
                if (maxLength != null)
                  LengthLimitingTextInputFormatter(maxLength),
              ]
            : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return '$label is required';
          }
          if (key == 'pincode' &&
              value != null &&
              value.isNotEmpty &&
              value.length != 6) {
            return 'Enter 6 digits';
          }
          return null;
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 58,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    ),
  );
}
