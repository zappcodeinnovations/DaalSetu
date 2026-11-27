import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/utils/india_location_data.dart';
import 'package:flutter/material.dart';

/// Country rules and location lists for a company address (web parity: any country, typed entries allowed).
///
/// India keeps the built-in state / city list (works offline) plus PAN, optional GST and the 6-digit pincode.
/// Every other country loads its states and cities from the server (`/api/locations/`) and has a free-form
/// postal code and no PAN / GST.
class CompanyLocation {
  CompanyLocation._();

  static const String india = 'India';

  static bool isIndia(String? country) {
    final value = (country ?? '').trim().toLowerCase();
    return value.isEmpty || value == 'india';
  }

  /// Same rule as the server: 6 digits in India, 3-12 letters / digits (spaces and dashes inside) elsewhere.
  static String? postalCodeError(String? country, String value) {
    final code = value.trim();
    final india = isIndia(country);
    if (code.isEmpty) return india ? 'Please enter Pincode.' : 'Please enter Postal Code.';
    if (india) {
      return RegExp(r'^\d{6}$').hasMatch(code) ? null : 'Pincode must be exactly 6 digits.';
    }
    return RegExp(r'^[A-Za-z0-9][A-Za-z0-9 \-]{1,10}[A-Za-z0-9]$').hasMatch(code)
        ? null
        : 'Postal code must be 3-12 letters or digits.';
  }

  static String postalCodeLabel(String? country) => isIndia(country) ? 'Pincode' : 'Postal Code';

  static List<String>? _countries;
  static final Map<String, List<String>> _states = {};
  static final Map<String, List<String>> _cities = {};

  /// Every country (server list); India alone when the server cannot be reached.
  static Future<List<String>> countries() async {
    if (_countries != null) return _countries!;
    final list = await _load('/api/locations/?countries=1', 'countries');
    if (list.isEmpty) return const [india];
    _countries = list.contains(india) ? list : [india, ...list];
    return _countries!;
  }

  static Future<List<String>> states(String country) async {
    if (isIndia(country)) return IndiaLocationData.stateCities.keys.toList()..sort();
    final key = country.trim().toLowerCase();
    if (_states.containsKey(key)) return _states[key]!;
    final list = await _load('/api/locations/?country=${Uri.encodeQueryComponent(country.trim())}', 'states');
    if (list.isNotEmpty) _states[key] = list;
    return list;
  }

  static Future<List<String>> cities(String country, String state) async {
    if (state.trim().isEmpty) return const [];
    if (isIndia(country)) {
      final match = IndiaLocationData.stateCities.keys.firstWhere(
        (k) => k.toLowerCase() == state.trim().toLowerCase(),
        orElse: () => '',
      );
      return match.isEmpty ? const [] : (List<String>.from(IndiaLocationData.stateCities[match]!)..sort());
    }
    final key = '${country.trim().toLowerCase()}|${state.trim().toLowerCase()}';
    if (_cities.containsKey(key)) return _cities[key]!;
    final list = await _load(
      '/api/locations/?country=${Uri.encodeQueryComponent(country.trim())}&state=${Uri.encodeQueryComponent(state.trim())}',
      'cities',
    );
    if (list.isNotEmpty) _cities[key] = list;
    return list;
  }

  static Future<List<String>> _load(String endpoint, String key) async {
    try {
      final response = await ApiClient.get(endpoint: endpoint, requireAuth: true, suppressErrorDialog: true);
      final raw = response is Map ? response[key] : null;
      if (raw is! List) return const [];
      return raw.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
    } catch (_) {
      // No list: the user can still type the name (manual entry).
      return const [];
    }
  }

  /// "Other": the user types a state / city that is not in the list.
  static Future<String?> askName(BuildContext context, {required String title, required String hint}) {
    final input = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: TextField(
          controller: input,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(input.text.trim()),
            child: const Text('Select'),
          ),
          OutlinedButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
        ],
      ),
    ).then((value) => (value ?? '').trim().isEmpty ? null : value!.trim());
  }

  /// Option key for "type my own" in a selection sheet.
  static const String otherOption = '__other__';
}
