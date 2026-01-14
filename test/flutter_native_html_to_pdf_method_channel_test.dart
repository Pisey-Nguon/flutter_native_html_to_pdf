import 'dart:io';

import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:test/test.dart';

void main() {
  group('HtmlToPdfConverter', () {
    late HtmlToPdfConverter converter;

    setUp(() {
      converter = HtmlToPdfConverter();
    });

    test('convertHtmlToPdfBytes returns valid PDF bytes', () async {
      const html = '<html><body><h1>Test</h1></body></html>';

      final bytes = await converter.convertHtmlToPdfBytes(html: html);

      expect(bytes, isNotEmpty);
      // PDF files start with %PDF
      expect(bytes[0], equals(0x25)); // %
      expect(bytes[1], equals(0x50)); // P
      expect(bytes[2], equals(0x44)); // D
      expect(bytes[3], equals(0x46)); // F
    });

    test('convertHtmlToPdfBytes with custom page size', () async {
      const html = '<html><body><h1>Test</h1></body></html>';

      final bytes = await converter.convertHtmlToPdfBytes(
        html: html,
        pageSize: PdfPageSize.letter,
      );

      expect(bytes, isNotEmpty);
    });

    test('convertHtmlToPdf creates file', () async {
      const html = '<html><body><h1>Test</h1></body></html>';
      final tempDir = Directory.systemTemp.createTempSync('pdf_test_');

      try {
        final file = await converter.convertHtmlToPdf(
          html: html,
          targetDirectory: tempDir.path,
          targetName: 'test_document',
        );

        expect(file.existsSync(), isTrue);
        expect(file.path, endsWith('.pdf'));

        final bytes = await file.readAsBytes();
        expect(bytes[0], equals(0x25)); // %
        expect(bytes[1], equals(0x50)); // P
        expect(bytes[2], equals(0x44)); // D
        expect(bytes[3], equals(0x46)); // F
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('convertHtmlToPdfBytes with CSS styles', () async {
      const html = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #ff0000; font-weight: bold; font-size: 24px; }
        .highlight { background-color: #ffff00; padding: 10px; }
        .box { border: 2px solid #ff00ff; padding: 15px; }
    </style>
</head>
<body>
    <h1>Red Heading</h1>
    <p style="color: green;">Green paragraph text.</p>
    <div class="highlight">
        <p>Highlighted text with yellow background.</p>
    </div>
    <div class="box">
        <p>Box with purple border.</p>
    </div>
</body>
</html>
''';

      final bytes = await converter.convertHtmlToPdfBytes(html: html);
      
      expect(bytes, isNotEmpty);
      // Verify it's a valid PDF
      expect(bytes[0], equals(0x25)); // %
      expect(bytes[1], equals(0x50)); // P
      expect(bytes[2], equals(0x44)); // D
      expect(bytes[3], equals(0x46)); // F
    });

    test('convertHtmlToPdfBytes with various HTML elements', () async {
      const html = '''
<!DOCTYPE html>
<html>
<body>
    <h1>Heading 1</h1>
    <h2>Heading 2</h2>
    <p>This is a <strong>bold</strong> and <em>italic</em> text.</p>
    <ul>
        <li>Item 1</li>
        <li>Item 2</li>
    </ul>
    <ol>
        <li>First</li>
        <li>Second</li>
    </ol>
    <blockquote>A famous quote</blockquote>
    <pre>code block</pre>
    <a href="https://example.com">Link</a>
</body>
</html>
''';

      final bytes = await converter.convertHtmlToPdfBytes(html: html);
      
      expect(bytes, isNotEmpty);
      expect(bytes[0], equals(0x25)); // %
    });
  });

  group('PdfPageSize', () {
    test('predefined sizes have correct values', () {
      expect(PdfPageSize.a4.width, equals(595.2));
      expect(PdfPageSize.a4.height, equals(841.8));

      expect(PdfPageSize.letter.width, equals(612));
      expect(PdfPageSize.letter.height, equals(792));
    });

    test('custom page size', () {
      final custom = PdfPageSize.custom(
        width: 500,
        height: 700,
        name: 'My Custom',
      );

      expect(custom.width, equals(500));
      expect(custom.height, equals(700));
      expect(custom.name, equals('My Custom'));
    });

    test('fromMillimeters conversion', () {
      final size = PdfPageSize.fromMillimeters(
        widthMm: 210,
        heightMm: 297,
      );

      // A4 in mm is 210x297, which should be approximately 595.2x841.8 points
      expect(size.width, closeTo(595.27, 0.1));
      expect(size.height, closeTo(841.89, 0.1));
    });

    test('fromInches conversion', () {
      final size = PdfPageSize.fromInches(
        widthInches: 8.5,
        heightInches: 11,
      );

      // Letter size is 8.5x11 inches = 612x792 points
      expect(size.width, equals(612));
      expect(size.height, equals(792));
    });

    test('landscape returns landscape orientation', () {
      final portrait = PdfPageSize.a4;
      final landscape = portrait.landscape;

      expect(landscape.width, greaterThan(landscape.height));
      expect(landscape.width, equals(portrait.height));
      expect(landscape.height, equals(portrait.width));
    });

    test('portrait returns portrait orientation', () {
      final landscape = PdfPageSize.a4.landscape;
      final portrait = landscape.portrait;

      expect(portrait.height, greaterThan(portrait.width));
    });

    test('equality', () {
      final size1 = PdfPageSize.custom(width: 100, height: 200);
      final size2 = PdfPageSize.custom(width: 100, height: 200);
      final size3 = PdfPageSize.custom(width: 100, height: 300);

      expect(size1, equals(size2));
      expect(size1, isNot(equals(size3)));
    });
  });
}

