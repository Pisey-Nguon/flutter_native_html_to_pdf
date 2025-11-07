import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? generatedPdfFilePath;
  Uint8List? generatedPdfBytes;

  final _flutterNativeHtmlToPdfPlugin = FlutterNativeHtmlToPdf();

  @override
  void initState() {
    super.initState();
    generateExampleDocument();
    generateExampleDocumentBytes();
  }
  
  Future<void> generateExampleDocument() async {
    const htmlContent = """
   <!DOCTYPE html>
<html>
<head>
    <title>Sample HTML Page</title>
</head>
<body>
    <h1>Welcome to My Website!</h1>
    <p>This is a sample paragraph text.</p>
    <img src="https://picsum.photos/200/300" alt="Description of the image">
</body>
</html>
    """;

    Directory appDocDir = await getApplicationDocumentsDirectory();
    final targetPath = appDocDir.path;
    const targetFileName = "mytext";
    final generatedPdfFile =
        await _flutterNativeHtmlToPdfPlugin.convertHtmlToPdf(
      html: htmlContent,
      targetDirectory: targetPath,
      targetName: targetFileName,
    );

    generatedPdfFilePath = generatedPdfFile?.path;
  }

  Future<void> generateExampleDocumentBytes() async {
    const htmlContent = """
   <!DOCTYPE html>
<html>
<head>
    <title>Sample HTML Page - Bytes</title>
</head>
<body>
    <h1>PDF Generated from Bytes!</h1>
    <p>This PDF was generated directly to Uint8List without saving to a file first.</p>
    <p>This is more performant for scenarios where you don't need to save the file locally.</p>
</body>
</html>
    """;

    final pdfBytes =
        await _flutterNativeHtmlToPdfPlugin.convertHtmlToPdfBytes(
      html: htmlContent,
    );

    setState(() {
      generatedPdfBytes = pdfBytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text("Flutter Native Html to PDF"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Share PDF (from file)"),
              onPressed: () async {
                if (generatedPdfFilePath != null) {
                  await Share.shareXFiles(
                    [XFile(generatedPdfFilePath!)],
                    text: 'This is pdf file',
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Share PDF (from bytes)"),
              onPressed: () async {
                if (generatedPdfBytes != null) {
                  // Save bytes to temporary file for sharing
                  final tempDir = await getTemporaryDirectory();
                  final tempFile = File('${tempDir.path}/temp_pdf_from_bytes.pdf');
                  await tempFile.writeAsBytes(generatedPdfBytes!);
                  
                  await Share.shareXFiles(
                    [XFile(tempFile.path)],
                    text: 'This PDF was generated from bytes!',
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Text(
              generatedPdfBytes != null 
                  ? 'PDF Bytes size: ${generatedPdfBytes!.length} bytes'
                  : 'Generating PDF bytes...',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ));
  }
}
