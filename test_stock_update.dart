import 'package:agro_broker/services/product_services.dart';
import 'package:agro_broker/utils/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Set up token mock for test
  SharedPreferences.setMockInitialValues({'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzg1ODUyNDc2LCJpYXQiOjE3ODUyNDc2NzYsImp0aSI6IjBhZTQyOTYwNDVlZTQ1ZWI4MGY3ZTZlYTNhYWRjZWU3IiwidXNlcl9pZCI6Ijg0In0.N7Q-VpqNnZxrB3fULoWz02NtRYAZE5X2MvmC-j_2PT8'});
  
  try {
    print('Calling updateStock...');
    final response = await ProductService.updateStock(
      productId: 107,
      action: 'Add',
      quantity: '1',
      bags: '',
      packingKg: '',
    );
    print('Response: \$response');
  } catch (e) {
    print('Error: \$e');
  }
}
