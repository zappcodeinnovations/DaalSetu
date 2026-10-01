class OfferInterestModel {
  final int? id;
  final int? productId;
  final String? buyerName;
  final String? buyerCompany;
  final String? buyerOfferedAmount;
  final String? buyerRequiredQuantity;
  final String? buyerRemark;
  final String? sellerRemark;
  final String? counterPrice;
  final String? counterQuantity;
  final int? counterBagCount;
  final String? counterPackingWeightKg;
  final String? status;
  final String? createdAt;

  OfferInterestModel({
    this.id,
    this.productId,
    this.buyerName,
    this.buyerCompany,
    this.buyerOfferedAmount,
    this.buyerRequiredQuantity,
    this.buyerRemark,
    this.sellerRemark,
    this.counterPrice,
    this.counterQuantity,
    this.counterBagCount,
    this.counterPackingWeightKg,
    this.status,
    this.createdAt,
  });

  factory OfferInterestModel.fromJson(Map<String, dynamic> json) {
    return OfferInterestModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      productId: json['product'] is int ? json['product'] : int.tryParse(json['product']?.toString() ?? ''),
      buyerName: json['buyer_name']?.toString() ?? json['buyer']?.toString(),
      buyerCompany: json['buyer_company']?.toString(),
      buyerOfferedAmount: json['buyer_offered_amount']?.toString(),
      buyerRequiredQuantity: json['buyer_required_quantity']?.toString(),
      buyerRemark: json['buyer_remark']?.toString(),
      sellerRemark: json['seller_remark']?.toString(),
      counterPrice: json['counter_price']?.toString(),
      counterQuantity: json['counter_quantity']?.toString(),
      counterBagCount: json['counter_bag_count'] is int
          ? json['counter_bag_count']
          : int.tryParse(json['counter_bag_count']?.toString() ?? ''),
      counterPackingWeightKg: json['counter_packing_weight_kg']?.toString(),
      status: json['status']?.toString() ?? json['deal_status']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
