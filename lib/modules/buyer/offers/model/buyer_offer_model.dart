class BuyerOfferModel {
  final int? id;
  final int? productId;
  final int? interestId;
  final String? transactionId;
  final String? title;
  final String? requestedQuantity;
  final String? quantityUnit;
  final String? requestedAmount;
  final String? amountUnit;
  final String? status;
  final String? createdAt;
  
  // Custom fields for UI mapping based on different API formats
  final String? displayTitle;
  final String? displayStatus;
  final String? displayQuantity;
  final String? displayPrice;
  final bool isRfq;

  BuyerOfferModel({
    this.id,
    this.productId,
    this.interestId,
    this.transactionId,
    this.title,
    this.requestedQuantity,
    this.quantityUnit,
    this.requestedAmount,
    this.amountUnit,
    this.status,
    this.createdAt,
    this.displayTitle,
    this.displayStatus,
    this.displayQuantity,
    this.displayPrice,
    this.isRfq = false,
  });

  factory BuyerOfferModel.fromJson(dynamic raw) {
    final Map<String, dynamic> json = (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    int? parsedProductId;
    if (json['product_id'] != null) {
      parsedProductId = int.tryParse(json['product_id'].toString());
    } else if (json['offer_id'] != null) {
      parsedProductId = int.tryParse(json['offer_id'].toString());
    } else if (json['offer'] is Map && json['offer']['id'] != null) {
      parsedProductId = int.tryParse(json['offer']['id'].toString());
    } else if (json['product'] is Map && json['product']['id'] != null) {
      parsedProductId = int.tryParse(json['product']['id'].toString());
    } else if (json['offer'] is int) {
      parsedProductId = json['offer'];
    } else if (json['product'] is int) {
      parsedProductId = json['product'];
    }

    int? parsedInterestId;
    if (json['interest_id'] != null) {
      parsedInterestId = int.tryParse(json['interest_id'].toString());
    } else if (json['interest'] is Map && json['interest']['id'] != null) {
      parsedInterestId = int.tryParse(json['interest']['id'].toString());
    } else if (json['interest'] is int) {
      parsedInterestId = json['interest'];
    }

    final rootId = json['id'] != null ? int.tryParse(json['id'].toString()) : null;

    if (parsedProductId == null && parsedInterestId == null) {
      parsedProductId = rootId;
    } else if (parsedProductId != null && parsedInterestId == null) {
      if (rootId != null && rootId != parsedProductId) {
        parsedInterestId = rootId;
      }
    } else if (parsedProductId == null && parsedInterestId != null) {
      if (rootId != null && rootId != parsedInterestId) {
        parsedProductId = rootId;
      }
    }

    final rawTitle = json['title'] ??
        json['product_title'] ??
        (json['offer'] is Map ? json['offer']['title'] : null) ??
        (json['product'] is Map ? json['product']['title'] : null) ??
        json['commodity'] ??
        json['category_name'] ??
        'Offer';

    final rawStatus = json['status'] ??
        json['deal_status'] ??
        json['product_status'] ??
        json['status_label'] ??
        json['status_code'] ??
        (json['offer'] is Map ? json['offer']['status'] : null) ??
        '';

    final rawQuantity = json['requested_quantity'] ??
        json['required_quantity'] ??
        json['buyer_required_quantity'] ??
        json['quantity'] ??
        json['available_quantity'] ??
        json['remaining_quantity'] ??
        json['original_quantity'] ??
        json['seller_snapshot_quantity'] ??
        (json['offer'] is Map ? json['offer']['quantity'] : null) ??
        '';

    final rawUnit = json['quantity_unit'] ??
        json['unit'] ??
        json['amount_unit'] ??
        (json['offer'] is Map ? json['offer']['unit'] : null) ??
        '';

    final rawPrice = json['requested_amount'] ??
        json['offered_amount'] ??
        json['buyer_offered_amount'] ??
        json['amount'] ??
        json['seller_snapshot_amount'] ??
        json['target_price'] ??
        json['offer_price'] ??
        json['price'] ??
        (json['offer'] is Map ? json['offer']['price'] : null) ??
        '';

    final isRfqItem = json.containsKey('rfq_id') ||
        json.containsKey('required_quantity') ||
        json.containsKey('target_price') ||
        json.containsKey('visible_branches') ||
        (json['status']?.toString().toLowerCase() == 'open' && json.containsKey('commodity'));

    String formattedPrice = rawPrice.toString().trim();
    if (formattedPrice.isNotEmpty && formattedPrice != '0' && !formattedPrice.startsWith('₹')) {
      formattedPrice = '₹$formattedPrice';
    } else if (formattedPrice == '0' || formattedPrice.isEmpty) {
      formattedPrice = '';
    }

    String formattedQuantity = rawQuantity.toString().trim();
    if (formattedQuantity.isNotEmpty && rawUnit.toString().trim().isNotEmpty) {
      formattedQuantity = '$formattedQuantity ${rawUnit.toString().trim()}';
    }

    String formattedStatus = rawStatus.toString().trim();
    if (formattedStatus.isEmpty) {
      formattedStatus = isRfqItem ? 'OPEN' : 'AVAILABLE';
    } else {
      formattedStatus = formattedStatus.replaceAll('_', ' ').toUpperCase();
    }

    return BuyerOfferModel(
      id: rootId ?? parsedProductId ?? parsedInterestId,
      productId: parsedProductId,
      interestId: parsedInterestId,
      transactionId: json['transaction_id']?.toString() ?? '',
      title: rawTitle.toString(),
      requestedQuantity: rawQuantity.toString(),
      quantityUnit: rawUnit.toString(),
      requestedAmount: rawPrice.toString(),
      amountUnit: json['amount_unit']?.toString() ?? '',
      status: rawStatus.toString(),
      createdAt: json['created_at']?.toString() ?? json['updated_at']?.toString() ?? '',
      
      displayTitle: rawTitle.toString(),
      displayStatus: formattedStatus,
      displayQuantity: formattedQuantity.isNotEmpty ? formattedQuantity : 'N/A',
      displayPrice: formattedPrice,
      isRfq: isRfqItem,
    );
  }

  bool get isConfirmed {
    final s = (displayStatus ?? status ?? '').toString().toLowerCase();
    return s.contains('confirm') || s.contains('deal_confirmed') || s.contains('approved');
  }

  bool get isRejected {
    final s = (displayStatus ?? status ?? '').toString().toLowerCase();
    return s.contains('reject') || s.contains('cancel') || s.contains('closed') || s.contains('expire');
  }

  bool get isActionable => !isConfirmed && !isRejected;
}
