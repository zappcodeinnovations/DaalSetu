class SellerRfqModel {
  final int? id;
  final String? buyerName;
  final String? buyerCompany;
  final String? categoryName;
  final String? brandName;
  final String? targetPrice;
  final String? requiredQuantity;
  final String? unit;
  final String? deliveryLocation;
  final String? status;
  final String? remarks;
  final String? createdAt;
  final bool? isQuoted;

  SellerRfqModel({
    this.id,
    this.buyerName,
    this.buyerCompany,
    this.categoryName,
    this.brandName,
    this.targetPrice,
    this.requiredQuantity,
    this.unit,
    this.deliveryLocation,
    this.status,
    this.remarks,
    this.createdAt,
    this.isQuoted,
  });

  factory SellerRfqModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    final categoryStr = cat is String ? cat : (json['category_name'] ?? json['category']?['name'] ?? json['title']);
    final br = json['brand'];
    final brandStr = br is String ? br : (json['brand_name'] ?? json['brand']?['name']);

    return SellerRfqModel(
      id: json['id'] as int? ?? (json['rfq_id'] is int ? json['rfq_id'] as int : int.tryParse(json['rfq_id']?.toString() ?? '')),
      buyerName: json['buyer_name'] ?? json['buyer']?['name'] ?? json['buyer_company'],
      buyerCompany: json['buyer_company'] ?? json['buyer']?['company_name'],
      categoryName: categoryStr,
      brandName: brandStr,
      targetPrice: json['target_price']?.toString() ?? json['expected_price']?.toString() ?? json['amount']?.toString(),
      requiredQuantity: json['required_quantity']?.toString() ?? json['quantity']?.toString(),
      unit: json['quantity_unit'] ?? json['price_unit'] ?? json['unit'] ?? 'Qtl',
      deliveryLocation: json['delivery_terms'] ?? json['delivery_location'] ?? json['destination'] ?? json['location'],
      status: json['status'] ?? 'active',
      remarks: json['buyer_remark'] ?? json['remarks'] ?? json['description'],
      createdAt: json['created_at'] ?? json['date'],
      isQuoted: (json['quotations'] is List && (json['quotations'] as List).isNotEmpty) || (json['is_quoted'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_name': buyerName,
      'buyer_company': buyerCompany,
      'category_name': categoryName,
      'brand_name': brandName,
      'target_price': targetPrice,
      'required_quantity': requiredQuantity,
      'unit': unit,
      'delivery_location': deliveryLocation,
      'status': status,
      'remarks': remarks,
      'created_at': createdAt,
      'is_quoted': isQuoted,
    };
  }
}
