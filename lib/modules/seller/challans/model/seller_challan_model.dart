class SellerChallanModel {
  final int? id;
  final String? challanNumber;
  final String? challanDate;
  final String? sellerName;
  final String? buyerName;
  final String? truckNumber;
  final String? driverName;
  final String? driverMobile;
  final String? totalAmount;
  final String? status;
  final String? dispatchedAt;

  SellerChallanModel({
    this.id,
    this.challanNumber,
    this.challanDate,
    this.sellerName,
    this.buyerName,
    this.truckNumber,
    this.driverName,
    this.driverMobile,
    this.totalAmount,
    this.status,
    this.dispatchedAt,
  });

  factory SellerChallanModel.fromJson(Map<String, dynamic> json) {
    return SellerChallanModel(
      id: json['id'] as int?,
      challanNumber: json['challan_number'] ?? json['challan_no'] ?? json['id']?.toString(),
      challanDate: json['challan_date'] ?? json['date'] ?? json['created_at'],
      sellerName: json['seller_name'] ?? (json['seller'] is Map ? json['seller']['name'] : null),
      buyerName: json['buyer_name'] ?? (json['buyer'] is Map ? json['buyer']['name'] : null),
      truckNumber: json['truck_number'] ?? json['vehicle_number'],
      driverName: json['driver_name'],
      driverMobile: json['driver_mobile']?.toString(),
      totalAmount: json['total_amount']?.toString() ?? json['amount']?.toString(),
      status: json['status'] ?? 'pending',
      dispatchedAt: json['dispatched_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challan_number': challanNumber,
      'challan_date': challanDate,
      'seller_name': sellerName,
      'buyer_name': buyerName,
      'truck_number': truckNumber,
      'driver_name': driverName,
      'driver_mobile': driverMobile,
      'total_amount': totalAmount,
      'status': status,
      'dispatched_at': dispatchedAt,
    };
  }
}
