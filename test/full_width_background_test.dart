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

  group('HtmlToPdfConverter - Full Width Background Tests', () {
    late HtmlToPdfConverter converter;

    setUp(() {
      converter = HtmlToPdfConverter();
    });

    test('div with background color generates valid PDF', () async {
      // This is the HTML from the issue report
      const html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Styled PDF</title>
    <style>
        html, body {
            width: 1920px;
        }
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        h1 {
            color: #ff0000;
            font-weight: bold;
        }
        p {
            color: #008000;
            font-size: 16px;
        }
        .highlight {
            background-color: #ffff00;
            padding: 10px;
        }
    </style>
</head>
<body>
    <h1>Red Heading</h1>
    <p>Green paragraph text.</p>
    <div class="highlight">
        <p>Yellow highlighted section.</p>
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

    test('div with border generates valid PDF', () async {
      const html = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        .box {
            border: 2px solid #ff00ff;
            padding: 15px;
        }
    </style>
</head>
<body>
    <div class="box">
        <p>Box with border should span full width.</p>
    </div>
</body>
</html>
''';

      final bytes = await converter.convertHtmlToPdfBytes(html: html);

      expect(bytes, isNotEmpty);
      expect(bytes[0], equals(0x25)); // %
    });

    test('paragraph with background color generates valid PDF', () async {
      const html = '''
<!DOCTYPE html>
<html>
<body>
    <p style="background-color: yellow; padding: 10px;">
        This paragraph has a yellow background and should span full width.
    </p>
</body>
</html>
''';

      final bytes = await converter.convertHtmlToPdfBytes(html: html);

      expect(bytes, isNotEmpty);
      expect(bytes[0], equals(0x25)); // %
    });

    test('multiple divs with backgrounds generate valid PDF', () async {
      const html = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        .red { background-color: #ffcccc; padding: 10px; }
        .green { background-color: #ccffcc; padding: 10px; }
        .blue { background-color: #ccccff; padding: 10px; }
    </style>
</head>
<body>
    <div class="red"><p>Red background section</p></div>
    <div class="green"><p>Green background section</p></div>
    <div class="blue"><p>Blue background section</p></div>
</body>
</html>
''';

      final bytes = await converter.convertHtmlToPdfBytes(html: html);

      expect(bytes, isNotEmpty);
      expect(bytes[0], equals(0x25)); // %
    });

    test('div without background does not break', () async {
      const html = '''
<!DOCTYPE html>
<html>
<body>
    <div>
        <p>This div has no background color or border.</p>
    </div>
</body>
</html>
''';

      final bytes = await converter.convertHtmlToPdfBytes(html: html);

      expect(bytes, isNotEmpty);
      expect(bytes[0], equals(0x25)); // %
    });
  });
}
