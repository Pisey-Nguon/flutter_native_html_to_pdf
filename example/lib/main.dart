import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

    try {
      // Show start toast
      Fluttertoast.showToast(
        msg: "Starting PDF generation...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
      
      print('Starting PDF file generation...');
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
      print('PDF file generated: $generatedPdfFilePath');
      
      // Show success toast
      Fluttertoast.showToast(
        msg: "PDF file generated successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error generating PDF file: $e');
      
      // Show error toast
      Fluttertoast.showToast(
        msg: "Failed to generate PDF file",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
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

    try {
      // Show start toast
      Fluttertoast.showToast(
        msg: "Converting HTML to PDF bytes...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
      
      print('Starting PDF bytes generation...');
      final pdfBytes =
          await _flutterNativeHtmlToPdfPlugin.convertHtmlToPdfBytes(
        html: htmlContent,
      );

      print('PDF bytes generated: ${pdfBytes?.length ?? 0} bytes');
      
      setState(() {
        generatedPdfBytes = pdfBytes;
      });
      
      if (pdfBytes != null) {
        // Show success toast
        Fluttertoast.showToast(
          msg: "PDF bytes generated successfully! (${pdfBytes.length} bytes)",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('Error generating PDF bytes: $e');
      setState(() {
        generatedPdfBytes = null;
      });
      
      // Show error toast
      Fluttertoast.showToast(
        msg: "Failed to generate PDF bytes",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
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
              child: const Text("Generate PDF Bytes"),
              onPressed: () async {
                await generateExampleDocumentBytes();
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Share PDF (from file)"),
              onPressed: () async {
                try {
                  print('Generating PDF file...');
                  
                  // Generate if not already generated
                  if (generatedPdfFilePath == null) {
                    await generateExampleDocument();
                  }
                  
                  if (generatedPdfFilePath != null) {
                    Fluttertoast.showToast(
                      msg: "Preparing to share PDF...",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.orange,
                      textColor: Colors.white,
                    );
                    
                    print('Sharing PDF file: $generatedPdfFilePath');
                    await Share.shareXFiles(
                      [XFile(generatedPdfFilePath!)],
                      text: 'This is pdf file',
                    );
                    print('Share completed');
                  } else {
                    print('ERROR: Failed to generate PDF file');
                    Fluttertoast.showToast(
                      msg: "ERROR: Failed to generate PDF file",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                  }
                } catch (e, stackTrace) {
                  print('Error with PDF file: $e');
                  print('Stack trace: $stackTrace');
                  Fluttertoast.showToast(
                    msg: "Error sharing PDF: $e",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Share PDF (from bytes)"),
              onPressed: () async {
                try {
                  print('Share button pressed. generatedPdfBytes: ${generatedPdfBytes?.length ?? "null"}');
                  
                  if (generatedPdfBytes == null) {
                    print('PDF bytes are null, regenerating...');
                    await generateExampleDocumentBytes();
                  }
                  
                  if (generatedPdfBytes != null) {
                    Fluttertoast.showToast(
                      msg: "Creating temporary file for sharing...",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.orange,
                      textColor: Colors.white,
                    );
                    
                    print('Creating temp file from ${generatedPdfBytes!.length} bytes');
                    // Save bytes to temporary file for sharing
                    final tempDir = await getTemporaryDirectory();
                    final tempFile = File('${tempDir.path}/temp_pdf_from_bytes.pdf');
                    await tempFile.writeAsBytes(generatedPdfBytes!);
                    print('Temp file created at: ${tempFile.path}');
                    
                    await Share.shareXFiles(
                      [XFile(tempFile.path)],
                      text: 'This PDF was generated from bytes!',
                    );
                    print('Share completed');
                  } else {
                    print('ERROR: Still no PDF bytes after regeneration');
                    Fluttertoast.showToast(
                      msg: "ERROR: Still no PDF bytes after regeneration",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                  }
                } catch (e, stackTrace) {
                  print('Error sharing PDF: $e');
                  print('Stack trace: $stackTrace');
                  Fluttertoast.showToast(
                    msg: "Error sharing PDF: $e",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Text(
              generatedPdfBytes != null 
                  ? 'PDF Bytes: ${generatedPdfBytes!.length} bytes ready'
                  : 'Click button to generate PDF',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ));
  }
}
