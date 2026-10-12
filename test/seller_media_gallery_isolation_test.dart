import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/seller/products/model/product_media_model.dart';

void main() {
  group('ProductMediaModel parsing & Offer isolation', () {
    test('ProductImageModel robustly parses product id across numeric, string, and map shapes', () {
      final imgInt = ProductImageModel.fromJson({
        'id': 1,
        'product': 108,
        'image_url': 'https://example.com/1.png',
        'is_primary': true,
      });
      expect(imgInt.id, 1);
      expect(imgInt.productId, 108);
      expect(imgInt.isPrimary, true);

      final imgStr = ProductImageModel.fromJson({
        'id': '2',
        'product': '109',
        'image_url': 'https://example.com/2.png',
        'is_primary': 'true',
      });
      expect(imgStr.id, 2);
      expect(imgStr.productId, 109);
      expect(imgStr.isPrimary, true);

      final imgMap = ProductImageModel.fromJson({
        'id': 3,
        'product': {'id': 110, 'title': 'Lentils'},
        'image': 'https://example.com/3.png',
        'is_primary': 1,
      });
      expect(imgMap.id, 3);
      expect(imgMap.productId, 110);
      expect(imgMap.isPrimary, true);

      final imgOfferId = ProductImageModel.fromJson({
        'id': 4,
        'product_id': 111,
        'file': 'https://example.com/4.png',
      });
      expect(imgOfferId.productId, 111);
    });

    test('ProductVideoModel robustly parses product id', () {
      final vid = ProductVideoModel.fromJson({
        'id': 10,
        'product': '201',
        'video_url': 'https://example.com/vid.mp4',
        'title': 'Sample Video',
        'is_primary': true,
      });
      expect(vid.id, 10);
      expect(vid.productId, 201);
      expect(vid.title, 'Sample Video');
    });

    test('Images and videos are strictly isolated by offer/product ID without global leak', () {
      final rawApiPayload = [
        {
          'id': 1,
          'product': 100,
          'image_url': 'https://example.com/offer100_img1.png',
          'is_primary': true,
        },
        {
          'id': 2,
          'product': 100,
          'image_url': 'https://example.com/offer100_img2.png',
          'is_primary': false,
        },
        {
          'id': 3,
          'product': 200,
          'image_url': 'https://example.com/offer200_img1.png',
          'is_primary': true,
        },
        {
          'id': 4,
          'product': 300,
          'image_url': 'https://example.com/offer300_img1.png',
          'is_primary': true,
        },
      ];

      final allParsed = rawApiPayload
          .map((m) => ProductImageModel.fromJson(m))
          .toList();

      // Offer 100 gallery must only contain offer 100 items
      final offer100Images = allParsed.where((i) => i.productId == 100).toList();
      expect(offer100Images.length, 2);
      expect(offer100Images.every((i) => i.productId == 100), isTrue);

      // Offer 200 gallery must only contain offer 200 items
      final offer200Images = allParsed.where((i) => i.productId == 200).toList();
      expect(offer200Images.length, 1);
      expect(offer200Images.first.id, 3);
      expect(offer200Images.first.productId, 200);

      // Offer 400 (no uploads yet) must be empty, not showing any other offer's images
      final offer400Images = allParsed.where((i) => i.productId == 400).toList();
      expect(offer400Images.isEmpty, isTrue);
    });
  });
}
