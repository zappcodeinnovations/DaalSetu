class SellerContractModel {
  final int id;
  final String contractNumber;
  final String status;
  final String buyerName;
  final String buyerCompany;
  final String commodity;
  final double quantity;
  final String unit;
  final double totalAmount;
  final DateTime createdAt;
  final String? pdfUrl;

  SellerContractModel({
    required this.id,
    required this.contractNumber,
    required this.status,
    required this.buyerName,
    required this.buyerCompany,
    required this.commodity,
    required this.quantity,
    required this.unit,
    required this.totalAmount,
    required this.createdAt,
    this.pdfUrl,
  });

  factory SellerContractModel.fromJson(Map<String, dynamic> json) {
    return SellerContractModel(
      id: json['id'],
      contractNumber: json['contract_id'] ?? json['id'].toString(),
      status: json['status'] ?? "pending",
      buyerName: json['buyer_name'] ?? "Unknown",
      buyerCompany: json['display_buyer_id'] ?? json['buyer_company'] ?? "N/A",
      commodity: json['product_title'] ?? json['product_name'] ?? "N/A",
      quantity: double.tryParse(json['deal_quantity']?.toString() ?? "0") ?? 0.0,
      unit: json['quantity_unit'] ?? json['unit'] ?? "qtl",
      totalAmount: double.tryParse(json['deal_amount']?.toString() ?? "0") ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      pdfUrl: json['contract_pdf'],
    );
  }
}
