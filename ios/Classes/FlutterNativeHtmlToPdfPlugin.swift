import Flutter
import UIKit
import WebKit

// MARK: - Plugin entry point

public class FlutterNativeHtmlToPdfPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_native_html_to_pdf",
            binaryMessenger: registrar.messenger()
        )
        let instance = FlutterNativeHtmlToPdfPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "convertHtmlToPdf":
            guard let args = call.arguments as? [String: Any],
                  let html = args["html"] as? String,
                  let targetDirectory = args["targetDirectory"] as? String,
                  let targetName = args["targetName"] as? String
            else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Missing required arguments: html, targetDirectory, targetName",
                    details: nil
                ))
                return
            }
            let pageWidth  = args["pageWidth"]  as? Double
            let pageHeight = args["pageHeight"] as? Double

            HtmlToPdfConverter.convert(
                html: html,
                pageWidth: pageWidth,
                pageHeight: pageHeight
            ) { data in
                guard let data = data else {
                    result(FlutterError(code: "PDF_ERROR", message: "Failed to generate PDF data", details: nil))
                    return
                }
                do {
                    let dirURL = URL(fileURLWithPath: targetDirectory)
                    try FileManager.default.createDirectory(
                        at: dirURL,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    let fileURL = dirURL.appendingPathComponent("\(targetName).pdf")
                    try data.write(to: fileURL)
                    result(fileURL.path)
                } catch {
                    result(FlutterError(code: "FILE_ERROR", message: error.localizedDescription, details: nil))
                }
            }

        case "convertHtmlToPdfBytes":
            guard let args = call.arguments as? [String: Any],
                  let html = args["html"] as? String
            else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Missing required argument: html",
                    details: nil
                ))
                return
            }
            let pageWidth  = args["pageWidth"]  as? Double
            let pageHeight = args["pageHeight"] as? Double

            HtmlToPdfConverter.convert(
                html: html,
                pageWidth: pageWidth,
                pageHeight: pageHeight
            ) { data in
                guard let data = data else {
                    result(FlutterError(code: "PDF_ERROR", message: "Failed to generate PDF data", details: nil))
                    return
                }
                result(FlutterStandardTypedData(bytes: data))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - HtmlToPdfConverter

/// Loads HTML into an offscreen WKWebView (properly attached to a UIWindow so that
/// layout and UIPrintPageRenderer work correctly), then exports a paginated PDF.
private class HtmlToPdfConverter: NSObject, WKNavigationDelegate {

    // Retain all in-flight converters so ARC doesn't collect them mid-flight.
    private static var instances = Set<HtmlToPdfConverter>()

    private let webView:      WKWebView
    private var hostWindow:   UIWindow?   // keeps the WKWebView in a live layout tree
    private let pdfPageWidth:  CGFloat
    private let pdfPageHeight: CGFloat
    private let completion:    (Data?) -> Void
    private var completed = false

    // Collected link annotations: one entry per visual rect of each <a href>.
    private var linkAnnotations: [(url: URL, pageIndex: Int, rectInPage: CGRect)] = []

    // -------------------------------------------------------------------------
    // Init – create the WKWebView inside an offscreen UIWindow
    // The window is placed far off-screen so it is invisible but still
    // participates in the layout system (hidden = false, alpha = 0).
    // -------------------------------------------------------------------------
    private init(
        pdfPageWidth:  CGFloat,
        pdfPageHeight: CGFloat,
        completion: @escaping (Data?) -> Void
    ) {
        self.pdfPageWidth  = pdfPageWidth
        self.pdfPageHeight = pdfPageHeight
        self.completion    = completion

        // PDF points → CSS px:  px = pt × (96/72)
        let cssWidth  = pdfPageWidth  * 96.0 / 72.0
        let cssHeight = pdfPageHeight * 96.0 / 72.0

        let cfg = WKWebViewConfiguration()
        cfg.suppressesIncrementalRendering = true
        self.webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: cssWidth, height: cssHeight),
            configuration: cfg
        )
        // Disable scroll / zoom – we control the frame manually.
        self.webView.scrollView.isScrollEnabled = false
        self.webView.scrollView.contentInsetAdjustmentBehavior = .never

        super.init()
        self.webView.navigationDelegate = self

        // Attach to a real UIWindow so UIPrintPageRenderer (and scrollView layout)
        // function correctly.  Place it off the visible screen area.
        let screen = UIScreen.main.bounds
        let win    = UIWindow(frame: CGRect(
            x: screen.width + 200,
            y: 0,
            width: cssWidth,
            height: cssHeight
        ))
        // Must NOT be hidden; alpha=0 makes it invisible without affecting layout.
        win.isHidden = false
        win.alpha    = 0
        win.windowLevel = UIWindow.Level(rawValue: -1_000)
        win.addSubview(self.webView)
        self.hostWindow = win
    }

    // -------------------------------------------------------------------------
    // Public factory
    // -------------------------------------------------------------------------
    static func convert(
        html:       String,
        pageWidth:  Double?,
        pageHeight: Double?,
        completion: @escaping (Data?) -> Void
    ) {
        // Must create WKWebView on the main thread.
        DispatchQueue.main.async {
            let w = CGFloat(pageWidth  ?? 595.2)
            let h = CGFloat(pageHeight ?? 841.8)
            let conv = HtmlToPdfConverter(pdfPageWidth: w, pdfPageHeight: h, completion: completion)
            instances.insert(conv)
            conv.webView.loadHTMLString(Self.injectPrintColorAdjust(into: html), baseURL: nil)
        }
    }

    /// Injects a `<style>` block that forces WebKit to render background colors
    /// and images when printing (i.e. when generating a PDF with
    /// UIPrintPageRenderer).  By default iOS suppresses backgrounds in print
    /// mode; `print-color-adjust: exact` overrides that behavior.
    private static func injectPrintColorAdjust(into html: String) -> String {
        let style = "<style>* { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }</style>"
        // Insert before </head> when present (preferred location).
        if let range = html.range(of: "</head>", options: .caseInsensitive) {
            return html.replacingCharacters(in: range, with: style + "</head>")
        }
        // Insert after <head> when there is no closing tag.
        if let range = html.range(of: "<head>", options: .caseInsensitive) {
            return html.replacingCharacters(in: range, with: "<head>" + style)
        }
        // No <head> at all – prepend the style.
        return style + html
    }

    // -------------------------------------------------------------------------
    // WKNavigationDelegate
    // -------------------------------------------------------------------------

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 1. Query the real rendered content height via JavaScript.
        webView.evaluateJavaScript(
            "Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)"
        ) { [weak self] value, _ in
            guard let self = self else { return }

            let jsHeight  = (value as? CGFloat) ?? CGFloat(self.pdfPageHeight * 96.0 / 72.0)
            let cssWidth  = self.pdfPageWidth  * 96.0 / 72.0
            let newHeight = max(jsHeight, 1)

            // 2. Expand the webView to the full content height so the print
            //    formatter can measure all pages.
            let newFrame = CGRect(x: 0, y: 0, width: cssWidth, height: newHeight)
            self.webView.frame  = newFrame
            self.hostWindow?.frame = CGRect(
                x: UIScreen.main.bounds.width + 200,
                y: 0,
                width: cssWidth,
                height: newHeight
            )

            // 3. Give the engine one runloop pass to reflow, then extract link
            //    annotations and export.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                self.extractLinks { [weak self] in
                    self?.exportPDF()
                }
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        finish(nil)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        finish(nil)
    }

    // -------------------------------------------------------------------------
    // PDF export – UIPrintPageRenderer (works on all supported iOS versions
    // and produces a properly paginated, print-quality PDF).
    // -------------------------------------------------------------------------

    /// Queries the rendered WebView for all <a href> elements and converts their
    /// bounding rects from CSS pixels to PDF points, storing the results in
    /// `linkAnnotations` for use during PDF generation.
    ///
    /// NOTE: ctx.setURL(_:for:) operates in the raw PDF coordinate space
    /// (origin bottom-left), NOT in the UIKit-flipped space used for drawing.
    /// Rects are stored in UIKit space and flipped at annotation-write time.
    private func extractLinks(completion: @escaping () -> Void) {
        // getClientRects() returns one rect per line fragment for inline elements.
        // Block-level anchors (e.g. <a><div>…</div></a>) return an empty list, so
        // we fall back to getBoundingClientRect() in that case.
        // pageYOffset converts viewport-relative rects to document-absolute.
        let js = """
        (function() {
            var scrollTop = window.pageYOffset
                || document.documentElement.scrollTop
                || document.body.scrollTop
                || 0;
            var links = [];
            var anchors = document.querySelectorAll('a[href]');
            for (var i = 0; i < anchors.length; i++) {
                var a = anchors[i];
                var href = a.href;
                if (!href || href.indexOf('javascript:') === 0) continue;
                var rects = Array.from(a.getClientRects());
                if (rects.length === 0) {
                    var br = a.getBoundingClientRect();
                    if (br.width > 0 && br.height > 0) rects = [br];
                }
                for (var j = 0; j < rects.length; j++) {
                    var r = rects[j];
                    if (r.width > 0 && r.height > 0) {
                        links.push({
                            href: href,
                            x: r.left,
                            y: r.top + scrollTop,
                            w: r.width,
                            h: r.height
                        });
                    }
                }
            }
            return JSON.stringify(links);
        })()
        """

        webView.evaluateJavaScript(js) { [weak self] value, _ in
            defer { completion() }
            guard let self = self,
                  let jsonString = value as? String,
                  let jsonData   = jsonString.data(using: .utf8),
                  let rawLinks   = try? JSONSerialization.jsonObject(with: jsonData)
                                       as? [[String: Any]]
            else { return }

            // CSS px → PDF pt:  1 pt = (96/72) px  →  scale = 72/96
            let scale: CGFloat = 72.0 / 96.0

            for link in rawLinks {
                guard let hrefStr = link["href"] as? String,
                      let url     = URL(string: hrefStr),
                      let xRaw    = link["x"] as? Double,
                      let yRaw    = link["y"] as? Double,
                      let wRaw    = link["w"] as? Double,
                      let hRaw    = link["h"] as? Double
                else { continue }

                let xPdf = CGFloat(xRaw) * scale
                let yPdf = CGFloat(yRaw) * scale
                let wPdf = CGFloat(wRaw) * scale
                let hPdf = CGFloat(hRaw) * scale

                // Which page does this rect start on?
                let pageIndex = Int(yPdf / self.pdfPageHeight)
                // y from the top of that page (UIKit / PDF upper-left origin).
                let yOnPage   = yPdf - CGFloat(pageIndex) * self.pdfPageHeight

                // Clamp to the page height so the annotation rect stays within
                // the page even if the link straddles a page break.
                let clampedH  = min(hPdf, self.pdfPageHeight - yOnPage)
                guard clampedH > 0 else { continue }

                let rectInPage = CGRect(x: xPdf, y: yOnPage, width: wPdf, height: clampedH)
                self.linkAnnotations.append(
                    (url: url, pageIndex: pageIndex, rectInPage: rectInPage)
                )
            }
        }
    }

    private func exportPDF() {
        let paperRect     = CGRect(x: 0, y: 0, width: pdfPageWidth, height: pdfPageHeight)
        let printableRect = paperRect   // no extra margins; caller controls via HTML/CSS

        let formatter = webView.viewPrintFormatter()
        let renderer  = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        // These KVC keys are private but documented by Apple's sample code and
        // used by every major PDF-printing library on iOS.
        renderer.setValue(NSValue(cgRect: paperRect),     forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: renderer.numberOfPages))
        for i in 0 ..< renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())

            // Overlay PDF URI annotations for every hyperlink on this page.
            // ctx.setURL(_:for:) writes into the raw PDF coordinate space
            // (origin bottom-left, y increases upward), regardless of the UIKit
            // flip transform applied for drawing.  Convert from UIKit rect
            // (origin top-left) by flipping: pdfY = pageHeight - uikitMaxY.
            if let ctx = UIGraphicsGetCurrentContext() {
                for annotation in linkAnnotations where annotation.pageIndex == i {
                    let r = annotation.rectInPage
                    let flipped = CGRect(
                        x: r.minX,
                        y: pdfPageHeight - r.maxY,
                        width: r.width,
                        height: r.height
                    )
                    ctx.setURL(annotation.url as CFURL, for: flipped)
                }
            }
        }
        UIGraphicsEndPDFContext()

        finish(pdfData.length > 0 ? (pdfData as Data) : nil)
    }

    // -------------------------------------------------------------------------
    // Cleanup
    // -------------------------------------------------------------------------
    private func finish(_ data: Data?) {
        guard !completed else { return }
        completed = true

        // Detach and release the window.
        webView.removeFromSuperview()
        hostWindow?.isHidden = true
        hostWindow = nil

        completion(data)
        HtmlToPdfConverter.instances.remove(self)
    }
}
