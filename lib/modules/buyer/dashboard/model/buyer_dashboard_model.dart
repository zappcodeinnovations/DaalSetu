class BuyerDashboardModel {
  final Map<String, dynamic> kpis;
  final Map<String, dynamic> charts;
  final List<dynamic> recentRfqs;
  final List<dynamic> recentOrders;
  final List<dynamic> transportTracking;

  BuyerDashboardModel({
    required this.kpis,
    required this.charts,
    required this.recentRfqs,
    required this.recentOrders,
    required this.transportTracking,
  });

  factory BuyerDashboardModel.fromJson(Map<String, dynamic> json) {
    return BuyerDashboardModel(
      kpis: json['kpis'] ?? {},
      charts: json['charts'] ?? {},
      recentRfqs: json['recent_rfqs'] ?? [],
      recentOrders: json['recent_orders'] ?? [],
      transportTracking: json['transport_tracking'] ?? [],
    );
  }
}
