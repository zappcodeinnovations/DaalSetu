import 'package:intl/intl.dart';

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
  final bool canEditInterest;
  final bool canCancelInterest;
  final bool canOpenNegotiation;
  final bool canBuyerAccept;
  final bool canBuyerReject;
  final bool hasSellerProposal;

  // Custom fields for UI mapping based on different API formats
  final String? displayTitle;
  final String? displayStatus;
  final String? displayQuantity;
  final String? displayPrice;
  final String? location;
  final bool isRfq;
  final bool isActive;

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
    this.canEditInterest = false,
    this.canCancelInterest = false,
    this.canOpenNegotiation = false,
    this.canBuyerAccept = false,
    this.canBuyerReject = false,
    this.hasSellerProposal = false,
    this.displayTitle,
    this.displayStatus,
    this.displayQuantity,
    this.displayPrice,
    this.location,
    this.isRfq = false,
    this.isActive = true,
    this.isExpired = false,
    this.expiresAt,
  });

  final bool isExpired;

  /// Earliest expiry the API sent for this offer/requirement, if any.
  final DateTime? expiresAt;

  /// Expired now, including deals whose expiry passed after they were loaded.
  bool get hasExpired =>
      isExpired || (expiresAt != null && expiresAt!.isBefore(DateTime.now()));

  /// Every field the API uses for an offer/requirement expiry.
  static List<dynamic> expiryCandidates(Map<String, dynamic> json) {
    final nested = [
      for (final key in const ['product', 'offer', 'rfq'])
        if (json[key] is Map) json[key] as Map,
    ];
    return [
      for (final source in [json, ...nested])
        for (final key in const [
          'deal_expiry_datetime',
          'expiry_datetime',
          'expiry_date',
          'broadcast_expiry',
          'broadcast_expiry_datetime',
          'expires_at',
        ])
          source[key],
    ];
  }

  static final List<DateFormat> _expiryDateTimeFormats = [
    DateFormat('dd-MM-yyyy HH:mm'),
    DateFormat('dd/MM/yyyy HH:mm'),
    DateFormat('dd-MM-yyyy hh:mm a'),
    DateFormat('dd/MM/yyyy hh:mm a'),
    DateFormat('dd MMM yyyy, hh:mm a'),
    DateFormat('dd MMM yyyy hh:mm a'),
  ];

  static final List<DateFormat> _expiryDateFormats = [
    DateFormat('dd-MM-yyyy'),
    DateFormat('dd/MM/yyyy'),
    DateFormat('dd MMM yyyy'),
  ];

  /// Parses an expiry value; a date without a time expires at the end of that day.
  static DateTime? parseExpiry(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return null;

    DateTime endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

    final iso = DateTime.tryParse(text);
    if (iso != null) {
      return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ? endOfDay(iso) : iso.toLocal();
    }
    for (final format in _expiryDateTimeFormats) {
      try {
        return format.parseStrict(text);
      } catch (_) {}
    }
    for (final format in _expiryDateFormats) {
      try {
        return endOfDay(format.parseStrict(text));
      } catch (_) {}
    }
    return null;
  }

  BuyerOfferModel copyWith({
    int? id,
    int? productId,
    int? interestId,
    String? transactionId,
    String? title,
    String? code,
    String? brand,
    String? category,
    String? availableQuantity,
    String? requestedQuantity,
    String? quantityUnit,
    String? requestedAmount,
    String? amountUnit,
    String? bagCount,
    String? packingWeight,
    String? pickupFrom,
    String? pickupTo,
    String? expiryDate,
    String? status,
    String? createdAt,
    String? imageUrl,
    String? interestCount,
    String? sellerName,
    bool? canEditInterest,
    bool? canCancelInterest,
    bool? canOpenNegotiation,
    bool? canBuyerAccept,
    bool? canBuyerReject,
    bool? hasSellerProposal,
    String? displayTitle,
    String? displayStatus,
    String? displayQuantity,
    String? displayPrice,
    String? location,
    bool? isRfq,
    bool? isActive,
    bool? isExpired,
    DateTime? expiresAt,
  }) {
    return BuyerOfferModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      interestId: interestId ?? this.interestId,
      transactionId: transactionId ?? this.transactionId,
      title: title ?? this.title,
      code: code ?? this.code,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      amountUnit: amountUnit ?? this.amountUnit,
      bagCount: bagCount ?? this.bagCount,
      packingWeight: packingWeight ?? this.packingWeight,
      pickupFrom: pickupFrom ?? this.pickupFrom,
      pickupTo: pickupTo ?? this.pickupTo,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      interestCount: interestCount ?? this.interestCount,
      sellerName: sellerName ?? this.sellerName,
      canEditInterest: canEditInterest ?? this.canEditInterest,
      canCancelInterest: canCancelInterest ?? this.canCancelInterest,
      canOpenNegotiation: canOpenNegotiation ?? this.canOpenNegotiation,
      canBuyerAccept: canBuyerAccept ?? this.canBuyerAccept,
      canBuyerReject: canBuyerReject ?? this.canBuyerReject,
      hasSellerProposal: hasSellerProposal ?? this.hasSellerProposal,
      displayTitle: displayTitle ?? this.displayTitle,
      displayStatus: displayStatus ?? this.displayStatus,
      displayQuantity: displayQuantity ?? this.displayQuantity,
      displayPrice: displayPrice ?? this.displayPrice,
      location: location ?? this.location,
      isRfq: isRfq ?? this.isRfq,
      isActive: isActive ?? this.isActive,
      isExpired: isExpired ?? this.isExpired,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  factory BuyerOfferModel.fromJson(dynamic raw) {
    final Map<String, dynamic> json = (raw is Map)
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    String cleanMapString(String s) {
      if (s.startsWith('{') && s.endsWith('}')) {
        // Try regex match for "name": "..." or name: ...
        final nameMatch = RegExp(
          r'''(?:['"]?name['"]?|['"]?title['"]?|['"]?brand_name['"]?|['"]?category_name['"]?)\s*:\s*['"]?([^,'"}]+)['"]?''',
        ).firstMatch(s);
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
            final mapName =
                c['name'] ??
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
          if (s.isNotEmpty &&
              s != 'null' &&
              s != 'N/A' &&
              s != 'na' &&
              s != 'None') {
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

    String pickPositiveNumStr(List<dynamic> candidates, {String fallback = ''}) {
      for (final c in candidates) {
        if (c != null) {
          final s = c.toString().trim();
          if (s.isNotEmpty &&
              s != 'null' &&
              s != 'N/A' &&
              s != 'na' &&
              s != 'None') {
            final cleaned = s.replaceAll(RegExp(r'[^\d.]'), '');
            final numVal = num.tryParse(cleaned);
            if (numVal != null && numVal > 0) {
              return s;
            }
          }
        }
      }
      return fallback;
    }

    String formatDateDisplay(String? raw, {bool withTime = false}) {
      if (raw == null || raw.trim().isEmpty) return '';
      final s = raw.trim();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      try {
        if (s.contains('T')) {
          final dt = DateTime.parse(s).toLocal();
          final mStr = (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : '${dt.month}';
          final d = "${dt.day} $mStr ${dt.year}";
          if (withTime) {
            final t = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
            return "$d $t";
          }
          return d;
        }
        if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
          final dt = DateTime.tryParse(s)?.toLocal();
          if (dt != null) {
            final mStr = (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : '${dt.month}';
            final d = "${dt.day} $mStr ${dt.year}";
            if (withTime) {
              final t = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
              return "$d $t";
            }
            return d;
          }
        }
        if (RegExp(r'^\d{2}-\d{2}-\d{4}').hasMatch(s)) {
          final parts = s.split(' ')[0].split('-');
          final day = int.tryParse(parts[0]) ?? 1;
          final month = int.tryParse(parts[1]) ?? 1;
          final year = parts[2];
          final mStr = (month >= 1 && month <= 12) ? months[month - 1] : '$month';
          final d = "$day $mStr $year";
          if (withTime && s.contains(' ')) {
            return "$d ${s.split(' ')[1]}";
          }
          return d;
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

    final rootId = json['id'] != null
        ? int.tryParse(json['id'].toString())
        : null;

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
      if (json['seller'] is Map)
        (json['seller']['seller_mapped_id'] ??
            json['seller']['code'] ??
            json['seller']['unique_id']),
      if (json['product'] is Map)
        (json['product']['code'] ??
            json['product']['seller_mapped_id'] ??
            json['product']['product_code']),
      if (json['offer'] is Map)
        (json['offer']['code'] ??
            json['offer']['seller_mapped_id'] ??
            json['offer']['offer_code']),
    ]);

    final rawBrand = pickStr([
      json['brand_name'],
      json['brand'],
      json['product_brand'],
      if (json['brand'] is Map)
        (json['brand']['name'] ?? json['brand']['brand_name']),
      if (json['offer'] is Map)
        (json['offer']['brand_name'] ??
            (json['offer']['brand'] is Map
                ? json['offer']['brand']['name']
                : json['offer']['brand'])),
      if (json['product'] is Map)
        (json['product']['brand_name'] ??
            (json['product']['brand'] is Map
                ? json['product']['brand']['name']
                : json['product']['brand'])),
    ]);

    final rawCategory = pickStr([
      json['category_name'],
      json['subcategory_name'],
      json['category'],
      json['commodity'],
      json['product_category'],
      json['product_category_name'],
      if (json['category'] is Map)
        (json['category']['name'] ?? json['category']['category_name']),
      if (json['offer'] is Map)
        (json['offer']['category_name'] ??
            (json['offer']['category'] is Map
                ? json['offer']['category']['name']
                : json['offer']['category'])),
      if (json['product'] is Map)
        (json['product']['category_name'] ??
            (json['product']['category'] is Map
                ? json['product']['category']['name']
                : json['product']['category'])),
    ]);

    final rawStatus = pickStr([
      json['deal_status_label'],
      json['deal_status'],
      json['status_label'],
      json['interest_status'],
      json['status'],
      json['status_code'],
      json['product_status'],
      json['stock_status'],
      if (json['product'] is Map)
        (json['product']['status'] ?? json['product']['stock_status']),
      if (json['offer'] is Map)
        (json['offer']['status'] ?? json['offer']['stock_status']),
    ]);
    final normalizedStatus = rawStatus.trim().toLowerCase();

    bool boolValue(String key, {required bool fallback}) {
      dynamic value = json[key];
      if (value == null && json['product'] is Map) {
        value = json['product'][key];
      }
      if (value == null && json['offer'] is Map) {
        value = json['offer'][key];
      }
      if (value == null && json['rfq'] is Map) {
        value = json['rfq'][key];
      }
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (const {'true', '1', 'yes'}.contains(normalized)) return true;
        if (const {'false', '0', 'no'}.contains(normalized)) return false;
      }
      return fallback;
    }

    final terminal = const {
      'deal_confirmed',
      'rejected',
      'cancelled',
    }.contains(normalizedStatus);
    final defaultBuyerDecision = normalizedStatus == 'seller_confirmed';

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
      json['rate_unit'],
      json['price_unit'],
      if (json['offer'] is Map) ...[
        json['offer']['amount_unit'],
        json['offer']['rate_unit'],
        json['offer']['price_unit'],
      ],
      if (json['product'] is Map) ...[
        json['product']['amount_unit'],
        json['product']['rate_unit'],
        json['product']['price_unit'],
      ],
      json['quantity_unit'],
      json['unit'],
    ], fallback: rawUnit);

    String rawAvailableQuantity = pickPositiveNumStr([
      json['quantity_qtl'],
      json['available_quantity_qtl'],
      json['remaining_quantity_qtl'],
      json['available_quantity'],
      json['remaining_quantity'],
      json['available_stock_qtl'],
      json['available_stock'],
      json['stock_qtl'],
      json['stock'],
      json['total_qtl'],
      json['original_quantity_qtl'],
      json['original_quantity'],
      json['latest_offered_quantity'],
      json['deal_quantity'],
      json['quantity'],
      json['total_quantity'],
      json['seller_snapshot_quantity'],
      json['buyer_required_quantity'],
      json['required_quantity'],
      json['requested_quantity'],
      json['target_quantity'],
      json['volume'],
      json['weight'],
      if (json['offer'] is Map) ...[
        json['offer']['quantity_qtl'],
        json['offer']['available_quantity_qtl'],
        json['offer']['remaining_quantity_qtl'],
        json['offer']['available_quantity'],
        json['offer']['remaining_quantity'],
        json['offer']['available_stock_qtl'],
        json['offer']['available_stock'],
        json['offer']['stock_qtl'],
        json['offer']['stock'],
        json['offer']['total_qtl'],
        json['offer']['original_quantity_qtl'],
        json['offer']['original_quantity'],
        json['offer']['latest_offered_quantity'],
        json['offer']['deal_quantity'],
        json['offer']['quantity'],
        json['offer']['total_quantity'],
        json['offer']['seller_snapshot_quantity'],
        json['offer']['buyer_required_quantity'],
        json['offer']['required_quantity'],
        json['offer']['requested_quantity'],
      ],
      if (json['product'] is Map) ...[
        json['product']['quantity_qtl'],
        json['product']['available_quantity_qtl'],
        json['product']['remaining_quantity_qtl'],
        json['product']['available_quantity'],
        json['product']['remaining_quantity'],
        json['product']['available_stock_qtl'],
        json['product']['available_stock'],
        json['product']['stock_qtl'],
        json['product']['stock'],
        json['product']['total_qtl'],
        json['product']['original_quantity_qtl'],
        json['product']['original_quantity'],
        json['product']['latest_offered_quantity'],
        json['product']['deal_quantity'],
        json['product']['quantity'],
        json['product']['total_quantity'],
        json['product']['seller_snapshot_quantity'],
        json['product']['buyer_required_quantity'],
        json['product']['required_quantity'],
        json['product']['requested_quantity'],
      ],
      if (json['rfq'] is Map) ...[
        json['rfq']['quantity_qtl'],
        json['rfq']['required_quantity'],
        json['rfq']['requested_quantity'],
        json['rfq']['quantity'],
        json['rfq']['target_quantity'],
      ],
      if (json['deal'] is Map) ...[
        json['deal']['quantity_qtl'],
        json['deal']['deal_quantity'],
        json['deal']['quantity'],
      ],
      if (json['contract'] is Map) ...[
        json['contract']['quantity_qtl'],
        json['contract']['deal_quantity'],
        json['contract']['quantity'],
      ],
    ]);

    final rawRequestedQuantity = pickPositiveNumStr([
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
    ], fallback: pickNumStr([
      json['requested_quantity'],
      json['required_quantity'],
      rawAvailableQuantity,
    ]));

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
      if (json['offer'] is Map)
        (json['offer']['price'] ??
            json['offer']['amount'] ??
            json['offer']['offered_amount'] ??
            json['offer']['offer_price'] ??
            json['offer']['latest_offered_amount']),
      if (json['product'] is Map)
        (json['product']['price'] ??
            json['product']['amount'] ??
            json['product']['offer_price']),
      if (json['rfq'] is Map)
        (json['rfq']['target_price'] ??
            json['rfq']['price'] ??
            json['rfq']['amount'] ??
            json['rfq']['requested_amount']),
    ]);

    final rawBags = pickPositiveNumStr([
      json['remaining_bag_count'],
      json['original_bag_count'],
      json['bag_count'],
      json['remaining_bags'],
      json['original_bags'],
      json['available_bags'],
      json['bags'],
      json['seller_snapshot_bag_count'],
      json['buyer_required_bag_count'],
      if (json['offer'] is Map) ...[
        json['offer']['remaining_bag_count'],
        json['offer']['original_bag_count'],
        json['offer']['bag_count'],
        json['offer']['remaining_bags'],
        json['offer']['original_bags'],
        json['offer']['available_bags'],
        json['offer']['bags'],
      ],
      if (json['product'] is Map) ...[
        json['product']['remaining_bag_count'],
        json['product']['original_bag_count'],
        json['product']['bag_count'],
        json['product']['remaining_bags'],
        json['product']['original_bags'],
        json['product']['available_bags'],
        json['product']['bags'],
      ],
    ], fallback: pickNumStr([
      json['remaining_bag_count'],
      json['original_bag_count'],
      json['bag_count'],
      json['bags'],
    ]));

    final rawPacking = pickPositiveNumStr([
      json['packing_weight_kg'],
      json['packing_weight'],
      json['packing_kg'],
      json['packing'],
      json['seller_snapshot_packing_weight_kg'],
      json['buyer_packing_weight_kg'],
      if (json['offer'] is Map) ...[
        json['offer']['packing_weight_kg'],
        json['offer']['packing_weight'],
        json['offer']['packing_kg'],
        json['offer']['packing'],
      ],
      if (json['product'] is Map) ...[
        json['product']['packing_weight_kg'],
        json['product']['packing_weight'],
        json['product']['packing_kg'],
        json['product']['packing'],
      ],
    ], fallback: pickNumStr([
      json['packing_weight_kg'],
      json['packing'],
    ]));

    // If available quantity is missing or non-positive, compute it directly from bags * packing_weight / 100
    final num? parsedAvailNum = num.tryParse(
      rawAvailableQuantity.replaceAll(RegExp(r'[^\d.]'), ''),
    );
    final num? parsedBagsNum = num.tryParse(
      rawBags.replaceAll(RegExp(r'[^\d.]'), ''),
    );
    final num? parsedPackingNum = num.tryParse(
      rawPacking.replaceAll(RegExp(r'[^\d.]'), ''),
    );

    if ((parsedAvailNum == null || parsedAvailNum <= 0) &&
        parsedBagsNum != null &&
        parsedBagsNum > 0 &&
        parsedPackingNum != null &&
        parsedPackingNum > 0) {
      final calcQtl = (parsedBagsNum * parsedPackingNum) / 100.0;
      rawAvailableQuantity = calcQtl.toStringAsFixed(3);
    }

    // Parse loading_location e.g. "2026-10-10 -> 2026-10-31" as fallback dates
    String? fallbackFromDate;
    String? fallbackToDate;
    final loadingLocStr =
        (json['loading_location'] ??
                (json['offer'] is Map
                    ? json['offer']['loading_location']
                    : null) ??
                (json['product'] is Map
                    ? json['product']['loading_location']
                    : null))
            ?.toString();
    if (loadingLocStr != null && loadingLocStr.contains('->')) {
      final parts = loadingLocStr.split('->');
      if (parts.length >= 2) {
        fallbackFromDate = parts[0].trim();
        fallbackToDate = parts[1].trim();
      }
    }

    final rawPickupFrom = formatDateDisplay(
      pickStr([
        json['loading_from'],
        json['pickup_from'],
        json['loading_date'],
        json['pickup_date'],
        json['from_date'],
        if (json['offer'] is Map)
          (json['offer']['loading_from'] ?? json['offer']['pickup_from']),
        if (json['product'] is Map)
          (json['product']['loading_from'] ?? json['product']['pickup_from']),
        fallbackFromDate,
      ]),
    );

    final rawPickupTo = formatDateDisplay(
      pickStr([
        json['loading_to'],
        json['pickup_to'],
        json['delivery_date'],
        json['to_date'],
        if (json['offer'] is Map)
          (json['offer']['loading_to'] ??
              json['offer']['pickup_to'] ??
              json['offer']['delivery_date']),
        if (json['product'] is Map)
          (json['product']['loading_to'] ??
              json['product']['pickup_to'] ??
              json['product']['delivery_date']),
        fallbackToDate,
      ]),
    );

    final rawExpiry = formatDateDisplay(pickStr(expiryCandidates(json)));

    String rawLocationCandidate = pickStr([
      json['visible_branch_labels'],
      json['destination'],
      json['city'],
      json['delivery_location'],
      if (json['location'] is String &&
          !json['location'].toString().contains('T') &&
          !json['location'].toString().contains('->'))
        json['location'],
      if (json['branch'] is Map)
        (json['branch']['location_name'] ??
            json['branch']['city'] ??
            json['branch']['name']),
      if (json['loading_location'] != null &&
          !json['loading_location'].toString().contains('->') &&
          !json['loading_location'].toString().contains('2026'))
        json['loading_location'],
    ]);

    String? extractFirstImageUrl(dynamic list) {
      if (list is! List || list.isEmpty) return null;
      for (final item in list) {
        if (item is Map) {
          final url = item['image_url'] ??
              item['image'] ??
              item['file'] ??
              item['photo'] ??
              item['download_url'] ??
              item['url'];
          if (url != null && url.toString().trim().isNotEmpty) {
            return url.toString().trim();
          }
        } else if (item != null && item.toString().trim().isNotEmpty) {
          return item.toString().trim();
        }
      }
      return null;
    }

    final rawImage = pickStr([
      json['primary_image_url'],
      json['image_url'],
      json['image'],
      json['file'],
      json['photo'],
      json['thumbnail'],
      json['download_url'],
      extractFirstImageUrl(json['images']),
      extractFirstImageUrl(json['product_images']),
      extractFirstImageUrl(json['media']),
      extractFirstImageUrl(json['photos']),
      if (json['offer'] is Map) ...[
        json['offer']['primary_image_url'],
        json['offer']['image_url'],
        json['offer']['image'],
        json['offer']['file'],
        extractFirstImageUrl(json['offer']['images']),
        extractFirstImageUrl(json['offer']['product_images']),
      ],
      if (json['product'] is Map) ...[
        json['product']['primary_image_url'],
        json['product']['image_url'],
        json['product']['image'],
        json['product']['file'],
        extractFirstImageUrl(json['product']['images']),
        extractFirstImageUrl(json['product']['product_images']),
      ],
      if (json['rfq'] is Map) ...[
        json['rfq']['primary_image_url'],
        json['rfq']['image_url'],
        json['rfq']['image'],
        json['rfq']['file'],
        extractFirstImageUrl(json['rfq']['images']),
      ],
    ]);

    final rawInterests = pickNumStr([
      json['interest_count'],
      json['interested_buyers_count'],
      json['interests_count'],
      json['total_interests'],
      if (json['interests'] is List) json['interests'].length.toString(),
      if (json['offer'] is Map) json['offer']['interest_count'],
      if (json['product'] is Map)
        (json['product']['interest_count'] ??
            json['product']['interested_buyers_count']),
    ], fallback: '0');

    final rawSellerName = pickStr([
      json['seller_name'],
      json['seller_full_name'],
      if (json['seller'] is Map)
        (json['seller']['full_name'] ??
            json['seller']['username'] ??
            json['seller']['name']),
      if (json['company'] is Map)
        (json['company']['legal_name'] ?? json['company']['trade_name']),
    ]);

    final isRfqItem =
        json.containsKey('rfq_id') ||
        json.containsKey('required_quantity') ||
        json.containsKey('target_price') ||
        json.containsKey('visible_branches') ||
        (json['status']?.toString().toLowerCase() == 'open' &&
            json.containsKey('commodity'));

    // Format display price e.g. "₹60.00/TON"
    String formattedPrice = '';
    if (rawPrice.isNotEmpty) {
      final cleanP = rawPrice.replaceAll('₹', '').trim();
      final unitStr = rawAmountUnit.isNotEmpty
          ? rawAmountUnit.toUpperCase()
          : rawUnit.toUpperCase();
      formattedPrice = '₹$cleanP/$unitStr';
    }

    // Format display quantity e.g. "20.100 QTL"
    String formattedQuantity = '';
    final num? finalAvailNum = num.tryParse(
      rawAvailableQuantity.replaceAll(RegExp(r'[^\d.]'), ''),
    );
    if (finalAvailNum != null && finalAvailNum > 0) {
      final unitUpper = rawUnit.toUpperCase();
      formattedQuantity = '${finalAvailNum.toStringAsFixed(3)} $unitUpper';
    } else if (rawAvailableQuantity.isNotEmpty &&
        rawAvailableQuantity != '0' &&
        rawAvailableQuantity != '0.0' &&
        rawAvailableQuantity != '0.000') {
      final unitUpper = rawUnit.toUpperCase();
      formattedQuantity = rawAvailableQuantity.toUpperCase().contains(unitUpper)
          ? rawAvailableQuantity
          : '$rawAvailableQuantity $unitUpper';
    } else if (parsedBagsNum != null &&
        parsedBagsNum > 0 &&
        parsedPackingNum != null &&
        parsedPackingNum > 0) {
      final calcQtl = (parsedBagsNum * parsedPackingNum) / 100.0;
      formattedQuantity = '${calcQtl.toStringAsFixed(3)} QTL';
      rawAvailableQuantity = calcQtl.toStringAsFixed(3);
    } else if (rawRequestedQuantity.isNotEmpty) {
      final num? reqNum = num.tryParse(
        rawRequestedQuantity.replaceAll(RegExp(r'[^\d.]'), ''),
      );
      if (reqNum != null && reqNum > 0) {
        final unitUpper = rawUnit.toUpperCase();
        formattedQuantity = '${reqNum.toStringAsFixed(3)} $unitUpper';
      } else {
        formattedQuantity = rawRequestedQuantity;
      }
    } else if (parsedBagsNum != null && parsedBagsNum > 0) {
      formattedQuantity = '$parsedBagsNum Bags';
    } else {
      formattedQuantity = '0.000 QTL';
      if (rawAvailableQuantity.isEmpty) {
        rawAvailableQuantity = '0.000';
      }
    }

    // Earliest expiry wins: once any of the offer's deadlines has passed it is no longer live.
    DateTime? parsedExpiry;
    for (final candidate in expiryCandidates(json)) {
      final parsed = parseExpiry(candidate);
      if (parsed != null && (parsedExpiry == null || parsed.isBefore(parsedExpiry))) {
        parsedExpiry = parsed;
      }
    }

    bool detectedExpired = boolValue('is_expired', fallback: false) ||
        rawStatus.toLowerCase().contains('expire') ||
        (json['status']?.toString().toLowerCase().contains('expire') ?? false) ||
        (json['deal_status']?.toString().toLowerCase().contains('expire') ?? false);

    if (parsedExpiry != null && parsedExpiry.isBefore(DateTime.now())) {
      detectedExpired = true;
    }

    final statusCandidates = [
      json['status'],
      json['status_code'],
      json['product_status'],
      if (json['product'] is Map) ...[
        json['product']['status'],
        json['product']['status_code'],
        json['product']['product_status'],
      ],
      if (json['offer'] is Map) ...[
        json['offer']['status'],
        json['offer']['status_code'],
      ],
    ];

    bool statusSaysInactive = false;
    for (final sc in statusCandidates) {
      if (sc != null) {
        final s = sc.toString().trim().toLowerCase();
        if (s == 'inactive' ||
            s == 'disabled' ||
            s == 'hidden' ||
            s == 'deactivated' ||
            s == 'deactivate' ||
            s == 'archived' ||
            s == 'deleted') {
          statusSaysInactive = true;
          break;
        }
      }
    }

    final visibilityStr = pickStr([
      json['visibility'],
      if (json['product'] is Map) json['product']['visibility'],
      if (json['offer'] is Map) json['offer']['visibility'],
    ]).toLowerCase().trim();
    final bool visibilityDisabled = visibilityStr == 'hidden' ||
        visibilityStr == 'disabled' ||
        visibilityStr == 'inactive' ||
        visibilityStr == 'private' ||
        visibilityStr == 'off' ||
        visibilityStr == 'false' ||
        visibilityStr == '0';

    final bool detectedActive = !statusSaysInactive &&
        !visibilityDisabled &&
        boolValue('is_active', fallback: true) &&
        boolValue('is_visible', fallback: true) &&
        boolValue('visible', fallback: true);

    final stockStatusCandidates = [
      json['stock_status'],
      json['product_stock_status'],
      if (json['product'] is Map) json['product']['stock_status'],
      if (json['offer'] is Map) json['offer']['stock_status'],
    ];

    bool detectedOutOfStock = boolValue('is_out_of_stock', fallback: false) ||
        boolValue('out_of_stock', fallback: false) ||
        rawStatus.toLowerCase().contains('out_of_stock') ||
        rawStatus.toLowerCase().contains('out of stock') ||
        rawStatus.toLowerCase().contains('sold_out') ||
        rawStatus.toLowerCase().contains('sold out');

    if (!detectedOutOfStock) {
      for (final ssc in stockStatusCandidates) {
        if (ssc != null) {
          final s = ssc.toString().toLowerCase().trim();
          if (s.contains('out_of_stock') ||
              s.contains('out of stock') ||
              s.contains('sold_out') ||
              s.contains('sold out') ||
              s.contains('no_stock')) {
            detectedOutOfStock = true;
            break;
          }
        }
      }
    }

    if (!detectedOutOfStock && !isRfqItem) {
      final num? parsedQty = num.tryParse(rawAvailableQuantity.replaceAll(RegExp(r'[^\d.]'), ''));
      if (parsedQty != null && parsedQty <= 0 && rawAvailableQuantity.isNotEmpty) {
        final num? parsedBags = num.tryParse(rawBags.replaceAll(RegExp(r'[^\d.]'), ''));
        if (parsedBags == null || parsedBags <= 0) {
          detectedOutOfStock = true;
        }
      }
    }

    String formattedStatus = rawStatus.trim();
    if (detectedExpired) {
      formattedStatus = 'Deal Expired';
    } else if (detectedOutOfStock) {
      formattedStatus = 'OUT OF STOCK';
    } else if (!detectedActive) {
      formattedStatus = 'INACTIVE';
    } else if (formattedStatus.isEmpty) {
      formattedStatus = isRfqItem ? 'OPEN' : 'ACTIVE';
    } else {
      formattedStatus = formattedStatus.replaceAll('_', ' ').toUpperCase();
      if (formattedStatus == 'AVAILABLE') {
        formattedStatus = 'ACTIVE';
      }
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
      availableQuantity: rawAvailableQuantity.isNotEmpty
          ? rawAvailableQuantity
          : rawRequestedQuantity,
      requestedQuantity: rawRequestedQuantity.isNotEmpty
          ? rawRequestedQuantity
          : rawAvailableQuantity,
      quantityUnit: rawUnit,
      requestedAmount: rawPrice,
      amountUnit: rawAmountUnit,
      bagCount: rawBags,
      packingWeight: rawPacking,
      pickupFrom: rawPickupFrom,
      pickupTo: rawPickupTo,
      expiryDate: rawExpiry,
      status: detectedExpired
          ? 'deal_expired'
          : (detectedOutOfStock
              ? 'out_of_stock'
              : (!detectedActive ? 'inactive' : rawStatus)),
      createdAt: formatDateDisplay(
        pickStr([
          json['created_at'],
          json['interest_date'],
          json['interest_datetime'],
          json['created_datetime'],
          json['updated_at'],
        ]),
        withTime: false,
      ),
      imageUrl: rawImage,
      interestCount: rawInterests,
      sellerName: rawSellerName,
      canEditInterest: boolValue(
        'can_edit',
        fallback: normalizedStatus == 'interested',
      ),
      canCancelInterest: boolValue(
        'can_cancel',
        fallback: normalizedStatus == 'interested',
      ),
      canOpenNegotiation: terminal
          ? false
          : boolValue(
              'can_open_negotiation',
              fallback: defaultBuyerDecision,
            ),
      canBuyerAccept: boolValue(
        'can_buyer_accept',
        fallback: defaultBuyerDecision,
      ),
      canBuyerReject: boolValue(
        'can_buyer_reject',
        fallback: defaultBuyerDecision,
      ),
      hasSellerProposal: boolValue(
        'has_seller_proposal',
        fallback: defaultBuyerDecision,
      ),
      location: rawLocationCandidate,
      displayTitle: rawTitle,
      displayStatus: formattedStatus,
      displayQuantity: formattedQuantity,
      displayPrice: formattedPrice,
      isRfq: isRfqItem,
      isActive: detectedActive,
      isExpired: detectedExpired,
      expiresAt: parsedExpiry,
    );
  }

  bool get isInterested {
    final s = (displayStatus ?? status ?? '').toString().toLowerCase().trim();
    return s == 'interested' || s.contains('interest');
  }

  bool get isConfirmed {
    final s = (displayStatus ?? status ?? '').toString().toLowerCase();
    return s.contains('confirm') ||
        s.contains('deal_confirmed') ||
        s.contains('approved');
  }

  bool get isRejected {
    if (isExpired) return true;
    final s = (displayStatus ?? status ?? '').toString().toLowerCase();
    return s.contains('reject') ||
        s.contains('cancel') ||
        s.contains('closed') ||
        s.contains('expire');
  }

  bool get isOutOfStock {
    final s = (displayStatus ?? status ?? '')
        .toString()
        .toUpperCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
    if (s.contains('OUT OF STOCK') ||
        s.contains('SOLD OUT') ||
        s.contains('NO STOCK')) {
      return true;
    }
    final rawS = (status ?? '').toString().toUpperCase();
    if (rawS.contains('OUT_OF_STOCK') || rawS.contains('SOLD_OUT')) {
      return true;
    }
    final num? qty = num.tryParse(
      (availableQuantity ?? '').replaceAll(RegExp(r'[^\d.]'), ''),
    );
    if (qty != null && qty <= 0 && !isRfq && (availableQuantity ?? '').isNotEmpty) {
      final num? bags = num.tryParse(
        (bagCount ?? '').replaceAll(RegExp(r'[^\d.]'), ''),
      );
      if (bags == null || bags <= 0) {
        return true;
      }
    }
    return false;
  }

  bool get canSubmitOffer =>
      isActive &&
      !isOutOfStock &&
      !isConfirmed &&
      !isRejected &&
      !isExpired;

  bool get isActionable => !isConfirmed && !isRejected;
}
