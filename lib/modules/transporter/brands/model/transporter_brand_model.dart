class TransporterBrandDashboardData {
  final int totalBrands;
  final int activeBrands;
  final int brandsInUse;

  TransporterBrandDashboardData({
    this.totalBrands = 0,
    this.activeBrands = 0,
    this.brandsInUse = 0,
  });

  factory TransporterBrandDashboardData.fromJson(dynamic json) {
    if (json == null || json is! Map) {
      return TransporterBrandDashboardData();
    }

    Map target = json;
    if (target['data'] is Map) {
      target = target['data'] as Map;
    } else if (target['body'] is Map) {
      final bodyMap = target['body'] as Map;
      if (bodyMap['data'] is Map) {
        target = bodyMap['data'] as Map;
      } else {
        target = bodyMap;
      }
    }

    return TransporterBrandDashboardData(
      totalBrands: _parseInt(target['total_brands'] ?? target['totalBrands'] ?? target['total']),
      activeBrands: _parseInt(target['active_brands'] ?? target['activeBrands'] ?? target['active']),
      brandsInUse: _parseInt(target['brands_in_use'] ?? target['brandsInUse'] ?? target['in_use']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class TransporterBrandModel {
  final int? id;
  final String name;
  final String? logoUrl;
  final String? companyName;
  final String? description;
  final bool isActive;
  final bool inUse;

  TransporterBrandModel({
    this.id,
    required this.name,
    this.logoUrl,
    this.companyName,
    this.description,
    this.isActive = true,
    this.inUse = false,
  });

  factory TransporterBrandModel.fromJson(dynamic rawJson) {
    if (rawJson == null || rawJson is! Map) {
      return TransporterBrandModel(name: 'Brand');
    }
    final json = rawJson;

    final rawName = json['name'] ?? json['brand_name'] ?? json['title'] ?? 'Brand';
    final rawId = json['id'];
    
    int? parsedId;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId != null) {
      parsedId = int.tryParse(rawId.toString());
    }

    bool active = true;
    if (json.containsKey('is_active')) {
      final val = json['is_active'];
      if (val is bool) {
        active = val;
      } else if (val is String) {
        active = val.toLowerCase() == 'true' || val == '1';
      }
    }

    bool inUseVal = false;
    if (json.containsKey('in_use')) {
      final val = json['in_use'];
      if (val is bool) {
        inUseVal = val;
      } else if (val is String) {
        inUseVal = val.toLowerCase() == 'true' || val == '1';
      }
    }

    return TransporterBrandModel(
      id: parsedId,
      name: rawName.toString(),
      logoUrl: json['logo_url'] ?? json['logo'] ?? json['image'],
      companyName: json['company_name'] ?? json['company']?['name'],
      description: json['description']?.toString(),
      isActive: active,
      inUse: inUseVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'company_name': companyName,
      'description': description,
      'is_active': isActive,
      'in_use': inUse,
    };
  }
}
