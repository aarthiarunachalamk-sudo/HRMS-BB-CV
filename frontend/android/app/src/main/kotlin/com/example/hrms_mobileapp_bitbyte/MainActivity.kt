package com.example.hrms_mobileapp_bitbyte

import android.content.ContentValues
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "hrms/location"

    private fun openExternalUrl(url: String): Boolean {
        val uri = Uri.parse(url)
        val providerPackages = when {
            uri.host?.contains("meet.google.com", ignoreCase = true) == true ->
                listOf("com.google.android.apps.tachyon")
            uri.host?.contains("teams.microsoft.com", ignoreCase = true) == true ->
                listOf("com.microsoft.teams", "com.microsoft.teams2")
            uri.host?.contains("zoom.us", ignoreCase = true) == true ->
                listOf("us.zoom.videomeetings")
            else -> emptyList()
        }

        for (packageName in providerPackages) {
            val appIntent = Intent(Intent.ACTION_VIEW, uri).apply {
                setPackage(packageName)
                addCategory(Intent.CATEGORY_BROWSABLE)
            }
            try {
                startActivity(appIntent)
                return true
            } catch (_: ActivityNotFoundException) {
                // The provider app is not installed; use the browser below.
            } catch (_: SecurityException) {
                // The installed package cannot accept this URL from our app.
            }
        }

        val browserIntent = Intent.makeMainSelectorActivity(
            Intent.ACTION_MAIN,
            Intent.CATEGORY_APP_BROWSER
        ).apply {
            data = uri
        }
        return try {
            startActivity(browserIntent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            if (call.method == "openUrl") {
                val url = call.argument<String>("url")
                if (url.isNullOrBlank()) {
                    result.error("URL_MISSING", "Meeting link is not available", null)
                    return@setMethodCallHandler
                }

                result.success(openExternalUrl(url))
                return@setMethodCallHandler
            }

            if (call.method != "openMap") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val latitude = call.argument<Double>("latitude")
            val longitude = call.argument<Double>("longitude")
            if (latitude == null || longitude == null) {
                result.error("LOCATION_MISSING", "Location not available for this record", null)
                return@setMethodCallHandler
            }

            val label = Uri.encode("Attendance Location")
            val geoIntent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude($label)")
            )
            val webIntent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude")
            )

            val intent = if (geoIntent.resolveActivity(packageManager) != null) {
                geoIntent
            } else {
                webIntent
            }

            if (intent.resolveActivity(packageManager) == null) {
                result.success(false)
                return@setMethodCallHandler
            }

            startActivity(intent)
            result.success(true)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "hrms/files"
        ).setMethodCallHandler { call, result ->
            if (call.method == "openUrl") {
                val url = call.argument<String>("url")
                val mimeType = call.argument<String>("mimeType")
                if (url.isNullOrBlank()) {
                    result.error("URL_MISSING", "Document link is not available", null)
                    return@setMethodCallHandler
                }

                if (mimeType.isNullOrBlank()) {
                    result.success(openExternalUrl(url))
                    return@setMethodCallHandler
                }

                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(Uri.parse(url), mimeType)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                try {
                    startActivity(Intent.createChooser(intent, "Open file with"))
                    result.success(true)
                } catch (_: ActivityNotFoundException) {
                    result.success(false)
                }
                return@setMethodCallHandler
            }

            if (call.method != "saveToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val fileName = call.argument<String>("fileName")
            val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
            val bytes = call.argument<ByteArray>("bytes")
            if (fileName.isNullOrBlank() || bytes == null) {
                result.error("FILE_DATA_MISSING", "File name or data is missing", null)
                return@setMethodCallHandler
            }

            try {
                var savedUri: Uri? = null
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val values = ContentValues().apply {
                        put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                        put(MediaStore.Downloads.MIME_TYPE, mimeType)
                        put(
                            MediaStore.Downloads.RELATIVE_PATH,
                        Environment.DIRECTORY_DOWNLOADS + "/HRMS-ERP"
                        )
                        put(MediaStore.Downloads.IS_PENDING, 1)
                    }
                    val uri = contentResolver.insert(
                        MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                        values
                    ) ?: throw IllegalStateException("Unable to create download")
                    savedUri = uri
                    try {
                        contentResolver.openOutputStream(uri)?.use { stream ->
                            stream.write(bytes)
                            stream.flush()
                        } ?: throw IllegalStateException("Unable to open download")
                        values.clear()
                        values.put(MediaStore.Downloads.IS_PENDING, 0)
                        contentResolver.update(uri, values, null, null)
                    } catch (error: Exception) {
                        contentResolver.delete(uri, null, null)
                        throw error
                    }
                } else {
                    val downloads = File(
                        Environment.getExternalStoragePublicDirectory(
                            Environment.DIRECTORY_DOWNLOADS
                        ),
                        "HRMS-ERP"
                    )
                    if (!downloads.exists() && !downloads.mkdirs()) {
                        throw IllegalStateException("Unable to create Downloads folder")
                    }
                    val file = File(downloads, fileName)
                    file.writeBytes(bytes)
                    savedUri = Uri.fromFile(file)
                }
                result.success(savedUri?.toString() ?: "Downloads/HRMS-ERP/$fileName")
            } catch (error: Exception) {
                result.error("SAVE_FAILED", error.message ?: "Unable to save report", null)
            }
        }
    }
}
