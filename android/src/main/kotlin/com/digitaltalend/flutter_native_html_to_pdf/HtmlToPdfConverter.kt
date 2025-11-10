package com.digitaltalend.flutter_native_html_to_pdf

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.print.PdfPrinter
import android.print.PrintAttributes
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient

import java.io.File


class HtmlToPdfConverter {

    interface Callback {
        fun onSuccess(filePath: String)
        fun onFailure()
    }

    interface BytesCallback {
        fun onSuccess(pdfBytes: ByteArray)
        fun onFailure()
    }

    @SuppressLint("SetJavaScriptEnabled")
    fun convert(filePath: String, applicationContext: Context, callback: Callback, pageSize: Map<String, Any>? = null) {
        val webView = WebView(applicationContext)
        val htmlContent = File(filePath).readText(Charsets.UTF_8)
        
        // Configure WebView settings
        webView.settings.javaScriptEnabled = true
        webView.settings.javaScriptCanOpenWindowsAutomatically = true
        webView.settings.allowFileAccess = true
        webView.settings.allowContentAccess = true
        
        // Enable loading images and external resources
        webView.settings.blockNetworkImage = false
        webView.settings.blockNetworkLoads = false
        webView.settings.loadsImagesAutomatically = true
        
        // Additional settings for better rendering
        webView.settings.domStorageEnabled = true
        webView.settings.useWideViewPort = true
        webView.settings.loadWithOverviewMode = true
        
        // Allow mixed content (HTTP images on HTTPS pages)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            webView.settings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
        }
        
        // Use a proper base URL to allow loading external resources
        webView.loadDataWithBaseURL("https://", htmlContent, "text/HTML", "UTF-8", null)
        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView, url: String) {
                super.onPageFinished(view, url)
                
                // Inject JavaScript to wait for all images to load
                view.evaluateJavascript(
                    """
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
                    """.trimIndent()
                ) { result ->
                    // Small delay to ensure rendering is complete after images load
                    Handler(Looper.getMainLooper()).postDelayed({
                        createPdfFromWebView(webView, applicationContext, callback, pageSize)
                    }, 300)
                }
            }
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    fun convertToBytes(html: String, applicationContext: Context, callback: BytesCallback, pageSize: Map<String, Any>? = null) {
        val webView = WebView(applicationContext)
        
        // Configure WebView settings
        webView.settings.javaScriptEnabled = true
        webView.settings.javaScriptCanOpenWindowsAutomatically = true
        webView.settings.allowFileAccess = true
        webView.settings.allowContentAccess = true
        
        // Enable loading images and external resources
        webView.settings.blockNetworkImage = false
        webView.settings.blockNetworkLoads = false
        webView.settings.loadsImagesAutomatically = true
        
        // Additional settings for better rendering
        webView.settings.domStorageEnabled = true
        webView.settings.useWideViewPort = true
        webView.settings.loadWithOverviewMode = true
        
        // Allow mixed content (HTTP images on HTTPS pages)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            webView.settings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
        }
        
        // Use a proper base URL to allow loading external resources
        webView.loadDataWithBaseURL("https://", html, "text/HTML", "UTF-8", null)
        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView, url: String) {
                super.onPageFinished(view, url)
                
                // Inject JavaScript to wait for all images to load
                view.evaluateJavascript(
                    """
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
                    """.trimIndent()
                ) { result ->
                    // Small delay to ensure rendering is complete after images load
                    Handler(Looper.getMainLooper()).postDelayed({
                        createPdfBytesFromWebView(webView, applicationContext, callback, pageSize)
                    }, 300)
                }
            }
        }
    }

    fun createPdfFromWebView(webView: WebView, applicationContext: Context, callback: Callback, pageSize: Map<String, Any>? = null) {
        val path = applicationContext.filesDir
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {

            // Get page size from parameter or use default A4
            val mediaSize = if (pageSize != null) {
                val width = (pageSize["width"] as? Double)?.toInt() ?: 595
                val height = (pageSize["height"] as? Double)?.toInt() ?: 842
                // Convert points to mils (1 point = 1000 mils / 72)
                val widthMils = (width * 1000.0 / 72.0).toInt()
                val heightMils = (height * 1000.0 / 72.0).toInt()
                PrintAttributes.MediaSize("custom", "Custom", widthMils, heightMils)
            } else {
                PrintAttributes.MediaSize.ISO_A4
            }

            val attributes = PrintAttributes.Builder()
                .setMediaSize(mediaSize)
                .setResolution(PrintAttributes.Resolution("pdf", "pdf", 600, 600))
                .setMinMargins(PrintAttributes.Margins.NO_MARGINS).build()

            val printer = PdfPrinter(attributes)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val adapter = webView.createPrintDocumentAdapter(temporaryDocumentName)

                printer.print(adapter, path, temporaryFileName, object : PdfPrinter.Callback {
                    override fun onSuccess(filePath: String) {
                        callback.onSuccess(filePath)
                    }

                    override fun onFailure() {
                        callback.onFailure()
                    }
                })
            }
        }
    }

    fun createPdfBytesFromWebView(webView: WebView, applicationContext: Context, callback: BytesCallback, pageSize: Map<String, Any>? = null) {
        val path = applicationContext.cacheDir
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {

            // Get page size from parameter or use default A4
            val mediaSize = if (pageSize != null) {
                val width = (pageSize["width"] as? Double)?.toInt() ?: 595
                val height = (pageSize["height"] as? Double)?.toInt() ?: 842
                // Convert points to mils (1 point = 1000 mils / 72)
                val widthMils = (width * 1000.0 / 72.0).toInt()
                val heightMils = (height * 1000.0 / 72.0).toInt()
                PrintAttributes.MediaSize("custom", "Custom", widthMils, heightMils)
            } else {
                PrintAttributes.MediaSize.ISO_A4
            }

            val attributes = PrintAttributes.Builder()
                .setMediaSize(mediaSize)
                .setResolution(PrintAttributes.Resolution("pdf", "pdf", 600, 600))
                .setMinMargins(PrintAttributes.Margins.NO_MARGINS).build()

            val printer = PdfPrinter(attributes)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val adapter = webView.createPrintDocumentAdapter(temporaryDocumentName)

                printer.print(adapter, path, temporaryBytesFileName, object : PdfPrinter.Callback {
                    override fun onSuccess(filePath: String) {
                        try {
                            val file = File(filePath)
                            val bytes = file.readBytes()
                            val deleteSuccess = file.delete()
                            if (!deleteSuccess) {
                                android.util.Log.w("HtmlToPdfConverter", "Failed to delete temporary file: $filePath")
                            }
                            callback.onSuccess(bytes)
                        } catch (e: Exception) {
                            android.util.Log.e("HtmlToPdfConverter", "Error reading or deleting temporary PDF file", e)
                            callback.onFailure()
                        }
                    }

                    override fun onFailure() {
                        callback.onFailure()
                    }
                })
            }
        }
    }

    companion object {
        const val temporaryDocumentName = "TemporaryDocumentName"
        const val temporaryFileName = "TemporaryDocumentFile.pdf"
        const val temporaryBytesFileName = "TemporaryBytesFile.pdf"
    }
}