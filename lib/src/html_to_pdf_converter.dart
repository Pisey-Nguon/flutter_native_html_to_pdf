import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'pdf_page_size.dart';

/// Converts HTML content to PDF using the native platform's WebView engine.
///
/// On Android the HTML is rendered in an offscreen [WebView] and exported
/// via [PrintDocumentAdapter].  On iOS a [WKWebView] renders the HTML and
/// the PDF is produced with `WKWebView.createPDF` (iOS 14+) or
/// `UIPrintPageRenderer` (iOS 12/13).
///
/// Because rendering happens inside a real browser engine, the output is
/// pixel-perfect and supports the full range of HTML/CSS/JavaScript that the
/// platform WebView handles — including custom fonts, flexbox, grids, images,
/// and `@media print` rules.
class HtmlToPdfConverter {
  static const MethodChannel _channel =
      MethodChannel('flutter_native_html_to_pdf');

  /// Converts [html] to a PDF file saved at
  /// `[targetDirectory]/[targetName].pdf`.
  ///
  /// [pageSize] controls the paper dimensions; defaults to A4 when omitted.
  ///
  /// Returns a [File] pointing to the generated PDF.
  /// Throws a [PlatformException] on native errors.
  Future<File> convertHtmlToPdf({
    required String html,
    required String targetDirectory,
    required String targetName,
    PdfPageSize? pageSize,
  }) async {
    final String? filePath = await _channel.invokeMethod<String>(
      'convertHtmlToPdf',
      {
        'html': html,
        'targetDirectory': targetDirectory,
        'targetName': targetName,
        if (pageSize != null) 'pageWidth': pageSize.width,
        if (pageSize != null) 'pageHeight': pageSize.height,
      },
    );

    if (filePath == null || filePath.isEmpty) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'Native side returned no file path.',
      );
    }

    return File(filePath);
  }

  /// Converts [html] to PDF bytes held in memory.
  ///
  /// [pageSize] controls the paper dimensions; defaults to A4 when omitted.
  ///
  /// Returns a [Uint8List] containing the raw PDF data.
  /// Throws a [PlatformException] on native errors.
  Future<Uint8List> convertHtmlToPdfBytes({
    required String html,
    PdfPageSize? pageSize,
  }) async {
    final Uint8List? bytes = await _channel.invokeMethod<Uint8List>(
      'convertHtmlToPdfBytes',
      {
        'html': html,
        if (pageSize != null) 'pageWidth': pageSize.width,
        if (pageSize != null) 'pageHeight': pageSize.height,
      },
    );

    if (bytes == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'Native side returned null bytes.',
      );
    }

    return bytes;
  }
}
