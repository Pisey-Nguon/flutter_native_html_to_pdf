## 2.0.0 - BREAKING CHANGE

### Major Changes
* **Migrated to Pure Dart**: The package no longer uses native code (iOS, Android, etc.) and is now 100% Dart
* **New Main Class**: Use `HtmlToPdfConverter` instead of `FlutterNativeHtmlToPdf`
* **No Flutter Dependency**: Package can now be used in pure Dart applications
* **Cross-platform**: Now supports all platforms including macOS and web

### New Features
* Added `PdfPageSize.fromMillimeters()` factory for creating page sizes from millimeter values
* Added `PdfPageSize.fromInches()` factory for creating page sizes from inch values
* Added `PdfPageSize.landscape` and `PdfPageSize.portrait` getters for orientation conversion
* Added `PdfPageSize.b5` and `PdfPageSize.executive` predefined page sizes
* Return types are now non-nullable (`File` and `Uint8List` instead of `File?` and `Uint8List?`)

### Migration Guide
```dart
// Old (v1.x)
final plugin = FlutterNativeHtmlToPdf();
final pdfFile = await plugin.convertHtmlToPdf(...);

// New (v2.x)
final converter = HtmlToPdfConverter();
final pdfFile = await converter.convertHtmlToPdf(...);
```

### Deprecated
* `FlutterNativeHtmlToPdf` class is deprecated. Use `HtmlToPdfConverter` instead.

---

## 1.1.6
* Refactor iOS code to support scene-based root view controller retrieval and update Info.plist for scene configuration
* Enhance PDF sharing functionality with improved metadata and file handling

## 1.1.5
* Refactor code for improved readability by removing unnecessary blank lines and formatting adjustments across multiple files

## 1.1.4
* Refactor PDF generation code by removing debug print statements and improving file path construction

## 1.1.3
* Fix PDF generation null return by adding early return after failure callback

## 1.1.2

* **Fix iOS 26 compatibility**: Fixed crash on iOS 26 caused by missing WKNavigationDelegate policy methods
* Added `decidePolicyForNavigationAction` and `decidePolicyForNavigationResponse` delegate methods
* These methods are now required by WebKit in iOS 26 to properly load HTML 
* Fixed issue sharing file cannot share in example project (Found in iOS 26)

## 1.1.1

* **Fix iOS color and font rendering**: HTML to PDF conversion on iOS now properly renders CSS colors and custom fonts
* Changed base URL in iOS from `Bundle.main.bundleURL` to `"https://"` to match Android behavior
* Added PDF context attributes for better color rendering in iOS
* Configured WKWebView with `isOpaque = false` and clear background for improved CSS support
* Updated example app with enhanced HTML demonstrating colors and font styles

## 1.1.0

* Add `convertHtmlToPdfBytes` method to convert HTML to PDF as Uint8List without saving to a file
* Improved performance for use cases that don't require saving PDF to disk
* Added support for direct PDF bytes manipulation in Android and iOS native implementations
* Updated example app to demonstrate both file-based and bytes-based conversion

## 1.0.0

* Initial release.
