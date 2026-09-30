import 'package:daalsetu/modules/Auth/login/model/login_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the documented admin login response', () {
    final response = LoginResponse.fromJson({
      'access': 'access-token',
      'refresh': 'refresh-token',
      'user': {
        'id': 84,
        'username': '7984130626',
        'role': 'admin',
        'kyc_status': 'pending',
        'status': 'active',
        'account_status': 'active',
        'active_branch_id': 22,
        'active_branch_code': 'PUN718M',
      },
    });

    expect(response.access, 'access-token');
    expect(response.user.role, 'admin');
    expect(response.user.activeBranchId, 22);
    expect(response.user.activeBranchCode, 'PUN718M');
  });
}
