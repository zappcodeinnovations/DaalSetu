import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
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

import '../controller/contract_controller.dart';
import 'contract_edit_view.dart';

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
      appBar: AppBar(
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
                _item('Product', contract.productTitle),
                _item('Category', contract.productCategory),
                _item('Product ID', contract.productId),
                _item('Interest ID', contract.interestId),
                _item(
                  'Deal amount',
                  '₹${contract.dealAmount} ${contract.amountUnit}',
                ),
                _item(
                  'Deal quantity',
                  '${contract.dealQuantity} ${contract.quantityUnit}',
                ),
                _item('Quantity (Qtl)', contract.quantityQtl),
                _item('Bag count', contract.bagCount),
                _item('Bags', contract.bags),
                _item('Packing weight', '${contract.packingWeightKg} kg'),
              ]),
              _section('Buyer', [
                _item('Buyer', contract.displayBuyerId),
                _item('Login/mobile', contract.buyerName),
                _item('Email', contract.buyerEmail),
                if (contract.buyerCompany != null && contract.buyerCompany!.isNotEmpty)
                  _item('Company', contract.buyerCompany),
                _item('Unique ID', contract.buyerUniqueId),
                _item('Database ID', contract.buyerId),
                _item('Remark', contract.buyerRemark),
              ]),
              _section('Seller', [
                _item('Seller', contract.displaySellerId),
                _item('Login/mobile', contract.sellerName),
                _item('Email', contract.sellerEmail),
                if (contract.sellerCompany != null && contract.sellerCompany!.isNotEmpty)
                  _item('Company', contract.sellerCompany),
                _item('Mapped ID', contract.sellerMappedId),
                _item('Database ID', contract.sellerId),
                _item('Remark', contract.sellerRemark),
              ]),
              _section('Loading & transporter', [
                _item('Loading from', contract.loadingFrom),
                _item('Loading to', contract.loadingTo),
                _item(
                  'Ready for loading at',
                  _date(contract.readyForLoadingAt),
                ),
                _item('Ready by user ID', contract.readyForLoadingById),
                _item(
                  'Transporter visible at',
                  _date(contract.transporterVisibleAt),
                ),
                _item(
                  'Visibility reason',
                  _label(contract.transporterVisibilityReason),
                ),
              ]),
              _section('Administration', [
                _item('Admin remark', contract.adminRemark),
                _item('Confirmed by admin ID', contract.confirmedByAdminId),
                _item('Confirmed branch ID', contract.confirmedBranchId),
                _item('Created by user ID', contract.createdByUserId),
                _item('Assigned sub-admin ID', contract.assignedSubAdminId),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    contract.contractId,
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
            const SizedBox(height: 8),
            Text('Internal ID: ${contract.id}'),
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
      ScaffoldMessenger.of(context).showSnackBar(
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
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
