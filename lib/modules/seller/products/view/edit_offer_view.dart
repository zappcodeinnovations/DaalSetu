import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';

/// Edits an offer's details. Stock (bags / quantity) is changed only from the
/// Stock dialog: sending packing fields here would reset the remaining stock.
class EditOfferView extends StatefulWidget {
  final int productId;
  const EditOfferView({super.key, required this.productId});

  @override
  State<EditOfferView> createState() => _EditOfferViewState();
}

class _EditOfferViewState extends State<EditOfferView> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _location = TextEditingController();
  final _remark = TextEditingController();

  Map<String, dynamic>? _offer;
  String _amountUnit = 'qtl';
  DateTime? _loadingFrom;
  DateTime? _loadingTo;
  DateTime? _dealExpiry;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _amount, _location, _remark]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final offer = await SellerServices.getOfferDetail(widget.productId);
      setState(() {
        _offer = offer;
        _title.text = offer['title']?.toString() ?? '';
        _description.text = offer['description']?.toString() ?? '';
        _amount.text = offer['amount']?.toString() ?? '';
        _location.text = offer['loading_location']?.toString() ?? '';
        _remark.text = offer['remark']?.toString() ?? '';
        final unit = (offer['amount_unit'] ?? 'qtl').toString().toLowerCase();
        _amountUnit = const ['kg', 'qtl', 'ton'].contains(unit) ? unit : 'qtl';
        _loadingFrom = DateTime.tryParse(offer['loading_from']?.toString() ?? '');
        _loadingTo = DateTime.tryParse(offer['loading_to']?.toString() ?? '');
        _dealExpiry = DateTime.tryParse(offer['deal_expiry_datetime']?.toString() ?? '')?.toLocal();
        _loading = false;
      });
    } catch (e) {
      SellerUi.error(e);
      setState(() => _loading = false);
    }
  }

  String _ymd(DateTime? d) =>
      d == null ? '' : "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _pickDate(DateTime? current, ValueChanged<DateTime> onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && current.isAfter(now) ? current : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  Future<void> _pickExpiry() async {
    await _pickDate(_dealExpiry, (date) => _dealExpiry = date);
    if (!mounted || _dealExpiry == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dealExpiry!),
    );
    if (time != null) {
      setState(() => _dealExpiry = DateTime(_dealExpiry!.year, _dealExpiry!.month, _dealExpiry!.day, time.hour, time.minute));
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _amount.text.trim().isEmpty || _loadingFrom == null) {
      SellerUi.error("Title, price and loading from date are required.");
      return;
    }
    final offer = _offer!;
    final body = <String, dynamic>{
      "title": _title.text.trim(),
      "description": _description.text.trim(),
      "category_id": offer['category_id'],
      if (offer['brand_id'] != null) "brand_id": offer['brand_id'],
      "amount": _amount.text.trim(),
      "amount_unit": _amountUnit,
      "loading_from": _ymd(_loadingFrom),
      "loading_to": _ymd(_loadingTo ?? _loadingFrom),
      "loading_location": _location.text.trim(),
      "remark": _remark.text.trim(),
      "is_active": offer['is_active'] ?? true,
      if (_dealExpiry != null)
        "deal_expiry_datetime": "${_ymd(_dealExpiry)}T${_dealExpiry!.hour.toString().padLeft(2, '0')}:${_dealExpiry!.minute.toString().padLeft(2, '0')}",
    };
    setState(() => _saving = true);
    try {
      final result = await SellerServices.updateOffer(widget.productId, body);
      SellerUi.success(result['message']?.toString() ?? "Offer updated");
      Get.back(result: true);
    } catch (e) {
      SellerUi.error(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController c, String label, {TextInputType? type, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: type,
        maxLength: type == null ? null : 10,
        maxLines: lines,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _dateTile(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: const Icon(Icons.calendar_month, color: SellerUi.primary),
          ),
          child: Text(value.isEmpty ? 'Select' : value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SellerUi.appBar(context, "Edit Offer"),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SellerUi.primary))
          : _offer == null
              ? const Center(child: Text("Offer could not be loaded"))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      "Category: ${_offer!['category_name'] ?? '-'}",
                      style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    _field(_title, "Offer Title *"),
                    _field(_description, "Description", lines: 3),
                    Row(
                      children: [
                        Expanded(child: _field(_amount, "Price *", type: const TextInputType.numberWithOptions(decimal: true))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: DropdownButtonFormField<String>(
                              initialValue: _amountUnit,
                              decoration: InputDecoration(labelText: "Per", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              items: const [
                                DropdownMenuItem(value: 'kg', child: Text('KG')),
                                DropdownMenuItem(value: 'qtl', child: Text('Quintal')),
                                DropdownMenuItem(value: 'ton', child: Text('Ton')),
                              ],
                              onChanged: (value) => setState(() => _amountUnit = value ?? 'qtl'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _dateTile("Loading From *", _ymd(_loadingFrom), () => _pickDate(_loadingFrom, (d) => _loadingFrom = d)),
                    _dateTile("Loading To", _ymd(_loadingTo), () => _pickDate(_loadingTo, (d) => _loadingTo = d)),
                    _dateTile("Deal Expiry", _dealExpiry == null ? '' : SellerUi.date(_dealExpiry!.toIso8601String()), _pickExpiry),
                    _field(_location, "Loading Location"),
                    _field(_remark, "Remark", lines: 2),
                    Text(
                      "To change bags / quantity use the Stock button on the offer card.",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SellerUi.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
    );
  }
}
