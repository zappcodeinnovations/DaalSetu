import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/contracts/model/contract_model.dart';
import 'package:daalsetu/modules/contracts/view/contract_view.dart';
import 'package:daalsetu/modules/users/controller/user_controller.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/repository/drawer_menu_service.dart';
import 'package:daalsetu/modules/buyer/consignment/view/buyer_consignment_view.dart';
import 'package:daalsetu/modules/seller/consignments/view/seller_consignments_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 14 Bug 1: Contracts In-Transit Filter', () {
    test('isContractInTransit correctly identifies in-transit contracts', () {
      final activeNoTransport = ContractModel(
        id: 1,
        productTitle: 'YELLOW DAAL',
        productCategory: 'Pulse',
        contractId: 'JBC2611188157',
        buyerName: 'Buyer',
        sellerName: 'Seller',
        displayBuyerId: 'B01',
        displaySellerId: 'S01',
        dealAmount: '6375',
        dealQuantity: '85',
        amountUnit: 'INR',
        quantityUnit: 'qtl',
        loadingFrom: 'Nagpur',
        loadingTo: 'Pune',
        status: 'active',
        createdAt: '2026-11-19',
      );
      expect(ContractsScreen.isContractInTransit(activeNoTransport), isFalse);

      final inTransitStatus = ContractModel(
        id: 2,
        productTitle: 'YELLOW DAAL',
        productCategory: 'Pulse',
        contractId: 'JBC2611188158',
        buyerName: 'Buyer',
        sellerName: 'Seller',
        displayBuyerId: 'B01',
        displaySellerId: 'S01',
        dealAmount: '6375',
        dealQuantity: '85',
        amountUnit: 'INR',
        quantityUnit: 'qtl',
        loadingFrom: 'Nagpur',
        loadingTo: 'Pune',
        status: 'in_transit',
        createdAt: '2026-11-19',
      );
      expect(ContractsScreen.isContractInTransit(inTransitStatus), isTrue);

      final contractWithTransporter = ContractModel(
        id: 3,
        productTitle: 'YELLOW DAAL',
        productCategory: 'Pulse',
        contractId: 'JBC2611188159',
        buyerName: 'Buyer',
        sellerName: 'Seller',
        displayBuyerId: 'B01',
        displaySellerId: 'S01',
        dealAmount: '6375',
        dealQuantity: '85',
        amountUnit: 'INR',
        quantityUnit: 'qtl',
        loadingFrom: 'Nagpur',
        loadingTo: 'Pune',
        status: 'active',
        transporterName: 'Wildernest Logistics',
        createdAt: '2026-11-19',
      );
      expect(ContractsScreen.isContractInTransit(contractWithTransporter), isTrue);

      final contractWithChallan = ContractModel(
        id: 4,
        productTitle: 'YELLOW DAAL',
        productCategory: 'Pulse',
        contractId: 'JBC2611188160',
        buyerName: 'Buyer',
        sellerName: 'Seller',
        displayBuyerId: 'B01',
        displaySellerId: 'S01',
        dealAmount: '6375',
        dealQuantity: '85',
        amountUnit: 'INR',
        quantityUnit: 'qtl',
        loadingFrom: 'Nagpur',
        loadingTo: 'Pune',
        status: 'active',
        hasDeliveryChallan: true,
        createdAt: '2026-11-19',
      );
      expect(ContractsScreen.isContractInTransit(contractWithChallan), isTrue);

      final completedContract = ContractModel(
        id: 5,
        productTitle: 'YELLOW DAAL',
        productCategory: 'Pulse',
        contractId: 'JBC2611188161',
        buyerName: 'Buyer',
        sellerName: 'Seller',
        displayBuyerId: 'B01',
        displaySellerId: 'S01',
        dealAmount: '6375',
        dealQuantity: '85',
        amountUnit: 'INR',
        quantityUnit: 'qtl',
        loadingFrom: 'Nagpur',
        loadingTo: 'Pune',
        status: 'completed',
        transporterName: 'Wildernest Logistics',
        createdAt: '2026-11-19',
      );
      expect(ContractsScreen.isContractInTransit(completedContract), isFalse);
    });
  });

  group('Batch 14 Bug 2: Admin User Management & Salesman Module', () {
    test('UserController role filters only expose branch user roles', () {
      expect(UserController.roleFilters, containsAll(['all', 'buyer', 'seller', 'transporter']));
      expect(UserController.roleFilters.contains('sub_admin'), isFalse);
      expect(UserController.roleFilters.contains('admin'), isFalse);
    });

    test('Salesman module is titled "Salesman" and placed under MASTERS in drawer', () async {
      expect(AdminModules.byKey('salesman').title, 'Salesman');

      final drawerSections = await DrawerMenuService().fetchMenu();
      final mastersSection = drawerSections.firstWhere((s) => s.sectionTitle == 'MASTERS');
      final salesmanItem = mastersSection.items.firstWhere(
        (i) => i.key == 'salesman' || i.key == 'sub_admins',
      );

      expect(salesmanItem.title, 'Salesman');
      expect(salesmanItem.route, '/admin/salesman');
    });
  });

  group('Batch 14 Bug 3: Consignments Filter & Stage Mapping', () {
    test('Buyer consignmentStageLabel correctly categorizes stages', () {
      final pendingItem = {
        'id': 101,
        'contract_id': 'JBC2611188157',
        'status': 'active',
        'is_dispatched': false,
        'is_delivered': false,
        'transporter_visible_at': null,
      };
      expect(consignmentStageLabel(pendingItem), 'Pending');

      final readyItem = {
        'id': 102,
        'contract_id': 'JBC2611171685',
        'status': 'active',
        'is_dispatched': false,
        'is_delivered': false,
        'transporter_visible_at': '2026-11-18 10:00:00',
      };
      expect(consignmentStageLabel(readyItem), 'Consignment Ready');

      final dispatchedItem = {
        'id': 103,
        'contract_id': 'JBC2611074575',
        'status': 'in_transit',
        'is_dispatched': true,
        'is_delivered': false,
      };
      expect(consignmentStageLabel(dispatchedItem), 'Dispatch');

      final receivedItem = {
        'id': 104,
        'contract_id': 'JBC2611074576',
        'status': 'received',
        'is_delivered': true,
      };
      expect(consignmentStageLabel(receivedItem), 'Consignment Received');
    });

    test('Seller stageOf correctly categorizes stages', () {
      expect(SellerConsignmentController.stageOf({
        'status': 'active',
        'is_dispatched': false,
        'is_delivered': false,
        'transporter_visible_at': null,
      }), 'pending');

      expect(SellerConsignmentController.stageOf({
        'status': 'active',
        'is_dispatched': false,
        'is_delivered': false,
        'transporter_visible_at': '2026-11-18',
      }), 'ready');

      expect(SellerConsignmentController.stageOf({
        'status': 'dispatched',
        'is_dispatched': true,
      }), 'dispatched');

      expect(SellerConsignmentController.stageOf({
        'status': 'received',
        'is_delivered': true,
      }), 'received');
    });
  });
}
