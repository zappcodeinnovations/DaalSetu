class BuyerChallanModel {
  final int id;
  final String challanNumber;
  final String truckNumber;
  final String dispatchedByName;
  final String status;
  final String sellerName;
  final String transporterName;
  final List<ChallanItem> items;
  final DateTime? dispatchedAt;
  final DateTime? receivedAt;

  BuyerChallanModel({
    required this.id,
    required this.challanNumber,
    required this.truckNumber,
    required this.dispatchedByName,
    required this.status,
    required this.sellerName,
    required this.transporterName,
    required this.items,
    this.dispatchedAt,
    this.receivedAt,
  });

  factory BuyerChallanModel.fromJson(Map<String, dynamic> json) {
    return BuyerChallanModel(
      id: json['id'],
      challanNumber: json['challan_number'] ?? json['id'].toString(),
      truckNumber: json['truck_number'] ?? "N/A",
      dispatchedByName: json['dispatched_by_name'] ?? "N/A",
      status: json['status'] ?? "pending",
      sellerName: json['seller_name_display'] ?? "N/A",
      transporterName: json['transporter_name_display'] ?? "N/A",
      items: (json['items'] as List?)?.map((e) => ChallanItem.fromJson(e)).toList() ?? [],
      dispatchedAt: json['dispatched_at'] != null ? DateTime.parse(json['dispatched_at']) : null,
      receivedAt: json['received_at'] != null ? DateTime.parse(json['received_at']) : null,
    );
  }
}

class ChallanItem {
  final String productName;
  final String quantity;
  final String unit;
  final String amount;

  ChallanItem({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.amount,
  });

  factory ChallanItem.fromJson(Map<String, dynamic> json) {
    return ChallanItem(
      productName: json['product_name'] ?? "Unknown",
      quantity: json['quantity']?.toString() ?? "0",
      unit: json['unit'] ?? "",
      amount: json['amount']?.toString() ?? "0",
    );
  }
}
