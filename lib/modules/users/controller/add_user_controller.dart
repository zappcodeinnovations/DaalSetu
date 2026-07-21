import 'dart:io';
import 'package:agro_broker/services/add_user_services.dart';
import 'package:agro_broker/modules/users/model/tag_model.dart';
import 'package:agro_broker/services/tag_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

      print("TAG RESULT: $result");
      print("TAG TYPE: ${result.runtimeType}");

      tags.assignAll(result);
    } catch (e) {
      print("Tag fetch error: $e");
    }
  }

  // create tag
  Future<Tag?> createTag(String tagName) async {
    try {
      final TagResponse response = await TagService.createTag(tagName);

      final Tag newTag = response.tag;

      tags.add(newTag);

      selectedTagId.value = newTag.id;

      return newTag;
    } catch (e) {
      print("Create tag error: $e");
      return null;
    }
  }

  /// ===============================
  /// CREATE USER
  /// ===============================
  Future<void> createUser({
    required String mobile,
    required String email,
    required String firstName,
    String? lastName,
    required String role,
    String? panNumber,
    String? gstNumber,
    String? gender,
    String? dob,
    File? panImage,
    File? gstImage,
  }) async {
    try {
      isLoading.value = true;

      final response = await AddUserServices.addUser(
        mobile: mobile,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        panNumber: panNumber,
        gstNumber: gstNumber,
        gender: gender,
        dob: dob,
        panImage: panImage,
        gstImage: gstImage,
        tagId: selectedTagId.value,
      );

      if (response["status"] == "success") {
        Get.snackbar(
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
      } else {
        Get.snackbar(
          "Error",
          response["message"] ?? "Something went wrong",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
