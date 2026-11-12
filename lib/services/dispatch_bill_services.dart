import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/modules/downloads/service/downloads_service.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

/// A bill / invoice file attached to a delivery challan at dispatch (MoM point 23).
class DispatchBill {
  const DispatchBill({
    required this.id,
    required this.fileName,
    this.contentType = '',
    this.uploadedBy = '',
    this.uploadedAt = '',
  });

  final int id;
  final String fileName;
  final String contentType;
  final String uploadedBy;
  final String uploadedAt;

  bool get isPdf =>
      contentType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');

  factory DispatchBill.fromJson(Map<String, dynamic> json) => DispatchBill(
        id: int.tryParse('${json['id']}') ?? 0,
        fileName: json['file_name']?.toString() ?? 'Bill',
        contentType: json['content_type']?.toString() ?? '',
        uploadedBy: json['uploaded_by']?.toString() ?? '',
        uploadedAt: json['uploaded_at']?.toString() ?? '',
      );

  static List<DispatchBill> listFrom(dynamic raw) => (raw is List ? raw : const [])
      .whereType<Map>()
      .map((item) => DispatchBill.fromJson(Map<String, dynamic>.from(item)))
      .where((bill) => bill.id > 0)
      .toList();
}

class DispatchBillServices {
  DispatchBillServices._();

  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];

  static String _billsEndpoint(int challanId) => '/api/delivery-challans/$challanId/bills/';
  static String _downloadEndpoint(int billId) => '/api/delivery-challans/bills/$billId/download/';

  /// Lets the user choose PDF / image bills; empty when cancelled.
  static Future<List<String>> pickBillFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    return (result?.files ?? const [])
        .map((file) => file.path)
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toList();
  }

  /// Bills of a challan and whether this user may add more.
  static Future<({List<DispatchBill> bills, bool canUpload})> list(int challanId) async {
    final response = await ApiClient.get(endpoint: _billsEndpoint(challanId), requireAuth: true);
    final data = response is Map ? response : const {};
    return (bills: DispatchBill.listFrom(data['data']), canUpload: data['can_upload'] == true);
  }

  /// Uploads bills to an already dispatched challan, all files in one request.
  static Future<void> upload(int challanId, List<String> paths) async {
    final response = await ApiClient.postMultipart(
      endpoint: _billsEndpoint(challanId),
      fields: const {},
      fileLists: {'bill_files': paths},
      requireAuth: true,
    );
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Could not upload the bill');
    }
  }

  /// Calls a dispatch endpoint with the bills in the same request, so the
  /// buyer's and seller's dispatch email carries them as attachments.
  static Future<Map<String, dynamic>> dispatchWithBills(String endpoint, List<String> paths) {
    return ApiClient.postMultipart(
      endpoint: endpoint,
      fields: const {},
      fileLists: {'bill_files': paths},
      requireAuth: true,
    );
  }

  /// Downloads a bill into the app's Downloads and returns where it was saved.
  static Future<String> download(DispatchBill bill) async {
    final token = await AppPreferences.getAccessToken();
    final response = await http.get(
      Uri.parse(ApiUrls.baseUrl + _downloadEndpoint(bill.id)),
      headers: {if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Could not download the bill.');
    }
    return DownloadsService.saveBytes(fileName: bill.fileName, bytes: response.bodyBytes);
  }
}
