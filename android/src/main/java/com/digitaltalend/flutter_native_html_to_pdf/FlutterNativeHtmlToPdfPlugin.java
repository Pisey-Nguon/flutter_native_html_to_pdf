package com.digitaltalend.flutter_native_html_to_pdf;

import android.annotation.SuppressLint;
import android.content.Context;
import android.os.Build;
import android.os.CancellationSignal;
import android.os.Handler;
import android.os.Looper;
import android.os.ParcelFileDescriptor;
import android.print.FlutterLayoutResultCallback;
import android.print.FlutterWriteResultCallback;
import android.print.PageRange;
import android.print.PrintAttributes;
import android.print.PrintDocumentAdapter;
import android.print.PrintDocumentInfo;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.annotation.NonNull;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class FlutterNativeHtmlToPdfPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {

    private static final double DEFAULT_PAGE_WIDTH_POINTS = 595.2;
    private static final String LINK_EXTRACTION_SCRIPT = "(function(){"
            + "var scrollTop=window.pageYOffset||document.documentElement.scrollTop||document.body.scrollTop||0;"
            + "var body=document.body||{};"
            + "var doc=document.documentElement||{};"
            + "var links=[];"
            + "var anchors=document.querySelectorAll('a[href]');"
            + "for(var i=0;i<anchors.length;i++){"
            + "var anchor=anchors[i];"
            + "var href=anchor.href;"
            + "if(!href||href.indexOf('javascript:')===0){continue;}"
            + "var rects=anchor.getClientRects();"
            + "if(!rects||rects.length===0){"
            + "var bounds=anchor.getBoundingClientRect();"
            + "if(bounds.width>0&&bounds.height>0){"
            + "links.push({href:href,x:bounds.left,y:bounds.top+scrollTop,w:bounds.width,h:bounds.height});"
            + "}"
            + "continue;"
            + "}"
            + "for(var j=0;j<rects.length;j++){"
            + "var rect=rects[j];"
            + "if(rect.width>0&&rect.height>0){"
            + "links.push({href:href,x:rect.left,y:rect.top+scrollTop,w:rect.width,h:rect.height});"
            + "}"
            + "}"
            + "}"
            + "return {"
            + "contentWidth:Math.max(body.scrollWidth||0,doc.scrollWidth||0,body.clientWidth||0,doc.clientWidth||0),"
            + "links:links"
            + "};"
            + "})()";

    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    private MethodChannel channel;
    private Context context;

    // ------------------------------------------------------------------
    // FlutterPlugin
    // ------------------------------------------------------------------

    @Override
    public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "flutter_native_html_to_pdf");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    // ------------------------------------------------------------------
    // MethodCallHandler
    // ------------------------------------------------------------------

    @Override
    public void onMethodCall(MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "convertHtmlToPdf": {
                String html = call.argument("html");
                String targetDirectory = call.argument("targetDirectory");
                String targetName = call.argument("targetName");
                Double pageWidth = call.argument("pageWidth");
                Double pageHeight = call.argument("pageHeight");
                if (html == null) html = "";
                if (targetDirectory == null) targetDirectory = "";
                if (targetName == null) targetName = "document";
                convertHtmlToPdf(html, targetDirectory, targetName, pageWidth, pageHeight, result);
                break;
            }
            case "convertHtmlToPdfBytes": {
                String html = call.argument("html");
                Double pageWidth = call.argument("pageWidth");
                Double pageHeight = call.argument("pageHeight");
                if (html == null) html = "";
                convertHtmlToPdfBytes(html, pageWidth, pageHeight, result);
                break;
            }
            default:
                result.notImplemented();
        }
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    /**
     * Converts PDF points (1 pt = 1/72 inch) to mils (1 mil = 1/1000 inch).
     * Android's PrintAttributes.MediaSize uses mils.
     */
    private static int pointsToMils(double points) {
        return (int) Math.round((points / 72.0) * 1000.0);
    }

    private float resolvePageWidthPoints(Double pageWidthPoints) {
        return pageWidthPoints != null ? pageWidthPoints.floatValue() : (float) DEFAULT_PAGE_WIDTH_POINTS;
    }

    private float resolvePageHeightPoints(Double pageHeightPoints) {
        return pageHeightPoints != null ? pageHeightPoints.floatValue() : 841.8f;
    }

    private PrintAttributes buildPrintAttributes(Double pageWidthPoints, Double pageHeightPoints) {
        PrintAttributes.MediaSize mediaSize;
        if (pageWidthPoints != null && pageHeightPoints != null) {
            int widthMils = pointsToMils(pageWidthPoints);
            int heightMils = pointsToMils(pageHeightPoints);
            mediaSize = new PrintAttributes.MediaSize("custom", "Custom", widthMils, heightMils);
        } else {
            mediaSize = PrintAttributes.MediaSize.ISO_A4;
        }
        return new PrintAttributes.Builder()
                .setMediaSize(mediaSize)
                .setResolution(new PrintAttributes.Resolution("res_id", "default", 300, 300))
                .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
                .build();
    }

    // ------------------------------------------------------------------
    // convertHtmlToPdf – save to file
    // ------------------------------------------------------------------

    @SuppressLint("SetJavaScriptEnabled")
    private void convertHtmlToPdf(
            final String html,
            final String targetDirectory,
            final String targetName,
            final Double pageWidth,
            final Double pageHeight,
            final MethodChannel.Result result) {
        File dir = new File(targetDirectory);
        //noinspection ResultOfMethodCallIgnored
        dir.mkdirs();
        File outputFile = new File(dir, targetName + ".pdf");

        renderHtmlToPdf(
                html,
                targetName,
                pageWidth,
                pageHeight,
                outputFile,
                new PdfReadyCallback() {
                    @Override
                    public void onSuccess(File pdfFile) {
                        result.success(pdfFile.getAbsolutePath());
                    }

                    @Override
                    public void onError(String code, String message) {
                        result.error(code, message, null);
                    }
                }
        );
    }

    // ------------------------------------------------------------------
    // convertHtmlToPdfBytes – return raw bytes
    // ------------------------------------------------------------------

    @SuppressLint("SetJavaScriptEnabled")
    private void convertHtmlToPdfBytes(
            final String html,
            final Double pageWidth,
            final Double pageHeight,
            final MethodChannel.Result result) {
        try {
            File tempFile = File.createTempFile("html_pdf_", ".pdf", context.getCacheDir());
            renderHtmlToPdf(
                    html,
                    "document",
                    pageWidth,
                    pageHeight,
                    tempFile,
                    new PdfReadyCallback() {
                        @Override
                        public void onSuccess(File pdfFile) {
                            byte[] bytes = readAndDelete(pdfFile);
                            if (bytes != null) {
                                result.success(bytes);
                            } else {
                                result.error("READ_ERROR", "Failed to read temp PDF", null);
                            }
                        }

                        @Override
                        public void onError(String code, String message) {
                            //noinspection ResultOfMethodCallIgnored
                            tempFile.delete();
                            result.error(code, message, null);
                        }
                    }
            );
        } catch (IOException e) {
            result.error("TEMP_FILE_ERROR", e.getMessage(), null);
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private void renderHtmlToPdf(
            final String html,
            final String documentName,
            final Double pageWidth,
            final Double pageHeight,
            final File outputFile,
            final PdfReadyCallback callback) {

        mainHandler.post(() -> {
            WebView webView = new WebView(context);
            webView.getSettings().setJavaScriptEnabled(true);

            webView.setWebViewClient(new WebViewClient() {
                private boolean errorOccurred = false;
                private boolean conversionStarted = false;

                @Override
                public void onPageFinished(WebView view, String url) {
                    if (errorOccurred || conversionStarted) {
                        return;
                    }
                    conversionStarted = true;

                    extractLinkRects(view, pageWidth, new LinkExtractionCallback() {
                        @Override
                        public void onExtracted(List<PdfLinkMapper.HtmlLinkRect> linkRects, double contentWidthCss) {
                            try {
                                writePdfToFile(
                                        view,
                                        documentName,
                                        pageWidth,
                                        pageHeight,
                                        outputFile,
                                        linkRects,
                                        contentWidthCss,
                                        new PdfReadyCallback() {
                                            @Override
                                            public void onSuccess(File pdfFile) {
                                                destroyWebView(view);
                                                callback.onSuccess(pdfFile);
                                            }

                                            @Override
                                            public void onError(String code, String message) {
                                                destroyWebView(view);
                                                callback.onError(code, message);
                                            }
                                        }
                                );
                            } catch (Exception e) {
                                destroyWebView(view);
                                callback.onError("CONVERSION_FAILED", safeMessage(e, "Conversion failed"));
                            }
                        }
                    });
                }

                @Override
                public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                    if (request != null && request.isForMainFrame()) {
                        errorOccurred = true;
                        destroyWebView(view);
                        String msg = null;
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            msg = error != null ? String.valueOf(error.getDescription()) : "Unknown error";
                        }
                        callback.onError("LOAD_FAILED", "WebView failed to load HTML: " + msg);
                    }
                }
            });

            webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null);
        });
    }

    private void writePdfToFile(
            WebView webView,
            String documentName,
            Double pageWidth,
            Double pageHeight,
            File outputFile,
            List<PdfLinkMapper.HtmlLinkRect> linkRects,
            double contentWidthCss,
            PdfReadyCallback callback) {

        PrintDocumentAdapter adapter = webView.createPrintDocumentAdapter(documentName);
        PrintAttributes attrs = buildPrintAttributes(pageWidth, pageHeight);

        adapter.onLayout(
                null,
                attrs,
                null,
                new FlutterLayoutResultCallback(new FlutterLayoutResultCallback.Callback() {
                    @Override
                    public void onLayoutFinished(PrintDocumentInfo info, boolean changed) {
                        try {
                            ParcelFileDescriptor pfd = ParcelFileDescriptor.open(
                                    outputFile,
                                    ParcelFileDescriptor.MODE_READ_WRITE
                                            | ParcelFileDescriptor.MODE_CREATE
                                            | ParcelFileDescriptor.MODE_TRUNCATE
                            );

                            adapter.onWrite(
                                    new PageRange[]{PageRange.ALL_PAGES},
                                    pfd,
                                    new CancellationSignal(),
                                    new FlutterWriteResultCallback(new FlutterWriteResultCallback.Callback() {
                                        @Override
                                        public void onWriteFinished(PageRange[] pages) {
                                            closeSilently(pfd);
                                            adapter.onFinish();
                                            annotatePdfInBackground(outputFile, linkRects, contentWidthCss, pageWidth, pageHeight, callback);
                                        }

                                        @Override
                                        public void onWriteFailed(CharSequence error) {
                                            closeSilently(pfd);
                                            adapter.onFinish();
                                            callback.onError(
                                                    "WRITE_FAILED",
                                                    error != null ? error.toString() : "Write failed"
                                            );
                                        }

                                        @Override
                                        public void onWriteCancelled() {
                                            closeSilently(pfd);
                                            adapter.onFinish();
                                            callback.onError("WRITE_CANCELLED", "Write cancelled");
                                        }
                                    })
                            );
                        } catch (Exception e) {
                            adapter.onFinish();
                            callback.onError("FILE_ERROR", safeMessage(e, "Failed to open output file"));
                        }
                    }

                    @Override
                    public void onLayoutFailed(CharSequence error) {
                        adapter.onFinish();
                        callback.onError(
                                "LAYOUT_FAILED",
                                error != null ? error.toString() : "Layout failed"
                        );
                    }

                    @Override
                    public void onLayoutCancelled() {
                        adapter.onFinish();
                        callback.onError("LAYOUT_CANCELLED", "Layout cancelled");
                    }
                }),
                null
        );
    }

    private void annotatePdfInBackground(
            File pdfFile,
            List<PdfLinkMapper.HtmlLinkRect> linkRects,
            double contentWidthCss,
            Double pageWidth,
            Double pageHeight,
            PdfReadyCallback callback) {

        if (linkRects == null || linkRects.isEmpty()) {
            callback.onSuccess(pdfFile);
            return;
        }

        new Thread(() -> {
            try {
                annotatePdfWithLinks(pdfFile, linkRects, contentWidthCss, pageWidth, pageHeight);
                mainHandler.post(() -> callback.onSuccess(pdfFile));
            } catch (IOException e) {
                mainHandler.post(() -> callback.onError(
                        "ANNOTATION_FAILED",
                        safeMessage(e, "Failed to add hyperlink annotations")
                ));
            }
        }).start();
    }

    private void annotatePdfWithLinks(
            File pdfFile,
            List<PdfLinkMapper.HtmlLinkRect> linkRects,
            double contentWidthCss,
            Double pageWidth,
            Double pageHeight) throws IOException {

        PdfAnnotationWriter.addUriLinks(
                pdfFile,
                linkRects,
                contentWidthCss,
                resolvePageWidthPoints(pageWidth),
                resolvePageHeightPoints(pageHeight)
        );
    }

    private void extractLinkRects(
            WebView webView,
            Double pageWidth,
            LinkExtractionCallback callback) {

        double fallbackContentWidthCss = PdfLinkMapper.defaultContentWidthCss(resolvePageWidthPoints(pageWidth));
        webView.evaluateJavascript(LINK_EXTRACTION_SCRIPT, value -> {
            if (value == null || "null".equals(value)) {
                callback.onExtracted(Collections.emptyList(), fallbackContentWidthCss);
                return;
            }

            try {
                JSONObject payload = new JSONObject(value);
                double contentWidthCss = payload.optDouble("contentWidth", fallbackContentWidthCss);
                JSONArray rawLinks = payload.optJSONArray("links");
                List<PdfLinkMapper.HtmlLinkRect> links = new ArrayList<>();
                if (rawLinks != null) {
                    for (int i = 0; i < rawLinks.length(); i++) {
                        JSONObject link = rawLinks.optJSONObject(i);
                        if (link == null) {
                            continue;
                        }
                        String href = link.optString("href", "");
                        if (href.isEmpty()) {
                            continue;
                        }
                        links.add(new PdfLinkMapper.HtmlLinkRect(
                                href,
                                link.optDouble("x", 0d),
                                link.optDouble("y", 0d),
                                link.optDouble("w", 0d),
                                link.optDouble("h", 0d)
                        ));
                    }
                }
                callback.onExtracted(links, contentWidthCss > 0d ? contentWidthCss : fallbackContentWidthCss);
            } catch (JSONException e) {
                callback.onExtracted(Collections.emptyList(), fallbackContentWidthCss);
            }
        });
    }

    private void destroyWebView(WebView webView) {
        mainHandler.post(() -> {
            webView.stopLoading();
            webView.setWebViewClient(null);
            webView.destroy();
        });
    }

    private static String safeMessage(Throwable throwable, String fallback) {
        String message = throwable.getMessage();
        return message == null || message.isEmpty() ? fallback : message;
    }

    private interface PdfReadyCallback {
        void onSuccess(File pdfFile);

        void onError(String code, String message);
    }

    private interface LinkExtractionCallback {
        void onExtracted(List<PdfLinkMapper.HtmlLinkRect> linkRects, double contentWidthCss);
    }

    // ------------------------------------------------------------------
    // Utility
    // ------------------------------------------------------------------

    private static void closeSilently(ParcelFileDescriptor pfd) {
        try {
            pfd.close();
        } catch (IOException ignored) {
        }
    }

    private static byte[] readAndDelete(File file) {
        try {
            FileInputStream fis = new FileInputStream(file);
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            byte[] buf = new byte[8192];
            int n;
            while ((n = fis.read(buf)) != -1) {
                bos.write(buf, 0, n);
            }
            fis.close();
            //noinspection ResultOfMethodCallIgnored
            file.delete();
            return bos.toByteArray();
        } catch (IOException e) {
            //noinspection ResultOfMethodCallIgnored
            file.delete();
            return null;
        }
    }
}
