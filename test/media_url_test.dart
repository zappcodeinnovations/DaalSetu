import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/widgets/media_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final base = Uri.parse(ApiUrls.baseUrl);

  test('http media links from the backend are served from the app HTTPS origin', () {
    final uri = resolveMediaUri('http://internal-host:8000/api/product-media/images/7/view/');
    expect(uri.scheme, base.scheme);
    expect(uri.host, base.host);
    expect(uri.path, '/api/product-media/images/7/view/');
  });

  test('relative media paths get the app origin', () {
    expect(resolveMediaUri('/media/products/a.png').toString(), '${ApiUrls.baseUrl}/media/products/a.png');
  });

  test('query strings are kept', () {
    expect(resolveMediaUri('http://x/api/product-media/videos/3/view/?token=abc').query, 'token=abc');
  });

  test('links outside the app are left alone', () {
    expect(resolveMediaUri('https://cdn.example.com/img.png').toString(), 'https://cdn.example.com/img.png');
  });
}
