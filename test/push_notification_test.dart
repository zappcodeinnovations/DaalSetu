import 'package:daalsetu/services/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a push payload becomes the same model the in-app list uses', () {
    final model = notificationFromPush({
      'type': 'interest',
      'reference_id': '5',
      'related_product_id': '12',
      'redirect_url': '/products/12/interests/5/negotiation/',
      'title': 'Counter Offer Received',
      'message': 'Seller sent a counter offer.',
    });
    expect(model.title, 'Counter Offer Received');
    expect(model.type, 'interest');
    expect(model.referenceId, 5);
    expect(model.relatedProduct, 12);
    expect(model.productTargetId, 12);
    expect(model.redirectUrl, '/products/12/interests/5/negotiation/');
    expect(model.isRead, isFalse);
  });

  test('missing or blank ids do not break a push', () {
    final model = notificationFromPush({'type': 'system', 'reference_id': '', 'title': 'Hi'});
    expect(model.referenceId, isNull);
    expect(model.relatedProduct, isNull);
    expect(model.message, isNull);
  });

  test('push calls are harmless when Firebase is not started (tests, web, desktop)', () async {
    await PushNotificationService.unregister();
    await PushNotificationService.registerForCurrentUser();
  });
}
