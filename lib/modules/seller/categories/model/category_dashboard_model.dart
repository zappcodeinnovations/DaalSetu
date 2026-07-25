class CategoryDashboardModel {
  final int total;
  final int root;
  final int active;
  final int pending;
  final int sub;

  CategoryDashboardModel({
    required this.total,
    required this.root,
    required this.active,
    required this.pending,
    required this.sub,
  });

  factory CategoryDashboardModel.fromJson(Map<String, dynamic> json) {
    return CategoryDashboardModel(
      total: json['total'] ?? 0,
      root: json['root'] ?? 0,
      active: json['active'] ?? 0,
      pending: json['pending'] ?? 0,
      sub: json['sub'] ?? 0,
    );
  }
}
