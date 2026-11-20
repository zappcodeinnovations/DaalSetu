import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Contract PDF used when the backend has no ready-made file: brand header band,
/// grid of deal details, Buyer and Seller cards side by side, route and footer.
pw.Document buildContractPdf(ContractDetailModel contract, String contractNumber) {
    final doc = pw.Document();
    const accent = PdfColor.fromInt(0xFFF05A28);
    const accentSoft = PdfColor.fromInt(0xFFFFF2D8);
    const ink = PdfColor.fromInt(0xFF1F2937);
    const muted = PdfColor.fromInt(0xFF6B7280);
    const line = PdfColor.fromInt(0xFFE5E7EB);

    String dash(String? value) =>
        (value == null || value.trim().isEmpty || value == 'null') ? '-' : value.trim();

    pw.Widget sectionTitle(String title) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
          padding: const pw.EdgeInsets.only(left: 8, top: 3, bottom: 3),
          decoration: const pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
          ),
          child: pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: accent,
              letterSpacing: 0.8,
            ),
          ),
        );

    pw.Widget cell(String label, String value) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: line, width: 0.6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: muted)),
              pw.SizedBox(height: 2),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: ink,
                ),
              ),
            ],
          ),
        );

    // Rows of two equal cells. A Table keeps both cells of a row the same height; a Row with
    // CrossAxisAlignment.stretch inside the page's unbounded-height Column made the whole body
    // silently disappear (blank PDF), so it must not be used here.
    pw.Widget grid(List<List<String>> items) {
      final rows = <pw.TableRow>[];
      for (var i = 0; i < items.length; i += 2) {
        final left = items[i];
        final right = i + 1 < items.length ? items[i + 1] : null;
        rows.add(
          pw.TableRow(
            children: [
              cell(left[0], left[1]),
              right == null ? cell('', '') : cell(right[0], right[1]),
            ],
          ),
        );
      }
      return pw.Table(
        columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FlexColumnWidth()},
        children: rows,
      );
    }

    pw.Widget partyCard(String title, List<List<String>> items) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: line, width: 0.8),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: accentSoft,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(6),
                    topRight: pw.Radius.circular(6),
                  ),
                ),
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (final item in items)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item[0], style: const pw.TextStyle(fontSize: 8, color: muted)),
                            pw.Text(
                              item[1],
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Brand header band.
              pw.Container(
                width: double.infinity,
                color: accent,
                padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DAALSETU CONTRACT',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Contract #: $contractNumber',
                          style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        contract.status.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Deal & Commodity Details'),
                    grid([
                      ['Product', dash(contract.productTitle)],
                      ['Status', dash(contract.status.toUpperCase())],
                      ['Quantity', dash('${contract.dealQuantity} ${contract.quantityUnit}')],
                      ['Deal Rate', dash('Rs ${contract.dealAmount} ${contract.amountUnit}')],
                    ]),
                    sectionTitle('Buyer & Seller'),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: partyCard('Buyer', [
                            ['Buyer', dash(contract.displayBuyerId.isNotEmpty ? contract.displayBuyerId : contractPersonName(contract.buyerPersonName, contract.buyerName))],
                            ['Name', dash(contractPersonName(contract.buyerPersonName, contract.buyerName))],
                            ['Company', dash(contractCompanyName(contract.buyerCompany, contract.buyerName, contract.buyerPersonName))],
                            ['Email', dash(contract.buyerEmail)],
                          ]),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Expanded(
                          child: partyCard('Seller', [
                            ['Seller', dash(contract.displaySellerId.isNotEmpty ? contract.displaySellerId : contractPersonName(contract.sellerPersonName, contract.sellerName))],
                            ['Name', dash(contractPersonName(contract.sellerPersonName, contract.sellerName))],
                            ['Company', dash(contractCompanyName(contract.sellerCompany, contract.sellerName, contract.sellerPersonName))],
                            ['Email', dash(contract.sellerEmail)],
                          ]),
                        ),
                      ],
                    ),
                    sectionTitle('Logistics & Route'),
                    grid([
                      ['Loading From', dash(contract.loadingFrom)],
                      ['Loading To', dash(contract.loadingTo)],
                      ['Ready For Loading', dash(contract.readyForLoadingAt)],
                      ['Confirmed At', dash(contract.confirmedAt)],
                    ]),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                child: pw.Column(
                  children: [
                    pw.Divider(thickness: 0.6, color: line),
                    pw.SizedBox(height: 4),
                    pw.Center(
                      child: pw.Text(
                        'Generated securely via DaalSetu Platform',
                        style: const pw.TextStyle(fontSize: 9, color: muted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  return doc;
}
