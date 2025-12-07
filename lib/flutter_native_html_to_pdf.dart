import 'dart:io';
import 'dart:typed_data';

import 'html_to_pdf_converter.dart';
import 'pdf_page_size.dart';

/// Pure Dart HTML to PDF converter with no native code dependencies
/// 
/// This class provides methods to convert HTML content to PDF files or bytes
/// using only Dart code, without relying on native platform APIs.
class FlutterNativeHtmlToPdf {
  final _converter = HtmlToPdfConverter();

  /// Converts HTML content to a PDF file
  /// 
  /// [html] - The HTML content to convert
  /// [targetDirectory] - The directory where the PDF file will be saved
  /// [targetName] - The name of the PDF file (without extension)
  /// [pageSize] - Optional page size for the PDF (defaults to A4)
  /// 
  /// Returns a [File] object pointing to the generated PDF file
  Future<File?> convertHtmlToPdf({
    required String html,
    required String targetDirectory,
    required String targetName,
    PdfPageSize? pageSize,
  }) async {
    return _converter.convertHtmlToPdf(
      html: html,
      targetDirectory: targetDirectory,
      targetName: targetName,
      pageSize: pageSize,
    );
  }

  /// Converts HTML content directly to PDF bytes without saving to a file
  /// 
  /// [html] - The HTML content to convert
  /// [pageSize] - Optional page size for the PDF (defaults to A4)
  /// 
  /// Returns a [Uint8List] containing the PDF data
  Future<Uint8List?> convertHtmlToPdfBytes({
    required String html,
    PdfPageSize? pageSize,
  }) async {
    return _converter.convertHtmlToPdfBytes(
      html: html,
      pageSize: pageSize,
    );
  }
}
