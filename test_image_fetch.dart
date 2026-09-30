import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  SharedPreferences.setMockInitialValues({'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzg1ODUyNDc2LCJpYXQiOjE3ODUyNDc2NzYsImp0aSI6IjBhZTQyOTYwNDVlZTQ1ZWI4MGY3ZTZlYTNhYWRjZWU3IiwidXNlcl9pZCI6Ijg0In0.N7Q-VpqNnZxrB3fULoWz02NtRYAZE5X2MvmC-j_2PT8'});
  
  try {
    print('Fetching image from Dart...');
    final response = await http.get(
      Uri.parse('https://daalsetu.zappcode.in/api/product-media/images/24/view/'),
      headers: {'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzg1ODUyNDc2LCJpYXQiOjE3ODUyNDc2NzYsImp0aSI6IjBhZTQyOTYwNDVlZTQ1ZWI4MGY3ZTZlYTNhYWRjZWU3IiwidXNlcl9pZCI6Ijg0In0.N7Q-VpqNnZxrB3fULoWz02NtRYAZE5X2MvmC-j_2PT8'},
    );
    print('Status Code: \${response.statusCode}');
    print('Content-Type: \${response.headers['content-type']}');
    print('Content-Length: \${response.bodyBytes.length}');
  } catch (e) {
    print('Error: \$e');
  }
}
