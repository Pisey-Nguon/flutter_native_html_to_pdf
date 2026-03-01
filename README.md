# Flutter Native HTML to PDF

A Flutter plugin that uses native WebView (Android WebView / iOS WKWebView) to render HTML and convert it to high-quality PDF files. Leverages native platform capabilities for accurate HTML rendering with full CSS support.

## Features

- **Native WebView Rendering**: Uses Android WebView and iOS WKWebView for accurate HTML-to-PDF conversion
- **Full CSS Support**: Complete support for modern CSS properties, layouts, fonts, and styling
- **HTML to PDF File Conversion**: Convert HTML content into a PDF file and save it to a specified directory
- **HTML to PDF Bytes Conversion**: Convert HTML content directly to `Uint8List` PDF data without saving to a file
- **Customizable Page Sizes**: Support for A4, Letter, Legal, A3, A5, B5, Executive, Tabloid, and custom page sizes
- **High-Quality Output**: Native rendering ensures professional-quality PDFs with accurate layout

## Installation

Add this to your package's `pubspec.yaml` file:

dependencies:
```yaml
  flutter_native_html_to_pdf: ^3.0.0
```

## Usage

### Convert HTML to PDF File

```dart
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';

final converter = HtmlToPdfConverter();

const htmlContent = """
<!DOCTYPE html>
<html>
<head><title>Sample PDF</title></head>
<body>
    <h1>Hello World!</h1>
    <p>This is a sample PDF.</p>
</body>
</html>
""";

Directory appDocDir = await getApplicationDocumentsDirectory();
final pdfFile = await converter.convertHtmlToPdf(
  html: htmlContent,
  targetDirectory: appDocDir.path,
  targetName: "my_document",
);

print('PDF saved at: ${pdfFile.path}');
```

### Convert HTML to PDF Bytes

For better performance when you don't need to save the PDF as a file:

```dart
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';

final converter = HtmlToPdfConverter();

const htmlContent = """
<!DOCTYPE html>
<html>
<head><title>Sample PDF</title></head>
<body>
    <h1>Hello World!</h1>
    <p>This PDF is generated as bytes.</p>
</body>
</html>
""";

final pdfBytes = await converter.convertHtmlToPdfBytes(
  html: htmlContent,
);

print('PDF size: ${pdfBytes.length} bytes');

// Use the bytes directly (e.g., upload to server, share, etc.)
// Or save to file if needed:
// await File('path/to/file.pdf').writeAsBytes(pdfBytes);
```

### Custom Page Sizes

You can specify different page sizes for your PDFs. The package supports common page sizes and custom dimensions:

```dart
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';

final converter = HtmlToPdfConverter();

// Use a predefined page size
final pdfFile = await converter.convertHtmlToPdf(
  html: htmlContent,
  targetDirectory: appDocDir.path,
  targetName: "my_document",
  pageSize: PdfPageSize.letter, // US Letter size
);

// Or create a custom page size (dimensions in points, 72 points = 1 inch)
final customPageSize = PdfPageSize.custom(
  width: 500,
  height: 700,
  name: 'My Custom Size',
);

// Create from millimeters
final mmPageSize = PdfPageSize.fromMillimeters(
  widthMm: 210,
  heightMm: 297,
  name: 'A4 from mm',
);

// Create from inches
final inchPageSize = PdfPageSize.fromInches(
  widthInches: 8.5,
  heightInches: 11,
  name: 'Letter from inches',
);

// Get landscape/portrait orientation
final landscapeA4 = PdfPageSize.a4.landscape;
final portraitA4 = PdfPageSize.a4.portrait;
```

**Available predefined page sizes:**
- `PdfPageSize.a4` - A4 (210mm x 297mm) - Default
- `PdfPageSize.letter` - US Letter (8.5" x 11")
- `PdfPageSize.legal` - US Legal (8.5" x 14")
- `PdfPageSize.a3` - A3 (297mm x 420mm)
- `PdfPageSize.a5` - A5 (148mm x 210mm)
- `PdfPageSize.b5` - B5 (176mm x 250mm)
- `PdfPageSize.executive` - Executive (7.25" x 10.5")
- `PdfPageSize.tabloid` - US Tabloid (11" x 17")

**Note:** If no page size is specified, the default is A4.

## Migration from v1.x and v2.x

If you're upgrading from version 1.x or 2.x, the API remains the same:

```dart
// Old (v1.x)
final plugin = FlutterNativeHtmlToPdf();
final pdfFile = await plugin.convertHtmlToPdf(...);

// New (v2.x and v3.x)
final converter = HtmlToPdfConverter();
final pdfFile = await converter.convertHtmlToPdf(...);
```

**Note:** Version 3.0.0 uses native platform code (WebView) for better rendering quality compared to the pure Dart implementation in v2.x.

## Benefits of Native WebView Implementation

- **Accurate Rendering**: Native WebView provides the same rendering quality as a web browser
- **Full CSS Support**: Complete support for modern CSS3 properties, flexbox, grid, and custom fonts
- **Better Performance**: Optimized native rendering engine
- **Professional Output**: High-quality PDFs suitable for production use
- **Web Standards**: Full compatibility with HTML5 and CSS3 standards

## Platform Support

- ✅ Android (uses Android WebView)
- ✅ iOS (uses WKWebView)

**Note:** This version requires native platform support and currently works on Android and iOS.

## Note

The HTML content can be static or dynamic. You can use any valid HTML, including CSS styles and images.

### CSS Styles and Fonts

This plugin fully supports CSS styling through native WebView rendering on both Android and iOS:
- **Colors**: Background colors, text colors, border colors, gradients
- **Fonts**: Font families, sizes, weights, styles (bold, italic, etc.), custom web fonts
- **Layout**: Margins, padding, borders, flexbox, grid, positioning
- **Modern CSS**: CSS3 properties, animations (static in PDF), transforms, shadows
- **All standard CSS properties**: Native WebView ensures complete CSS compatibility

**Example HTML with CSS:**

```dart
const htmlContent = """
<!DOCTYPE html>
<html>
<head>
    <title>Styled PDF</title>
    <style>
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
""";
```

### Using Images in HTML

This plugin supports loading images in your HTML content, including:
- **External images** via HTTP/HTTPS URLs (e.g., `https://example.com/image.jpg`)
- **Base64 encoded images** (e.g., `data:image/png;base64,...`)
- **Local file images** (with proper file:// URLs)

**Important Configuration for External Images:**

#### Android
Add the INTERNET permission to your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application>
        ...
    </application>
</manifest>
```

#### iOS
Add App Transport Security settings to your `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Example HTML with images:**

```dart
const htmlContent = """
<!DOCTYPE html>
<html>
<head>
    <title>PDF with Images</title>
</head>
<body>
    <h1>My Document</h1>
    <img src="https://picsum.photos/200/300" alt="Sample image">
    <p>Image from URL</p>
</body>
</html>
""";
```

**Note:** The native WebView automatically waits for images to load before generating the PDF. For optimal results with external images:
- Ensure you have a stable internet connection
- The plugin uses native WebView callbacks to detect when all images have finished loading
- WebView rendering ensures accurate image placement and sizing
- For faster generation, consider using base64 encoded images or local assets
