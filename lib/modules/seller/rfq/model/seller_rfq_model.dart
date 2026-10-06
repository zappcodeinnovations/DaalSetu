/// Buyer requirement (RFQ) as returned by /api/buyer-requirements/.
class SellerRfqModel {
  final int id;
  final String rfqId;
  final String title;
  final String? description;
  final String? buyerName;
  final String? categoryName;
  final String? brandName;
  final String? requiredQuantity;
  final String quantityUnit;
  final int? requiredBagCount;
  final String? packingWeightKg;
  final String? targetPrice;
  final String priceUnit;
  final String? deliveryTerms;
  final String? buyerRemark;
  final String status;
  final String? expiryDatetime;
  final String? createdAt;
  final List<String> targetBranches;
  final int quotationCount;
  final int? myQuotationId;
  final bool canQuote;
  final List<SellerQuotationModel> quotations;

  SellerRfqModel({
    required this.id,
    required this.rfqId,
    required this.title,
    this.description,
    this.buyerName,
    this.categoryName,
    this.brandName,
    this.requiredQuantity,
    required this.quantityUnit,
    this.requiredBagCount,
    this.packingWeightKg,
    this.targetPrice,
    required this.priceUnit,
    this.deliveryTerms,
    this.buyerRemark,
    required this.status,
    this.expiryDatetime,
    this.createdAt,
    required this.targetBranches,
    required this.quotationCount,
    this.myQuotationId,
    required this.canQuote,
    required this.quotations,
  });

  bool get isQuoted => myQuotationId != null;

  factory SellerRfqModel.fromJson(Map<String, dynamic> json) {
    String? nameOf(dynamic value) => value is Map ? value['name']?.toString() : value?.toString();
    final permissions = json['permissions'] is Map ? json['permissions'] as Map : const {};
    return SellerRfqModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      rfqId: json['rfq_id']?.toString() ?? '${json['id']}',
      title: json['title']?.toString() ?? 'Buyer Requirement',
      description: json['description']?.toString(),
      buyerName: json['buyer_name']?.toString(),
      categoryName: nameOf(json['category']),
      brandName: nameOf(json['brand']),
      requiredQuantity: json['required_quantity']?.toString(),
      quantityUnit: (json['quantity_unit'] ?? 'qtl').toString(),
      requiredBagCount: json['required_bag_count'] is int ? json['required_bag_count'] : int.tryParse('${json['required_bag_count']}'),
      packingWeightKg: json['packing_weight_kg']?.toString(),
      targetPrice: json['target_price']?.toString(),
      priceUnit: (json['price_unit'] ?? json['quantity_unit'] ?? 'qtl').toString(),
      deliveryTerms: json['delivery_terms']?.toString(),
      buyerRemark: json['buyer_remark']?.toString(),
      status: (json['status'] ?? 'open').toString(),
      expiryDatetime: json['expiry_datetime']?.toString(),
      createdAt: json['created_at']?.toString(),
      targetBranches: (json['target_branches'] as List? ?? []).map((b) => b is Map ? '${b['name']}' : '$b').toList(),
      quotationCount: json['quotation_count'] is int ? json['quotation_count'] : 0,
      myQuotationId: json['my_quotation_id'] is int ? json['my_quotation_id'] : null,
      canQuote: permissions['can_quote'] == true,
      quotations: (json['quotations'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SellerQuotationModel.fromJson)
          .toList(),
    );
  }
}

class SellerQuotationModel {
  final int id;
  final String? sellerName;
  final String? offeredPrice;
  final String? priceUnit;
  final String? offeredQuantity;
  final String? quantityUnit;
  final int? offeredBagCount;
  final String? deliveryTerms;
  final String? sellerRemark;
  final String status;
  final bool isReadOnly;
  final String? createdAt;
  final String? latestPrice;
  final String? latestQuantity;
  final String? latestOfferBy;
  final List<NegotiationMessageModel> messages;
  // Present only on the negotiation-thread response.
  final bool canAccept;
  final bool canReject;
  final bool canReply;
  final String? buyerDisplayId;
  final String? sellerDisplayId;

  SellerQuotationModel({
    required this.id,
    this.sellerName,
    this.offeredPrice,
    this.priceUnit,
    this.offeredQuantity,
    this.quantityUnit,
    this.offeredBagCount,
    this.deliveryTerms,
    this.sellerRemark,
    required this.status,
    required this.isReadOnly,
    this.createdAt,
    this.latestPrice,
    this.latestQuantity,
    this.latestOfferBy,
    required this.messages,
    required this.canAccept,
    required this.canReject,
    required this.canReply,
    this.buyerDisplayId,
    this.sellerDisplayId,
  });

  factory SellerQuotationModel.fromJson(Map<String, dynamic> json) {
    final latest = json['latest_terms'] is Map ? json['latest_terms'] as Map : const {};
    return SellerQuotationModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      sellerName: json['seller_name']?.toString(),
      offeredPrice: json['offered_price']?.toString(),
      priceUnit: json['price_unit']?.toString(),
      offeredQuantity: json['offered_quantity']?.toString(),
      quantityUnit: json['quantity_unit']?.toString(),
      offeredBagCount: json['offered_bag_count'] is int ? json['offered_bag_count'] : null,
      deliveryTerms: json['delivery_terms']?.toString(),
      sellerRemark: json['seller_remark']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      isReadOnly: json['is_read_only'] == true,
      createdAt: json['created_at']?.toString(),
      latestPrice: latest['latest_price']?.toString(),
      latestQuantity: latest['latest_quantity']?.toString(),
      latestOfferBy: (json['latest_offer_by'] ?? latest['latest_by'])?.toString(),
      messages: (json['messages'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(NegotiationMessageModel.fromJson)
          .toList(),
      canAccept: json['can_accept'] == true,
      canReject: json['can_reject'] == true,
      canReply: json['can_reply'] == true,
      buyerDisplayId: json['buyer_display_id']?.toString(),
      sellerDisplayId: json['seller_display_id']?.toString(),
    );
  }
}

class NegotiationMessageModel {
  final String senderRole;
  final String? senderName;
  final String? counterPrice;
  final String? priceUnit;
  final String? counterQuantity;
  final String? quantityUnit;
  final String? message;
  final String? createdAt;

  NegotiationMessageModel({
    required this.senderRole,
    this.senderName,
    this.counterPrice,
    this.priceUnit,
    this.counterQuantity,
    this.quantityUnit,
    this.message,
    this.createdAt,
  });

  factory NegotiationMessageModel.fromJson(Map<String, dynamic> json) => NegotiationMessageModel(
        senderRole: (json['sender_role'] ?? '').toString(),
        senderName: json['sender_name']?.toString(),
        counterPrice: json['counter_price']?.toString(),
        priceUnit: json['price_unit']?.toString(),
        counterQuantity: json['counter_quantity']?.toString(),
        quantityUnit: json['quantity_unit']?.toString(),
        message: json['message']?.toString(),
        createdAt: json['created_at']?.toString(),
      );
}
