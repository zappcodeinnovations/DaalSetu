import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses product fields required by admin edit flow', () {
    final product = ProductModel.fromJson({
      'id': 107,
      'title': 'Moong',
      'description': 'Premium quality',
      'category': {'id': 77, 'name': 'Split Yellow'},
      'seller': {'id': 111, 'username': 'MUKESH'},
      'amount': '45.00',
      'loading_location': 'Nagpur',
      'status': 'available',
      'interest_count': 0,
      'images': [
        {
          'id': 22,
          'image_url': 'https://example.com/image/',
          'download_url': 'https://example.com/image/download/',
          'is_primary': true,
        },
      ],
      'video': [
        {
          'id': 8,
          'title': 'Offer video',
          'video_url': 'https://example.com/video/',
          'download_url': 'https://example.com/video/download/',
          'is_primary': true,
        },
      ],
    });

    expect(product.id, 107);
    expect(product.category?.id, 77);
    expect(product.amount, '45.00');
    expect(product.loadingLocation, 'Nagpur');
    expect(product.images.single.isPrimary, isTrue);
    expect(product.videos.single.title, 'Offer video');
  });
}
