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
  PdfPageSize selectedPageSize = PdfPageSize.a4;
  bool isCustomSize = false;
  final TextEditingController _widthController = TextEditingController(text: '210');
  final TextEditingController _heightController = TextEditingController(text: '297');
  String _customUnit = 'mm'; // 'mm', 'in', 'pt'

  final _htmlToPdfConverter = HtmlToPdfConverter();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  PdfPageSize _getPageSizeByName(String name) {
    switch (name) {
      case 'A4':
        return PdfPageSize.a4;
      case 'Letter':
        return PdfPageSize.letter;
      case 'Legal':
        return PdfPageSize.legal;
      case 'A3':
        return PdfPageSize.a3;
      case 'A5':
        return PdfPageSize.a5;
      case 'Tabloid':
        return PdfPageSize.tabloid;
      default:
        return PdfPageSize.a4;
    }
  }

  PdfPageSize _getEffectivePageSize() {
    if (!isCustomSize) {
      return selectedPageSize;
    }
    
    final width = double.tryParse(_widthController.text) ?? 210;
    final height = double.tryParse(_heightController.text) ?? 297;
    
    switch (_customUnit) {
      case 'mm':
        return PdfPageSize.fromMillimeters(
          widthMm: width,
          heightMm: height,
          name: 'Custom (${width}mm x ${height}mm)',
        );
      case 'in':
        return PdfPageSize.fromInches(
          widthInches: width,
          heightInches: height,
          name: 'Custom ($width" x $height")',
        );
      case 'pt':
        return PdfPageSize.custom(
          width: width,
          height: height,
          name: 'Custom (${width}pt x ${height}pt)',
        );
      default:
        return PdfPageSize.fromMillimeters(widthMm: width, heightMm: height);
    }
  }

  List<Widget> _buildCustomSizeInputs() {
    return [
      const SizedBox(height: 16),
      const Text('Enter custom dimensions:',
          style: TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: TextField(
              controller: _widthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Width',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (_) => setState(() {
                generatedPdfFilePath = null;
                generatedPdfBytes = null;
              }),
            ),
          ),
          const SizedBox(width: 8),
          const Text('x'),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Height',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (_) => setState(() {
                generatedPdfFilePath = null;
                generatedPdfBytes = null;
              }),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _customUnit,
            items: const [
              DropdownMenuItem(value: 'mm', child: Text('mm')),
              DropdownMenuItem(value: 'in', child: Text('inches')),
              DropdownMenuItem(value: 'pt', child: Text('points')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _customUnit = value;
                  generatedPdfFilePath = null;
                  generatedPdfBytes = null;
                });
              }
            },
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Current: ${_getEffectivePageSize().name}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    ];
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
      final effectivePageSize = _getEffectivePageSize();
      
      // Show start toast
      Fluttertoast.showToast(
        msg: "Starting PDF generation with ${effectivePageSize.name} size...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );

      Directory appDocDir = await getApplicationDocumentsDirectory();
      final targetPath = appDocDir.path;
      const targetFileName = "mytext";
      final generatedPdfFile =
          await _htmlToPdfConverter.convertHtmlToPdf(
        html: htmlContent,
        targetDirectory: targetPath,
        targetName: targetFileName,
        pageSize: effectivePageSize,
      );

      generatedPdfFilePath = generatedPdfFile.path;

      // Show success toast
      Fluttertoast.showToast(
        msg:
            "PDF file generated successfully with ${effectivePageSize.name} size!",
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
    const htmlTemplate = """
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
    """;

    try {
      final effectivePageSize = _getEffectivePageSize();
      final htmlContent = htmlTemplate.replaceAll('SELECTED_PAGE_SIZE', effectivePageSize.name);
      
      // Show start toast
      Fluttertoast.showToast(
        msg:
            "Converting HTML to PDF bytes with ${effectivePageSize.name} size...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );

      final pdfBytes =
          await _htmlToPdfConverter.convertHtmlToPdfBytes(
        html: htmlContent,
        pageSize: effectivePageSize,
      );

      setState(() {
        generatedPdfBytes = pdfBytes;
      });

      // Show success toast
      Fluttertoast.showToast(
        msg:
            "PDF bytes generated successfully! (${pdfBytes.length} bytes, ${effectivePageSize.name})",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
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
              DropdownButton<String>(
                value: isCustomSize ? 'custom' : selectedPageSize.name,
                items: const [
                  DropdownMenuItem(value: 'A4', child: Text('A4 (210mm x 297mm)')),
                  DropdownMenuItem(value: 'Letter', child: Text('Letter (8.5" x 11")')),
                  DropdownMenuItem(value: 'Legal', child: Text('Legal (8.5" x 14")')),
                  DropdownMenuItem(value: 'A3', child: Text('A3 (297mm x 420mm)')),
                  DropdownMenuItem(value: 'A5', child: Text('A5 (148mm x 210mm)')),
                  DropdownMenuItem(value: 'Tabloid', child: Text('Tabloid (11" x 17")')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Size...')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      isCustomSize = newValue == 'custom';
                      if (!isCustomSize) {
                        selectedPageSize = _getPageSizeByName(newValue);
                      }
                      // Clear cached PDFs when page size changes
                      generatedPdfFilePath = null;
                      generatedPdfBytes = null;
                    });
                  }
                },
              ),
              if (isCustomSize) ..._buildCustomSizeInputs(),
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
                    ? 'PDF Bytes: ${generatedPdfBytes!.length} bytes ready (${_getEffectivePageSize().name})'
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
