import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_html_to_pdf/flutter_native_specific.dart';

import 'file_utils.dart';
import 'flutter_native_html_to_pdf_platform_interface.dart';

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
  }) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isFuchsia) {
      return await nativeSpecific.convert(
        html: html,
        targetDirectory: targetDirectory,
        targetName: targetName,
      );
    }
    final temporaryCreatedHtmlFile =
        await FileUtils.createFileWithStringContent(
            html, "$targetDirectory/$targetName.html");
    final generatedPdfFilePath = await _convertFromHtmlFilePath(
      temporaryCreatedHtmlFile.path,
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
  }) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isFuchsia) {
      return await nativeSpecific.convertToBytes(html: html);
    }
    final pdfBytes = await _convertHtmlToPdfBytes(html);
    return pdfBytes;
  }

  /// Assumes the invokeMethod call will return successfully
  Future<String> _convertFromHtmlFilePath(String htmlFilePath) async {
    final result = await methodChannel.invokeMethod(
        'convertHtmlToPdf', <String, dynamic>{'htmlFilePath': htmlFilePath});
    return result as String;
  }

  /// Converts HTML content directly to PDF bytes without saving to file
  Future<Uint8List?> _convertHtmlToPdfBytes(String html) async {
    final result = await methodChannel.invokeMethod(
        'convertHtmlToPdfBytes', <String, dynamic>{'html': html});
    return result as Uint8List?;
  }
}
