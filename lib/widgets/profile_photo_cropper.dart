import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-screen square cropper for a profile photo.
/// Returns the cropped image bytes, or null when the user cancels.
Future<Uint8List?> showProfilePhotoCropper(Uint8List imageBytes) async {
  return await Get.to<Uint8List>(
    () => _ProfilePhotoCropper(imageBytes: imageBytes),
    fullscreenDialog: true,
  );
}

class _ProfilePhotoCropper extends StatefulWidget {
  const _ProfilePhotoCropper({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<_ProfilePhotoCropper> createState() => _ProfilePhotoCropperState();
}

class _ProfilePhotoCropperState extends State<_ProfilePhotoCropper> {
  final _controller = CropController();
  bool _cropping = false;

  void _apply() {
    if (_cropping) return;
    setState(() => _cropping = true);
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop photo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Crop(
                key: const Key('profile-photo-crop'),
                image: widget.imageBytes,
                controller: _controller,
                aspectRatio: 1,
                withCircleUi: true,
                onCropped: (result) {
                  switch (result) {
                    case CropSuccess(:final croppedImage):
                      Get.back(result: croppedImage);
                    case CropFailure():
                      if (mounted) setState(() => _cropping = false);
                      Get.snackbar('Crop failed', 'Could not crop this photo. Try another one.');
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  key: const Key('profile-photo-crop-apply'),
                  onPressed: _cropping ? null : _apply,
                  child: _cropping
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Use cropped photo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
