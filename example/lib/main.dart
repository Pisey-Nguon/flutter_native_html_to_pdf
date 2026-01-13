import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:flutter_native_html_to_pdf/pdf_page_size.dart';
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
  PdfPageSize selectedPageSize = PdfPageSize.a4;

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
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f0f0f0;
        }
        h1 {
            color: #ff0000;
            font-weight: bold;
            font-size: 24px;
        }
        h2 {
            color: #0000ff;
            font-style: italic;
        }
        p {
            color: #008000;
            font-size: 16px;
        }
        .highlight {
            background-color: #ffff00;
            padding: 10px;
            color: #000000;
        }
        .box {
            border: 2px solid #ff00ff;
            padding: 15px;
            margin: 10px 0;
            background-color: #e0e0ff;
        }
    </style>
</head>
<body>
    <h1>Welcome to My Website!</h1>
    <h2>Testing Colors and Fonts on iOS</h2>
    <p>This is a sample paragraph text with green color.</p>
    <div class="highlight">
        <p>This is highlighted text with yellow background.</p>
    </div>
    <div class="box">
        <p>This is a box with purple border and light blue background.</p>
    </div>
    <img src="https://picsum.photos/200/300" alt="Description of the image">
</body>
</html>
    """;

    try {
      // Show start toast
      Fluttertoast.showToast(
        msg: "Starting PDF generation with ${selectedPageSize.name} size...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );

      Directory appDocDir = await getApplicationDocumentsDirectory();
      final targetPath = appDocDir.path;
      const targetFileName = "mytext";
      final generatedPdfFile =
          await _flutterNativeHtmlToPdfPlugin.convertHtmlToPdf(
        html: htmlContent,
        targetDirectory: targetPath,
        targetName: targetFileName,
        pageSize: selectedPageSize,
      );

      generatedPdfFilePath = generatedPdfFile?.path;

      // Show success toast
      Fluttertoast.showToast(
        msg:
            "PDF file generated successfully with ${selectedPageSize.name} size!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
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
    final htmlContent = """
   <!DOCTYPE html>
<html>
<head>
    <title>Sample HTML Page - Bytes</title>
    <style>
        body {
            font-family: 'Georgia', serif;
            margin: 20px;
            background-color: #ffffff;
        }
        h1 {
            color: #ff6600;
            font-weight: bold;
            font-size: 28px;
            text-decoration: underline;
        }
        p {
            color: #333333;
            font-size: 14px;
            line-height: 1.6;
        }
        .info-box {
            background-color: #cce5ff;
            border-left: 4px solid #0066cc;
            padding: 12px;
            margin: 15px 0;
        }
    </style>
</head>
<body>
    <h1>PDF Generated from Bytes!</h1>
    <p>This PDF was generated directly to Uint8List without saving to a file first.</p>
    <p>This is more performant for scenarios where you don't need to save the file locally.</p>
    <p>Page size: SELECTED_PAGE_SIZE</p>
</body>
</html>
    """
        .replaceAll('SELECTED_PAGE_SIZE', selectedPageSize.name);

    try {
      // Show start toast
      Fluttertoast.showToast(
        msg:
            "Converting HTML to PDF bytes with ${selectedPageSize.name} size...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );

      final pdfBytes =
          await _flutterNativeHtmlToPdfPlugin.convertHtmlToPdfBytes(
        html: htmlContent,
        pageSize: selectedPageSize,
      );

      setState(() {
        generatedPdfBytes = pdfBytes;
      });

      if (pdfBytes != null) {
        // Show success toast
        Fluttertoast.showToast(
          msg:
              "PDF bytes generated successfully! (${pdfBytes.length} bytes, ${selectedPageSize.name})",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Select Page Size:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              DropdownButton<PdfPageSize>(
                value: selectedPageSize,
                items: [
                  DropdownMenuItem(
                      value: PdfPageSize.a4,
                      child: Text('A4 (${PdfPageSize.a4.name})')),
                  DropdownMenuItem(
                      value: PdfPageSize.letter,
                      child: Text('Letter (${PdfPageSize.letter.name})')),
                  DropdownMenuItem(
                      value: PdfPageSize.legal,
                      child: Text('Legal (${PdfPageSize.legal.name})')),
                  DropdownMenuItem(
                      value: PdfPageSize.a3,
                      child: Text('A3 (${PdfPageSize.a3.name})')),
                  DropdownMenuItem(
                      value: PdfPageSize.a5,
                      child: Text('A5 (${PdfPageSize.a5.name})')),
                  DropdownMenuItem(
                      value: PdfPageSize.tabloid,
                      child: Text('Tabloid (${PdfPageSize.tabloid.name})')),
                ],
                onChanged: (PdfPageSize? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedPageSize = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
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
                      await SharePlus.instance.share(ShareParams(
                        title: "Generated PDF Document",
                        text: "Here is the PDF document generated from HTML.",
                        subject: "Generated PDF",
                        files: [XFile(generatedPdfFilePath!, mimeType: 'application/pdf')],
                      ));
                    } else {
                      Fluttertoast.showToast(
                        msg: "ERROR: Failed to generate PDF file",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  } catch (e) {
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
                    if (generatedPdfBytes == null) {
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

                      // Save bytes to temporary file for sharing
                      final tempDir = await getTemporaryDirectory();
                      final tempFile =
                          File('${tempDir.path}/temp_pdf_from_bytes.pdf');
                      await tempFile.writeAsBytes(generatedPdfBytes!);
                      await SharePlus.instance.share(ShareParams(
                        title: "Generated PDF Document",
                        text: "Here is the PDF document generated from HTML.",
                        subject: "Generated PDF",
                        files: [XFile(tempFile.path, mimeType: 'application/pdf')],
                      ));
                    } else {
                      Fluttertoast.showToast(
                        msg: "ERROR: Still no PDF bytes after regeneration",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  } catch (e) {
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
                    ? 'PDF Bytes: ${generatedPdfBytes!.length} bytes ready (${selectedPageSize.name})'
                    : 'Click button to generate PDF',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
