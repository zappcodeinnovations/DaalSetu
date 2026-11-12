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
  /// Per-offer id (INT-…): one buyer can send a new offer after an earlier one moves on.
  final String? transactionId;
  final bool canSellerAction;
  final bool canOpenNegotiation;
  /// Another accepted offer already holds the stock this one needs: no accept or
  /// negotiation, only reject (the final deal confirmation rejects it anyway).
  final bool stockBlocked;
  final String? blockedReason;
  final bool canSellerReject;

  String get displayBuyerInfo {
    final name = (buyerName ?? '').trim();
    final company = (buyerCompany ?? '').trim();
    if (name.isNotEmpty && company.isNotEmpty && name.toLowerCase() != company.toLowerCase()) {
      return '$name ($company)';
    }
    if (name.isNotEmpty) return name;
    if (company.isNotEmpty) return company;
    return '-';
  }

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
    this.transactionId,
    this.canSellerAction = false,
    this.canOpenNegotiation = false,
    this.stockBlocked = false,
    this.blockedReason,
    this.canSellerReject = false,
  });

  factory OfferInterestModel.fromJson(Map<String, dynamic> json) {
    bool flag(String key, {bool fallback = false}) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      final normalized = value?.toString().trim().toLowerCase();
      if (const {'true', '1', 'yes'}.contains(normalized)) return true;
      if (const {'false', '0', 'no'}.contains(normalized)) return false;
      return fallback;
    }

    String? bName;
    String? bCompany = (json['buyer_company'] ??
            json['buyer_company_name'] ??
            json['company_name'])
        ?.toString();

    final buyerObj = json['buyer'];
    if (buyerObj is Map) {
      final firstLast =
          '${buyerObj['first_name'] ?? ''} ${buyerObj['last_name'] ?? ''}'
              .trim();
      bName = (buyerObj['full_name'] ??
              buyerObj['name'] ??
              (firstLast.isNotEmpty ? firstLast : null) ??
              buyerObj['username'])
          ?.toString();
      bCompany ??= (buyerObj['company_name'] ??
              buyerObj['legal_name'] ??
              buyerObj['company'])
          ?.toString();
    }

    bName ??= json['buyer_full_name']?.toString() ??
        json['buyer_name']?.toString() ??
        json['buyer_unique_id']?.toString() ??
        (buyerObj is String ? buyerObj : null);

    return OfferInterestModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      productId: json['product'] is int
          ? json['product']
          : int.tryParse(json['product']?.toString() ?? ''),
      buyerName: bName,
      buyerCompany: bCompany,
      buyerOfferedAmount:
          (json['buyer_offered_amount'] ?? json['offered_amount'])?.toString(),
      buyerRequiredQuantity:
          (json['buyer_required_quantity'] ?? json['required_quantity'])
              ?.toString(),
      buyerRemark: (json['buyer_remark'] ?? json['remark'])?.toString(),
      sellerRemark: json['seller_remark']?.toString(),
      counterPrice: json['counter_price']?.toString(),
      counterQuantity: json['counter_quantity']?.toString(),
      counterBagCount: json['counter_bag_count'] is int
          ? json['counter_bag_count']
          : int.tryParse(json['counter_bag_count']?.toString() ?? ''),
      counterPackingWeightKg: json['counter_packing_weight_kg']?.toString(),
      status: json['status']?.toString() ?? json['deal_status']?.toString(),
      createdAt: json['created_at']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      canSellerAction: flag(
        'can_seller_action',
        fallback: json['status']?.toString().toLowerCase() == 'interested',
      ),
      // An expired deal is closed the same way: reason + Reject only.
      stockBlocked: flag('stock_blocked') || flag('deal_expired'),
      blockedReason: json['blocked_reason']?.toString(),
      canSellerReject: flag(
        'can_seller_reject',
        fallback: flag(
          'can_seller_action',
          fallback: json['status']?.toString().toLowerCase() == 'interested',
        ),
      ),
      canOpenNegotiation: flag(
        'can_open_negotiation',
        fallback: !const {
          'deal_confirmed',
          'rejected',
          'cancelled',
        }.contains(json['status']?.toString().toLowerCase()),
      ),
    );
  }
}
