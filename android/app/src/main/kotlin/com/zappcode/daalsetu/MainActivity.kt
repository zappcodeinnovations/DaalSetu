package com.zappcode.daalsetu

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "com.zappcode.daalsetu/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "savePdfToDownloads") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val fileName = call.argument<String>("fileName")
                val bytes = call.argument<ByteArray>("bytes")
                if (fileName.isNullOrBlank() || bytes == null || bytes.isEmpty()) {
                    result.error("invalid_arguments", "A PDF filename and file bytes are required.", null)
                    return@setMethodCallHandler
                }

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val values = ContentValues().apply {
                            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                            put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                            put(
                                MediaStore.Downloads.RELATIVE_PATH,
                                "${Environment.DIRECTORY_DOWNLOADS}/DaalSetu",
                            )
                            put(MediaStore.Downloads.IS_PENDING, 1)
                        }
                        val uri = contentResolver.insert(
                            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                            values,
                        ) ?: throw IllegalStateException("Could not create the Downloads file.")
                        contentResolver.openOutputStream(uri)?.use { output ->
                            output.write(bytes)
                        } ?: throw IllegalStateException("Could not write the Downloads file.")
                        ContentValues().apply {
                            put(MediaStore.Downloads.IS_PENDING, 0)
                        }.also { contentResolver.update(uri, it, null, null) }
                        result.success(uri.toString())
                    } else {
                        val directory = File(
                            Environment.getExternalStoragePublicDirectory(
                                Environment.DIRECTORY_DOWNLOADS,
                            ),
                            "DaalSetu",
                        )
                        if (!directory.exists() && !directory.mkdirs()) {
                            throw IllegalStateException("Could not create the Downloads folder.")
                        }
                        val file = File(directory, fileName)
                        FileOutputStream(file).use { output -> output.write(bytes) }
                        result.success(file.absolutePath)
                    }
                } catch (error: Exception) {
                    result.error("download_failed", error.message, null)
                }
            }
    }
}
