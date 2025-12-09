import 'dart:io';
import 'dart:typed_data';

import 'flutter_native_html_to_pdf_platform_interface.dart';
import 'pdf_page_size.dart';

class FlutterNativeHtmlToPdf {
  Future<File?> convertHtmlToPdf({
    required String html,
    required String targetDirectory,
    required String targetName,
    PdfPageSize? pageSize,
  }) async {
    return FlutterNativeHtmlToPdfPlatform.instance.convertHtmlToPdf(
      html: html,
      targetDirectory: targetDirectory,
      targetName: targetName,
      pageSize: pageSize,
    );
  }

  Future<Uint8List?> convertHtmlToPdfBytes({
    required String html,
    PdfPageSize? pageSize,
  }) async {
    return FlutterNativeHtmlToPdfPlatform.instance.convertHtmlToPdfBytes(
      html: html,
      pageSize: pageSize,
    );
  }
}
