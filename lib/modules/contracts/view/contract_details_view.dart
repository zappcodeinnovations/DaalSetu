import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:daalsetu/modules/downloads/service/downloads_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'package:daalsetu/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/contract_controller.dart';
import 'package:daalsetu/modules/admin_catalog/view/transport_bids_sheet.dart';
import 'contract_edit_view.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import '../../../utils/app_snackbar.dart';

class ContractDetailScreen extends StatefulWidget {
  const ContractDetailScreen({super.key});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  late final ContractController controller;
  late final int contractId;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ContractController>()
        ? Get.find<ContractController>()
        : Get.put(ContractController());
    final rawArgs = Get.arguments;
    contractId = rawArgs is int
        ? rawArgs
        : int.tryParse(rawArgs?.toString() ?? '') ?? 0;
    final existing = controller.contracts.firstWhereOrNull((c) => c.id == contractId);
    if (existing != null) {
      controller.contractDetail.value = ContractDetailModel.fromContractModel(existing);
    }
    Future.microtask(() => controller.fetchContractDetail(contractId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBarLeading(), leadingWidth: AppBarLeading.widthFor(context), 
        title: const Text('Contract details'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              final contract = controller.contractDetail.value;
              if (contract != null) {
                _downloadContractPdf(context, contract);
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final contract = controller.contractDetail.value;
        if (contract == null || contract.id != contractId) {
          return const Center(child: Text('Contract details unavailable'));
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchContractDetail(contractId),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              _header(contract),
              _section('Product & deal', [
                _item(
                  'Offer',
                  () {
                    final title = contract.productTitle.trim();
                    final hasId = contract.productId != null && contract.productId != 0;
                    if (title.isNotEmpty && hasId) {
                      return '$title (ID: ${contract.productId})';
                    } else if (title.isNotEmpty) {
                      return title;
                    } else if (hasId) {
                      return 'ID: ${contract.productId}';
                    }
                    return '-';
                  }(),
                ),
                _item('Category', contract.productCategory),
                if (contract.interestId != null && contract.interestId != 0)
                  _item('Interest ID', contract.interestId),
                _item(
                  'Deal amount',
                  contract.amountUnit.isEmpty
                      ? '₹${contract.dealAmount}'
                      : '₹${contract.dealAmount}/${contract.amountUnit}',
                ),
                _item(
                  'Deal quantity',
                  '${contract.dealQuantity} ${contract.quantityUnit}'.trim(),
                ),
                if (contract.quantityQtl.isNotEmpty && contract.quantityQtl != contract.dealQuantity)
                  _item('Quantity (Qtl)', contract.quantityQtl),
                if (contract.bagCount != null && contract.bagCount != 0)
                  _item('Bag count', contract.bagCount),
                if (contract.bags.isNotEmpty && contract.bags != contract.bagCount?.toString())
                  _item('Bags', contract.bags),
                if (contract.packingWeightKg.isNotEmpty)
                  _item('Packing weight', '${contract.packingWeightKg} kg'),
              ]),
              _transporterSection(contract),
              _partySection(
                title: 'Buyer',
                displayPartyId: contract.displayBuyerId,
                name: contract.buyerName,
                mobile: contract.buyerMobile,
                email: contract.buyerEmail,
                company: contract.buyerCompany,
                uniqueId: contract.buyerUniqueId,
              ),
              _partySection(
                title: 'Seller',
                displayPartyId: contract.displaySellerId,
                name: contract.sellerName,
                mobile: contract.sellerMobile,
                email: contract.sellerEmail,
                company: contract.sellerCompany,
                mappedId: contract.sellerMappedId,
              ),
              if (contract.loadingFrom.isNotEmpty || contract.loadingTo.isNotEmpty)
                _section('Logistics Route', [
                  if (contract.loadingFrom.isNotEmpty)
                    _item('Pickup Location', contract.loadingFrom),
                  if (contract.loadingTo.isNotEmpty)
                    _item('Delivery Location', contract.loadingTo),
                  if (contract.readyForLoadingAt.isNotEmpty)
                    _item(
                      'Ready for loading at',
                      _date(contract.readyForLoadingAt),
                    ),
                  if (contract.transporterVisibleAt.isNotEmpty)
                    _item(
                      'Transporter visible at',
                      _date(contract.transporterVisibleAt),
                    ),
                ]),
              _section('Transaction Notes', [
                _item('Buyer Note', contract.buyerRemark),
                _item('Seller Note', contract.sellerRemark),
                _item('Admin Note', contract.adminRemark),
              ]),
              _section('Timeline', [
                _item('Created', _date(contract.createdAt)),
                _item('Confirmed', _date(contract.confirmedAt)),
                _item('Updated', _date(contract.updatedAt)),
              ]),
            ],
          ),
        );
      }),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final contract = controller.contractDetail.value;
                      if (contract != null) _downloadContractPdf(context, contract);
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primaryGold),
                    label: const Text(
                      'Download PDF',
                      style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final contract = controller.contractDetail.value;
                      if (contract != null) Get.to(() => ContractEditView(contract: contract));
                    },
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Edit contract'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => Get.toNamed(AppRoutes.adminCreateDC, arguments: contractId),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Create Delivery Challan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(ContractDetailModel contract) {
    final color = _statusColor(contract.status);
    final contractTitle = contract.contractId.isNotEmpty
        ? 'Contract: ${contract.contractId}'
        : 'Contract #${contract.id}';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                contractTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _label(contract.status),
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _partySection({
    required String title,
    required String displayPartyId,
    required String name,
    String? mobile,
    String? email,
    String? company,
    String? uniqueId,
    String? mappedId,
  }) {
    final theme = Theme.of(context);
    final isMobileNumeric = mobile != null && RegExp(r'^\+?[0-9]{7,15}$').hasMatch(mobile.trim());
    final phoneToDisplay = isMobileNumeric ? mobile.trim() : (RegExp(r'^\+?[0-9]{7,15}$').hasMatch(name.trim()) ? name.trim() : null);

    // If displayPartyId has "Name (ID: ...)", extract the leading name, or fallback to name
    String headingName = name;
    String? subtitleId = displayPartyId.isNotEmpty ? displayPartyId : (uniqueId ?? mappedId);
    if (displayPartyId.isNotEmpty && displayPartyId.contains('(')) {
      final parts = displayPartyId.split('(');
      headingName = parts[0].trim();
      subtitleId = '(${parts.sublist(1).join('(').trim()}';
      if (subtitleId.startsWith('(') && subtitleId.endsWith(')')) {
        subtitleId = subtitleId.substring(1, subtitleId.length - 1).trim();
      }
    } else if (headingName.isEmpty || RegExp(r'^\+?[0-9]{7,15}$').hasMatch(headingName)) {
      if (displayPartyId.isNotEmpty) headingName = displayPartyId;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.15),
                  child: const Icon(Icons.person, color: AppTheme.primaryGold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headingName.isNotEmpty ? headingName : '—',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitleId != null && subtitleId.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitleId,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (company != null && company.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Company: $company',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (phoneToDisplay != null && phoneToDisplay.isNotEmpty)
              InkWell(
                onTap: () async {
                  final uri = Uri.parse('tel:$phoneToDisplay');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: AppTheme.primaryGold),
                      const SizedBox(width: 10),
                      Text(
                        phoneToDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (email != null && email.isNotEmpty)
              InkWell(
                onTap: () async {
                  final uri = Uri.parse('mailto:$email');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: AppTheme.primaryGold),
                      const SizedBox(width: 10),
                      Text(
                        email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _transporterSection(ContractDetailModel contract) {
    final hasTransporter = (contract.transporterName != null && contract.transporterName!.trim().isNotEmpty) ||
        (contract.bidAmount != null && contract.bidAmount!.trim().isNotEmpty);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transporter Bids',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (hasTransporter) ...[
              if (contract.transporterName != null && contract.transporterName!.trim().isNotEmpty)
                _item('Assigned Transporter', contract.transporterName!),
              if (contract.transporterMobile != null && contract.transporterMobile!.trim().isNotEmpty)
                _item('Transporter Mobile', contract.transporterMobile!),
              if (contract.bidAmount != null && contract.bidAmount!.trim().isNotEmpty)
                _item('Accepted Bid Amount', '₹${contract.bidAmount}'),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _openTransportBids(contract),
                icon: const Icon(Icons.gavel_outlined, size: 18),
                label: const Text(
                  'Manage Bids (Accept / Reject)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasTransporter
                  ? 'Tap above to view other bids or update transporter bid status.'
                  : 'Tap above to view pending bids from transporters and Accept or Reject them.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTransportBids(ContractDetailModel contract) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TransportBidsSheet(
        contractId: contract.id,
        contractNumber: contract.contractId,
      ),
    );
    if (changed == true && mounted) {
      await controller.fetchContractDetail(contract.id);
    }
  }

  Widget _item(String label, Object? rawValue) {
    final value = rawValue?.toString().trim() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String value) {
    if (value.trim().isEmpty) return '—';
    return value
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _date(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.primaryGold;
      case 'cancelled':
        return AppTheme.errorRed;
      case 'pending':
        return AppTheme.secondaryOrange;
      default:
        return AppTheme.successGreen;
    }
  }

  Future<void> _downloadContractPdf(
    BuildContext context,
    ContractDetailModel contract,
  ) async {
    try {
      AppSnackbar.showSnackBar(context, 
        const SnackBar(
          content: Text('Preparing contract PDF...'),
          duration: Duration(seconds: 1),
        ),
      );

      final contractNumber = contract.contractId.isNotEmpty
          ? contract.contractId
          : 'Contract_${contract.id}';
      final fileName =
          '${contractNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.pdf';
      final file = File('${Directory.systemTemp.path}/$fileName');

      // 1. Try downloading directly from backend
      bool downloaded = false;
      try {
        final token = await AppPreferences.getAccessToken();
        if (token != null && token.isNotEmpty) {
          final endpoints = [
            '${ApiUrls.baseUrl}/api/contracts/${contract.id}/?download=pdf',
            '${ApiUrls.baseUrl}/api/contracts/${contract.id}/pdf/',
          ];
          for (final url in endpoints) {
            final res = await http.get(
              Uri.parse(url),
              headers: {'Authorization': 'Bearer $token'},
            );
            if (res.statusCode == 200 && res.bodyBytes.length > 500) {
              await file.writeAsBytes(res.bodyBytes, flush: true);
              downloaded = true;
              break;
            }
          }
        }
      } catch (_) {}

      // 2. Client-side fallback generator if backend has no direct PDF endpoint
      if (!downloaded) {
        final doc = pw.Document();
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context ctx) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'DAALSETU CONTRACT',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber800,
                        ),
                      ),
                      pw.Text(
                        'Contract #: $contractNumber',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 1.5, color: PdfColors.amber800),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Deal & Commodity Details',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  _pdfRow('Product', contract.productTitle),
                  _pdfRow(
                    'Quantity',
                    '${contract.dealQuantity} ${contract.quantityUnit}',
                  ),
                  _pdfRow(
                    'Deal Rate',
                    'Rs ${contract.dealAmount} ${contract.amountUnit}',
                  ),
                  _pdfRow('Status', contract.status.toUpperCase()),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Buyer Details',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  _pdfRow('Buyer ID', contract.displayBuyerId.isNotEmpty ? contract.displayBuyerId : contract.buyerName),
                  _pdfRow('Name', contract.buyerName),
                  _pdfRow('Company', contract.buyerCompany ?? '-'),
                  _pdfRow('Email', contract.buyerEmail ?? '-'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Seller Details',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  _pdfRow('Seller ID', contract.displaySellerId.isNotEmpty ? contract.displaySellerId : contract.sellerName),
                  _pdfRow('Name', contract.sellerName),
                  _pdfRow('Company', contract.sellerCompany ?? '-'),
                  _pdfRow('Email', contract.sellerEmail ?? '-'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Logistics & Route',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  _pdfRow('Loading From', contract.loadingFrom),
                  _pdfRow('Loading To', contract.loadingTo),
                  _pdfRow(
                    'Ready For Loading',
                    contract.readyForLoadingAt.isNotEmpty ? contract.readyForLoadingAt : '-',
                  ),
                  _pdfRow(
                    'Confirmed At',
                    contract.confirmedAt.isNotEmpty ? contract.confirmedAt : '-',
                  ),
                  pw.Spacer(),
                  pw.Divider(thickness: 0.5),
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'Generated securely via DaalSetu Platform',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
        await file.writeAsBytes(await doc.save(), flush: true);
      }

      await DownloadsService.saveBytes(
        fileName: fileName,
        bytes: await file.readAsBytes(),
        mimeType: 'application/pdf',
      );

      if (context.mounted) {
        AppSnackbar.showSnackBar(context, 
          const SnackBar(
            content: Text('Contract PDF downloaded successfully.'),
          ),
        );
      }

      try {
        final result = await OpenFilex.open(file.path, type: 'application/pdf');
        if (result.type != ResultType.done) {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'application/pdf')],
              subject: 'Contract $contractNumber',
            ),
          );
        }
      } catch (_) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/pdf')],
            subject: 'Contract $contractNumber',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.showSnackBar(context, 
          SnackBar(content: Text('Could not download PDF: $e')),
        );
      }
    }
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '-' : value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
