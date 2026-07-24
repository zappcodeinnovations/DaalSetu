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
      header: SellerHeader.fromJson(json['header'] ?? {}),
      kpis: (json['kpis'] as List?)?.map((x) => SellerKpi.fromJson(x)).toList() ?? [],
      charts: SellerCharts.fromJson(json['charts'] ?? {}),
      recentContracts: (json['recent_contracts'] as List?)?.map((x) => SellerContract.fromJson(x)).toList() ?? [],
      recentDeals: (json['recent_deals'] as List?)?.map((x) => SellerDeal.fromJson(x)).toList() ?? [],
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
      name: json['name'] ?? '',
      branchCode: json['branch_code'] ?? '',
      branchName: json['branch_name'] ?? '',
      profileCompletion: json['profile_completion'] ?? 0,
      kycStatus: json['kyc_status'] ?? '',
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
      title: json['title'] ?? '',
      value: json['value'] ?? 0.0,
      subtitle: json['subtitle'] ?? '',
      type: json['type'] ?? '',
      screen: json['screen'] ?? '',
    );
  }
}

class SellerCharts {
  final List<CommodityMix> commodityMix;
  final Map<String, dynamic> dealPipeline;

  SellerCharts({
    required this.commodityMix,
    required this.dealPipeline,
  });

  factory SellerCharts.fromJson(Map<String, dynamic> json) {
    return SellerCharts(
      commodityMix: (json['commodity_mix'] as List?)?.map((x) => CommodityMix.fromJson(x)).toList() ?? [],
      dealPipeline: json['deal_pipeline'] ?? {},
    );
  }
}

class CommodityMix {
  final String categoryName;
  final double volume;

  CommodityMix({
    required this.categoryName,
    required this.volume,
  });

  factory CommodityMix.fromJson(Map<String, dynamic> json) {
    return CommodityMix(
      categoryName: json['product__category__category_name'] ?? 'Unknown',
      volume: (json['volume'] ?? 0).toDouble(),
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
      id: json['id'] ?? 0,
      contractId: json['contract_id'] ?? '',
      status: json['status'] ?? '',
      buyerName: json['buyer__first_name'] ?? '',
      buyerCompany: json['buyer__company_name'] ?? '',
      brandName: json['product__brand__brand_name'] ?? '',
      categoryName: json['product__category__category_name'] ?? '',
      dealQuantity: (json['deal_quantity'] ?? 0).toDouble(),
      dealAmount: (json['deal_amount'] ?? 0).toDouble(),
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
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      requestedAmount: (json['requested_amount'] ?? 0).toDouble(),
      requestedQuantity: (json['requested_quantity'] ?? 0).toDouble(),
      brandName: json['brand__brand_name'] ?? '',
      categoryName: json['category__category_name'] ?? '',
    );
  }
}
