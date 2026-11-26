import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:daalsetu/utils/app_date.dart';
import 'package:daalsetu/utils/pdf_text.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The contract PDF, laid out exactly like the web's: an orange band (title, contract number, status and total),
/// then one two-column table per section - Deal, Buyer, Seller, Logistics Route, Transaction Notes,
/// Administration (admin accounts only) and Timeline - and a "Generated on ... via DaalSetu" footer.
pw.Document buildContractPdf(
  ContractDetailModel contract,
  String contractNumber, {
  DateTime? now,
  DeflateCallback? deflate,
}) {
  final doc = pw.Document(deflate: deflate);
  const accent = PdfColor.fromInt(0xFFF05A28);
  const sectionBg = PdfColor.fromInt(0xFFFFF2D8);
  const sectionInk = PdfColor.fromInt(0xFFD9481A);
  const ink = PdfColor.fromInt(0xFF2C2C2C);
  const muted = PdfColor.fromInt(0xFF787878);
  const line = PdfColor.fromInt(0xFFC8C8C8);
  const margin = 14 * PdfPageFormat.mm;

  String dash(Object? value) {
    final text = (value ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty || text == 'null' ? '-' : pdfSafeText(text);
  }

  // Helvetica has no rupee glyph, so money is "Rs. 2,254.50" like the web's PDF.
  String money(String? value) {
    final sanitized = pdfSafeText(value).replaceAll('Rs.', '').trim();
    final amount = double.tryParse(sanitized.replaceAll(',', '').trim());
    if (amount == null) return '-';
    return 'Rs. ${NumberFormat('#,##,##0.00', 'en_IN').format(amount)}';
  }

  String two(int n) => n.toString().padLeft(2, '0');

  // "19/11/2026 18:36" (24 hour, like the web PDF); a value with no time is just the date.
  String stamp(String? raw) {
    final text = (raw ?? '').trim();
    final parsed = AppDate.parse(text);
    if (parsed == null) return dash(text);
    final hasTime = RegExp(r'\d{1,2}:\d{2}').hasMatch(text);
    final date = '${two(parsed.day)}/${two(parsed.month)}/${parsed.year}';
    return hasTime ? '$date ${two(parsed.hour)}:${two(parsed.minute)}' : date;
  }

  String pickupDate(String? raw) {
    final parsed = AppDate.parse(raw);
    return parsed == null ? '-' : '${two(parsed.day)}-${two(parsed.month)}-${parsed.year}';
  }

  String statusLabel(String status) {
    final value = status.trim();
    if (value.isEmpty) return '-';
    final words = value.replaceAll('_', ' ').split(' ');
    return words.map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  String generatedOn() {
    final at = now ?? DateTime.now();
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    return 'Generated on ${two(at.day)}/${two(at.month)}/${at.year}, $hour:${two(at.minute)}:${two(at.second)} '
        '${at.hour >= 12 ? 'pm' : 'am'} via DaalSetu';
  }

  String firstFilled(List<String?> values) {
    for (final value in values) {
      if ((value ?? '').trim().isNotEmpty) return value!.trim();
    }
    return '';
  }

  pw.Widget section(String title, List<List<String>> rows) {
    pw.Widget text(String value, {bool bold = false, PdfColor color = ink}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
          child: pw.Text(
            pdfSafeText(value),
            style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color),
          ),
        );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      // A Column is not splittable, so a section moves to the next page whole instead of leaving its header behind.
      child: pw.Column(children: [pw.Table(
        border: pw.TableBorder.all(color: line, width: 0.5),
        columnWidths: {
          0: const pw.FixedColumnWidth(55 * PdfPageFormat.mm),
          1: const pw.FlexColumnWidth(),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: sectionBg),
            children: [
              text(title, bold: true, color: sectionInk),
              pw.SizedBox(),
            ],
          ),
          for (final row in rows)
            pw.TableRow(children: [text(row[0], bold: true), text(row[1])]),
        ],
      )]),
    );
  }

  final buyerCode = firstFilled([contract.buyerUniqueId, contract.displayBuyerId]);
  final sellerCode = firstFilled([contract.sellerMappedId, contract.displaySellerId]);
  final buyerPerson = contractPersonName(contract.buyerPersonName, contract.buyerName);
  final sellerPerson = contractPersonName(contract.sellerPersonName, contract.sellerName);
  final isAdminView = contract.adminRemark.isNotEmpty ||
      contract.confirmedByAdminName.isNotEmpty ||
      contract.confirmedBranchName.isNotEmpty ||
      contract.createdByUserName.isNotEmpty ||
      contract.assignedSubAdminName.isNotEmpty ||
      contract.confirmedByAdminId != null ||
      contract.createdByUserId != null ||
      contract.assignedSubAdminId != null;

  final sections = <pw.Widget>[
    section('Deal', [
      ['Offer', dash(contract.productTitle)],
      if (contract.productBrand.isNotEmpty) ['Brand', dash(contract.productBrand)],
      ['Category', dash(contract.productCategory)],
      ['Deal Amount', '${money(contract.dealAmount)}/${dash(contract.amountUnit)}'],
      ['Trade Value', (contract.tradeValue ?? '').isNotEmpty ? 'Rs. ${pdfSafeText(contract.tradeValue).replaceAll('Rs.', '').trim()}' : money(contract.tradeValue)],
      ['Seller Offered Quantity', dash('${contract.sellerQuantity ?? ''} ${contract.quantityUnit}'.trim())],
      ['Buyer Offered Rate', money(contract.buyerOfferAmount)],
      ['Buyer Required Qty', dash('${contract.buyerRequiredQuantity ?? ''} ${contract.quantityUnit}'.trim())],
      ['Deal Date', stamp(firstFilled([contract.dealDate, contract.confirmedAt]))],
      ['Deal Quantity', dash('${contract.dealQuantity} ${contract.quantityUnit}'.trim())],
      ['Total Deal Price', money(firstFilled([contract.tradeValue, contract.dealAmount.isEmpty ? '' : _tradeFromRate(contract)]))],
      if (contract.bagCount != null && contract.bagCount != 0)
        ['Bag Count', contract.bagCount.toString()],
      if (contract.packingWeightKg.isNotEmpty)
        ['Packing Weight', '${contract.packingWeightKg} kg'],
      if (contract.deliveryPeriod.isNotEmpty || contract.deliveryDate != null)
        ['Delivery Period', dash(firstFilled([contract.deliveryPeriod, contract.deliveryDate]))],
      if (contract.loadingFromDate != null || contract.loadingToDate != null)
        ['Pickup From / To', '${pickupDate(contract.loadingFromDate)} - ${pickupDate(contract.loadingToDate)}'],
    ]),
    section('Buyer', [
      ['Buyer ID', dash(buyerCode)],
      ['Name', dash(buyerPerson)],
      ['Company', dash(contractCompanyName(contract.buyerCompany, contract.buyerName, contract.buyerPersonName))],
      ['Mobile', dash(contract.buyerMobile)],
      ['Email', dash(contract.buyerEmail)],
      ['GST No.', dash(contract.buyerGst)],
    ]),
    section('Seller', [
      ['Seller ID', dash(sellerCode)],
      ['Name', dash(sellerPerson)],
      ['Company', dash(contractCompanyName(contract.sellerCompany, contract.sellerName, contract.sellerPersonName))],
      ['Mobile', dash(contract.sellerMobile)],
      ['Email', dash(contract.sellerEmail)],
      ['GST No.', dash(contract.sellerGst)],
    ]),
    section('Logistics Route', [
      ['Loading From', dash(contract.loadingFrom)],
      ['Loading To', dash(contract.loadingTo)],
    ]),
    section('Transaction Notes', [
      ['Buyer Note', dash(contract.buyerRemark)],
      ['Seller Note', dash(contract.sellerRemark)],
      ['Admin Note', dash(contract.adminRemark)],
    ]),
    if (isAdminView)
      section('Administration', [
        ['Admin Remark', dash(contract.adminRemark)],
        ['Confirmed By Admin', dash(contract.confirmedByAdminName)],
        ['Branch', dash(contract.confirmedBranchName)],
        ['Created By', dash(contract.createdByUserName)],
        ['Assigned Sub Admin', dash(contract.assignedSubAdminName)],
      ]),
    section('Timeline', [
      ['Created', stamp(contract.createdAt)],
      ['Confirmed', stamp(contract.confirmedAt)],
      ['Ready For Loading', stamp(contract.readyForLoadingAt)],
      ['Updated', stamp(contract.updatedAt)],
    ]),
  ];

  final totalText = money(firstFilled([contract.tradeValue, contract.dealAmount.isEmpty ? '' : _tradeFromRate(contract)]));

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      header: (context) => context.pageNumber == 1
          ? pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6 * PdfPageFormat.mm),
              color: accent,
              padding: const pw.EdgeInsets.symmetric(horizontal: margin, vertical: 7 * PdfPageFormat.mm),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DAALSETU CONTRACT',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      pw.SizedBox(height: 4),
                      pw.Text('Contract: ${dash(contractNumber)}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Status: ${statusLabel(contract.status)}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                      pw.SizedBox(height: 4),
                      pw.Text('Total: $totalText',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                    ],
                  ),
                ],
              ),
            )
          : pw.SizedBox(height: 14 * PdfPageFormat.mm),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(margin, 0, margin, 8 * PdfPageFormat.mm),
        child: pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(generatedOn(), style: const pw.TextStyle(fontSize: 8, color: muted)),
        ),
      ),
      build: (context) => [
        for (final item in sections)
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: margin), child: item),
      ],
    ),
  );
  return doc;
}

/// Total for an API that sent no trade value: rate x quantity, only when both are numbers.
String _tradeFromRate(ContractDetailModel contract) {
  final rate = double.tryParse(contract.dealAmount.replaceAll(',', '').trim());
  final quantity = double.tryParse(contract.dealQuantity.replaceAll(',', '').trim());
  if (rate == null || quantity == null) return '';
  return (rate * quantity).toStringAsFixed(2);
}
