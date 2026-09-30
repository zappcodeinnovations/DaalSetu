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

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      kpis: KpiModel.fromJson(json['kpis']),
      charts: ChartsModel.fromJson(json['charts']),
      branchPerformance: (json['branch_performance'] as List)
          .map((e) => BranchPerformanceModel.fromJson(e))
          .toList(),
      recentActivities: (json['recent_activities'] as List)
          .map((e) => ActivityModel.fromJson(e))
          .toList(),
      recentContracts: (json['recent_contracts'] as List)
          .map((e) => ContractModel.fromJson(e))
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
  final int otdPercent;
  final double avgTransitDays;
  final int paymentsOverdue;
  final double atRiskAmount;
  final int activeTransporters;
  final int capacityUtilized;
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

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return KpiModel(
      activeContracts: json['active_contracts'] ?? 0,
      gtvMtd: parseDouble(json['gtv_mtd']),
      brokerageEarnedMtd: parseDouble(json['brokerage_earned_mtd']),
      brokerageRate: parseDouble(json['brokerage_rate']),
      pendingDispatches: json['pending_dispatches'] ?? 0,
      activeSellers: json['active_sellers'] ?? 0,
      listedSkus: json['listed_skus'] ?? 0,
      activeBuyers: json['active_buyers'] ?? 0,
      finalDealsMtd: json['final_deals_mtd'] ?? 0,
      openComplaints: json['open_complaints'] ?? 0,
      otdPercent: json['otd_percent'] ?? 0,
      avgTransitDays: parseDouble(json['avg_transit_days']),
      paymentsOverdue: json['payments_overdue'] ?? 0,
      atRiskAmount: parseDouble(json['at_risk_amount']),
      activeTransporters: json['active_transporters'] ?? 0,
      capacityUtilized: json['capacity_utilized'] ?? 0,
      branches: json['branches'] ?? 0,
      adminsActive: json['admins_active'] ?? 0,
      dealsInNegotiation: json['deals_in_negotiation'] ?? 0,
      avgTtcDays: parseDouble(json['avg_ttc_days']),
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
  final int otdPercent;
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

  factory BranchPerformanceModel.fromJson(Map<String, dynamic> json) {
    return BranchPerformanceModel(
      name: json['name'] ?? '',
      admin: json['admin'] ?? '',
      sellers: json['sellers'] ?? 0,
      buyers: json['buyers'] ?? 0,
      contracts: json['contracts'] ?? 0,
      gtvMtd: (json['gtv_mtd'] ?? 0).toDouble(),
      otdPercent: json['otd_percent'] ?? 0,
      status: json['status'] ?? '',
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

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      time: json['time'] ?? '',
    );
  }
}

class ContractModel {
  final String id;
  final String seller;
  final String buyer;
  final String commodity;
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
    required this.quantity,
    required this.rate,
    required this.value,
    required this.brokerage,
    required this.paymentStatus,
    required this.deliveryStatus,
    required this.transporter,
    required this.branch,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] ?? '',
      seller: json['seller'] ?? '',
      buyer: json['buyer'] ?? '',
      commodity: json['commodity'] ?? '',
      quantity: json['quantity'] ?? '',
      rate: json['rate'] ?? '',
      value: json['value'] ?? '',
      brokerage: json['brokerage'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      deliveryStatus: json['delivery_status'] ?? '',
      transporter: json['transporter'] ?? '',
      branch: json['branch'] ?? '',
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
      gtvDeals: GtvDealsChart.fromJson(json['gtv_deals'] ?? {}),
      pipelineByStage: PipelineChart.fromJson(json['pipeline_by_stage'] ?? {}),
      commodityMix: CommodityMixChart.fromJson(json['commodity_mix'] ?? {}),
      topBuyers: TopBuyersChart.fromJson(json['top_buyers'] ?? {}),
      transporterSla: TransporterSlaChart.fromJson(
        json['transporter_sla'] ?? {},
      ),
      paymentsReceivables: PaymentsReceivablesChart.fromJson(
        json['payments_receivables'] ?? {},
      ),
      userDistribution: UserDistributionChart.fromJson(
        json['user_distribution'] ?? {},
      ),
    );
  }
}

class TransporterSlaChart {
  final List<String> labels;
  final List<int> otdPercentages;

  TransporterSlaChart({required this.labels, required this.otdPercentages});

  factory TransporterSlaChart.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return TransporterSlaChart(
      labels: List<String>.from(json['labels'] ?? []),
      otdPercentages: List<int>.from(json['otd_percentages'] ?? []),
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
      labels: List<String>.from(json['labels'] ?? []),
      received: (json['received'] ?? [])
          .map((e) => (e is num) ? e.toDouble() : 0.0)
          .toList()
          .cast<double>(),
      outstanding: (json['outstanding'] ?? [])
          .map((e) => (e is num) ? e.toDouble() : 0.0)
          .toList()
          .cast<double>(),
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
      labels: List<String>.from(json['labels'] ?? []),
      volumes: List<int>.from(json['volumes'] ?? []),
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
      labels: List<String>.from(json['labels'] ?? []),
      gtvValues: (json['gtv_values'] ?? [])
          .map((e) => (e is num) ? e.toDouble() : 0.0)
          .toList()
          .cast<double>(),
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

  factory GtvDealsChart.fromJson(Map<String, dynamic> json) {
    return GtvDealsChart(
      labels: List<String>.from(json['labels'] ?? []),
      gtvValues: (json['gtv_values'] ?? [])
          .map((e) => (e is num) ? e.toDouble() : 0.0)
          .toList()
          .cast<double>(),
      dealsValues: List<int>.from(json['deals_values'] ?? []),
    );
  }
}

class PipelineChart {
  final List<String> labels;
  final List<int> values;

  PipelineChart({required this.labels, required this.values});

  factory PipelineChart.fromJson(Map<String, dynamic> json) {
    return PipelineChart(
      labels: List<String>.from(json['labels'] ?? []),
      values: List<int>.from(json['values'] ?? []),
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
      labels: List<String>.from(json['labels'] ?? []),
      counts: List<int>.from(json['counts'] ?? []),
    );
  }
}
