import 'package:flutter/services.dart';

const MethodChannel _androidPrintChannel =
    MethodChannel('com.smarthospital.nurse/print');

Future<bool> printHtmlDocumentImpl({
  required String title,
  required String htmlContent,
}) async {
  try {
    final ok = await _androidPrintChannel.invokeMethod<bool>(
      'printHtml',
      <String, dynamic>{
        'title': title,
        'html': htmlContent,
      },
    );
    return ok == true;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  } catch (_) {
    return false;
  }
}
