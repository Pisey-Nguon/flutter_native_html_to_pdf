/// A Flutter plugin for converting HTML to PDF using native WebView rendering.
///
/// On **Android**, the HTML is loaded into an offscreen [WebView] and exported
/// to PDF via the Android print framework (`PrintDocumentAdapter`).
/// On **iOS**, the HTML is loaded into a [WKWebView] and the PDF data is
/// produced with `WKWebView.createPDF` (iOS 14+) or `UIPrintPageRenderer`
/// (iOS 12–13).
///
/// Because native WebView engines do the rendering, the output faithfully
/// reproduces the full range of HTML/CSS/JavaScript supported by the platform,
/// including custom fonts, flexbox, CSS Grid, images, `@media print` rules,
/// and more.
///
/// ## Usage
///
/// ```dart
/// import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
///
/// // Create an instance of the converter
/// final converter = HtmlToPdfConverter();
///
/// // Convert HTML to a PDF file
/// final file = await converter.convertHtmlToPdf(
///   html: '<h1>Hello World</h1>',
///   targetDirectory: '/path/to/directory',
///   targetName: 'my_document',
/// );
///
/// // Or convert HTML to PDF bytes
/// final bytes = await converter.convertHtmlToPdfBytes(
///   html: '<h1>Hello World</h1>',
/// );
/// ```
library;

export 'src/html_to_pdf_converter.dart';
export 'src/pdf_page_size.dart';

// For backward compatibility, also export the main class with the old name
import 'dart:io';
import 'dart:typed_data';

import 'src/html_to_pdf_converter.dart';
import 'src/pdf_page_size.dart';

/// Legacy class for backward compatibility.
///
/// Consider using [HtmlToPdfConverter] directly for new code.
@Deprecated('Use HtmlToPdfConverter instead')
class FlutterNativeHtmlToPdf {
  final _converter = HtmlToPdfConverter();

  /// Converts HTML content to a PDF file.
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

  /// Converts HTML content to PDF bytes.
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

