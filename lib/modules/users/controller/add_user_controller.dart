import 'dart:io';
import '../../../services/add_user_services.dart';
import '../model/tag_model.dart';
import '../../../services/tag_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './user_controller.dart';
import '../../../utils/app_snackbar.dart';

class AddUserController extends GetxController {
  var isLoading = false.obs;

  /// TAG LIST
  var tags = <Tag>[].obs;

  /// SELECTED TAG
  var selectedTagId = RxnInt();

  @override
  void onInit() {
    fetchTags();
    super.onInit();
  }

  /// ===============================
  /// FETCH TAGS FROM API
  /// ===============================
  Future<void> fetchTags() async {
    try {
      final result = await TagService.fetchTags();
      tags.assignAll(result);
    } catch (e) {
      debugPrint("Tag fetch error: $e");
    }
  }

  /// Resets controller state to clean initial values.
  void reset() {
    selectedTagId.value = null;
    isLoading.value = false;
  }

  /// ===============================
  /// CREATE USER
  /// ===============================
  Future<bool> createUser({
    required String mobile,
    required String email,
    required String firstName,
    String? lastName,
    required String role,
    required String password,
    String? branchCode,
    String? panNumber,
    String? gstNumber,
    String? gender,
    String? dob,
    File? panImage,
    File? gstImage,
    VoidCallback? onSuccess,
  }) async {
    try {
      isLoading.value = true;

      final response = await AddUserServices.addUser(
        mobile: mobile,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        password: password,
        branchCode: branchCode,
        panNumber: panNumber,
        gstNumber: gstNumber,
        gender: gender,
        dob: dob,
        panImage: panImage,
        gstImage: gstImage,
        tagId: selectedTagId.value,
      );

      if (response["status"] == "success") {
        if (Get.isRegistered<UserController>()) {
          Get.find<UserController>().fetchUsers();
        }

        reset();
        onSuccess?.call();

        AppSnackbar.snackbar(
          "Success",
          response["message"] ?? "User created successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(milliseconds: 800),
        );

        Future.delayed(const Duration(milliseconds: 900), () {
          Get.back(result: true);
        });
        return true;
      } else {
        AppSnackbar.snackbar(
          "Error",
          response["message"] ?? "Something went wrong",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      AppSnackbar.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
