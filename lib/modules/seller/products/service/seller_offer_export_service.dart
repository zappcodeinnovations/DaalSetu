import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/seller_product_model.dart';

class SellerOfferExportService {
  static const sheetName = 'Seller Offers';

  static Excel buildWorkbook({
    required List<SellerProductModel> products,
    required DateTime generatedAt,
  }) {
    final workbook = Excel.createExcel();
    final sheet = workbook[sheetName];
    workbook.setDefaultSheet(sheetName);
    if (workbook.sheets.containsKey('Sheet1')) {
      workbook.delete('Sheet1');
    }

    const columnWidths = <double>[30, 22, 25, 14, 14, 18, 18, 16, 32, 18];
    for (var column = 0; column < columnWidths.length; column++) {
      sheet.setColumnWidth(column, columnWidths[column]);
    }
    sheet.setRowHeight(0, 28);
    sheet.setRowHeight(1, 22);
    sheet.setRowHeight(3, 24);

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1E293B'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final timestampStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#7C2D12'),
      backgroundColorHex: ExcelColor.fromHexString('#FEF3C7'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#F97316'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    CellStyle dataStyle({required bool alternate, required bool numeric}) {
      return CellStyle(
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        backgroundColorHex: ExcelColor.fromHexString(
          alternate ? '#F8FAFC' : '#FFFFFF',
        ),
        horizontalAlign: numeric ? HorizontalAlign.Right : HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      );
    }

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0),
      customValue: TextCellValue('DaalSetu Seller Offers'),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 1),
      customValue: TextCellValue(
        'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(generatedAt)}',
      ),
    );
    for (var column = 0; column < 10; column++) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
              )
              .cellStyle =
          titleStyle;
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 1),
              )
              .cellStyle =
          timestampStyle;
    }

    const headers = <String>[
      'Title',
      'Category',
      'Brand',
      'Price',
      'Price Unit',
      'Status',
      'Available Bags',
      'Packing (KG)',
      'Location',
      'Buyer Interests',
    ];
    for (var column = 0; column < headers.length; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 3),
      );
      cell.value = TextCellValue(headers[column]);
      cell.cellStyle = headerStyle;
    }

    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      final row = index + 4;
      sheet.setRowHeight(row, 22);
      final price = double.tryParse(product.amount.replaceAll(',', '').trim());
      final values = <CellValue>[
        TextCellValue(product.title),
        TextCellValue(product.categoryName ?? ''),
        TextCellValue(product.brandName ?? ''),
        price == null ? TextCellValue(product.amount) : DoubleCellValue(price),
        TextCellValue(product.unit.toUpperCase()),
        TextCellValue(_displayStatus(product.status)),
        IntCellValue(product.bagCount),
        DoubleCellValue(product.packingWeight),
        TextCellValue(product.loadingLocation),
        IntCellValue(product.interestCount),
      ];

      for (var column = 0; column < values.length; column++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
        );
        cell.value = values[column];
        cell.cellStyle = dataStyle(
          alternate: index.isOdd,
          numeric: const {3, 6, 7, 9}.contains(column),
        );
      }
    }

    return workbook;
  }

  static Future<String> exportAndShare({
    required List<SellerProductModel> products,
  }) async {
    final generatedAt = DateTime.now();
    final workbook = buildWorkbook(
      products: products,
      generatedAt: generatedAt,
    );
    final bytes = workbook.save();
    if (bytes == null) {
      throw StateError('Unable to generate the Excel file.');
    }

    final directory = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(generatedAt);
    final path = '${directory.path}/DaalSetu_Seller_Offers_$stamp.xlsx';
    await File(path).writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'DaalSetu Seller Offers',
        text: 'Seller offers Excel export generated from DaalSetu.',
      ),
    );
    return path;
  }

  static String _displayStatus(String value) {
    return value
        .trim()
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
