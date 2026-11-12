import 'dart:typed_data';

import 'photo_picker_stub.dart'
    if (dart.library.html) 'photo_picker_web.dart' as impl;

class PickedPhotoData {
  final Uint8List bytes;
  final String filename;
  final String mimeType;

  const PickedPhotoData({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });
}

class ProfilePhotoPicker {
  ProfilePhotoPicker._();

  static bool get supportsNativePicker => impl.supportsNativePicker;

  static Future<PickedPhotoData?> pickImage() => impl.pickProfileImage();
}
