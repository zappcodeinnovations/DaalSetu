class SellerContractModel {
  final int? id;
  final String? contractId;
  final String? buyerCompany;
  final String? sellerCompany;
  final String? categoryName;
  final String? brandName;
  final String? dealAmount;
  final String? dealQuantity;
  final String? status;
  final String? createdAt;

  SellerContractModel({
    this.id,
    this.contractId,
    this.buyerCompany,
    this.sellerCompany,
    this.categoryName,
    this.brandName,
    this.dealAmount,
    this.dealQuantity,
    this.status,
    this.createdAt,
  });

  String? get contractNumber => contractId ?? id?.toString();
  String? get commodity => categoryName;
  String? get quantity => dealQuantity;
  String? get unit => 'Qtl';
  String? get totalAmount => dealAmount;

  factory SellerContractModel.fromJson(Map<String, dynamic> json) {
    return SellerContractModel(
      id: json['id'] as int?,
      contractId: json['contract_id']?.toString() ?? json['id']?.toString(),
      buyerCompany: json['buyer_company'] ?? json['buyer']?['company_name'] ?? json['buyer_name'],
      sellerCompany: json['seller_company'] ?? json['seller']?['company_name'] ?? json['seller_name'],
      categoryName: json['category_name'] ?? json['category']?['name'] ?? json['commodity'],
      brandName: json['brand_name'] ?? json['brand']?['name'],
      dealAmount: json['deal_amount']?.toString() ?? json['amount']?.toString() ?? json['total_price']?.toString(),
      dealQuantity: json['deal_quantity']?.toString() ?? json['quantity']?.toString(),
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] ?? json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'buyer_company': buyerCompany,
      'seller_company': sellerCompany,
      'category_name': categoryName,
      'brand_name': brandName,
      'deal_amount': dealAmount,
      'deal_quantity': dealQuantity,
      'status': status,
      'created_at': createdAt,
    };
  }
}
