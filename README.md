# Flutter Native HTML to PDF

Pure Dart HTML to PDF converter that works on all platforms. Converts HTML content into PDF files or bytes with CSS color and style support.

## Features

- **Pure Dart Implementation**: No native code dependencies - works entirely in Dart
- **Cross-Platform**: Works on Android, iOS, Windows, Linux, macOS, and Web
- **HTML to PDF File Conversion**: Convert HTML content into a PDF file and save it to a specified directory
- **HTML to PDF Bytes Conversion**: Convert HTML content directly to `Uint8List` PDF data without saving to a file (better performance)
- **Customizable Page Sizes**: Support for A4, Letter, Legal, A3, A5, Tabloid, and custom page sizes
- **CSS Support**: Supports colors (hex, rgb, named), font sizes, bold, italic, underline, and more
- **HTML Elements**: Supports headings, paragraphs, divs, spans, lists, tables, links, and more

## Usage

### Convert HTML to PDF File

```dart
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';

final plugin = FlutterNativeHtmlToPdf();

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
final pdfFile = await plugin.convertHtmlToPdf(
  html: htmlContent,
  targetDirectory: appDocDir.path,
  targetName: "my_document",
);

print('PDF saved at: ${pdfFile?.path}');
```

### Convert HTML to PDF Bytes

For better performance when you don't need to save the PDF as a file:

```dart
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';

final plugin = FlutterNativeHtmlToPdf();

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

final pdfBytes = await plugin.convertHtmlToPdfBytes(
  html: htmlContent,
);

print('PDF size: ${pdfBytes?.length} bytes');

// Use the bytes directly (e.g., upload to server, share, etc.)
// Or save to file if needed:
// await File('path/to/file.pdf').writeAsBytes(pdfBytes!);
```

### Custom Page Sizes

You can specify different page sizes for your PDFs. The plugin supports common page sizes and custom dimensions:

```dart
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:flutter_native_html_to_pdf/pdf_page_size.dart';
import 'package:path_provider/path_provider.dart';

final plugin = FlutterNativeHtmlToPdf();

// Use a predefined page size
Directory appDocDir = await getApplicationDocumentsDirectory();
final pdfFile = await plugin.convertHtmlToPdf(
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

final pdfBytes = await plugin.convertHtmlToPdfBytes(
  html: htmlContent,
  pageSize: customPageSize,
);
```

**Available predefined page sizes:**
- `PdfPageSize.a4` - A4 (210mm x 297mm) - Default
- `PdfPageSize.letter` - US Letter (8.5" x 11")
- `PdfPageSize.legal` - US Legal (8.5" x 14")
- `PdfPageSize.a3` - A3 (297mm x 420mm)
- `PdfPageSize.a5` - A5 (148mm x 210mm)
- `PdfPageSize.tabloid` - US Tabloid (11" x 17")

**Note:** If no page size is specified, the default is A4.

## Benefits of Using Bytes Method

- **Better Performance**: Skip file I/O operations when you don't need a physical file
- **Memory Efficiency**: Directly use PDF data in memory
- **Flexibility**: Easy to upload to servers, share via network, or save conditionally

## Platform Support

This package uses **pure Dart** with no native code dependencies:

- ✅ **Android** - Pure Dart implementation
- ✅ **iOS** - Pure Dart implementation
- ✅ **Windows** - Pure Dart implementation
- ✅ **Linux** - Pure Dart implementation
- ✅ **macOS** - Pure Dart implementation
- ✅ **Web** - Pure Dart implementation

## Dependencies

This package uses only Dart dependencies:
- `pdf` - Pure Dart PDF generation library
- `html` - Pure Dart HTML parsing library

**No native code dependencies** - works entirely in Dart across all platforms.

## Note

The HTML content can be static or dynamic. You can use any valid HTML, including CSS styles and images.

### CSS Styles and Fonts

This plugin supports CSS styling in your HTML content:
- **Colors**: Text colors (hex, rgb, named colors), background colors
- **Fonts**: Font sizes, weights (bold), and styles (italic, underline)
- **Layout**: Basic layout with support for common HTML elements
- **Supported HTML elements**: h1-h6, p, div, span, strong, b, em, i, u, a, br, hr, ul, ol, li, table, tr, td, th

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

**Note:** Image support is currently limited in the pure Dart implementation. For basic image placeholders, the alt text will be displayed. For better image support, consider using base64 encoded images in future versions.
