import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../model/downloaded_file.dart';

class DownloadsService {
  DownloadsService._();

  static const MethodChannel _channel = MethodChannel(
    'com.zappkode.daalsetu/downloads',
  );

  static Future<List<DownloadedFile>> listFiles() async {
    final files = <DownloadedFile>[];
    if (Platform.isAndroid) {
      try {
        final raw = await _channel.invokeMethod<List<dynamic>>('listDownloads');
        files.addAll(
          (raw ?? const <dynamic>[])
              .whereType<Map<dynamic, dynamic>>()
              .map(DownloadedFile.fromMap)
              .where((file) => file.target.isNotEmpty),
        );
      } on MissingPluginException catch (error) {
        // An APK built before the Downloads feature: show what the app saved itself.
        debugPrint('📂 Native downloads list unavailable ($error); showing app files.');
      }
    }
    // Files saved inside the app (iOS, and the Android fallback in saveBytes).
    files.addAll(await _appFiles());
    files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return files;
  }

  static Future<List<DownloadedFile>> _appFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final entries = await directory
        .list()
        .where((entry) => entry is File)
        .toList();
    final files = <DownloadedFile>[];
    for (final entry in entries.whereType<File>().where((f) => _isDocument(f.path))) {
      final stat = await entry.stat();
      files.add(
        DownloadedFile(
          name: entry.uri.pathSegments.last,
          target: entry.path,
          size: stat.size,
          modifiedAt: stat.modified,
          mimeType: mimeTypeFor(entry.path),
        ),
      );
    }
    return files;
  }

  /// The documents folder also holds plugin/cache files; list only real downloads.
  static bool _isDocument(String path) =>
      mimeTypeFor(path) != 'application/octet-stream';

  static Future<String> saveBytes({
    required String fileName,
    required List<int> bytes,
    String? mimeType,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final type = mimeType ?? mimeTypeFor(safeName);
    if (Platform.isAndroid) {
      final args = <String, dynamic>{
        'fileName': safeName,
        'bytes': Uint8List.fromList(bytes),
        'mimeType': type,
      };
      try {
        // Phone's Downloads folder (and so the app's Downloads screen).
        return await _channel.invokeMethod<String>('saveFileToDownloads', args) ?? '';
      } on MissingPluginException {
        // Older APK: its PDF-only save, else keep the file inside the app.
        if (type == 'application/pdf') {
          try {
            return await _channel.invokeMethod<String>('savePdfToDownloads', args) ?? '';
          } on MissingPluginException {
            // fall through
          }
        }
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<bool> open(DownloadedFile file) async {
    if (Platform.isAndroid) {
      final opened = await _channel.invokeMethod<bool>(
        'openDownload',
        <String, dynamic>{'target': file.target, 'mimeType': file.mimeType},
      );
      if (opened == true) return true;
    }
    final result = await OpenFilex.open(file.target, type: file.mimeType);
    return result.type == ResultType.done;
  }

  static Future<bool> delete(DownloadedFile file) async {
    if (Platform.isAndroid && file.target.startsWith('content://')) {
      return await _channel.invokeMethod<bool>(
            'deleteDownload',
            <String, dynamic>{'target': file.target},
          ) ??
          false;
    }
    final localFile = File(file.target);
    if (!await localFile.exists()) return false;
    await localFile.delete();
    return true;
  }

  static String mimeTypeFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'pdf' => 'application/pdf',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'xls' => 'application/vnd.ms-excel',
      'csv' => 'text/csv',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'mp4' => 'video/mp4',
      _ => 'application/octet-stream',
    };
  }
}
