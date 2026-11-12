double _dashboardDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _dashboardInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Map<String, dynamic> _dashboardMap(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

class SellerDashboardModel {
  final SellerHeader header;
  final List<SellerKpi> kpis;
  final SellerCharts charts;
  final List<SellerContract> recentContracts;
  final List<SellerDeal> recentDeals;

  SellerDashboardModel({
    required this.header,
    required this.kpis,
    required this.charts,
    required this.recentContracts,
    required this.recentDeals,
  });

  factory SellerDashboardModel.fromJson(Map<String, dynamic> json) {
    return SellerDashboardModel(
      header: SellerHeader.fromJson(_dashboardMap(json['header'])),
      kpis:
          (json['kpis'] as List?)
              ?.map((x) => SellerKpi.fromJson(_dashboardMap(x)))
              .toList() ??
          [],
      charts: SellerCharts.fromJson(_dashboardMap(json['charts'])),
      recentContracts:
          (json['recent_contracts'] as List?)
              ?.map((x) => SellerContract.fromJson(_dashboardMap(x)))
              .toList() ??
          [],
      recentDeals:
          (json['recent_deals'] as List?)
              ?.map((x) => SellerDeal.fromJson(_dashboardMap(x)))
              .toList() ??
          [],
    );
  }
}

class SellerHeader {
  final String name;
  final String branchCode;
  final String branchName;
  final int profileCompletion;
  final String kycStatus;

  SellerHeader({
    required this.name,
    required this.branchCode,
    required this.branchName,
    required this.profileCompletion,
    required this.kycStatus,
  });

  factory SellerHeader.fromJson(Map<String, dynamic> json) {
    return SellerHeader(
      name: json['name']?.toString() ?? '',
      branchCode: json['branch_code']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? '',
      profileCompletion: _dashboardInt(json['profile_completion']),
      kycStatus: json['kyc_status']?.toString() ?? '',
    );
  }
}

class SellerKpi {
  final String title;
  final dynamic value;
  final String subtitle;
  final String type;
  final String screen;

  SellerKpi({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.type,
    required this.screen,
  });

  factory SellerKpi.fromJson(Map<String, dynamic> json) {
    return SellerKpi(
      title: json['title']?.toString() ?? '',
      value: json['value'] ?? 0.0,
      subtitle: json['subtitle']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      screen: json['screen']?.toString() ?? '',
    );
  }
}

class SellerCharts {
  final List<CommodityMix> commodityMix;
  final Map<String, dynamic> dealPipeline;

  SellerCharts({required this.commodityMix, required this.dealPipeline});

  factory SellerCharts.fromJson(Map<String, dynamic> json) {
    return SellerCharts(
      commodityMix:
          (json['commodity_mix'] as List?)
              ?.map((x) => CommodityMix.fromJson(_dashboardMap(x)))
              .toList() ??
          [],
      dealPipeline: _dashboardMap(json['deal_pipeline']),
    );
  }
}

class CommodityMix {
  final String categoryName;
  final double volume;

  CommodityMix({required this.categoryName, required this.volume});

  factory CommodityMix.fromJson(Map<String, dynamic> json) {
    return CommodityMix(
      categoryName:
          json['product__category__category_name']?.toString() ?? 'Unknown',
      volume: _dashboardDouble(json['volume']),
    );
  }
}

class SellerContract {
  final int id;
  final String contractId;
  final String status;
  final String buyerName;
  final String buyerCompany;
  final String brandName;
  final String categoryName;
  final double dealQuantity;
  final double dealAmount;

  SellerContract({
    required this.id,
    required this.contractId,
    required this.status,
    required this.buyerName,
    required this.buyerCompany,
    required this.brandName,
    required this.categoryName,
    required this.dealQuantity,
    required this.dealAmount,
  });

  factory SellerContract.fromJson(Map<String, dynamic> json) {
    return SellerContract(
      id: _dashboardInt(json['id']),
      contractId: json['contract_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      buyerName: json['buyer__first_name']?.toString() ?? '',
      buyerCompany: json['buyer__company_name']?.toString() ?? '',
      brandName: json['product__brand__brand_name']?.toString() ?? '',
      categoryName: json['product__category__category_name']?.toString() ?? '',
      dealQuantity: _dashboardDouble(json['deal_quantity']),
      dealAmount: _dashboardDouble(json['deal_amount']),
    );
  }
}

class SellerDeal {
  final int id;
  final String status;
  final double requestedAmount;
  final double requestedQuantity;
  final String brandName;
  final String categoryName;

  SellerDeal({
    required this.id,
    required this.status,
    required this.requestedAmount,
    required this.requestedQuantity,
    required this.brandName,
    required this.categoryName,
  });

  factory SellerDeal.fromJson(Map<String, dynamic> json) {
    return SellerDeal(
      id: _dashboardInt(json['id']),
      status: json['status']?.toString() ?? '',
      requestedAmount: _dashboardDouble(json['requested_amount']),
      requestedQuantity: _dashboardDouble(json['requested_quantity']),
      brandName: json['brand__brand_name']?.toString() ?? '',
      categoryName: json['category__category_name']?.toString() ?? '',
    );
  }
}
