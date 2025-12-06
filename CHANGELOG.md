## 2.0.0 (BREAKING CHANGE)

* **MAJOR CHANGE: Pure Dart Implementation** - Removed all native code dependencies
* The package now uses pure Dart code (`htmltopdfwidgets` package) for all platforms
* Removed native platform implementations for Android (Kotlin) and iOS (Swift)
* Removed `plugin_platform_interface` dependency
* **Breaking Change**: Native platform-specific behavior is no longer available. The package now uses a consistent pure Dart implementation across all platforms.
* **Benefits**: 
  - Easier to maintain and debug
  - Consistent behavior across all platforms
  - No native build requirements
  - Supports all Flutter platforms including Web and macOS
* **Migration**: No API changes required - the public API remains the same. Simply update to this version.
* Note: For advanced users who need WebView-based rendering with native features, consider using the previous version (1.1.4)

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
