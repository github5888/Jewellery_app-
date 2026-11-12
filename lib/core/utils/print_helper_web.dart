// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<bool> printHtmlDocumentImpl({
  required String title,
  required String htmlContent,
}) async {
  try {
    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final win = html.window.open(url, '_blank');
    if (win != null) {
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        html.Url.revokeObjectUrl(url);
      });
      return true;
    }
    html.Url.revokeObjectUrl(url);
    html.window.print();
    return true;
  } catch (_) {
    try {
      html.window.print();
      return true;
    } catch (_) {
      return false;
    }
  }
}
