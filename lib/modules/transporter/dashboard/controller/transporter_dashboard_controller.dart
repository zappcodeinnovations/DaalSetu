import '../../../../comman/api_url.dart';
import '../../../../network/api_client.dart';
import '../../../../services/seller_services.dart';
import '../../../../utils/app_preferences.dart';
import 'package:get/get.dart';

/// One labelled series for the dashboard charts.
class ChartSeries {
  final List<String> labels;
  final List<double> values;
  const ChartSeries(this.labels, this.values);

  static ChartSeries fromJson(
    dynamic json,
    String labelsKey,
    String valuesKey,
  ) {
    final map = json is Map ? json : const {};
    final labels = (map[labelsKey] as List? ?? []).map((e) => '$e').toList();
    final values = (map[valuesKey] as List? ?? [])
        .map((e) => double.tryParse('$e') ?? 0)
        .toList();
    return ChartSeries(labels, values);
  }

  bool get isEmpty => labels.isEmpty || values.every((v) => v == 0);
}

/// Same data as the web transporter dashboard (GET /api/transporter/dashboard/overview/).
class TransporterDashboardController extends GetxController {
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  var username = ''.obs;
  var branchCodes = <String>[].obs;
  var kycStatus = ''.obs;
  var kpis = <String, dynamic>{}.obs;

  /// "7D" | "1M" | "3M" | "1Y"
  var selectedRange = '7D'.obs;
  var ranges = <String, Map<String, ChartSeries>>{}.obs;
  var deliveryStatus = const ChartSeries([], []).obs;
  var transportTypes = const ChartSeries([], []).obs;
  var topRoutes = const ChartSeries([], []).obs;
  var slaDrivers = const ChartSeries([], []).obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    fetchDashboardOverview();
  }

  Future<void> _loadUserInfo() async {
    username.value = await AppPreferences.getUsername() ?? '';
  }

  Map<String, ChartSeries> get currentRange =>
      ranges[selectedRange.value] ?? const {};

  Future<void> fetchDashboardOverview() async {
    try {
      isLoading(true);
      errorMessage('');
      final response = await ApiClient.get(
        endpoint: ApiUrls.transporterDashboardOverview,
        requireAuth: true,
      );
      final data = response is Map && response['data'] is Map
          ? response['data'] as Map
          : const {};

      final profile = data['profile'] is Map
          ? data['profile'] as Map
          : const {};
      if ('${profile['name'] ?? ''}'.isNotEmpty) {
        username.value = '${profile['name']}';
      }
      kycStatus.value = '${profile['kyc_status'] ?? ''}';

      final Set<String> codes = {};
      void addCodes(dynamic val) {
        if (val is List) {
          for (final item in val) {
            if (item is Map) {
              final c = item['branch_code'] ?? item['code'] ?? item['name'];
              if (c != null && '$c'.trim().isNotEmpty) codes.add('$c'.trim());
            } else if (item != null && '$item'.trim().isNotEmpty) {
              codes.add('$item'.trim());
            }
          }
        } else if (val is String && val.trim().isNotEmpty) {
          for (final part in val.split(RegExp(r'[\s,\-]+'))) {
            if (part.trim().isNotEmpty) codes.add(part.trim());
          }
        }
      }

      addCodes(profile['branch_codes']);
      addCodes(profile['assigned_branch_codes']);
      addCodes(profile['branches']);
      addCodes(profile['branch_code']);
      addCodes(data['branch_codes']);
      addCodes(data['branches']);

      // Also fetch from getSellerBranches to guarantee full parity with web branches network
      try {
        final branchRes = await SellerServices.getSellerBranches();
        if (branchRes['data'] is Map<String, dynamic>) {
          final bData = branchRes['data'] as Map<String, dynamic>;
          if (bData['primary_branch'] is Map) {
            final pCode = bData['primary_branch']['branch_code'] ?? bData['primary_branch']['code'];
            if (pCode != null && '$pCode'.trim().isNotEmpty) codes.add('$pCode'.trim());
          }
          if (bData['my_branches'] is List) {
            for (final b in bData['my_branches']) {
              if (b is Map) {
                final bCode = b['branch_code'] ?? b['code'];
                if (bCode != null && '$bCode'.trim().isNotEmpty) codes.add('$bCode'.trim());
              }
            }
          }
        }
      } catch (_) {}

      branchCodes.value = codes.toList();

      kpis.value = data['kpis'] is Map
          ? Map<String, dynamic>.from(data['kpis'] as Map)
          : {};

      final rawRanges = data['ranges'] is Map
          ? data['ranges'] as Map
          : const {};
      ranges.value = {
        for (final entry in rawRanges.entries)
          '${entry.key}': {
            'earnings': ChartSeries.fromJson(
              entry.value,
              'labels',
              'earnLakhs',
            ),
            'shipments': ChartSeries.fromJson(
              entry.value,
              'labels',
              'shipments',
            ),
          },
      };
      deliveryStatus.value = ChartSeries.fromJson(
        data['deliveryStatus'],
        'labels',
        'counts',
      );
      transportTypes.value = ChartSeries.fromJson(
        data['transportTypes'],
        'labels',
        'share',
      );
      topRoutes.value = ChartSeries.fromJson(
        data['topRoutes'],
        'labels',
        'trips',
      );

      final slaData = data['slaDrivers'] ??
          data['sla_drivers'] ??
          data['slaOnTime'] ??
          data['sla_on_time'] ??
          data['driverSla'] ??
          data['driver_sla'] ??
          data['sla'];
      ChartSeries parsedSla = const ChartSeries([], []);
      if (slaData is Map) {
        for (final vKey in ['percentages', 'values', 'otd', 'rates', 'scores', 'share']) {
          final s = ChartSeries.fromJson(slaData, 'labels', vKey);
          if (!s.isEmpty) {
            parsedSla = s;
            break;
          }
        }
      }
      slaDrivers.value = parsedSla;
    } catch (e) {
      errorMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading(false);
    }
  }
}
