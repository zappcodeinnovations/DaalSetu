int _parseInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String)
    return int.tryParse(value) ?? (double.tryParse(value)?.toInt() ?? 0);
  return 0;
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class DashboardModel {
  final KpiModel kpis;
  final ChartsModel charts;
  final List<BranchPerformanceModel> branchPerformance;
  final List<ActivityModel> recentActivities;
  final List<ContractModel> recentContracts;

  DashboardModel({
    required this.kpis,
    required this.charts,
    required this.branchPerformance,
    required this.recentActivities,
    required this.recentContracts,
  });

  factory DashboardModel.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return DashboardModel(
      kpis: KpiModel.fromJson(json['kpis'] as Map<String, dynamic>?),
      charts: ChartsModel.fromJson(json['charts'] as Map<String, dynamic>?),
      branchPerformance: (json['branch_performance'] as List? ?? [])
          .map(
            (e) => BranchPerformanceModel.fromJson(
              e as Map<String, dynamic>? ?? {},
            ),
          )
          .toList(),
      recentActivities: (json['recent_activities'] as List? ?? [])
          .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>? ?? {}))
          .toList(),
      recentContracts: (json['recent_contracts'] as List? ?? [])
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>? ?? {}))
          .toList(),
    );
  }
}

class KpiModel {
  final int activeContracts;
  final double gtvMtd;
  final double brokerageEarnedMtd;
  final double brokerageRate;
  final int pendingDispatches;
  final int activeSellers;
  final int listedSkus;
  final int activeBuyers;
  final int finalDealsMtd;
  final int openComplaints;
  final double otdPercent;
  final double avgTransitDays;
  final int paymentsOverdue;
  final double atRiskAmount;
  final int activeTransporters;
  final double capacityUtilized;
  final int branches;
  final int adminsActive;
  final int dealsInNegotiation;
  final double avgTtcDays;

  KpiModel({
    required this.activeContracts,
    required this.gtvMtd,
    required this.brokerageEarnedMtd,
    required this.brokerageRate,
    required this.pendingDispatches,
    required this.activeSellers,
    required this.listedSkus,
    required this.activeBuyers,
    required this.finalDealsMtd,
    required this.openComplaints,
    required this.otdPercent,
    required this.avgTransitDays,
    required this.paymentsOverdue,
    required this.atRiskAmount,
    required this.activeTransporters,
    required this.capacityUtilized,
    required this.branches,
    required this.adminsActive,
    required this.dealsInNegotiation,
    required this.avgTtcDays,
  });

  factory KpiModel.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return KpiModel(
      activeContracts: _parseInt(json['active_contracts']),
      gtvMtd: _parseDouble(json['gtv_mtd']),
      brokerageEarnedMtd: _parseDouble(json['brokerage_earned_mtd']),
      brokerageRate: _parseDouble(json['brokerage_rate']),
      pendingDispatches: _parseInt(json['pending_dispatches']),
      activeSellers: _parseInt(json['active_sellers']),
      listedSkus: _parseInt(json['listed_skus']),
      activeBuyers: _parseInt(json['active_buyers']),
      finalDealsMtd: _parseInt(json['final_deals_mtd']),
      openComplaints: _parseInt(json['open_complaints']),
      otdPercent: _parseDouble(json['otd_percent']),
      avgTransitDays: _parseDouble(json['avg_transit_days']),
      paymentsOverdue: _parseInt(json['payments_overdue']),
      atRiskAmount: _parseDouble(json['at_risk_amount']),
      activeTransporters: _parseInt(json['active_transporters']),
      capacityUtilized: _parseDouble(json['capacity_utilized']),
      branches: _parseInt(json['branches']),
      adminsActive: _parseInt(json['admins_active']),
      dealsInNegotiation: _parseInt(json['deals_in_negotiation']),
      avgTtcDays: _parseDouble(json['avg_ttc_days']),
    );
  }
}

class BranchPerformanceModel {
  final String name;
  final String admin;
  final int sellers;
  final int buyers;
  final int contracts;
  final double gtvMtd;
  final double otdPercent;
  final String status;

  BranchPerformanceModel({
    required this.name,
    required this.admin,
    required this.sellers,
    required this.buyers,
    required this.contracts,
    required this.gtvMtd,
    required this.otdPercent,
    required this.status,
  });

  factory BranchPerformanceModel.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return BranchPerformanceModel(
      name: json['name']?.toString() ?? '',
      admin: json['admin']?.toString() ?? '',
      sellers: _parseInt(json['sellers']),
      buyers: _parseInt(json['buyers']),
      contracts: _parseInt(json['contracts']),
      gtvMtd: _parseDouble(json['gtv_mtd']),
      otdPercent: _parseDouble(json['otd_percent']),
      status: json['status']?.toString() ?? '',
    );
  }
}

class ActivityModel {
  final String title;
  final String description;
  final String time;

  ActivityModel({
    required this.title,
    required this.description,
    required this.time,
  });

  factory ActivityModel.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return ActivityModel(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
    );
  }
}

class ContractModel {
  final String id;
  final String seller;
  final String buyer;
  final String commodity;
  final String bagCount;
  final String packingWeightKg;
  final String quantity;
  final String rate;
  final String value;
  final String brokerage;
  final String paymentStatus;
  final String deliveryStatus;
  final String transporter;
  final String branch;

  ContractModel({
    required this.id,
    required this.seller,
    required this.buyer,
    required this.commodity,
    required this.bagCount,
    required this.packingWeightKg,
    required this.quantity,
    required this.rate,
    required this.value,
    required this.brokerage,
    required this.paymentStatus,
    required this.deliveryStatus,
    required this.transporter,
    required this.branch,
  });

  factory ContractModel.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return ContractModel(
      id: json['id']?.toString() ?? '',
      seller: json['seller']?.toString() ?? '',
      buyer: json['buyer']?.toString() ?? '',
      commodity: json['commodity']?.toString() ?? '',
      bagCount: json['bag_count']?.toString() ?? '',
      packingWeightKg: json['packing_weight_kg']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '',
      rate: json['rate']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      brokerage: json['brokerage']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      deliveryStatus: json['delivery_status']?.toString() ?? '',
      transporter: json['transporter']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
    );
  }
}

class ChartsModel {
  final GtvDealsChart gtvDeals;
  final PipelineChart pipelineByStage;
  final CommodityMixChart commodityMix;
  final TopBuyersChart topBuyers;
  final TransporterSlaChart transporterSla;
  final PaymentsReceivablesChart paymentsReceivables;
  final UserDistributionChart userDistribution;

  ChartsModel({
    required this.gtvDeals,
    required this.pipelineByStage,
    required this.commodityMix,
    required this.topBuyers,
    required this.transporterSla,
    required this.paymentsReceivables,
    required this.userDistribution,
  });

  factory ChartsModel.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return ChartsModel(
      gtvDeals: GtvDealsChart.fromJson(
        json['gtv_deals'] as Map<String, dynamic>?,
      ),
      pipelineByStage: PipelineChart.fromJson(
        json['pipeline_by_stage'] as Map<String, dynamic>?,
      ),
      commodityMix: CommodityMixChart.fromJson(
        json['commodity_mix'] as Map<String, dynamic>?,
      ),
      topBuyers: TopBuyersChart.fromJson(
        json['top_buyers'] as Map<String, dynamic>?,
      ),
      transporterSla: TransporterSlaChart.fromJson(
        json['transporter_sla'] as Map<String, dynamic>?,
      ),
      paymentsReceivables: PaymentsReceivablesChart.fromJson(
        json['payments_receivables'] as Map<String, dynamic>?,
      ),
      userDistribution: UserDistributionChart.fromJson(
        json['user_distribution'] as Map<String, dynamic>?,
      ),
    );
  }
}

class TransporterSlaChart {
  final List<String> labels;
  final List<double> otdPercentages;

  TransporterSlaChart({required this.labels, required this.otdPercentages});

  factory TransporterSlaChart.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return TransporterSlaChart(
      labels: (json['labels'] as List? ?? []).map((e) => e.toString()).toList(),
      otdPercentages: (json['otd_percentages'] as List? ?? [])
          .map((e) => _parseDouble(e))
          .toList(),
    );
  }
}

class PaymentsReceivablesChart {
  final List<String> labels;
  final List<double> received;
  final List<double> outstanding;

  PaymentsReceivablesChart({
    required this.labels,
    required this.received,
    required this.outstanding,
  });

  factory PaymentsReceivablesChart.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return PaymentsReceivablesChart(
      labels: (json['labels'] as List? ?? []).map((e) => e.toString()).toList(),
      received: (json['received'] as List? ?? [])
          .map((e) => _parseDouble(e))
          .toList(),
      outstanding: (json['outstanding'] as List? ?? [])
          .map((e) => _parseDouble(e))
          .toList(),
    );
  }
}

class CommodityMixChart {
  final List<String> labels;
  final List<int> volumes;

  CommodityMixChart({required this.labels, required this.volumes});

  factory CommodityMixChart.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return CommodityMixChart(
      labels: (json['labels'] as List? ?? []).map((e) => e.toString()).toList(),
      volumes: (json['volumes'] as List? ?? [])
          .map((e) => _parseInt(e))
          .toList(),
    );
  }
}

class TopBuyersChart {
  final List<String> labels;
  final List<double> gtvValues;

  TopBuyersChart({required this.labels, required this.gtvValues});

  factory TopBuyersChart.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return TopBuyersChart(
      labels: (json['labels'] as List? ?? []).map((e) => e.toString()).toList(),
      gtvValues: (json['gtv_values'] as List? ?? [])
          .map((e) => _parseDouble(e))
          .toList(),
    );
  }
}

class GtvDealsChart {
  final List<String> labels;
  final List<double> gtvValues;
  final List<int> dealsValues;

  GtvDealsChart({
    required this.labels,
    required this.gtvValues,
    required this.dealsValues,
  });

  factory GtvDealsChart.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return GtvDealsChart(
      labels: (json['labels'] as List? ?? []).map((e) => e.toString()).toList(),
      gtvValues: (json['gtv_values'] as List? ?? [])
          .map((e) => _parseDouble(e))
          .toList(),
      dealsValues: (json['deals_values'] as List? ?? [])
          .map((e) => _parseInt(e))
          .toList(),
    );
  }
}

class PipelineChart {
  final List<String> labels;
  final List<int> values;

  PipelineChart({required this.labels, required this.values});

  factory PipelineChart.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return PipelineChart(
      labels: (json['labels'] as List? ?? []).map((e) => e.toString()).toList(),
      values: (json['values'] as List? ?? []).map((e) => _parseInt(e)).toList(),
    );
  }
}

class UserDistributionChart {
  final List<String> labels;
  final List<int> counts;

  UserDistributionChart({required this.labels, required this.counts});

  factory UserDistributionChart.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return UserDistributionChart(
      labels: (json['labels'] as List? ?? []).map((e) => e.toString()).toList(),
      counts: (json['counts'] as List? ?? []).map((e) => _parseInt(e)).toList(),
    );
  }
}
