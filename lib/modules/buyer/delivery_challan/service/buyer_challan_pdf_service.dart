import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../model/buyer_delivery_challan_model.dart';

class BuyerChallanPdfService {
  const BuyerChallanPdfService._();

  static const MethodChannel _downloadsChannel = MethodChannel(
    'com.zappcode.daalsetu/downloads',
  );

  /// Saves a generated challan PDF to the device Downloads folder.
  static Future<String> download(BuyerDeliveryChallanModel challan) =>
      downloadAndShare(challan, openShareSheet: false);

  /// Generates the same buyer-visible challan data as a portable PDF. When
  /// [openShareSheet] is true it opens the native share sheet; otherwise it
  /// saves the file directly to Downloads on Android.
  static Future<String> downloadAndShare(
    BuyerDeliveryChallanModel challan,
    {bool openShareSheet = true,}
  ) async {
    final document = pw.Document();
    final company = challan.company;
    final itemRows = (challan.items ?? const <DeliveryChallanItem>[])
        .map(
          (item) => <String>[
            item.productName ?? '-',
            '${item.quantity ?? '-'} ${item.unit ?? ''}'.trim(),
            item.bagCount?.toString() ?? '-',
            item.packingWeightKg ?? '-',
            item.rate ?? '-',
            item.amount ?? '-',
          ],
        )
        .toList();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    company?.legalName ?? 'DaalSetu',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if ((company?.addressDisplay ?? '').isNotEmpty)
                    pw.Text(
                      company!.addressDisplay!,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  if ((company?.gstNumber ?? '').isNotEmpty)
                    pw.Text(
                      'GST: ${company!.gstNumber}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'DELIVERY CHALLAN',
                    style: pw.TextStyle(
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('No: ${challan.challanNumber ?? '-'}'),
                  pw.Text('Date: ${challan.challanDate ?? '-'}'),
                  pw.Text('Status: ${(challan.status ?? '-').toUpperCase()}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _partyPanel(
                  'Seller',
                  challan.sellerName,
                  challan.sellerAddress,
                  challan.sellerGst,
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: _partyPanel(
                  'Buyer',
                  challan.buyerName,
                  challan.buyerAddress,
                  challan.buyerGst,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Transport Details',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Vehicle: ${challan.truckNumber ?? '-'}   •   Driver: ${challan.driverName ?? '-'}   •   Mobile: ${challan.driverMobile ?? '-'}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Product',
              'Quantity',
              'Bags',
              'Packing KG',
              'Rate',
              'Amount',
            ],
            data: itemRows.isEmpty
                ? const [
                    ['No item details available', '-', '-', '-', '-', '-'],
                  ]
                : itemRows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey500, width: .4),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey500),
              ),
              child: pw.Text(
                'Total Amount: ₹${challan.totalAmount ?? '0.00'}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
          if ((challan.narration ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'Narration',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(challan.narration!, style: const pw.TextStyle(fontSize: 9)),
          ],
          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.Text(
            'Generated from DaalSetu',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    final safeNumber =
        (challan.challanNumber ?? challan.id?.toString() ?? 'challan')
            .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final fileName = 'Delivery-Challan-$safeNumber.pdf';
    final pdfBytes = await document.save();

    if (!openShareSheet && Platform.isAndroid) {
      try {
        final savedUri = await _downloadsChannel.invokeMethod<String>(
          'savePdfToDownloads',
          <String, dynamic>{'fileName': fileName, 'bytes': pdfBytes},
        );
        if (savedUri != null && savedUri.isNotEmpty) return savedUri;
      } on PlatformException {
        // Fall back to app documents below when an older device blocks
        // public Downloads access.
      }
    }

    final directory = openShareSheet
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);
    if (!openShareSheet) return file.path;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Delivery Challan ${challan.challanNumber ?? ''}'.trim(),
        text: 'Delivery challan generated from DaalSetu.',
      ),
    );
    return file.path;
  }

  static pw.Widget _partyPanel(
    String label,
    String? name,
    String? address,
    String? gst,
  ) => pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey500),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(name ?? '-', style: const pw.TextStyle(fontSize: 9)),
        pw.Text(address ?? '-', style: const pw.TextStyle(fontSize: 8)),
        if ((gst ?? '').isNotEmpty)
          pw.Text('GST: $gst', style: const pw.TextStyle(fontSize: 8)),
      ],
    ),
  );
}
