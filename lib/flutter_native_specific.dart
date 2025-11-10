import 'dart:io';
import 'dart:typed_data';

import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';

class FlutterNativeSpecific {
  Future<File?> convert({
    required String html,
    required String targetDirectory,
    required String targetName,
  }) async {
    var filePath = targetDirectory + "/" + targetName + "." + "pdf";
    var file = File(filePath);
    final newpdf = Document();
    List<Widget> widgets = await HTMLToPdf().convert(html);
    newpdf.addPage(MultiPage(
        maxPages: 200,
        build: (context) {
          return widgets;
        }));
    return await file.writeAsBytes(await newpdf.save());
  }

  Future<Uint8List?> convertToBytes({
    required String html,
  }) async {
    final newpdf = Document();
    List<Widget> widgets = await HTMLToPdf().convert(html);
    newpdf.addPage(MultiPage(
        maxPages: 200,
        build: (context) {
          return widgets;
        }));
    return await newpdf.save();
  }
}
