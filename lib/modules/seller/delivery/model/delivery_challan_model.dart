class SellerChallanModel {
  final int id;
  final String challanNumber;
  final String truckNumber;
  final String driverName;
  final String driverPhone;
  final String status;
  final String buyerName;
  final String buyerCompany;
  final String commodity;
  final double quantity;
  final String unit;
  final double totalAmount;
  final DateTime? dispatchedAt;
  final DateTime? receivedAt;

  SellerChallanModel({
    required this.id,
    required this.challanNumber,
    required this.truckNumber,
    required this.driverName,
    required this.driverPhone,
    required this.status,
    required this.buyerName,
    required this.buyerCompany,
    required this.commodity,
    required this.quantity,
    required this.unit,
    required this.totalAmount,
    this.dispatchedAt,
    this.receivedAt,
  });

  factory SellerChallanModel.fromJson(Map<String, dynamic> json) {
    // Handling nested items
    final items = json['items'] as List?;
    final firstItem = (items != null && items.isNotEmpty) ? items[0] : {};

    // Handling nested company
    final company = json['company'] as Map<String, dynamic>? ?? {};

    return SellerChallanModel(
      id: json['id'],
      challanNumber: json['challan_number'] ?? json['id'].toString(),
      truckNumber: json['truck_number'] ?? "N/A",
      driverName: json['driver_name'] ?? json['dispatched_by_name'] ?? "N/A",
      driverPhone: json['driver_phone'] ?? "N/A",
      status: json['status'] ?? "pending",
      buyerName: json['buyer_name_display'] ?? "N/A",
      buyerCompany: company['legal_name'] ?? "N/A",
      commodity: firstItem['product_name'] ?? "N/A",
      quantity: double.tryParse(firstItem['quantity']?.toString() ?? "0") ?? 0.0,
      unit: firstItem['unit'] ?? "qtl",
      totalAmount: double.tryParse(firstItem['amount']?.toString() ?? "0") ?? 0.0,
      dispatchedAt: json['dispatched_at'] != null ? DateTime.parse(json['dispatched_at']) : null,
      receivedAt: json['received_at'] != null ? DateTime.parse(json['received_at']) : null,
    );
  }
}
