class ContractDetailModel {
  final int id;
  final String contractId;
  final String productTitle;
  final String productCategory;
  final String buyerName;
  final String buyerUniqueId;
  final String sellerName;
  final String sellerMappedId;
  final String displaySellerId;
  final String displayBuyerId;
  final String quantityQtl;
  final String bags;
  final String dealAmount;
  final String dealQuantity;
  final String amountUnit;
  final String quantityUnit;
  final int? bagCount;
  final String packingWeightKg;
  final String loadingFrom;
  final String loadingTo;
  final String buyerRemark;
  final String sellerRemark;
  final String adminRemark;
  final String status;
  final String confirmedAt;
  final String transporterVisibleAt;
  final String transporterVisibilityReason;
  final String readyForLoadingAt;
  final String createdAt;
  final String updatedAt;
  final int? interestId;
  final int? productId;
  final int? buyerId;
  final int? sellerId;
  final int? confirmedByAdminId;
  final int? confirmedBranchId;
  final int? createdByUserId;
  final int? assignedSubAdminId;
  final int? readyForLoadingById;

  final String? truckNumber;
  final String? driverName;
  final String? driverMobile;
  final String? driverLicenseNumber;
  final String? transporterName;
  final String? transporterMobile;
  final String? bidAmount;

  ContractDetailModel({
    required this.id,
    required this.contractId,
    required this.productTitle,
    required this.productCategory,
    required this.buyerName,
    required this.buyerUniqueId,
    required this.sellerName,
    required this.sellerMappedId,
    required this.displaySellerId,
    required this.displayBuyerId,
    required this.quantityQtl,
    required this.bags,
    required this.dealAmount,
    required this.dealQuantity,
    required this.amountUnit,
    required this.quantityUnit,
    required this.bagCount,
    required this.packingWeightKg,
    required this.loadingFrom,
    required this.loadingTo,
    required this.buyerRemark,
    required this.sellerRemark,
    required this.adminRemark,
    required this.status,
    required this.confirmedAt,
    required this.transporterVisibleAt,
    required this.transporterVisibilityReason,
    required this.readyForLoadingAt,
    required this.createdAt,
    required this.updatedAt,
    required this.interestId,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.confirmedByAdminId,
    required this.confirmedBranchId,
    required this.createdByUserId,
    required this.assignedSubAdminId,
    required this.readyForLoadingById,
    this.truckNumber,
    this.driverName,
    this.driverMobile,
    this.driverLicenseNumber,
    this.transporterName,
    this.transporterMobile,
    this.bidAmount,
  });

  factory ContractDetailModel.fromJson(Map<String, dynamic> json) {
    String text(String key) => json[key]?.toString() ?? '';
    int? number(String key) => json[key] is int
        ? json[key] as int
        : int.tryParse(json[key]?.toString() ?? '');

    // Check nested bid or transport objects
    dynamic bidObj = json['accepted_bid'] ??
        json['transport_bid'] ??
        json['accepted_transport_bid'] ??
        json['assigned_transport'] ??
        json['bid'];

    if (bidObj == null && json['bids'] is List && (json['bids'] as List).isNotEmpty) {
      final list = json['bids'] as List;
      bidObj = list.firstWhere(
        (b) => b is Map && (b['status'] == 'accepted' || b['is_accepted'] == true),
        orElse: () => list.first,
      );
    }

    String transName = text('transporter_name_display');
    if (transName.isEmpty) transName = text('transporter_name');
    if (transName.isEmpty && json['transporter'] != null) {
      if (json['transporter'] is Map) {
        transName = json['transporter']['username']?.toString() ?? json['transporter']['name']?.toString() ?? '';
      } else {
        transName = json['transporter'].toString();
      }
    }

    String? truck = text('truck_number').isNotEmpty ? text('truck_number') : (text('vehicle_number').isNotEmpty ? text('vehicle_number') : null);
    String? driver = text('driver_name').isNotEmpty ? text('driver_name') : null;
    String? driverMobile = text('driver_mobile').isNotEmpty ? text('driver_mobile') : (text('driver_phone').isNotEmpty ? text('driver_phone') : null);
    String? license = text('driver_license_number').isNotEmpty ? text('driver_license_number') : (text('driver_license').isNotEmpty ? text('driver_license') : null);
    String? bidAmt = text('bid_amount').isNotEmpty ? text('bid_amount') : (text('accepted_bid_amount').isNotEmpty ? text('accepted_bid_amount') : null);

    // If direct fields were empty, extract from nested bid object
    if (bidObj is Map) {
      if (transName.isEmpty) {
        if (bidObj['transporter'] is Map) {
          transName = bidObj['transporter']['username']?.toString() ?? bidObj['transporter']['name']?.toString() ?? '';
        } else {
          transName = bidObj['transporter_name']?.toString() ?? bidObj['transporter']?.toString() ?? '';
        }
      }
      truck ??= bidObj['truck_number']?.toString() ?? bidObj['vehicle_number']?.toString() ?? (bidObj['vehicle'] is Map ? bidObj['vehicle']['vehicle_number']?.toString() : null);
      driver ??= bidObj['driver_name']?.toString() ?? (bidObj['driver'] is Map ? bidObj['driver']['name']?.toString() : null);
      driverMobile ??= bidObj['driver_mobile']?.toString() ?? bidObj['driver_phone']?.toString() ?? (bidObj['driver'] is Map ? bidObj['driver']['mobile']?.toString() : null);
      license ??= bidObj['driver_license_number']?.toString() ?? bidObj['driver_license']?.toString() ?? (bidObj['driver'] is Map ? bidObj['driver']['license_number']?.toString() : null);
      bidAmt ??= bidObj['bid_amount']?.toString() ?? bidObj['amount']?.toString() ?? bidObj['accepted_bid_amount']?.toString();
    }

    return ContractDetailModel(
      id: number('id') ?? 0,
      contractId: text('contract_id'),
      productTitle: text('product_title'),
      productCategory: text('product_category_name'),
      buyerName: text('buyer_name'),
      buyerUniqueId: text('buyer_unique_id'),
      sellerName: text('seller_name'),
      sellerMappedId: text('seller_mapped_id'),
      displaySellerId: text('display_seller_id'),
      displayBuyerId: text('display_buyer_id'),
      quantityQtl: text('quantity_qtl'),
      bags: text('bags'),
      dealAmount: text('deal_amount'),
      dealQuantity: text('deal_quantity'),
      amountUnit: text('amount_unit'),
      quantityUnit: text('quantity_unit'),
      bagCount: number('bag_count') ?? number('bags'),
      packingWeightKg: text('packing_weight_kg'),
      loadingFrom: text('loading_from'),
      loadingTo: text('loading_to'),
      buyerRemark: text('buyer_remark'),
      sellerRemark: text('seller_remark'),
      adminRemark: text('admin_remark'),
      status: text('status'),
      confirmedAt: text('confirmed_at'),
      transporterVisibleAt: text('transporter_visible_at'),
      transporterVisibilityReason: text('transporter_visibility_reason'),
      readyForLoadingAt: text('ready_for_loading_at'),
      createdAt: text('created_at'),
      updatedAt: text('updated_at'),
      interestId: number('interest'),
      productId: number('product'),
      buyerId: number('buyer'),
      sellerId: number('seller'),
      confirmedByAdminId: number('confirmed_by_admin'),
      confirmedBranchId: number('confirmed_branch'),
      createdByUserId: number('created_by_user'),
      assignedSubAdminId: number('assigned_sub_admin'),
      readyForLoadingById: number('ready_for_loading_by'),
      truckNumber: truck,
      driverName: driver,
      driverMobile: driverMobile,
      driverLicenseNumber: license,
      transporterName: transName.isNotEmpty ? transName : null,
      transporterMobile: text('transporter_mobile').isNotEmpty ? text('transporter_mobile') : null,
      bidAmount: bidAmt,
    );
  }
}
