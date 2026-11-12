import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'photo_picker.dart';

const MethodChannel _androidPhotoPickerChannel =
    MethodChannel('com.smarthospital.nurse/photo_picker');

bool get supportsNativePicker => true;

Future<PickedPhotoData?> pickProfileImage() async {
  try {
    final res = await _androidPhotoPickerChannel
        .invokeMethod<Map<dynamic, dynamic>>('pickImage');
    if (res == null) return null;

    final rawBytes = res['bytes'];
    Uint8List? bytes;
    if (rawBytes is Uint8List) {
      bytes = rawBytes;
    } else if (rawBytes is List<int>) {
      bytes = Uint8List.fromList(rawBytes);
    }
    if (bytes == null || bytes.isEmpty) return null;

    final filename = (res['filename']?.toString().trim().isNotEmpty ?? false)
        ? res['filename'].toString().trim()
        : 'profile.jpg';
    final mimeType = (res['mimeType']?.toString().trim().isNotEmpty ?? false)
        ? res['mimeType'].toString().trim()
        : 'image/jpeg';

    return PickedPhotoData(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
  } on MissingPluginException {
    throw const FormatException('NATIVE_REBUILD_NEEDED');
  } catch (_) {
    return null;
  }
}
