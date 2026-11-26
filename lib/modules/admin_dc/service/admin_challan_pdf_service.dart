import '../../buyer/delivery_challan/model/buyer_delivery_challan_model.dart';
import '../../buyer/delivery_challan/service/buyer_challan_pdf_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:daalsetu/modules/downloads/service/downloads_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
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
    'com.zappkode.daalsetu/downloads',
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
    // Same layout as the web admin panel's challan PDF (shared with the buyer/seller download), so the
    // parties show their names (M/S + Party's name) with the company underneath, as on the web.
    final pdfBytes = await BuyerChallanPdfService.buildPdf(
      BuyerDeliveryChallanModel.fromJson(challan.raw),
      ownPhoneAsBuyerPhone: false,
    );

    final safeNumber = (challan.challanNumber ?? 'challan_${challan.id}')
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final fileName = 'Delivery-Challan-$safeNumber.pdf';

    // 1. Always write to an accessible local file for instant opening via OpenFilex
    final directory = await getTemporaryDirectory();
    final localFile = File('${directory.path}/$fileName');
    await localFile.writeAsBytes(pdfBytes, flush: true);

    String? savedUri;
    // 2. On Android, also save to root public Downloads folder for permanent offline storage
    // Same save as every other download: phone Downloads + the app's Downloads screen.
    try {
      savedUri = await DownloadsService.saveBytes(fileName: fileName, bytes: pdfBytes, mimeType: 'application/pdf');
    } catch (error) {
      debugPrint('📂 Challan PDF not saved to Downloads: $error');
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

}
