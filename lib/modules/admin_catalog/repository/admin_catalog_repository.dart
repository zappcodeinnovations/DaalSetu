import 'package:agro_broker/modules/admin_catalog/config/admin_module_config.dart';
import 'package:agro_broker/modules/admin_catalog/model/admin_record.dart';
import 'package:agro_broker/network/api_client.dart';

class AdminPageResult {
  const AdminPageResult({
    required this.records,
    required this.hasNext,
    required this.total,
  });

  final List<AdminRecord> records;
  final bool hasNext;
  final int? total;
}

class AdminCatalogRepository {
  const AdminCatalogRepository(this.config);

  final AdminModuleConfig config;

  Future<AdminPageResult> fetch({
    required int page,
    required int pageSize,
    String search = '',
    String filter = '',
  }) async {
    final query = <String, String>{
      ...config.staticQuery,
      'page': '$page',
      'page_size': '$pageSize',
      if (search.isNotEmpty && config.searchParameter != null)
        config.searchParameter!: search,
      if (filter.isNotEmpty && config.filterParameter != null)
        config.filterParameter!: filter,
    };
    final endpoint = Uri(
      path: config.listEndpoint,
      queryParameters: query,
    ).toString();
    final response = await ApiClient.get(endpoint: endpoint, requireAuth: true);
    final decoded = _decodeList(response);
    var records = decoded.$1;
    if (config.clientFilter != null) {
      records = records.where(config.clientFilter!).toList();
    }
    return AdminPageResult(
      records: records.map(AdminRecord.new).toList(),
      hasNext: decoded.$2,
      total: decoded.$3,
    );
  }

  Future<AdminRecord> detail(AdminRecord record) async {
    if (config.detailEndpoint == null || record.id.isEmpty) return record;
    final response = await ApiClient.get(
      endpoint: config.detailEndpoint!(record.id),
      requireAuth: true,
    );
    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      final data = map['data'];
      if (data is Map) return AdminRecord(Map<String, dynamic>.from(data));
      return AdminRecord(map);
    }
    return record;
  }

  Future<void> create(Map<String, dynamic> body) async {
    await ApiClient.post(
      endpoint: config.createEndpoint!,
      body: body,
      requireAuth: true,
    );
  }

  Future<void> update(String id, Map<String, dynamic> body) async {
    final endpoint = config.updateEndpoint!(id);
    if (config.updateMethod == AdminRequestMethod.post) {
      await ApiClient.post(endpoint: endpoint, body: body, requireAuth: true);
    } else {
      await ApiClient.patch(endpoint: endpoint, data: body, requireAuth: true);
    }
  }

  Future<void> delete(String id) async {
    final endpoint = config.deleteEndpoint!(id);
    if (config.key == 'tags') {
      await ApiClient.post(
        endpoint: endpoint,
        body: const {'confirm': true},
        requireAuth: true,
      );
      return;
    }
    if (config.key == 'users' || config.key == 'salesman') {
      await ApiClient.post(
        endpoint: endpoint,
        body: const {},
        requireAuth: true,
      );
      return;
    }
    await ApiClient.delete(endpoint: endpoint, requireAuth: true);
  }

  (List<Map<String, dynamic>>, bool, int?) _decodeList(dynamic response) {
    if (response is List) {
      return (
        response.whereType<Map>().map(Map<String, dynamic>.from).toList(),
        false,
        response.length,
      );
    }
    if (response is! Map) {
      throw Exception('Invalid ${config.title} response');
    }
    final map = Map<String, dynamic>.from(response);
    dynamic raw =
        map['results'] ?? map['data'] ?? map['items'] ?? map['brands'];
    if (raw is Map) {
      raw = raw['results'] ?? raw['data'] ?? raw['items'] ?? raw['brands'];
    }
    if (raw is! List) {
      if (map.containsKey('id')) return ([map], false, 1);
      return (const [], false, 0);
    }
    final next = map['next'];
    final count = int.tryParse((map['count'] ?? map['total'] ?? '').toString());
    return (
      raw.whereType<Map>().map(Map<String, dynamic>.from).toList(),
      next != null && next.toString().isNotEmpty,
      count,
    );
  }
}
