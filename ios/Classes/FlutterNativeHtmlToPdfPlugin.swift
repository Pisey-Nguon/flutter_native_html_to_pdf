import Flutter
import UIKit
import WebKit

public class FlutterNativeHtmlToPdfPlugin: NSObject, FlutterPlugin {
    static let WEBVIEW_TAG_FILE = 100
    static let WEBVIEW_TAG_BYTES = 101
    
    var wkWebView : WKWebView!
    var urlObservation: NSKeyValueObservation?
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_native_html_to_pdf", binaryMessenger: registrar.messenger())
    let instance = FlutterNativeHtmlToPdfPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
       switch call.method {
       case "convertHtmlToPdf":
           convertHtmlToPdf(call, result)
       case "convertHtmlToPdfBytes":
           convertHtmlToPdfBytes(call, result)
       default:
           result(FlutterMethodNotImplemented)
       }
     }
    
    private func convertHtmlToPdf(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        let htmlFilePath = args!["htmlFilePath"] as? String
        
        // !!! this is workaround for issue with rendering PDF images on iOS !!!
        let viewControler = UIApplication.shared.delegate?.window?!.rootViewController
        wkWebView = WKWebView.init(frame: viewControler!.view.bounds)
        wkWebView.isHidden = true
        wkWebView.tag = FlutterNativeHtmlToPdfPlugin.WEBVIEW_TAG_FILE
        viewControler?.view.addSubview(wkWebView)
        
        let htmlFileContent = FileHelper.getContent(from: htmlFilePath!) // get html content from file
        wkWebView.loadHTMLString(htmlFileContent, baseURL: Bundle.main.bundleURL) // load html into hidden webview
        
        urlObservation = wkWebView.observe(\.isLoading, changeHandler: { (webView, change) in
            // this is workaround for issue with loading local images
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let convertedFileURL = PDFCreator.create(printFormatter: self.wkWebView.viewPrintFormatter())
                let convertedFilePath = convertedFileURL.absoluteString.replacingOccurrences(of: "file://", with: "") // return generated pdf path
                if let viewWithTag = viewControler?.view.viewWithTag(FlutterNativeHtmlToPdfPlugin.WEBVIEW_TAG_FILE) {
                    viewWithTag.removeFromSuperview() // remove hidden webview when pdf is generated
                    
                    // clear WKWebView cache
                    if #available(iOS 9.0, *) {
                        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                            records.forEach { record in
                                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                            }
                        }
                    }
                }
                
                // dispose WKWebView
                self.urlObservation = nil
                self.wkWebView = nil
                result(convertedFilePath)
            }
        })
    }
    
    private func convertHtmlToPdfBytes(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        let html = args!["html"] as? String
        
        // !!! this is workaround for issue with rendering PDF images on iOS !!!
        let viewControler = UIApplication.shared.delegate?.window?!.rootViewController
        wkWebView = WKWebView.init(frame: viewControler!.view.bounds)
        wkWebView.isHidden = true
        wkWebView.tag = FlutterNativeHtmlToPdfPlugin.WEBVIEW_TAG_BYTES
        viewControler?.view.addSubview(wkWebView)
        
        wkWebView.loadHTMLString(html!, baseURL: Bundle.main.bundleURL) // load html into hidden webview
        
        urlObservation = wkWebView.observe(\.isLoading, changeHandler: { (webView, change) in
            // this is workaround for issue with loading local images
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let pdfData = PDFCreator.createBytes(printFormatter: self.wkWebView.viewPrintFormatter())
                let flutterData = FlutterStandardTypedData(bytes: pdfData)
                
                if let viewWithTag = viewControler?.view.viewWithTag(FlutterNativeHtmlToPdfPlugin.WEBVIEW_TAG_BYTES) {
                    viewWithTag.removeFromSuperview() // remove hidden webview when pdf is generated
                    
                    // clear WKWebView cache
                    if #available(iOS 9.0, *) {
                        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                            records.forEach { record in
                                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                            }
                        }
                    }
                }
                
                // dispose WKWebView
                self.urlObservation = nil
                self.wkWebView = nil
                result(flutterData)
            }
        })
    }
}
