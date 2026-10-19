import 'package:daalsetu/modules/seller/products/model/seller_product_model.dart';
import 'package:daalsetu/modules/seller/products/service/seller_offer_export_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seller offer export creates a styled and readable Excel workbook', () {
    final workbook = SellerOfferExportService.buildWorkbook(
      generatedAt: DateTime(2026, 10, 18, 20, 24),
      products: [
        SellerProductModel(
          id: 146,
          title: 'Premium Toor Dal Offer',
          description: 'Export test',
          categoryId: 4,
          categoryName: 'Toor Dal',
          brandName: '24 Mantra Organic',
          amount: '1000.00',
          unit: 'kg',
          status: 'out_of_stock',
          isActive: true,
          isExpired: false,
          interestCount: 2,
          bagCount: 67,
          packingWeight: 30,
          loadingLocation: 'Nagpur, Maharashtra, India',
          imageUrls: const [],
          createdAt: DateTime(2026, 10, 15),
        ),
      ],
    );

    expect(workbook.sheets.keys, contains(SellerOfferExportService.sheetName));
    expect(workbook.sheets.keys, isNot(contains('Sheet1')));

    final sheet = workbook[SellerOfferExportService.sheetName];
    CellValue? valueAt(int column, int row) => sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
        .value;

    expect(valueAt(0, 0).toString(), 'DaalSetu Seller Offers');
    expect(valueAt(0, 1).toString(), 'Generated on: 18 Oct 2026, 08:24 PM');
    expect(valueAt(0, 3).toString(), 'Title');
    expect(valueAt(9, 3).toString(), 'Buyer Interests');
    expect(valueAt(0, 4).toString(), 'Premium Toor Dal Offer');
    expect(valueAt(5, 4).toString(), 'Out Of Stock');
    expect(valueAt(6, 4), const IntCellValue(67));
    expect(valueAt(7, 4), const DoubleCellValue(30));

    expect(sheet.getColumnWidth(0), 30);
    expect(sheet.getColumnWidth(1), 22);
    expect(sheet.getColumnWidth(2), 25);
    expect(sheet.getColumnWidth(8), 32);

    final titleStyle = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle;
    final headerStyle = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .cellStyle;
    expect(titleStyle?.isBold, isTrue);
    expect(titleStyle?.fontColor.colorHex, 'FFFFFFFF');
    expect(headerStyle?.isBold, isTrue);
    expect(headerStyle?.backgroundColor.colorHex, 'FFF97316');

    final bytes = workbook.save();
    expect(bytes, isNotNull);
    expect(bytes, isNotEmpty);
  });
}
