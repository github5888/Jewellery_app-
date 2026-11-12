package com.smarthospital.nurse

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.print.PrintAttributes
import android.print.PrintManager
import android.provider.OpenableColumns
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.math.max
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private val printChannelName = "com.smarthospital.nurse/print"
    private val photoChannelName = "com.smarthospital.nurse/photo_picker"
    private val pickPhotoRequestCode = 49021

    private var printWebView: WebView? = null
    private var pendingPhotoResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, printChannelName)
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, photoChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "pickImage") {
                    launchAndroidPhotoPicker(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun launchAndroidPhotoPicker(result: MethodChannel.Result) {
        if (pendingPhotoResult != null) {
            result.success(null)
            return
        }
        pendingPhotoResult = result
        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                Intent("android.provider.action.PICK_IMAGES").apply {
                    type = "image/*"
                }
            } else {
                Intent(Intent.ACTION_GET_CONTENT).apply {
                    type = "image/*"
                    addCategory(Intent.CATEGORY_OPENABLE)
                }
            }
            @Suppress("DEPRECATION")
            startActivityForResult(intent, pickPhotoRequestCode)
        } catch (_: Throwable) {
            try {
                val fallback = Intent(Intent.ACTION_GET_CONTENT).apply {
                    type = "image/*"
                    addCategory(Intent.CATEGORY_OPENABLE)
                }
                @Suppress("DEPRECATION")
                startActivityForResult(
                    Intent.createChooser(fallback, "Select Profile Photo"),
                    pickPhotoRequestCode,
                )
            } catch (_: Throwable) {
                val pending = pendingPhotoResult
                pendingPhotoResult = null
                pending?.success(null)
            }
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickPhotoRequestCode) return

        val callback = pendingPhotoResult ?: return
        pendingPhotoResult = null

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            callback.success(null)
            return
        }

        val uri: Uri = data.data!!
        try {
            val rawBytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
            if (rawBytes == null || rawBytes.isEmpty()) {
                callback.success(null)
                return
            }

            val processed = optimizeProfileImage(rawBytes, uri)
            callback.success(
                hashMapOf(
                    "bytes" to processed.first,
                    "filename" to processed.second,
                    "mimeType" to processed.third,
                ),
            )
        } catch (_: Throwable) {
            callback.success(null)
        }
    }

    private fun optimizeProfileImage(
        rawBytes: ByteArray,
        uri: Uri,
    ): Triple<ByteArray, String, String> {
        var displayName = "profile_${System.currentTimeMillis()}.jpg"
        try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0 && cursor.moveToFirst()) {
                    val rawName = cursor.getString(idx)
                    if (!rawName.isNullOrBlank()) {
                        displayName = rawName.replace(Regex("[^a-zA-Z0-9._-]"), "_")
                    }
                }
            }
        } catch (_: Throwable) {}

        try {
            val boundsOpts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(rawBytes, 0, rawBytes.size, boundsOpts)
            val srcW = boundsOpts.outWidth
            val srcH = boundsOpts.outHeight
            if (srcW > 0 && srcH > 0) {
                var sampleSize = 1
                val maxDim = 640
                while ((srcW / sampleSize) > maxDim * 2 || (srcH / sampleSize) > maxDim * 2) {
                    sampleSize *= 2
                }
                val decodeOpts = BitmapFactory.Options().apply { inSampleSize = sampleSize }
                val decoded =
                    BitmapFactory.decodeByteArray(rawBytes, 0, rawBytes.size, decodeOpts)
                if (decoded != null) {
                    val largest = max(decoded.width, decoded.height)
                    val finalBmp = if (largest > maxDim) {
                        val ratio = maxDim.toFloat() / largest.toFloat()
                        val targetW = (decoded.width * ratio).roundToInt().coerceAtLeast(1)
                        val targetH = (decoded.height * ratio).roundToInt().coerceAtLeast(1)
                        Bitmap.createScaledBitmap(decoded, targetW, targetH, true)
                    } else {
                        decoded
                    }
                    val out = ByteArrayOutputStream()
                    finalBmp.compress(Bitmap.CompressFormat.JPEG, 88, out)
                    val jpgName = displayName.substringBeforeLast('.', displayName) + ".jpg"
                    return Triple(out.toByteArray(), jpgName, "image/jpeg")
                }
            }
        } catch (_: Throwable) {}

        val mime = contentResolver.getType(uri) ?: "image/jpeg"
        return Triple(rawBytes, displayName, mime)
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
