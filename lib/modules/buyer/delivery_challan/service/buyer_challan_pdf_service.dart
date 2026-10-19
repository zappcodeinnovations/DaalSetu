import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:daalsetu/modules/downloads/service/downloads_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../utils/app_preferences.dart';
import '../../../profile/controller/profile_controller.dart';
import '../model/buyer_delivery_challan_model.dart';

class BuyerChallanPdfService {
  const BuyerChallanPdfService._();


  static String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    try {
      final parsed = DateTime.parse(raw.trim());
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      final match = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(raw.trim());
      if (match != null) {
        final y = match.group(1);
        final m = match.group(2)!.padLeft(2, '0');
        final d = match.group(3)!.padLeft(2, '0');
        return '$d/$m/$y';
      }
      return raw.trim();
    }
  }

  static const _rupeeSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="7" height="7">
  <path d="M6 3h12v2h-4.5c1.8 1.1 3 3 3 5.5H18v2h-1.6C15.6 15.6 13 18 10 18H9.3l6.7 5H13L6 17v-2h3.5c2 0 3.7-1.4 4.3-3H6v-2h7.8c-.4-1.3-1.6-2.3-3.1-2.8H6V5h5.5C10.7 4.5 9.4 4 8 4H6V3z" fill="#000000"/>
</svg>
''';

  static String _formatPlainNumber(dynamic val) {
    if (val == null) return '0.00';
    final str = val
        .toString()
        .trim()
        .replaceAll('₹', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .replaceAll(',', '');
    final d = double.tryParse(str);
    if (d == null) return val.toString().trim();
    return NumberFormat('#,##,##0.00').format(d);
  }

  static pw.Widget _currencyWidget(
    dynamic val, {
    bool isBold = false,
    double fontSize = 6.5,
  }) {
    final numStr = _formatPlainNumber(val);
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SvgImage(
          svg: _rupeeSvg,
          width: fontSize * 0.9,
          height: fontSize * 0.9,
        ),
        pw.SizedBox(width: 1),
        pw.Text(
          numStr,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }


  /// Saves a generated challan PDF to the device Downloads folder.
  static Future<String> download(BuyerDeliveryChallanModel challan) =>
      downloadAndShare(challan, openShareSheet: false);

  /// Generates the exact Delivery Challan PDF matching the Buyer web panel format.
  static Future<String> downloadAndShare(
    BuyerDeliveryChallanModel challan, {
    bool openShareSheet = true,
  }) async {
    final document = pw.Document();
    final company = challan.company;

    // Company Header Info
    final companyName = (company?.legalName ?? challan.companyNameDisplay ?? 'FARMLAND').toUpperCase();
    final companyAddress = (company?.addressDisplay ?? challan.sellerAddress ?? 'NAGPUR, NAGPUR, Nagpur, Maharashtra, 440023, India').toUpperCase();
    final companyGst = (company?.gstNumber ?? challan.sellerGst ?? '23ABVSC1223F1Z4').toUpperCase();
    String resolvedPan = (company?.panNumber ?? '').trim();
    if (resolvedPan.isEmpty || resolvedPan.toLowerCase() == 'null') {
      final cleanGst = companyGst.replaceAll(RegExp(r'\s+'), '');
      if (cleanGst.length >= 12 && RegExp(r'^\d{2}[A-Z0-9]{10}').hasMatch(cleanGst)) {
        resolvedPan = cleanGst.substring(2, 12);
      }
    }
    if (resolvedPan.isEmpty || resolvedPan.toLowerCase() == 'null') {
      resolvedPan = 'ABVSC1223F';
    }
    final companyPan = resolvedPan.toUpperCase();

    // Resolve buyer telephone number (consignee contact)
    String buyerPhone = (challan.buyerMobile ?? '').trim();
    if (buyerPhone.isEmpty || buyerPhone.toLowerCase() == 'null') {
      try {
        if (Get.isRegistered<ProfileController>()) {
          final m = Get.find<ProfileController>().profile.value?.mobile;
          if (m != null && m.trim().isNotEmpty && m.toLowerCase() != 'null') {
            buyerPhone = m.trim();
          }
        }
      } catch (_) {}
    }
    if (buyerPhone.isEmpty || buyerPhone.toLowerCase() == 'null') {
      try {
        final u = await AppPreferences.getUsername();
        if (u != null && RegExp(r'^\d{10}$').hasMatch(u.trim())) {
          buyerPhone = u.trim();
        }
      } catch (_) {}
    }

    // Items calculation
    final items = challan.items ?? <DeliveryChallanItem>[];
    int totalBags = 0;
    double totalQty = 0;
    String unit = 'QTL';
    double totalItemAmount = 0;

    for (final it in items) {
      if (it.bagCount != null) totalBags += it.bagCount!;
      final q = double.tryParse(it.quantity?.replaceAll(',', '') ?? '');
      if (q != null) totalQty += q;
      if (it.unit != null && it.unit!.isNotEmpty) unit = it.unit!;
      final a = double.tryParse(it.amount?.replaceAll(',', '') ?? '');
      if (a != null) totalItemAmount += a;
    }

    final challanTotalAmountStr = challan.totalAmount?.replaceAll(',', '') ?? totalItemAmount.toString();
    final totalAmountVal = double.tryParse(challanTotalAmountStr) ?? totalItemAmount;

    final lorryFreightVal = double.tryParse(challan.lorryFreightPerBag?.replaceAll(',', '') ?? '') ?? 0.0;
    final loadingChargesVal = double.tryParse(challan.loadingCharges?.replaceAll(',', '') ?? '') ?? 0.0;
    final otherExpVal = double.tryParse(challan.otherExp?.replaceAll(',', '') ?? '') ?? 0.0;
    final lessAdvanceVal = double.tryParse(challan.lessAdvance?.replaceAll(',', '') ?? '') ?? 0.0;

    final primaryRed = PdfColor.fromHex('#B8253E');
    final tableHeaderBlue = PdfColor.fromHex('#E1EDFE');
    final highlightYellow = PdfColor.fromHex('#FFF5DC');

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Align(
          alignment: pw.Alignment.topCenter,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
              // 1. Top devotional header
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
                child: pw.Text(
                  '|| Shree Ganeshaya Namah ||',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),

              // 2. Document Title
              pw.Text(
                'DELIVERY CHALLAN',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),

              // 3. Company Name
              pw.Text(
                companyName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),

              // 4. Company Address & GST/PAN
              pw.Text(
                companyAddress,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                'GST: $companyGst  PAN: $companyPan',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.SizedBox(height: 4),

              // 5. Red Banner
              pw.Container(
                color: primaryRed,
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Text(
                  'GRAINS, PULSES & CATTLEFEED TRADING',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // 6. Two-column Party & Challan details
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left Column: Buyer details
                    pw.Expanded(
                      flex: 5,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.RichText(
                              text: pw.TextSpan(
                                text: 'M/S.    ',
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                children: [
                                  pw.TextSpan(
                                    text: challan.buyerName ?? challan.buyerNameDisplay ?? 'Test Buyer',
                                    style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              challan.buyerCompanyName ?? challan.buyerName ?? 'Indigo land',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                            if ((challan.buyerAddress ?? '').isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                challan.buyerAddress!,
                                style: const pw.TextStyle(fontSize: 7.5),
                              ),
                            ],
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'TEL : ${buyerPhone.isNotEmpty ? buyerPhone : '-'}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Divider
                    pw.Container(
                      width: 0.8,
                      height: 85,
                      color: PdfColors.black,
                    ),
                    // Right Column: Challan metadata
                    pw.Expanded(
                      flex: 5,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                _metaRow('DELIVERY NO.', ': ${challan.challanNumber ?? '-'}', boldVal: true),
                                pw.Text(
                                  'DATE : ${_formatDate(challan.challanDate)}',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 2),
                            _metaRow('LORRY NO.', ': ${challan.truckNumber ?? '-'}'),
                            pw.SizedBox(height: 2),
                            _metaRow('TRANSPORT', ': ${challan.transporterNameDisplay ?? '-'}'),
                            pw.SizedBox(height: 2),
                            _metaRow('CREATED BY', ': ${challan.createdByName ?? challan.createdByDisplay?.name ?? '-'}'),
                            pw.SizedBox(height: 2),
                            _metaRow('DEL AT', ': ${challan.deliveryAddress ?? ''}'),
                            pw.SizedBox(height: 2),
                            _metaRow('PAYMENT SCHEDULE', ':'),
                            pw.SizedBox(height: 2),
                            _metaRow(
                              'ITEM NAME',
                              ': ${items.isNotEmpty ? (items.first.productName ?? '-') : '-'}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Sub-header instruction text
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: pw.Text(
                  'Dear Sir / Madam, As per your valued order, we have dispatched the goods/bags as detailed below. Please take delivery of the above consignment in good condition.',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),

              // 7. Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.2), // PARTY'S NAME
                  1: pw.FlexColumnWidth(1.6), // MARKA/REMARKS
                  2: pw.FlexColumnWidth(0.9), // BAGS
                  3: pw.FlexColumnWidth(1.2), // PACKING
                  4: pw.FlexColumnWidth(1.3), // QTY/UNIT
                  5: pw.FlexColumnWidth(1.1), // RATE
                  6: pw.FlexColumnWidth(1.1), // ADVANCE
                  7: pw.FlexColumnWidth(1.1), // INSURANCE
                  8: pw.FlexColumnWidth(1.0), // OTHERS
                  9: pw.FlexColumnWidth(1.5), // TOTAL
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: tableHeaderBlue),
                    children: [
                      _th("PARTY'S NAME"),
                      _th('MARKA/REMARKS'),
                      _th('BAGS'),
                      _th('PACKING'),
                      _th('QTY/UNIT'),
                      _th('RATE'),
                      _th('ADVANCE'),
                      _th('INSURANCE'),
                      _th('OTHERS'),
                      _th('TOTAL'),
                    ],
                  ),
                  // Item Rows
                  if (items.isEmpty)
                    pw.TableRow(
                      children: [
                        _td(challan.sellerName ?? '-', align: pw.TextAlign.left),
                        _td('-'),
                        _td('-'),
                        _td('-'),
                        _td('-'),
                        _tdCurrency(0.0),
                        _tdCurrency(0.0),
                        _tdCurrency(0.0),
                        _tdCurrency(0.0),
                        _tdCurrency(totalAmountVal),
                      ],
                    )
                  else
                    ...items.map(
                      (item) => pw.TableRow(
                        children: [
                          _td(challan.sellerName ?? item.productName ?? '-', align: pw.TextAlign.left),
                          _td(item.productName ?? '-'),
                          _td(item.bagCount?.toString() ?? '-'),
                          _td(item.packingWeightKg != null ? '${item.packingWeightKg}' : '-'),
                          _td('${item.quantity ?? '-'} ${item.unit ?? ''}'.trim()),
                          _tdCurrency(item.rate),
                          _tdCurrency(0.0),
                          _tdCurrency(0.0),
                          _tdCurrency(0.0),
                          _tdCurrency(item.amount),
                        ],
                      ),
                    ),
                  // NET TOTAL Row
                  pw.TableRow(
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.Text(
                          'NET TOTAL',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      _td(''),
                      _td(totalBags > 0 ? '$totalBags' : '-', isBold: true),
                      _td(''),
                      _td(totalQty > 0 ? '${totalQty.toStringAsFixed(3)} $unit' : '-', isBold: true),
                      _td(''),
                      _tdCurrency(0.0),
                      _tdCurrency(0.0),
                      _tdCurrency(0.0),
                      _tdCurrency(totalAmountVal, isBold: true),
                    ],
                  ),
                ],
              ),

              // 8. Driver Info Row
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.6),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: pw.Text(
                  'Driver Info :  ${challan.driverName ?? 'driver'}, ${challan.driverMobile ?? ''}'.trim(),
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
              ),

              // 9. Bottom Section: Terms, Tax Info, and Charges Summary
              pw.Table(
                border: const pw.TableBorder(
                  verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.6),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    children: [
                      // Left Box: TERMS
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TERMS :',
                              style: pw.TextStyle(
                                fontSize: 7.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            _termItem('1) Subject to Direct Lorry & Door Delivery.'),
                            _termItem('2) Our risk & responsibility ceases after loading goods.'),
                            _termItem('3) Please send Demand Draft/Cheques in favour of party as per their bill by Courier/Registry Only.'),
                            _termItem('4) Weight shortages are not our liability.'),
                            _termItem('5) Subject to Nagpur Jurisdiction.'),
                          ],
                        ),
                      ),

                      // Middle Box: Narration, GST/PAN, Company Signature
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.SizedBox(
                                      width: 45,
                                      child: pw.Text(
                                        'Remark  :',
                                        style: pw.TextStyle(
                                          fontSize: 7.5,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    pw.Expanded(
                                      child: pw.Text(
                                        (challan.narration ?? '').trim().isNotEmpty
                                            ? challan.narration!
                                            : 'Selected Contract Details',
                                        style: const pw.TextStyle(fontSize: 6.5),
                                        maxLines: 4,
                                      ),
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 4),
                                pw.Row(
                                  children: [
                                    pw.SizedBox(
                                      width: 45,
                                      child: pw.Text(
                                        'GST No. :',
                                        style: pw.TextStyle(
                                          fontSize: 7.5,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    pw.Text(
                                      companyGst,
                                      style: const pw.TextStyle(fontSize: 7),
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 2),
                                pw.Row(
                                  children: [
                                    pw.SizedBox(
                                      width: 45,
                                      child: pw.Text(
                                        'PAN No. :',
                                        style: pw.TextStyle(
                                          fontSize: 7.5,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    pw.Text(
                                      companyPan,
                                      style: const pw.TextStyle(fontSize: 7),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 8),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'For    $companyName',
                                    style: pw.TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 8),
                                  pw.Text(
                                    'Authorized Signatory',
                                    style: const pw.TextStyle(fontSize: 6),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Box: Charges Calculation Breakdown
                      pw.Container(
                        padding: pw.EdgeInsets.zero,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            _chargeRow('LORRY FREIGHT', lorryFreightVal),
                            _chargeRow('LOADING CHARGES', loadingChargesVal),
                            _chargeRow('OTHER EXP', otherExpVal),
                            _chargeRow('LESS ADVANCE', lessAdvanceVal),
                            pw.SizedBox(height: 4),
                            // NET AMOUNT Highlight Bar
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                              decoration: pw.BoxDecoration(
                                color: highlightYellow,
                                border: const pw.Border(
                                  top: pw.BorderSide(color: PdfColors.black, width: 0.6),
                                ),
                              ),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'NET AMOUNT',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  _currencyWidget(totalAmountVal, isBold: true, fontSize: 8.5),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

    final safeNumber =
        (challan.challanNumber ?? challan.id?.toString() ?? 'challan')
            .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final fileName = 'Delivery-Challan-$safeNumber.pdf';
    final pdfBytes = await document.save();

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);

    // Same save as every other download: phone Downloads + the app's Downloads screen.
    try {
      await DownloadsService.saveBytes(fileName: fileName, bytes: pdfBytes, mimeType: 'application/pdf');
    } catch (error) {
      debugPrint('📂 Challan PDF not saved to Downloads: $error');
    }

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

  static pw.Widget _th(String title) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: pw.Text(
        title,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.center, bool isBold = false}) {
    return pw.Container(
      alignment: align == pw.TextAlign.left ? pw.Alignment.centerLeft : pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _tdCurrency(dynamic val, {bool isBold = false, double fontSize = 6.5}) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: _currencyWidget(val, isBold: isBold, fontSize: fontSize),
    );
  }

  static pw.Widget _metaRow(String label, String value, {bool boldVal = false}) {
    return pw.RichText(
      text: pw.TextSpan(
        text: '$label ',
        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
        children: [
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: boldVal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _termItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 6),
      ),
    );
  }

  static pw.Widget _chargeRow(String label, double val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7),
          ),
          _currencyWidget(val, fontSize: 7),
        ],
      ),
    );
  }
}
