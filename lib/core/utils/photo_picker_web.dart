// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'photo_picker.dart';

bool get supportsNativePicker => true;

Future<PickedPhotoData?> pickProfileImage() async {
  final completer = Completer<PickedPhotoData?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();

  input.onChange.first.then((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.first.then((_) {
      final result = reader.result;
      Uint8List? bytes;
      if (result is Uint8List) {
        bytes = result;
      } else if (result is ByteBuffer) {
        bytes = result.asUint8List();
      } else if (result is List<int>) {
        bytes = Uint8List.fromList(result);
      }
      if (bytes != null && bytes.isNotEmpty) {
        final mime = file.type.trim().isNotEmpty ? file.type : 'image/jpeg';
        completer.complete(
          PickedPhotoData(
            bytes: bytes,
            filename: file.name.isNotEmpty ? file.name : 'profile.jpg',
            mimeType: mime,
          ),
        );
      } else {
        completer.complete(null);
      }
    });
  });

  return completer.future;
}
