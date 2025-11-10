# Flutter Native HTML to PDF

This is a Flutter plugin that converts HTML content into a PDF file or PDF bytes. The generated PDF can be saved as a file or used directly as `Uint8List` for better performance.

## Features

- **HTML to PDF File Conversion**: Convert HTML content into a PDF file and save it to a specified directory
- **HTML to PDF Bytes Conversion**: Convert HTML content directly to `Uint8List` PDF data without saving to a file (better performance)
- **Customizable Page Sizes**: Support for A4, Letter, Legal, A3, A5, Tabloid, and custom page sizes
- **Cross-platform Support**: Works on Android, iOS, Windows, and Linux

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

## Dependencies

- flutter_native_html_to_pdf
- path_provider (for file-based conversion)

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ Linux

## Note

The HTML content can be static or dynamic. You can use any valid HTML, including CSS styles and images.

### CSS Styles and Fonts

This plugin fully supports CSS styling in your HTML content on both Android and iOS:
- **Colors**: Background colors, text colors, border colors
- **Fonts**: Font families, sizes, weights, and styles (bold, italic, etc.)
- **Layout**: Margins, padding, borders, positioning
- **All standard CSS properties**

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

**Note:** The plugin automatically waits for images to load before generating the PDF. For optimal results with external images:
- Ensure you have a stable internet connection
- The plugin uses JavaScript to detect when all images have finished loading (either successfully or with errors)
- Only a minimal 300ms delay is added after image loading for final rendering
- For faster generation, consider using base64 encoded images or local assets
