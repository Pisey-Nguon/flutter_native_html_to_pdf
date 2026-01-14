import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'html_parser.dart';
import 'pdf_page_size.dart';

/// A pure Dart implementation for converting HTML to PDF.
///
/// This class provides methods to convert HTML content to PDF files or bytes
/// without requiring any native platform code or external conversion packages.
class HtmlToPdfConverter {
  final HtmlParser _parser = HtmlParser();

  /// Converts HTML content to a PDF file.
  ///
  /// [html] - The HTML string to convert to PDF.
  /// [targetDirectory] - The directory path where the PDF file will be saved.
  /// [targetName] - The name of the PDF file (without extension).
  /// [pageSize] - Optional page size configuration. Defaults to A4.
  ///
  /// Returns a [File] object pointing to the generated PDF file.
  /// Throws an exception if the conversion fails.
  Future<File> convertHtmlToPdf({
    required String html,
    required String targetDirectory,
    required String targetName,
    PdfPageSize? pageSize,
  }) async {
    final pdfBytes = await convertHtmlToPdfBytes(
      html: html,
      pageSize: pageSize,
    );

    final filePath = '$targetDirectory/$targetName.pdf';
    final file = File(filePath);

    // Ensure directory exists
    final directory = Directory(targetDirectory);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return await file.writeAsBytes(pdfBytes);
  }

  /// Converts HTML content to PDF bytes.
  ///
  /// [html] - The HTML string to convert to PDF.
  /// [pageSize] - Optional page size configuration. Defaults to A4.
  ///
  /// Returns a [Uint8List] containing the PDF data.
  /// Throws an exception if the conversion fails.
  Future<Uint8List> convertHtmlToPdfBytes({
    required String html,
    PdfPageSize? pageSize,
  }) async {
    final document = pw.Document();
    final parseResult = await _parser.parseWithStyles(html);

    // Use pageSize if provided, otherwise use default A4
    final pdfPageFormat = pageSize != null
        ? PdfPageFormat(pageSize.width, pageSize.height)
        : PdfPageFormat.a4;

    // Use body margin from CSS, or default margin if not specified
    final pageMargin = parseResult.bodyMargin ?? const pw.EdgeInsets.all(24);

    document.addPage(
      pw.MultiPage(
        pageFormat: pdfPageFormat,
        margin: pageMargin,
        maxPages: 200,
        build: (context) => parseResult.widgets,
      ),
    );

    return await document.save();
  }
}
