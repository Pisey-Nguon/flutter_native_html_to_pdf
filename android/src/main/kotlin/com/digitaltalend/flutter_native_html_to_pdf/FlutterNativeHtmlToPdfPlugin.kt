package com.digitaltalend.flutter_native_html_to_pdf

import android.annotation.SuppressLint
import android.content.Context
import android.content.Context.PRINT_SERVICE
import android.os.Build
import android.print.PdfPrinter
import android.print.PrintAttributes
import android.print.PrintManager
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.annotation.NonNull
import com.digitaltalend.flutter_native_html_to_pdf.HtmlToPdfConverter.Companion.temporaryDocumentName
import com.digitaltalend.flutter_native_html_to_pdf.HtmlToPdfConverter.Companion.temporaryFileName

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/** FlutterNativeHtmlToPdfPlugin */
class FlutterNativeHtmlToPdfPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_native_html_to_pdf")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "convertHtmlToPdf" -> convertHtmlToPdf(call, result)
      "convertHtmlToPdfBytes" -> convertHtmlToPdfBytes(call, result)
      else -> result.notImplemented()
    }
  }
  
  private fun convertHtmlToPdf(call: MethodCall, result: Result) {
    val htmlFilePath = call.argument<String>("htmlFilePath")

    HtmlToPdfConverter().convert(htmlFilePath!!, context, object : HtmlToPdfConverter.Callback {
      override fun onSuccess(filePath: String) {
        result.success(filePath)
      }

      override fun onFailure() {
        result.error("ERROR", "Unable to convert html to pdf document!", "")
      }
    })
  }

  private fun convertHtmlToPdfBytes(call: MethodCall, result: Result) {
    val html = call.argument<String>("html")

    HtmlToPdfConverter().convertToBytes(html!!, context, object : HtmlToPdfConverter.BytesCallback {
      override fun onSuccess(pdfBytes: ByteArray) {
        result.success(pdfBytes)
      }

      override fun onFailure() {
        result.error("ERROR", "Unable to convert html to pdf bytes!", "")
      }
    })
  }
  
  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
