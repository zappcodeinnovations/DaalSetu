import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../model/admin_challan_model.dart';

class ChallanPdfResult {
  final String filePath;
  final String? downloadsUri;
  final String fileName;

  const ChallanPdfResult({
    required this.filePath,
    this.downloadsUri,
    required this.fileName,
  });
}

class AdminChallanPdfService {
  const AdminChallanPdfService._();

  static const MethodChannel _downloadsChannel = MethodChannel(
    'com.zappcode.daalsetu/downloads',
  );

  /// Saves the generated admin Delivery Challan PDF directly to Downloads folder
  /// and returns both the local path and system downloads URI.
  static Future<ChallanPdfResult> download(AdminChallanModel challan) =>
      downloadAndShare(challan, openShareSheet: false);

  /// Generates the PDF and immediately opens the system share sheet.
  static Future<ChallanPdfResult> share(AdminChallanModel challan) =>
      downloadAndShare(challan, openShareSheet: true);

  /// Direct Open (just like WhatsApp):
  /// Tries OpenFilex with application/pdf first, then native Android Intent, then fallback to Share.
  static Future<bool> openPdf(String filePath, {String? uri}) async {
    try {
      final result = await OpenFilex.open(filePath, type: 'application/pdf');
      if (result.type == ResultType.done) {
        return true;
      }
      if (uri != null && uri.isNotEmpty && Platform.isAndroid) {
        final opened = await _downloadsChannel.invokeMethod<bool>(
          'openPdfUri',
          <String, dynamic>{'uri': uri},
        );
        if (opened == true) return true;
      }
    } catch (_) {
      // Fallback below
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/pdf')],
          subject: 'Delivery Challan',
          text: 'Delivery challan from DaalSetu.',
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Generates the official Delivery Challan PDF and opens the native share sheet
  /// or saves it to device downloads folder.
  static Future<ChallanPdfResult> downloadAndShare(
    AdminChallanModel challan, {
    bool openShareSheet = true,
  }) async {
    final document = pw.Document();

    final itemRows = challan.items.map((item) {
      return <String>[
        item.productName.isNotEmpty ? item.productName : challan.displayCommodity,
        '${item.quantity > 0 ? item.quantity.toString() : challan.displayQuantity} ${item.unit}'.trim(),
        item.bagCount > 0 ? item.bagCount.toString() : (challan.displayBagCount > 0 ? challan.displayBagCount.toString() : '-'),
        item.packingWeight > 0 ? '${item.packingWeight} Kg' : '-',
        item.rate > 0 ? 'Rs. ${item.rate.toStringAsFixed(2)}' : '-',
        item.amount > 0 ? 'Rs. ${item.amount.toStringAsFixed(2)}' : (challan.totalAmount > 0 ? 'Rs. ${challan.totalAmount.toStringAsFixed(2)}' : '-'),
      ];
    }).toList();

    if (itemRows.isEmpty) {
      itemRows.add([
        challan.displayCommodity,
        challan.displayQuantity,
        challan.displayBagCount > 0 ? challan.displayBagCount.toString() : '-',
        '-',
        '-',
        challan.totalAmount > 0 ? 'Rs. ${challan.totalAmount.toStringAsFixed(2)}' : '-',
      ]);
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          // ── Header ─────────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DaalSetu',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber800,
                    ),
                  ),
                  pw.Text(
                    'Agro Broker B2B Trading Platform',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'admin@daalsetu.com | https://daalsetu.zappcode.in',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber100,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.amber700, width: 0.8),
                    ),
                    child: pw.Text(
                      'DELIVERY CHALLAN',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.amber900,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Challan No: ${challan.displayChallanNo}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Date: ${challan.challanDate ?? challan.createdAt?.split('T').first ?? '-'}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Status: ${challan.statusTitle.toUpperCase()}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: challan.status?.toLowerCase() == 'delivered'
                          ? PdfColors.green800
                          : (challan.status?.toLowerCase() == 'dispatched'
                              ? PdfColors.blue800
                              : PdfColors.orange800),
                    ),
                  ),
                  if (challan.displayContract.isNotEmpty)
                    pw.Text(
                      'Contract: ${challan.displayContract}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                    ),
                ],
              ),
            ],
          ),

          pw.Divider(thickness: 1.2, color: PdfColors.grey400, height: 24),

          // ── Consignor / Consignee Panels ───────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _partyPanel(
                  'SELLER / CONSIGNOR',
                  challan.sellerCompanyName ?? challan.displaySeller,
                  challan.sellerAddress,
                  challan.sellerGst,
                  challan.sellerPan,
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: _partyPanel(
                  'BUYER / CONSIGNEE',
                  challan.buyerCompanyName ?? challan.displayBuyer,
                  challan.buyerAddress,
                  challan.buyerGst,
                  challan.buyerPan,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // ── Items Table ────────────────────────────────────────────────────
          pw.Text(
            'COMMODITY & DISPATCH PARTICULARS',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const <String>[
              'Item / Product',
              'Quantity',
              'Bags',
              'Packing',
              'Rate',
              'Amount',
            ],
            data: itemRows,
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerHeight: 22,
            cellHeight: 20,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),

          pw.SizedBox(height: 12),

          // ── Total Amount Banner ────────────────────────────────────────────
          if (challan.totalAmount > 0)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
                ),
                child: pw.Text(
                  'Total Consignment Value: Rs. ${challan.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),

          pw.SizedBox(height: 16),

          // ── Transport & Logistics Information ──────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TRANSPORT & VEHICLE DETAILS',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                ),
                pw.Divider(thickness: 0.5, color: PdfColors.grey300, height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _infoLine('Transporter', challan.transporterNameDisplay ?? 'Direct / Self'),
                    ),
                    pw.Expanded(
                      child: _infoLine('Truck / Vehicle No.', challan.displayTruck),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _infoLine('Driver Name', challan.displayDriver),
                    ),
                    pw.Expanded(
                      child: _infoLine('Driver Contact', challan.driverMobile ?? '-'),
                    ),
                  ],
                ),
                if ((challan.driverLicenseNumber ?? '').isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  _infoLine('Driver License', challan.driverLicenseNumber!),
                ],
              ],
            ),
          ),

          if ((challan.narration ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Narration / Remarks:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text(challan.narration!, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
          ],

          pw.Spacer(),

          // ── Signatures & Footer ───────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 130, height: 1, color: PdfColors.grey500),
                  pw.SizedBox(height: 4),
                  pw.Text("Receiver's Signature & Stamp", style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 130, height: 1, color: PdfColors.grey500),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorized Signatory (DaalSetu)', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'This is a system generated delivery challan issued via DaalSetu. Valid without physical signature where permissible.',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    final safeNumber = (challan.challanNumber ?? 'challan_${challan.id}')
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final fileName = 'Delivery-Challan-$safeNumber.pdf';
    final pdfBytes = await document.save();

    // 1. Always write to an accessible local file for instant opening via OpenFilex
    final directory = await getTemporaryDirectory();
    final localFile = File('${directory.path}/$fileName');
    await localFile.writeAsBytes(pdfBytes, flush: true);

    String? savedUri;
    // 2. On Android, also save to root public Downloads folder for permanent offline storage
    if (Platform.isAndroid) {
      try {
        savedUri = await _downloadsChannel.invokeMethod<String>(
          'savePdfToDownloads',
          <String, dynamic>{'fileName': fileName, 'bytes': pdfBytes},
        );
      } catch (_) {
        // Fallback to localFile path
      }
    }

    if (openShareSheet) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(localFile.path, mimeType: 'application/pdf')],
          subject: 'Delivery Challan ${challan.displayChallanNo}',
          text: 'Delivery challan ${challan.displayChallanNo} generated from DaalSetu.',
        ),
      );
    }

    return ChallanPdfResult(
      filePath: localFile.path,
      downloadsUri: savedUri,
      fileName: fileName,
    );
  }

  static pw.Widget _partyPanel(
    String label,
    String? name,
    String? address,
    String? gst,
    String? pan,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.amber800),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            (name ?? 'N/A').trim(),
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          if ((address ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(address!.trim(), style: const pw.TextStyle(fontSize: 8)),
          ],
          if ((gst ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text('GSTIN: ${gst!.trim()}', style: const pw.TextStyle(fontSize: 8)),
          ],
          if ((pan ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text('PAN: ${pan!.trim()}', style: const pw.TextStyle(fontSize: 8)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _infoLine(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
        children: [
          pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: value),
        ],
      ),
    );
  }
}
