import 'print_helper_stub.dart'
    if (dart.library.html) 'print_helper_web.dart' as impl;

class PrintDocumentHelper {
  PrintDocumentHelper._();

  static Future<bool> printHtmlDocument({
    required String title,
    required String htmlContent,
  }) =>
      impl.printHtmlDocumentImpl(title: title, htmlContent: htmlContent);
}
