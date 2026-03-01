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

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class FlutterNativeHtmlToPdfPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {

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

        new Handler(Looper.getMainLooper()).post(() -> {
            WebView webView = new WebView(context);
            webView.getSettings().setJavaScriptEnabled(true);

            webView.setWebViewClient(new WebViewClient() {
                private boolean errorOccurred = false;

                @Override
                public void onPageFinished(WebView view, String url) {
                    if (errorOccurred) return;
                    try {
                        PrintDocumentAdapter adapter = view.createPrintDocumentAdapter(targetName);
                        PrintAttributes attrs = buildPrintAttributes(pageWidth, pageHeight);

                        File dir = new File(targetDirectory);
                        //noinspection ResultOfMethodCallIgnored
                        dir.mkdirs();
                        File outputFile = new File(dir, targetName + ".pdf");

                        adapter.onLayout(null, attrs, null,
                                new FlutterLayoutResultCallback(new FlutterLayoutResultCallback.Callback() {
                                    @Override
                                    public void onLayoutFinished(PrintDocumentInfo info, boolean changed) {
                                        try {
                                            ParcelFileDescriptor pfd = ParcelFileDescriptor.open(
                                                    outputFile,
                                                    ParcelFileDescriptor.MODE_READ_WRITE
                                                            | ParcelFileDescriptor.MODE_CREATE
                                                            | ParcelFileDescriptor.MODE_TRUNCATE);

                                            adapter.onWrite(
                                                    new PageRange[]{PageRange.ALL_PAGES},
                                                    pfd,
                                                    new CancellationSignal(),
                                                    new FlutterWriteResultCallback(new FlutterWriteResultCallback.Callback() {
                                                        @Override
                                                        public void onWriteFinished(PageRange[] pages) {
                                                            closeSilently(pfd);
                                                            adapter.onFinish();
                                                            result.success(outputFile.getAbsolutePath());
                                                        }

                                                        @Override
                                                        public void onWriteFailed(CharSequence error) {
                                                            closeSilently(pfd);
                                                            adapter.onFinish();
                                                            result.error("WRITE_FAILED",
                                                                    error != null ? error.toString() : "Write failed",
                                                                    null);
                                                        }

                                                        @Override
                                                        public void onWriteCancelled() {
                                                            closeSilently(pfd);
                                                            adapter.onFinish();
                                                            result.error("WRITE_CANCELLED", "Write cancelled", null);
                                                        }
                                                    }));
                                        } catch (Exception e) {
                                            adapter.onFinish();
                                            result.error("FILE_ERROR", e.getMessage(), null);
                                        }
                                    }

                                    @Override
                                    public void onLayoutFailed(CharSequence error) {
                                        adapter.onFinish();
                                        result.error("LAYOUT_FAILED",
                                                error != null ? error.toString() : "Layout failed",
                                                null);
                                    }

                                    @Override
                                    public void onLayoutCancelled() {
                                        adapter.onFinish();
                                        result.error("LAYOUT_CANCELLED", "Layout cancelled", null);
                                    }
                                }), null);
                    } catch (Exception e) {
                        result.error("CONVERSION_FAILED", e.getMessage(), null);
                    }
                }

                @Override
                public void onReceivedError(WebView view, WebResourceRequest request,
                                            WebResourceError error) {
                    if (request != null && request.isForMainFrame()) {
                        errorOccurred = true;
                        String msg = null;
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            msg = (error != null) ? error.getDescription().toString() : "Unknown error";
                        }
                        result.error("LOAD_FAILED", "WebView failed to load HTML: " + msg, null);
                    }
                }
            });

            webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null);
        });
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

        new Handler(Looper.getMainLooper()).post(() -> {
            WebView webView = new WebView(context);
            webView.getSettings().setJavaScriptEnabled(true);

            webView.setWebViewClient(new WebViewClient() {
                private boolean errorOccurred = false;

                @Override
                public void onPageFinished(WebView view, String url) {
                    if (errorOccurred) return;
                    try {
                        File tempFile = File.createTempFile("html_pdf_", ".pdf", context.getCacheDir());
                        PrintDocumentAdapter adapter = view.createPrintDocumentAdapter("document");
                        PrintAttributes attrs = buildPrintAttributes(pageWidth, pageHeight);

                        adapter.onLayout(null, attrs, null,
                                new FlutterLayoutResultCallback(new FlutterLayoutResultCallback.Callback() {
                                    @Override
                                    public void onLayoutFinished(PrintDocumentInfo info, boolean changed) {
                                        try {
                                            ParcelFileDescriptor pfd = ParcelFileDescriptor.open(
                                                    tempFile,
                                                    ParcelFileDescriptor.MODE_READ_WRITE
                                                            | ParcelFileDescriptor.MODE_CREATE
                                                            | ParcelFileDescriptor.MODE_TRUNCATE);

                                            adapter.onWrite(
                                                    new PageRange[]{PageRange.ALL_PAGES},
                                                    pfd,
                                                    new CancellationSignal(),
                                                    new FlutterWriteResultCallback(new FlutterWriteResultCallback.Callback() {
                                                        @Override
                                                        public void onWriteFinished(PageRange[] pages) {
                                                            closeSilently(pfd);
                                                            adapter.onFinish();
                                                            byte[] bytes = readAndDelete(tempFile);
                                                            if (bytes != null) {
                                                                result.success(bytes);
                                                            } else {
                                                                result.error("READ_ERROR", "Failed to read temp PDF", null);
                                                            }
                                                        }

                                                        @Override
                                                        public void onWriteFailed(CharSequence error) {
                                                            closeSilently(pfd);
                                                            adapter.onFinish();
                                                            //noinspection ResultOfMethodCallIgnored
                                                            tempFile.delete();
                                                            result.error("WRITE_FAILED",
                                                                    error != null ? error.toString() : "Write failed",
                                                                    null);
                                                        }

                                                        @Override
                                                        public void onWriteCancelled() {
                                                            closeSilently(pfd);
                                                            adapter.onFinish();
                                                            //noinspection ResultOfMethodCallIgnored
                                                            tempFile.delete();
                                                            result.error("WRITE_CANCELLED", "Write cancelled", null);
                                                        }
                                                    }));
                                        } catch (Exception e) {
                                            adapter.onFinish();
                                            //noinspection ResultOfMethodCallIgnored
                                            tempFile.delete();
                                            result.error("FILE_ERROR", e.getMessage(), null);
                                        }
                                    }

                                    @Override
                                    public void onLayoutFailed(CharSequence error) {
                                        adapter.onFinish();
                                        //noinspection ResultOfMethodCallIgnored
                                        tempFile.delete();
                                        result.error("LAYOUT_FAILED",
                                                error != null ? error.toString() : "Layout failed",
                                                null);
                                    }

                                    @Override
                                    public void onLayoutCancelled() {
                                        adapter.onFinish();
                                        //noinspection ResultOfMethodCallIgnored
                                        tempFile.delete();
                                        result.error("LAYOUT_CANCELLED", "Layout cancelled", null);
                                    }
                                }), null);
                    } catch (IOException e) {
                        result.error("TEMP_FILE_ERROR", e.getMessage(), null);
                    } catch (Exception e) {
                        result.error("CONVERSION_FAILED", e.getMessage(), null);
                    }
                }

                @Override
                public void onReceivedError(WebView view, WebResourceRequest request,
                                            WebResourceError error) {
                    if (request != null && request.isForMainFrame()) {
                        errorOccurred = true;
                        String msg = null;
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            msg = (error != null) ? error.getDescription().toString() : "Unknown error";
                        }
                        result.error("LOAD_FAILED", "WebView failed to load HTML: " + msg, null);
                    }
                }
            });

            webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null);
        });
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
