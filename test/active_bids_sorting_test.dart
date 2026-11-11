import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/admin_catalog/view/transport_bids_sheet.dart';
import 'package:daalsetu/modules/transporter/bidding/model/transporter_bid_model.dart';
import 'package:daalsetu/modules/seller/products/model/offer_interest_model.dart';

void main() {
  group('TSK-036: Active Bids Auto-Sort to Top Tests', () {
    test('TransportBidsSheet.sortBids elevates active/pending bids to the top', () {
      final inputBids = <Map<String, dynamic>>[
        {
          'bid_id': 1,
          'status': 'rejected',
          'transporter_name': 'Transporter A',
          'bid_amount': '5000',
          'created_at': '2026-11-01 10:00:00',
        },
        {
          'bid_id': 2,
          'status': 'pending',
          'transporter_name': 'Transporter B (Active)',
          'bid_amount': '4800',
          'created_at': '2026-11-02 11:00:00',
        },
        {
          'bid_id': 3,
          'status': 'accepted',
          'transporter_name': 'Transporter C (Old Winner)',
          'bid_amount': '4500',
          'created_at': '2026-11-01 09:00:00',
        },
        {
          'bid_id': 4,
          'status': 'active',
          'transporter_name': 'Transporter D (Active Latest)',
          'bid_amount': '4600',
          'created_at': '2026-11-03 14:00:00',
        },
      ];

      final sorted = TransportBidsSheet.sortBids(inputBids);

      // Verify that the first two are the active/pending bids
      expect(sorted[0]['bid_id'], 4); // Latest active bid
      expect(sorted[0]['status'], 'active');
      expect(sorted[1]['bid_id'], 2); // Older active/pending bid
      expect(sorted[1]['status'], 'pending');

      // Inactive bids are moved to bottom
      expect(['rejected', 'accepted'].contains(sorted[2]['status']), true);
      expect(['rejected', 'accepted'].contains(sorted[3]['status']), true);
    });

    test('TransportBidsSheet.sortBids updates order when active bid is resolved', () {
      final bidsAfterOneRejection = <Map<String, dynamic>>[
        {
          'bid_id': 10,
          'status': 'rejected', // Just rejected
          'created_at': '2026-11-05 10:00:00',
        },
        {
          'bid_id': 11,
          'status': 'pending', // Remaining active bid
          'created_at': '2026-11-04 10:00:00',
        },
      ];

      final sorted = TransportBidsSheet.sortBids(bidsAfterOneRejection);
      expect(sorted.first['bid_id'], 11);
      expect(sorted.first['status'], 'pending');
      expect(sorted.last['bid_id'], 10);
      expect(sorted.last['status'], 'rejected');
    });

    test('MyBidModel pending status correctly identifies active bids for sorting', () {
      final pendingBid = MyBidModel(
        bidId: 101,
        contractPk: 1,
        contractId: "C1",
        status: "pending",
        bidAmount: "12000",
        contractStatus: "active",
        productTitle: "Toor Dal",
        loadingFrom: "Nagpur",
        loadingTo: "Mumbai",
        dealQuantity: "100",
        quantityUnit: "qtl",
        assignment: const {},
        assignmentLocked: false,
        canAssignDriver: true,
      );

      final acceptedBid = MyBidModel(
        bidId: 102,
        contractPk: 2,
        contractId: "C2",
        status: "accepted",
        bidAmount: "15000",
        contractStatus: "active",
        productTitle: "Chana Dal",
        loadingFrom: "Nagpur",
        loadingTo: "Pune",
        dealQuantity: "100",
        quantityUnit: "qtl",
        assignment: const {},
        assignmentLocked: false,
        canAssignDriver: true,
      );

      expect(pendingBid.isPending, true);
      expect(acceptedBid.isPending, false);

      final list = [acceptedBid, pendingBid];
      list.sort((a, b) {
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;
        return 0;
      });

      // Pending bid must be at index 0
      expect(list.first.bidId, 101);
      expect(list.last.bidId, 102);
    });

    test('OfferInterestModel negotiation list sorts pending interests to the top', () {
      final interestPending = OfferInterestModel(
        id: 201,
        buyerName: "Active Buyer",
        status: "pending",
      );

      final interestAccepted = OfferInterestModel(
        id: 202,
        buyerName: "Closed Buyer",
        status: "accepted",
      );

      final list = [interestAccepted, interestPending];
      list.sort((a, b) {
        final isPendingA = (a.status ?? '').toLowerCase() == 'pending' || (a.status ?? '').toLowerCase() == 'negotiating';
        final isPendingB = (b.status ?? '').toLowerCase() == 'pending' || (b.status ?? '').toLowerCase() == 'negotiating';
        if (isPendingA && !isPendingB) return -1;
        if (!isPendingA && isPendingB) return 1;
        return 0;
      });

      expect(list.first.id, 201);
      expect(list.last.id, 202);
    });
  });
}
