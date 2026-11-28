import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/utils/india_location_data.dart';

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

  /// State and city of a pincode / postal code (server lookup: India Post, or the country's postal codes).
  /// Null when the code is not complete yet or unknown.
  static Future<({String state, String city})?> lookupPostalCode(String country, String code) async {
    final value = code.trim();
    if (postalCodeError(country, value) != null) return null;
    try {
      final response = await ApiClient.get(
        endpoint: '/api/locations/?pincode=${Uri.encodeQueryComponent(value)}'
            '&country=${Uri.encodeQueryComponent(isIndia(country) ? india : country.trim())}',
        requireAuth: true,
        suppressErrorDialog: true,
      );
      if (response is! Map || response['success'] != true) return null;
      final state = '${response['state'] ?? ''}'.trim();
      final city = '${response['city'] ?? ''}'.trim();
      if (state.isEmpty && city.isEmpty) return null;
      return (state: state, city: city);
    } catch (_) {
      return null; // Unknown code or no network: the user picks the state and city as before.
    }
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
}
