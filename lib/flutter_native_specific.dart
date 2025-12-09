import 'dart:io';
import 'dart:typed_data';

import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';
import 'pdf_page_size.dart';

class FlutterNativeSpecific {
  Future<File?> convert({
    required String html,
    required String targetDirectory,
    required String targetName,
    PdfPageSize? pageSize,
  }) async {
    var filePath = '$targetDirectory/$targetName.pdf';
    var file = File(filePath);
    final newpdf = Document();
    List<Widget> widgets = await HTMLToPdf().convert(html);

    // Use pageSize if provided, otherwise use default
    final pdfPageFormat = pageSize != null
        ? PdfPageFormat(pageSize.width, pageSize.height)
        : PdfPageFormat.a4;

    newpdf.addPage(MultiPage(
        pageFormat: pdfPageFormat,
        maxPages: 200,
        build: (context) {
          return widgets;
        }));
    return await file.writeAsBytes(await newpdf.save());
  }

  Future<Uint8List?> convertToBytes({
    required String html,
    PdfPageSize? pageSize,
  }) async {
    final newpdf = Document();
    List<Widget> widgets = await HTMLToPdf().convert(html);

    // Use pageSize if provided, otherwise use default
    final pdfPageFormat = pageSize != null
        ? PdfPageFormat(pageSize.width, pageSize.height)
        : PdfPageFormat.a4;

    newpdf.addPage(MultiPage(
        pageFormat: pdfPageFormat,
        maxPages: 200,
        build: (context) {
          return widgets;
        }));
    return await newpdf.save();
  }
}
