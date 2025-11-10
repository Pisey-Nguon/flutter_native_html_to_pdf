import Flutter
import UIKit
import WebKit

public class FlutterNativeHtmlToPdfPlugin: NSObject, FlutterPlugin, WKNavigationDelegate {
    static let WEBVIEW_TAG_FILE = 100
    static let WEBVIEW_TAG_BYTES = 101
    
    var wkWebView : WKWebView!
    var urlObservation: NSKeyValueObservation?
    var currentResult: FlutterResult?
    var currentPageSize: [String: Any]?
    var isGeneratingBytes: Bool = false
    var isProcessing: Bool = false
    
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
        // Check if already processing
        if isProcessing {
            result(FlutterError(code: "BUSY", message: "Another PDF conversion is in progress", details: nil))
            return
        }
        
        let args = call.arguments as? [String: Any]
        let htmlFilePath = args!["htmlFilePath"] as? String
        let pageSize = args?["pageSize"] as? [String: Any]
        
        // Store the result callback and pageSize
        currentResult = result
        currentPageSize = pageSize
        isGeneratingBytes = false
        isProcessing = true
        
        // !!! this is workaround for issue with rendering PDF images on iOS !!!
        let viewControler = UIApplication.shared.delegate?.window?!.rootViewController
        
        // Create WebView configuration with settings for loading external resources
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        
        wkWebView = WKWebView.init(frame: viewControler!.view.bounds, configuration: configuration)
        wkWebView.navigationDelegate = self
        wkWebView.isHidden = true
        wkWebView.tag = FlutterNativeHtmlToPdfPlugin.WEBVIEW_TAG_FILE
        wkWebView.isOpaque = false
        wkWebView.backgroundColor = UIColor.clear
        viewControler?.view.addSubview(wkWebView)
        
        let htmlFileContent = FileHelper.getContent(from: htmlFilePath!) // get html content from file
        // Use a proper base URL to allow CSS and external resources to load correctly
        if let baseURL = URL(string: "https://") {
            wkWebView.loadHTMLString(htmlFileContent, baseURL: baseURL)
        } else {
            wkWebView.loadHTMLString(htmlFileContent, baseURL: nil)
        }
    }
    
    private func convertHtmlToPdfBytes(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        // Check if already processing
        if isProcessing {
            result(FlutterError(code: "BUSY", message: "Another PDF conversion is in progress", details: nil))
            return
        }
        
        let args = call.arguments as? [String: Any]
        let html = args!["html"] as? String
        let pageSize = args?["pageSize"] as? [String: Any]
        
        // Store the result callback and pageSize
        currentResult = result
        currentPageSize = pageSize
        isGeneratingBytes = true
        isProcessing = true
        
        // !!! this is workaround for issue with rendering PDF images on iOS !!!
        let viewControler = UIApplication.shared.delegate?.window?!.rootViewController
        
        // Create WebView configuration with settings for loading external resources
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        
        wkWebView = WKWebView.init(frame: viewControler!.view.bounds, configuration: configuration)
        wkWebView.navigationDelegate = self
        wkWebView.isHidden = true
        wkWebView.tag = FlutterNativeHtmlToPdfPlugin.WEBVIEW_TAG_BYTES
        wkWebView.isOpaque = false
        wkWebView.backgroundColor = UIColor.clear
        viewControler?.view.addSubview(wkWebView)
        
        // Use a proper base URL to allow CSS and external resources to load correctly
        if let baseURL = URL(string: "https://") {
            wkWebView.loadHTMLString(html!, baseURL: baseURL)
        } else {
            wkWebView.loadHTMLString(html!, baseURL: nil)
        }
    }
    
    // WKNavigationDelegate method - called when navigation finishes
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Use JavaScript to wait for all images to load
        let script = """
        (function() {
            return new Promise(function(resolve) {
                var images = document.getElementsByTagName('img');
                if (images.length === 0) {
                    resolve('no-images');
                    return;
                }
                var loadedCount = 0;
                var totalImages = images.length;
                
                function checkAllLoaded() {
                    loadedCount++;
                    if (loadedCount >= totalImages) {
                        resolve('all-loaded');
                    }
                }
                
                for (var i = 0; i < images.length; i++) {
                    if (images[i].complete) {
                        checkAllLoaded();
                    } else {
                        images[i].addEventListener('load', checkAllLoaded);
                        images[i].addEventListener('error', checkAllLoaded);
                    }
                }
            });
        })();
        """
        
        webView.evaluateJavaScript(script) { (result, error) in
            // Small delay to ensure rendering is complete after images load
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if self.isGeneratingBytes {
                    self.generatePdfBytes()
                } else {
                    self.generatePdfFile()
                }
            }
        }
    }
    
    // WKNavigationDelegate method - called when navigation fails
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }
    
    private func handleNavigationError(_ error: Error) {
        // Clean up
        if let viewControler = UIApplication.shared.delegate?.window?!.rootViewController {
            let tag = isGeneratingBytes ? FlutterNativeHtmlToPdfPlugin.WEBVIEW_TAG_BYTES : FlutterNativeHtmlToPdfPlugin.WEBVIEW_TAG_FILE
            if let viewWithTag = viewControler.view.viewWithTag(tag) {
                viewWithTag.removeFromSuperview()
            }
        }
        
        self.wkWebView?.navigationDelegate = nil
        self.wkWebView = nil
        self.isProcessing = false
        
        // Return error
        if let result = self.currentResult {
            result(FlutterError(code: "NAVIGATION_ERROR", message: error.localizedDescription, details: nil))
            self.currentResult = nil
        }
    }
    
    private func generatePdfBytes() {
        guard let viewControler = UIApplication.shared.delegate?.window?!.rootViewController else {
            isProcessing = false
            return
        }
        guard let webView = self.wkWebView else {
            print("WebView is nil in generatePdfBytes")
            if let result = self.currentResult {
                result(FlutterError(code: "WEBVIEW_ERROR", message: "WebView was deallocated", details: nil))
                self.currentResult = nil
            }
            isProcessing = false
            return
        }
        
        let pdfData = PDFCreator.createBytes(printFormatter: webView.viewPrintFormatter(), pageSize: currentPageSize)
        let flutterData = FlutterStandardTypedData(bytes: pdfData)
        
        if let viewWithTag = viewControler.view.viewWithTag(FlutterNativeHtmlToPdfPlugin.WEBVIEW_TAG_BYTES) {
            viewWithTag.removeFromSuperview()
            
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
        self.wkWebView.navigationDelegate = nil
        self.wkWebView = nil
        self.isGeneratingBytes = false
        self.isProcessing = false
        self.currentPageSize = nil
        
        // Return the result
        if let result = self.currentResult {
            result(flutterData)
            self.currentResult = nil
        }
    }
    
    private func generatePdfFile() {
        guard let viewControler = UIApplication.shared.delegate?.window?!.rootViewController else {
            isProcessing = false
            return
        }
        guard let webView = self.wkWebView else {
            print("WebView is nil in generatePdfFile")
            if let result = self.currentResult {
                result(FlutterError(code: "WEBVIEW_ERROR", message: "WebView was deallocated", details: nil))
                self.currentResult = nil
            }
            isProcessing = false
            return
        }
        
        let convertedFileURL = PDFCreator.create(printFormatter: webView.viewPrintFormatter(), pageSize: currentPageSize)
        let convertedFilePath = convertedFileURL.absoluteString.replacingOccurrences(of: "file://", with: "")
        
        if let viewWithTag = viewControler.view.viewWithTag(FlutterNativeHtmlToPdfPlugin.WEBVIEW_TAG_FILE) {
            viewWithTag.removeFromSuperview()
            
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
        self.wkWebView.navigationDelegate = nil
        self.urlObservation = nil
        self.wkWebView = nil
        self.isProcessing = false
        self.currentPageSize = nil
        
        // Return the result
        if let result = self.currentResult {
            result(convertedFilePath)
            self.currentResult = nil
        }
    }
}
