class TransporterDashboardModel {
  final EarningsShipmentsTrend earningsShipmentsTrend;
  final DeliveryStatus deliveryStatus;
  final List<TransportType> transportTypes;
  final List<TopRoute> topRoutes;
  final SlaOnTime slaOnTime;

  TransporterDashboardModel({
    required this.earningsShipmentsTrend,
    required this.deliveryStatus,
    required this.transportTypes,
    required this.topRoutes,
    required this.slaOnTime,
  });

  factory TransporterDashboardModel.fromJson(Map<String, dynamic> json) {
    return TransporterDashboardModel(
      earningsShipmentsTrend: EarningsShipmentsTrend.fromJson(json['earnings_shipments_trend'] ?? {}),
      deliveryStatus: DeliveryStatus.fromJson(json['delivery_status'] ?? {}),
      transportTypes: (json['transport_types'] as List<dynamic>?)
              ?.map((e) => TransportType.fromJson(e))
              .toList() ??
          [],
      topRoutes: (json['top_routes'] as List<dynamic>?)
              ?.map((e) => TopRoute.fromJson(e))
              .toList() ??
          [],
      slaOnTime: SlaOnTime.fromJson(json['sla_on_time'] ?? {}),
    );
  }
}

class EarningsShipmentsTrend {
  final List<String> labels;
  final List<double> earnings;
  final List<int> shipments;

  EarningsShipmentsTrend({
    required this.labels,
    required this.earnings,
    required this.shipments,
  });

  factory EarningsShipmentsTrend.fromJson(Map<String, dynamic> json) {
    return EarningsShipmentsTrend(
      labels: List<String>.from(json['labels'] ?? []),
      earnings: (json['earnings'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      shipments: List<int>.from(json['shipments'] ?? []),
    );
  }
}

class DeliveryStatus {
  final int delivered;
  final int inTransit;
  final int pickupDue;
  final int cancelled;

  DeliveryStatus({
    required this.delivered,
    required this.inTransit,
    required this.pickupDue,
    required this.cancelled,
  });

  factory DeliveryStatus.fromJson(Map<String, dynamic> json) {
    return DeliveryStatus(
      delivered: json['delivered'] ?? 0,
      inTransit: json['in_transit'] ?? 0,
      pickupDue: json['pickup_due'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
    );
  }
}

class TransportType {
  final String type;
  final int percentage;

  TransportType({
    required this.type,
    required this.percentage,
  });

  factory TransportType.fromJson(Map<String, dynamic> json) {
    return TransportType(
      type: json['type'] ?? '',
      percentage: json['percentage'] ?? 0,
    );
  }
}

class TopRoute {
  final String routeName;
  final int trips;

  TopRoute({
    required this.routeName,
    required this.trips,
  });

  factory TopRoute.fromJson(Map<String, dynamic> json) {
    return TopRoute(
      routeName: json['route_name'] ?? '',
      trips: json['trips'] ?? 0,
    );
  }
}

class SlaOnTime {
  final List<String> labels;
  final List<int> percentages;

  SlaOnTime({
    required this.labels,
    required this.percentages,
  });

  factory SlaOnTime.fromJson(Map<String, dynamic> json) {
    return SlaOnTime(
      labels: List<String>.from(json['labels'] ?? []),
      percentages: List<int>.from(json['percentages'] ?? []),
    );
  }
}
