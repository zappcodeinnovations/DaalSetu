/// Contract open for freight bidding (GET /api/transport-bids/?view=open, web "Active Shipment Offer's").
class ShipmentOfferModel {
  final int id;
  final String contractId;
  final String productTitle;
  final String pickupLocation;
  final String deliveryLocation;
  final String loadingDateRange;
  final String? expectedDeliveryDate;
  final String dealQuantity;
  final String quantityUnit;
  final int? bagCount;
  final String? packingWeightKg;
  final String? currentLowestBid;
  final String? myBid;
  final String? myBidStatus;
  final int? myBidPosition;
  final int activeBidCount;

  ShipmentOfferModel({
    required this.id,
    required this.contractId,
    required this.productTitle,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.loadingDateRange,
    this.expectedDeliveryDate,
    required this.dealQuantity,
    required this.quantityUnit,
    this.bagCount,
    this.packingWeightKg,
    this.currentLowestBid,
    this.myBid,
    this.myBidStatus,
    this.myBidPosition,
    required this.activeBidCount,
  });

  factory ShipmentOfferModel.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key];
      return value == null || '$value'.isEmpty ? null : '$value';
    }

    return ShipmentOfferModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      contractId: text('contract_id') ?? '${json['id']}',
      productTitle: text('product_title') ?? 'Consignment',
      pickupLocation: text('pickup_location') ?? '-',
      deliveryLocation: text('delivery_location') ?? '-',
      loadingDateRange: text('loading_date_range') ?? '-',
      expectedDeliveryDate: text('expected_delivery_date'),
      dealQuantity: text('deal_quantity') ?? '-',
      quantityUnit: text('quantity_unit') ?? '',
      bagCount: json['bag_count'] is int ? json['bag_count'] : null,
      packingWeightKg: text('packing_weight_kg'),
      currentLowestBid: text('current_lowest_bid'),
      myBid: text('my_bid'),
      myBidStatus: text('my_bid_status'),
      myBidPosition: json['my_bid_position'] is int ? json['my_bid_position'] : null,
      activeBidCount: json['active_bid_count'] is int ? json['active_bid_count'] : 0,
    );
  }
}

/// One of my bids (GET /api/transport-bids/?view=mine, web "My Deals").
class MyBidModel {
  final int bidId;
  final String status;
  final String bidAmount;
  final String? adminRemark;
  final String? createdAt;
  final int contractPk;
  final String contractId;
  final String contractStatus;
  final String productTitle;
  final String loadingFrom;
  final String loadingTo;
  final String dealQuantity;
  final String quantityUnit;
  final int? assignedVehicleId;
  final int? assignedDriverId;
  final Map<String, String> assignment;
  final bool assignmentLocked;
  final bool canAssignDriver;

  MyBidModel({
    required this.bidId,
    required this.status,
    required this.bidAmount,
    this.adminRemark,
    this.createdAt,
    required this.contractPk,
    required this.contractId,
    required this.contractStatus,
    required this.productTitle,
    required this.loadingFrom,
    required this.loadingTo,
    required this.dealQuantity,
    required this.quantityUnit,
    this.assignedVehicleId,
    this.assignedDriverId,
    required this.assignment,
    required this.assignmentLocked,
    required this.canAssignDriver,
  });

  factory MyBidModel.fromJson(Map<String, dynamic> json) {
    final contract = json['contract'] is Map ? json['contract'] as Map : const {};
    final assignment = json['assignment'] is Map ? json['assignment'] as Map : const {};
    return MyBidModel(
      bidId: json['bid_id'] is int ? json['bid_id'] : int.tryParse('${json['bid_id']}') ?? 0,
      status: '${json['status'] ?? 'pending'}',
      bidAmount: '${json['bid_amount'] ?? '-'}',
      adminRemark: '${json['admin_remark'] ?? ''}'.isEmpty ? null : '${json['admin_remark']}',
      createdAt: json['created_at']?.toString(),
      contractPk: contract['id'] is int ? contract['id'] : 0,
      contractId: '${contract['contract_id'] ?? '-'}',
      contractStatus: '${contract['status'] ?? ''}',
      productTitle: '${contract['product_title'] ?? 'Consignment'}',
      loadingFrom: '${contract['loading_from'] ?? '-'}',
      loadingTo: '${contract['loading_to'] ?? '-'}',
      dealQuantity: '${contract['deal_quantity'] ?? '-'}',
      quantityUnit: '${contract['quantity_unit'] ?? ''}',
      assignedVehicleId: json['assigned_vehicle_id'] is int ? json['assigned_vehicle_id'] : null,
      assignedDriverId: json['assigned_driver_id'] is int ? json['assigned_driver_id'] : null,
      assignment: {for (final e in assignment.entries) '${e.key}': '${e.value ?? ''}'},
      assignmentLocked: json['assignment_locked'] == true,
      canAssignDriver: json['can_assign_driver'] == true ||
          ('${json['status']}'.toLowerCase() == 'accepted' && json['assignment_locked'] != true),
    );
  }
}

class FleetOption {
  final int id;
  final String label;
  final int? linkedVehicleId;
  const FleetOption(this.id, this.label, {this.linkedVehicleId});
}
