import 'package:daalsetu/modules/downloads/model/downloaded_file.dart';
import 'package:daalsetu/modules/downloads/service/downloads_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('downloaded file parses native MediaStore values', () {
    final file = DownloadedFile.fromMap(<String, dynamic>{
      'name': 'Delivery-Challan-123.pdf',
      'target': 'content://downloads/123',
      'size': 2048,
      'modifiedAt': 1760877000000,
      'mimeType': 'application/pdf',
    });

    expect(file.name, 'Delivery-Challan-123.pdf');
    expect(file.target, 'content://downloads/123');
    expect(file.size, 2048);
    expect(file.modifiedAt.millisecondsSinceEpoch, 1760877000000);
  });

  test('download MIME types cover supported file previews', () {
    expect(DownloadsService.mimeTypeFor('challan.pdf'), 'application/pdf');
    expect(
      DownloadsService.mimeTypeFor('offers.xlsx'),
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    expect(DownloadsService.mimeTypeFor('photo.JPG'), 'image/jpeg');
    expect(DownloadsService.mimeTypeFor('clip.mp4'), 'video/mp4');
  });
}
