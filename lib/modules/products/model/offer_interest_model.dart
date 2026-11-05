class OfferInterestModel {
  final int id;
  final String? buyerName;
  final String? buyerMobile;
  final String? offerPrice;
  final String? requiredQuantity;
  final String? deliveryDate;
  final String? loadingTo;
  final String? condition;
  final String? status;
  final String? createdAt;
  final bool canSellerAction;
  final bool canSellerReject;
  final bool canOpenNegotiation;
  final bool canAdminFinalAction;
  final bool isReadOnly;

  // Convenience getters used by offer_interests_dialog
  int get interestId => id;
  String get transactionId => _transactionId ?? '';
  String get buyerOfferedAmount => offerPrice ?? '0';
  String get statusLabel => status ?? 'pending';

  final String? _transactionId;

  OfferInterestModel({
    required this.id,
    this.buyerName,
    this.buyerMobile,
    this.offerPrice,
    this.requiredQuantity,
    this.deliveryDate,
    this.loadingTo,
    this.condition,
    this.status,
    this.createdAt,
    this.canSellerAction = false,
    this.canSellerReject = false,
    this.canOpenNegotiation = false,
    this.canAdminFinalAction = false,
    this.isReadOnly = false,
    String? transactionId,
  }) : _transactionId = transactionId;

  static bool isFinalStatus(String? status) => const {
    'deal_confirmed',
    'confirmed',
    'approved',
    'completed',
    'rejected',
    'cancelled',
  }.contains(status?.trim().toLowerCase());

  bool get isFinal => isFinalStatus(status);

  bool canAcceptForRole({required bool isAdmin}) =>
      !isFinal && (canSellerAction || (isAdmin && canAdminFinalAction));

  bool canRejectForRole({required bool isAdmin}) =>
      !isFinal &&
      (canSellerReject || canSellerAction || (isAdmin && canAdminFinalAction));

  OfferInterestModel withStatus(String value) => OfferInterestModel(
    id: id,
    buyerName: buyerName,
    buyerMobile: buyerMobile,
    offerPrice: offerPrice,
    requiredQuantity: requiredQuantity,
    deliveryDate: deliveryDate,
    loadingTo: loadingTo,
    condition: condition,
    status: value,
    createdAt: createdAt,
    transactionId: transactionId,
    isReadOnly: true,
  );

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

    // API returns interest_id (not id) on the interests endpoint
    final rawId = json['interest_id'] ?? json['id'] ?? 0;

    // Buyer info — may be flat keys or nested 'buyer' object
    final buyer = json['buyer'];
    String? bName = json['buyer_name'];
    String? bMobile = json['buyer_mobile'];

    if (buyer != null && buyer is Map) {
      bName ??= buyer['username'] ?? buyer['first_name'] ?? buyer['name'];
      bMobile ??= buyer['mobile'];
    }

    // Amount field differs per endpoint: buyer_offered_amount vs offer_price
    final amount =
        json['buyer_offered_amount']?.toString() ??
        json['offered_amount']?.toString() ??
        json['offer_price']?.toString();

    // Quantity field
    final qty =
        json['buyer_required_quantity']?.toString() ??
        json['required_quantity']?.toString();

    return OfferInterestModel(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      buyerName: bName,
      buyerMobile: bMobile,
      offerPrice: amount,
      requiredQuantity: qty,
      deliveryDate: json['delivery_date']?.toString(),
      loadingTo: json['loading_to']?.toString(),
      condition: json['condition']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
      canSellerAction: flag(
        'can_seller_action',
        fallback: json['status']?.toString().toLowerCase() == 'interested',
      ),
      canOpenNegotiation: flag(
        'can_open_negotiation',
        fallback: !const {
          'deal_confirmed',
          'rejected',
          'cancelled',
        }.contains(json['status']?.toString().toLowerCase()),
      ),
      canAdminFinalAction: flag('can_admin_final_action'),
      canSellerReject: flag('can_seller_reject'),
      isReadOnly: flag(
        'is_read_only',
        fallback: const {
          'deal_confirmed',
          'rejected',
          'cancelled',
        }.contains(json['status']?.toString().toLowerCase()),
      ),
      transactionId: json['transaction_id']?.toString(),
    );
  }
}
