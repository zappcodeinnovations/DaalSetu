import 'package:daalsetu/modules/profile/controller/profile_controller.dart';
import 'package:daalsetu/modules/profile/model/profile_model.dart';
import 'package:daalsetu/widgets/header_profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeProfile extends ProfileController {
  @override
  void onInit() {}
  @override
  Future<void> fetchProfile({bool showError = false, bool silent = false}) async {}
}

void main() {
  tearDown(Get.reset);

  Future<CircleAvatar> pump(WidgetTester tester, Map<String, dynamic> json) async {
    final controller = Get.put<ProfileController>(_FakeProfile());
    controller.profile.value = ProfileModel.fromJson(json);
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: Center(child: HeaderProfileAvatar()))));
    await tester.pump();
    return tester.widget<CircleAvatar>(find.byType(CircleAvatar));
  }

  testWidgets('shows the real photo when the user has one', (tester) async {
    final avatar = await pump(tester, {'id': 1, 'profile_image': '/media/profile/me.png'});
    expect(avatar.foregroundImage, isA<NetworkImage>());
    expect((avatar.foregroundImage as NetworkImage).url, contains('/media/profile/me.png'));
    // The test environment has no network: the photo request fails, which is fine (the icon stays underneath).
    await tester.pump(const Duration(milliseconds: 200));
    tester.takeException();
  });

  testWidgets('keeps the person icon when there is no photo', (tester) async {
    final avatar = await pump(tester, {'id': 1});
    expect(avatar.foregroundImage, isNull);
    expect(find.byIcon(Icons.person), findsNothing);
    expect(avatar.child, isA<Icon>());
  });
}
