package com.smarthospital.nurse

import android.content.Context
import android.print.PrintAttributes
import android.print.PrintManager
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.smarthospital.nurse/print"
    private var printWebView: WebView? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "printHtml") {
                    val title = call.argument<String>("title") ?: "Hospital Document"
                    val html = call.argument<String>("html") ?: ""
                    if (html.isBlank()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    runOnUiThread {
                        launchAndroidHtmlPrint(title, html, result)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun launchAndroidHtmlPrint(
        jobTitle: String,
        htmlContent: String,
        result: MethodChannel.Result,
    ) {
        try {
            val webView = WebView(this)
            webView.settings.loadsImagesAutomatically = true
            webView.settings.defaultTextEncodingName = "utf-8"

            var hasTriggeredPrint = false
            webView.webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(
                    view: WebView?,
                    request: WebResourceRequest?,
                ): Boolean = false

                override fun onPageFinished(view: WebView, url: String?) {
                    if (hasTriggeredPrint) return
                    hasTriggeredPrint = true
                    try {
                        val printManager =
                            getSystemService(Context.PRINT_SERVICE) as? PrintManager
                        if (printManager == null) {
                            result.success(false)
                            return
                        }
                        val safeJobName = jobTitle.ifBlank { "Hospital_Document" }
                        val printAdapter = view.createPrintDocumentAdapter(safeJobName)
                        val attributes = PrintAttributes.Builder()
                            .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
                            .setResolution(PrintAttributes.Resolution("pdf", "pdf", 300, 300))
                            .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
                            .build()
                        printManager.print(safeJobName, printAdapter, attributes)
                        result.success(true)
                    } catch (_: Throwable) {
                        result.success(false)
                    }
                }
            }

            printWebView = webView
            webView.loadDataWithBaseURL(
                "https://hospital.hrpocket.in/",
                htmlContent,
                "text/html",
                "UTF-8",
                null,
            )
        } catch (_: Throwable) {
            result.success(false)
        }
    }
}
