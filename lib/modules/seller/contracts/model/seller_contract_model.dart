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
    // Contract API sends buyer/seller as ids (not objects), so only read nested keys from maps.
    String? nested(String key, String field) {
      final value = json[key];
      return value is Map ? value[field]?.toString() : null;
    }

    String? text(String key) => json[key]?.toString();

    return SellerContractModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      contractId: text('contract_id') ?? text('id'),
      buyerCompany: text('buyer_company') ?? nested('buyer', 'company_name') ?? text('display_buyer_id') ?? text('buyer_name'),
      sellerCompany: text('seller_company') ?? nested('seller', 'company_name') ?? text('display_seller_id') ?? text('seller_name'),
      categoryName: text('category_name') ?? text('product_category_name') ?? nested('category', 'name') ?? text('product_title') ?? text('commodity'),
      brandName: text('brand_name') ?? nested('brand', 'name'),
      dealAmount: text('deal_amount') ?? text('amount') ?? text('total_price'),
      dealQuantity: text('deal_quantity') ?? text('quantity'),
      status: text('status') ?? 'active',
      createdAt: text('confirmed_at') ?? text('created_at') ?? text('date'),
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
