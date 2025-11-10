import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_html_to_pdf/flutter_native_specific.dart';

import 'file_utils.dart';
import 'flutter_native_html_to_pdf_platform_interface.dart';
import 'pdf_page_size.dart';

/// An implementation of [FlutterNativeHtmlToPdfPlatform] that uses method channels.
class MethodChannelFlutterNativeHtmlToPdf
    extends FlutterNativeHtmlToPdfPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_native_html_to_pdf');
  final nativeSpecific = FlutterNativeSpecific();

  @override
  Future<File?> convertHtmlToPdf({
    required String html,
    required String targetDirectory,
    required String targetName,
    PdfPageSize? pageSize,
  }) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isFuchsia) {
      return await nativeSpecific.convert(
        html: html,
        targetDirectory: targetDirectory,
        targetName: targetName,
        pageSize: pageSize,
      );
    }
    final temporaryCreatedHtmlFile =
        await FileUtils.createFileWithStringContent(
            html, "$targetDirectory/$targetName.html");
    final generatedPdfFilePath = await _convertFromHtmlFilePath(
      temporaryCreatedHtmlFile.path,
      pageSize,
    );
    final generatedPdfFile = FileUtils.copyAndDeleteOriginalFile(
      generatedPdfFilePath,
      targetDirectory,
      targetName,
    );
    temporaryCreatedHtmlFile.delete();

    return generatedPdfFile;
  }

  @override
  Future<Uint8List?> convertHtmlToPdfBytes({
    required String html,
    PdfPageSize? pageSize,
  }) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isFuchsia) {
      return await nativeSpecific.convertToBytes(
        html: html,
        pageSize: pageSize,
      );
    }
    final pdfBytes = await _convertHtmlToPdfBytes(html, pageSize);
    return pdfBytes;
  }

  /// Assumes the invokeMethod call will return successfully
  Future<String> _convertFromHtmlFilePath(
    String htmlFilePath,
    PdfPageSize? pageSize,
  ) async {
    final args = <String, dynamic>{
      'htmlFilePath': htmlFilePath,
    };
    if (pageSize != null) {
      args['pageSize'] = pageSize.toMap();
    }
    final result = await methodChannel.invokeMethod('convertHtmlToPdf', args);
    return result as String;
  }

  /// Converts HTML content directly to PDF bytes without saving to file
  Future<Uint8List?> _convertHtmlToPdfBytes(
    String html,
    PdfPageSize? pageSize,
  ) async {
    final args = <String, dynamic>{
      'html': html,
    };
    if (pageSize != null) {
      args['pageSize'] = pageSize.toMap();
    }
    final result = await methodChannel.invokeMethod('convertHtmlToPdfBytes', args);
    return result as Uint8List?;
  }
}
