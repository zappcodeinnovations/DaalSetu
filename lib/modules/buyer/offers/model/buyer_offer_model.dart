class BuyerOfferModel {
  final int? id;
  final int? productId;
  final int? interestId;
  final String? transactionId;
  final String? title;
  final String? code;
  final String? brand;
  final String? category;
  final String? availableQuantity;
  final String? requestedQuantity;
  final String? quantityUnit;
  final String? requestedAmount;
  final String? amountUnit;
  final String? bagCount;
  final String? packingWeight;
  final String? pickupFrom;
  final String? pickupTo;
  final String? expiryDate;
  final String? status;
  final String? createdAt;
  final String? imageUrl;
  final String? interestCount;
  final String? sellerName;
  
  // Custom fields for UI mapping based on different API formats
  final String? displayTitle;
  final String? displayStatus;
  final String? displayQuantity;
  final String? displayPrice;
  final String? location;
  final bool isRfq;

  BuyerOfferModel({
    this.id,
    this.productId,
    this.interestId,
    this.transactionId,
    this.title,
    this.code,
    this.brand,
    this.category,
    this.availableQuantity,
    this.requestedQuantity,
    this.quantityUnit,
    this.requestedAmount,
    this.amountUnit,
    this.bagCount,
    this.packingWeight,
    this.pickupFrom,
    this.pickupTo,
    this.expiryDate,
    this.status,
    this.createdAt,
    this.imageUrl,
    this.interestCount,
    this.sellerName,
    this.displayTitle,
    this.displayStatus,
    this.displayQuantity,
    this.displayPrice,
    this.location,
    this.isRfq = false,
  });

  factory BuyerOfferModel.fromJson(dynamic raw) {
    final Map<String, dynamic> json = (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    String cleanMapString(String s) {
      if (s.startsWith('{') && s.endsWith('}')) {
        // Try regex match for "name": "..." or name: ...
        final nameMatch = RegExp(r'''(?:['"]?name['"]?|['"]?title['"]?|['"]?brand_name['"]?|['"]?category_name['"]?)\s*:\s*['"]?([^,'"}]+)['"]?''').firstMatch(s);
        if (nameMatch != null) {
          final val = nameMatch.group(1)?.trim();
          if (val != null && val.isNotEmpty && val != 'null') {
            return val;
          }
        }
        return '';
      }
      return s;
    }

    String pickStr(List<dynamic> candidates, {String fallback = ''}) {
      for (final c in candidates) {
        if (c != null) {
          if (c is Map) {
            final mapName = c['name'] ??
                c['title'] ??
                c['label'] ??
                c['brand_name'] ??
                c['category_name'] ??
                c['commodity_name'] ??
                c['full_name'] ??
                c['username'] ??
                c['trade_name'];
            if (mapName != null) {
              final s = cleanMapString(mapName.toString().trim());
              if (s.isNotEmpty && s != 'null' && s != 'None') {
                return s;
              }
            }
            continue;
          }
          final raw = c.toString().trim();
          final s = cleanMapString(raw);
          if (s.isNotEmpty && s != 'null' && s != 'None') {
            return s;
          }
        }
      }
      return fallback;
    }

    String pickNumStr(List<dynamic> candidates, {String fallback = ''}) {
      String? zeroVal;
      for (final c in candidates) {
        if (c != null) {
          final s = c.toString().trim();
          if (s.isNotEmpty && s != 'null' && s != 'N/A' && s != 'na' && s != 'None') {
            final cleaned = s.replaceAll(RegExp(r'[^\d.]'), '');
            final numVal = num.tryParse(cleaned);
            if (numVal != null) {
              if (numVal > 0) {
                return s;
              } else {
                zeroVal ??= s;
              }
            } else {
              return s;
            }
          }
        }
      }
      return zeroVal ?? fallback;
    }

    String formatDateDisplay(String? raw) {
      if (raw == null || raw.trim().isEmpty) return '';
      final s = raw.trim();
      try {
        if (s.contains('T')) {
          final dt = DateTime.parse(s).toLocal();
          return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
        }
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
          final parts = s.split('-');
          return "${parts[2]}-${parts[1]}-${parts[0]}";
        }
      } catch (_) {}
      return s;
    }

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

    final rawTitle = pickStr([
      json['title'],
      json['product_title'],
      if (json['offer'] is Map) json['offer']['title'],
      if (json['product'] is Map) json['product']['title'],
      json['commodity'],
      json['category_name'],
    ], fallback: 'Offer');

    final rawCode = pickStr([
      json['code'],
      json['product_code'],
      json['offer_code'],
      json['seller_mapped_id'],
      json['seller_code'],
      json['unique_id'],
      json['contract_id'],
      json['transaction_id'],
      if (json['seller'] is Map) (json['seller']['seller_mapped_id'] ?? json['seller']['code'] ?? json['seller']['unique_id']),
      if (json['product'] is Map) (json['product']['code'] ?? json['product']['seller_mapped_id'] ?? json['product']['product_code']),
      if (json['offer'] is Map) (json['offer']['code'] ?? json['offer']['seller_mapped_id'] ?? json['offer']['offer_code']),
    ]);

    final rawBrand = pickStr([
      json['brand_name'],
      json['brand'],
      json['product_brand'],
      if (json['brand'] is Map) (json['brand']['name'] ?? json['brand']['brand_name']),
      if (json['offer'] is Map) (json['offer']['brand_name'] ?? (json['offer']['brand'] is Map ? json['offer']['brand']['name'] : json['offer']['brand'])),
      if (json['product'] is Map) (json['product']['brand_name'] ?? (json['product']['brand'] is Map ? json['product']['brand']['name'] : json['product']['brand'])),
    ]);

    final rawCategory = pickStr([
      json['category_name'],
      json['subcategory_name'],
      json['category'],
      json['commodity'],
      json['product_category'],
      json['product_category_name'],
      if (json['category'] is Map) (json['category']['name'] ?? json['category']['category_name']),
      if (json['offer'] is Map) (json['offer']['category_name'] ?? (json['offer']['category'] is Map ? json['offer']['category']['name'] : json['offer']['category'])),
      if (json['product'] is Map) (json['product']['category_name'] ?? (json['product']['category'] is Map ? json['product']['category']['name'] : json['product']['category'])),
    ]);

    final rawStatus = pickStr([
      json['status'],
      json['deal_status'],
      json['deal_status_label'],
      json['stock_status'],
      json['product_status'],
      json['status_label'],
      json['status_code'],
      if (json['offer'] is Map) json['offer']['status'],
      if (json['product'] is Map) (json['product']['status'] ?? json['product']['stock_status']),
    ]);

    final rawUnit = pickStr([
      json['quantity_unit'],
      json['unit'],
      json['amount_unit'],
      if (json['offer'] is Map) json['offer']['quantity_unit'],
      if (json['offer'] is Map) json['offer']['unit'],
      if (json['product'] is Map) json['product']['quantity_unit'],
      if (json['product'] is Map) json['product']['unit'],
      if (json['rfq'] is Map) json['rfq']['quantity_unit'],
      if (json['rfq'] is Map) json['rfq']['unit'],
    ], fallback: 'QTL');

    final rawAmountUnit = pickStr([
      json['amount_unit'],
      json['quantity_unit'],
      json['unit'],
      if (json['offer'] is Map) json['offer']['amount_unit'],
      if (json['product'] is Map) json['product']['amount_unit'],
    ], fallback: rawUnit);

    final rawAvailableQuantity = pickNumStr([
      json['available_quantity'],
      json['remaining_quantity'],
      json['latest_offered_quantity'],
      json['original_quantity'],
      json['quantity_qtl'],
      json['deal_quantity'],
      json['quantity'],
      json['available_stock'],
      json['stock'],
      json['total_quantity'],
      json['seller_snapshot_quantity'],
      json['buyer_required_quantity'],
      json['required_quantity'],
      json['requested_quantity'],
      json['target_quantity'],
      json['volume'],
      json['weight'],
      if (json['offer'] is Map) ...[
        json['offer']['available_quantity'],
        json['offer']['remaining_quantity'],
        json['offer']['latest_offered_quantity'],
        json['offer']['original_quantity'],
        json['offer']['quantity_qtl'],
        json['offer']['deal_quantity'],
        json['offer']['quantity'],
        json['offer']['available_stock'],
        json['offer']['stock'],
        json['offer']['total_quantity'],
        json['offer']['seller_snapshot_quantity'],
        json['offer']['buyer_required_quantity'],
        json['offer']['required_quantity'],
        json['offer']['requested_quantity'],
      ],
      if (json['product'] is Map) ...[
        json['product']['available_quantity'],
        json['product']['remaining_quantity'],
        json['product']['latest_offered_quantity'],
        json['product']['original_quantity'],
        json['product']['quantity_qtl'],
        json['product']['deal_quantity'],
        json['product']['quantity'],
        json['product']['available_stock'],
        json['product']['stock'],
        json['product']['total_quantity'],
        json['product']['seller_snapshot_quantity'],
        json['product']['buyer_required_quantity'],
        json['product']['required_quantity'],
        json['product']['requested_quantity'],
      ],
      if (json['rfq'] is Map) ...[
        json['rfq']['required_quantity'],
        json['rfq']['requested_quantity'],
        json['rfq']['quantity'],
        json['rfq']['quantity_qtl'],
        json['rfq']['target_quantity'],
      ],
      if (json['deal'] is Map) ...[
        json['deal']['deal_quantity'],
        json['deal']['quantity_qtl'],
        json['deal']['quantity'],
      ],
      if (json['contract'] is Map) ...[
        json['contract']['deal_quantity'],
        json['contract']['quantity_qtl'],
        json['contract']['quantity'],
      ],
    ]);

    final rawRequestedQuantity = pickNumStr([
      json['requested_quantity'],
      json['required_quantity'],
      json['latest_offered_quantity'],
      json['buyer_required_quantity'],
      json['target_quantity'],
      json['seller_snapshot_quantity'],
      json['deal_quantity'],
      json['quantity_qtl'],
      json['quantity'],
      json['available_quantity'],
      json['remaining_quantity'],
      if (json['rfq'] is Map) ...[
        json['rfq']['required_quantity'],
        json['rfq']['requested_quantity'],
        json['rfq']['quantity'],
      ],
      if (json['offer'] is Map) ...[
        json['offer']['requested_quantity'],
        json['offer']['required_quantity'],
        json['offer']['latest_offered_quantity'],
        json['offer']['buyer_required_quantity'],
      ],
      rawAvailableQuantity,
    ]);

    final rawPrice = pickNumStr([
      json['amount'],
      json['offered_amount'],
      json['requested_amount'],
      json['offer_price'],
      json['target_price'],
      json['price'],
      json['rate'],
      json['unit_price'],
      json['latest_offered_amount'],
      json['deal_amount'],
      json['seller_snapshot_amount'],
      json['buyer_offered_amount'],
      if (json['offer'] is Map) (json['offer']['price'] ?? json['offer']['amount'] ?? json['offer']['offered_amount'] ?? json['offer']['offer_price'] ?? json['offer']['latest_offered_amount']),
      if (json['product'] is Map) (json['product']['price'] ?? json['product']['amount'] ?? json['product']['offer_price']),
      if (json['rfq'] is Map) (json['rfq']['target_price'] ?? json['rfq']['price'] ?? json['rfq']['amount'] ?? json['rfq']['requested_amount']),
    ]);

    final rawBags = pickNumStr([
      json['remaining_bag_count'],
      json['original_bag_count'],
      json['bag_count'],
      json['bags'],
      json['seller_snapshot_bag_count'],
      json['buyer_required_bag_count'],
      if (json['offer'] is Map) (json['offer']['bag_count'] ?? json['offer']['bags']),
      if (json['product'] is Map) (json['product']['remaining_bag_count'] ?? json['product']['bag_count'] ?? json['product']['original_bag_count']),
    ]);

    final rawPacking = pickNumStr([
      json['packing_weight_kg'],
      json['packing'],
      json['seller_snapshot_packing_weight_kg'],
      json['buyer_packing_weight_kg'],
      if (json['offer'] is Map) (json['offer']['packing_weight_kg'] ?? json['offer']['packing']),
      if (json['product'] is Map) (json['product']['packing_weight_kg'] ?? json['product']['packing']),
    ]);

    // Parse loading_location e.g. "2026-10-10 -> 2026-10-31" as fallback dates
    String? fallbackFromDate;
    String? fallbackToDate;
    final loadingLocStr = (json['loading_location'] ?? (json['offer'] is Map ? json['offer']['loading_location'] : null) ?? (json['product'] is Map ? json['product']['loading_location'] : null))?.toString();
    if (loadingLocStr != null && loadingLocStr.contains('->')) {
      final parts = loadingLocStr.split('->');
      if (parts.length >= 2) {
        fallbackFromDate = parts[0].trim();
        fallbackToDate = parts[1].trim();
      }
    }

    final rawPickupFrom = formatDateDisplay(pickStr([
      json['loading_from'],
      json['pickup_from'],
      json['loading_date'],
      json['pickup_date'],
      json['from_date'],
      if (json['offer'] is Map) (json['offer']['loading_from'] ?? json['offer']['pickup_from']),
      if (json['product'] is Map) (json['product']['loading_from'] ?? json['product']['pickup_from']),
      fallbackFromDate,
    ]));

    final rawPickupTo = formatDateDisplay(pickStr([
      json['loading_to'],
      json['pickup_to'],
      json['delivery_date'],
      json['to_date'],
      if (json['offer'] is Map) (json['offer']['loading_to'] ?? json['offer']['pickup_to'] ?? json['offer']['delivery_date']),
      if (json['product'] is Map) (json['product']['loading_to'] ?? json['product']['pickup_to'] ?? json['product']['delivery_date']),
      fallbackToDate,
    ]));

    final rawExpiry = formatDateDisplay(pickStr([
      json['deal_expiry_datetime'],
      json['expiry_date'],
      json['expiry_datetime'],
      if (json['product'] is Map) json['product']['deal_expiry_datetime'],
    ]));

    String rawLocationCandidate = pickStr([
      json['visible_branch_labels'],
      json['destination'],
      json['city'],
      json['delivery_location'],
      if (json['location'] is String && !json['location'].toString().contains('T') && !json['location'].toString().contains('->')) json['location'],
      if (json['branch'] is Map) (json['branch']['location_name'] ?? json['branch']['city'] ?? json['branch']['name']),
      if (json['loading_location'] != null && !json['loading_location'].toString().contains('->') && !json['loading_location'].toString().contains('2026'))
        json['loading_location'],
    ]);

    final rawImage = pickStr([
      json['primary_image_url'],
      json['image'],
      json['image_url'],
      if (json['images'] is List && json['images'].isNotEmpty)
        (json['images'][0] is Map ? (json['images'][0]['image'] ?? json['images'][0]['image_url']) : json['images'][0]),
      if (json['product_images'] is List && json['product_images'].isNotEmpty)
        (json['product_images'][0] is Map ? (json['product_images'][0]['image'] ?? json['product_images'][0]['image_url']) : json['product_images'][0]),
      if (json['offer'] is Map) (json['offer']['image'] ?? json['offer']['primary_image_url'] ?? json['offer']['image_url']),
      if (json['product'] is Map) (json['product']['image'] ?? json['product']['primary_image_url'] ?? json['product']['image_url']),
    ]);

    final rawInterests = pickNumStr([
      json['interest_count'],
      json['interested_buyers_count'],
      json['interests_count'],
      json['total_interests'],
      if (json['interests'] is List) json['interests'].length.toString(),
      if (json['offer'] is Map) json['offer']['interest_count'],
      if (json['product'] is Map) (json['product']['interest_count'] ?? json['product']['interested_buyers_count']),
    ], fallback: '0');

    final rawSellerName = pickStr([
      json['seller_name'],
      json['seller_full_name'],
      if (json['seller'] is Map) (json['seller']['full_name'] ?? json['seller']['username'] ?? json['seller']['name']),
      if (json['company'] is Map) (json['company']['legal_name'] ?? json['company']['trade_name']),
    ]);

    final isRfqItem = json.containsKey('rfq_id') ||
        json.containsKey('required_quantity') ||
        json.containsKey('target_price') ||
        json.containsKey('visible_branches') ||
        (json['status']?.toString().toLowerCase() == 'open' && json.containsKey('commodity'));

    // Format display price e.g. "₹60.00/TON"
    String formattedPrice = '';
    if (rawPrice.isNotEmpty) {
      final cleanP = rawPrice.replaceAll('₹', '').trim();
      final unitStr = rawAmountUnit.isNotEmpty ? rawAmountUnit.toUpperCase() : rawUnit.toUpperCase();
      formattedPrice = '₹$cleanP/$unitStr';
    }

    // Format display quantity e.g. "600.000 QTL"
    String formattedQuantity = '';
    final qtyVal = rawAvailableQuantity.isNotEmpty ? rawAvailableQuantity : rawRequestedQuantity;
    if (qtyVal.isNotEmpty) {
      final unitUpper = rawUnit.toUpperCase();
      if (qtyVal.toUpperCase().contains(unitUpper)) {
        formattedQuantity = qtyVal;
      } else {
        formattedQuantity = '$qtyVal $unitUpper';
      }
    } else if (rawBags.isNotEmpty) {
      formattedQuantity = '$rawBags Bags';
    } else {
      formattedQuantity = '0.000 QTL';
    }

    String formattedStatus = rawStatus.trim();
    if (formattedStatus.isEmpty) {
      formattedStatus = isRfqItem ? 'OPEN' : 'ACTIVE';
    } else {
      formattedStatus = formattedStatus.replaceAll('_', ' ').toUpperCase();
    }

    return BuyerOfferModel(
      id: rootId ?? parsedProductId ?? parsedInterestId,
      productId: parsedProductId,
      interestId: parsedInterestId,
      transactionId: json['transaction_id']?.toString() ?? rawCode,
      title: rawTitle,
      code: rawCode,
      brand: rawBrand,
      category: rawCategory,
      availableQuantity: rawAvailableQuantity.isNotEmpty ? rawAvailableQuantity : rawRequestedQuantity,
      requestedQuantity: rawRequestedQuantity.isNotEmpty ? rawRequestedQuantity : rawAvailableQuantity,
      quantityUnit: rawUnit,
      requestedAmount: rawPrice,
      amountUnit: rawAmountUnit,
      bagCount: rawBags,
      packingWeight: rawPacking,
      pickupFrom: rawPickupFrom,
      pickupTo: rawPickupTo,
      expiryDate: rawExpiry,
      status: rawStatus,
      createdAt: json['created_at']?.toString() ?? json['updated_at']?.toString() ?? '',
      imageUrl: rawImage,
      interestCount: rawInterests,
      sellerName: rawSellerName,
      location: rawLocationCandidate,
      displayTitle: rawTitle,
      displayStatus: formattedStatus,
      displayQuantity: formattedQuantity,
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
