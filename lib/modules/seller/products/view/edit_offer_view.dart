import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';
import 'package:daalsetu/widgets/delivery_period_picker.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

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
  DateTime? _deliveryFrom;
  DateTime? _deliveryTo;
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
        _deliveryFrom = DeliveryPeriodPicker.parseUpcoming(offer['delivery_from']?.toString());
        _deliveryTo = DeliveryPeriodPicker.parseUpcoming(offer['delivery_to']?.toString()) ?? _deliveryFrom;
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
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dealExpiry != null && _dealExpiry!.isAfter(now)
          ? _dealExpiry!
          : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final minimumExpiry = now.add(const Duration(minutes: 2));
    final initialDateTime = _dealExpiry != null &&
            DateUtils.isSameDay(_dealExpiry, date) &&
            _dealExpiry!.isAfter(now)
        ? _dealExpiry!
        : DateUtils.isSameDay(date, now)
            ? minimumExpiry
            : DateTime(date.year, date.month, date.day, 18);
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (time != null) {
      final selectedExpiry = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (!selectedExpiry.isAfter(DateTime.now())) {
        SellerUi.error('Deal expiry time must be in the future.');
        return;
      }
      setState(() => _dealExpiry = selectedExpiry);
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _amount.text.trim().isEmpty || _loadingFrom == null) {
      SellerUi.error("Title, price and loading from date are required.");
      return;
    }
    if (_dealExpiry == null || !_dealExpiry!.isAfter(DateTime.now())) {
      SellerUi.error("Deal expiry time must be in the future.");
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
      // Sent only when set, so an offer without a period keeps working.
      if (_deliveryFrom != null) "delivery_from": _ymd(_deliveryFrom),
      if (_deliveryFrom != null) "delivery_to": _ymd(_deliveryTo ?? _deliveryFrom),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: type,
        maxLength: type == null ? null : 10,
        buildCounter:
            (_, {required currentLength, required isFocused, maxLength}) =>
                null,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          counterText: "",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
          ),
          filled: true,
          fillColor: theme.cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _dateTile(String label, String value, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
            ),
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFFFFB300)),
          ),
          child: Text(
            value.isEmpty ? 'Select' : value,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Edit Offer",
        subtitle: "Commodity pricing, delivery window & terms",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        trailing: IconButton(
          tooltip: 'Reload',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _load,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SellerUi.primary))
          : _offer == null
              ? const Center(child: Text("Offer could not be loaded"))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF282828) : const Color(0xFFFFF8E1).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.category_outlined, size: 16, color: Color(0xFFE65100)),
                          const SizedBox(width: 8),
                          Text(
                            "Category: ${_offer!['category_name'] ?? '-'}",
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.grey.shade300 : const Color(0xFF5D4037),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: "Per",
                                labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'kg', child: Text('KG', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'qtl', child: Text('Quintal', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'ton', child: Text('Ton', overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (value) => setState(() => _amountUnit = value ?? 'qtl'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _dateTile("Loading From *", _ymd(_loadingFrom), () => _pickDate(_loadingFrom, (d) => _loadingFrom = d)),
                    _dateTile("Loading To", _ymd(_loadingTo), () => _pickDate(_loadingTo, (d) => _loadingTo = d)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DeliveryPeriodPicker(
                        label: "Delivery Period",
                        from: _deliveryFrom,
                        to: _deliveryTo,
                        hint: "This delivery period is visible to buyers, and they can negotiate it",
                        onChanged: (from, to) => setState(() {
                          _deliveryFrom = from;
                          _deliveryTo = to;
                        }),
                      ),
                    ),
                    _dateTile("Deal Expiry", _dealExpiry == null ? '' : SellerUi.date(_dealExpiry!.toIso8601String()), _pickExpiry),
                    _field(_location, "Loading Location"),
                    _field(_remark, "Add Remark", lines: 2),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "To change bags / quantity use the Stock button on the offer card.",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text("SAVE CHANGES", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
    );
  }
}
