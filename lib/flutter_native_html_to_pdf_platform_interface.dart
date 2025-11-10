import 'dart:io';
import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_native_html_to_pdf_method_channel.dart';

abstract class FlutterNativeHtmlToPdfPlatform extends PlatformInterface {
  /// Constructs a FlutterNativeHtmlToPdfPlatform.
  FlutterNativeHtmlToPdfPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterNativeHtmlToPdfPlatform _instance =
      MethodChannelFlutterNativeHtmlToPdf();

  /// The default instance of [FlutterNativeHtmlToPdfPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterNativeHtmlToPdf].
  static FlutterNativeHtmlToPdfPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterNativeHtmlToPdfPlatform] when
  /// they register themselves.
  static set instance(FlutterNativeHtmlToPdfPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }


  Future<File?> convertHtmlToPdf({
    required String html,
 required String targetDirectory, required String targetName
  }) {
    throw UnimplementedError('convertHtmlToPdf() has not been implemented.');
  }

  Future<Uint8List?> convertHtmlToPdfBytes({
    required String html,
  }) {
    throw UnimplementedError('convertHtmlToPdfBytes() has not been implemented.');
  }
}
