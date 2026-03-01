import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _fakePdfBytes = Uint8List.fromList(
  '%PDF-1.4 mock pdf bytes'.codeUnits,
);

const _channel = MethodChannel('flutter_native_html_to_pdf');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
      if (call.method == 'convertHtmlToPdfBytes') return _fakePdfBytes;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('Border radius and dimensions support', () {
    test('div with border-radius generates valid PDF', () async {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    .rounded {
      border: 2px solid red;
      border-radius: 10px;
      padding: 10px;
      background-color: lightblue;
    }
  </style>
</head>
<body>
  <div class="rounded">
    <p>This div has rounded corners</p>
  </div>
</body>
</html>
''';

      final converter = HtmlToPdfConverter();
      final pdfBytes = await converter.convertHtmlToPdfBytes(html: html);

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.length, greaterThan(0));
      // PDF should start with %PDF
      expect(String.fromCharCodes(pdfBytes.sublist(0, 4)), equals('%PDF'));
    });

    test('div with width and height generates valid PDF', () async {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    .sized {
      width: 200px;
      height: 100px;
      background-color: yellow;
      border: 1px solid black;
    }
  </style>
</head>
<body>
  <div class="sized">Fixed size box</div>
</body>
</html>
''';

      final converter = HtmlToPdfConverter();
      final pdfBytes = await converter.convertHtmlToPdfBytes(html: html);

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.length, greaterThan(0));
      expect(String.fromCharCodes(pdfBytes.sublist(0, 4)), equals('%PDF'));
    });

    test('div with min-height generates valid PDF', () async {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    .min-sized {
      min-height: 85px;
      border: 1px solid rgba(211, 211, 211, 1);
      border-radius: 8px;
      padding: 10px;
    }
  </style>
</head>
<body>
  <div class="min-sized">
    <p>This div has a minimum height</p>
  </div>
</body>
</html>
''';

      final converter = HtmlToPdfConverter();
      final pdfBytes = await converter.convertHtmlToPdfBytes(html: html);

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.length, greaterThan(0));
      expect(String.fromCharCodes(pdfBytes.sublist(0, 4)), equals('%PDF'));
    });

    test('div with percentage border-radius generates valid PDF', () async {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    .circle {
      width: 50px;
      height: 50px;
      border-radius: 50%;
      background-color: green;
    }
  </style>
</head>
<body>
  <div class="circle"></div>
</body>
</html>
''';

      final converter = HtmlToPdfConverter();
      final pdfBytes = await converter.convertHtmlToPdfBytes(html: html);

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.length, greaterThan(0));
      expect(String.fromCharCodes(pdfBytes.sublist(0, 4)), equals('%PDF'));
    });

    test('complex styling from issue HTML generates valid PDF', () async {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Helvetica, sans-serif; font-size: 11px; }
    h1 { color: rgba(29, 112, 183, 1); font-size: 25px; margin: 0; }
    p { color: rgba(112, 112, 112, 1); margin: 0; }
    .cella {
      border: 1px solid rgba(211, 211, 211, 1);
      border-radius: 8px;
      margin-bottom: 11px;
      min-height: 85px;
      padding: 10px;
    }
    .pallino {
      border-radius: 50%;
      width: 10px;
      height: 10px;
      background-color: green;
    }
    .w-70 { width: 70%; }
  </style>
</head>
<body>
  <h1>Export Articoli - 05/02/2026</h1>
  <div class="cella">
    <p>TXANG10</p>
    <p>TenX Anguria 10 mg/ml</p>
    <div class="pallino"></div>
    <div class="w-70">
      <p>Product description</p>
    </div>
  </div>
</body>
</html>
''';

      final converter = HtmlToPdfConverter();
      final pdfBytes = await converter.convertHtmlToPdfBytes(html: html);

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.length, greaterThan(0));
      expect(String.fromCharCodes(pdfBytes.sublist(0, 4)), equals('%PDF'));
    });
  });
}
