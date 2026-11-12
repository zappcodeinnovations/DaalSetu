package com.zappkode.daalsetu

import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "com.zappkode.daalsetu/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "savePdfToDownloads", "saveFileToDownloads" -> {
                        val fileName = call.argument<String>("fileName")
                        val bytes = call.argument<ByteArray>("bytes")
                        val mimeType = call.argument<String>("mimeType") ?: "application/pdf"
                        if (fileName.isNullOrBlank() || bytes == null || bytes.isEmpty()) {
                            result.error("invalid_arguments", "A filename and file bytes are required.", null)
                            return@setMethodCallHandler
                        }

                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                val values = ContentValues().apply {
                                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                                    put(
                                        MediaStore.Downloads.RELATIVE_PATH,
                                        Environment.DIRECTORY_DOWNLOADS,
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
                                val directory = Environment.getExternalStoragePublicDirectory(
                                    Environment.DIRECTORY_DOWNLOADS,
                                )
                                if (!directory.exists() && !directory.mkdirs()) {
                                    throw IllegalStateException("Could not create the Downloads folder.")
                                }
                                val file = File(directory, fileName)
                                FileOutputStream(file).use { output -> output.write(bytes) }
                                MediaScannerConnection.scanFile(
                                    applicationContext,
                                    arrayOf(file.absolutePath),
                                    arrayOf(mimeType),
                                    null,
                                )
                                result.success(file.absolutePath)
                            }
                        } catch (error: Exception) {
                            result.error("download_failed", error.message, null)
                        }
                    }
                    "listDownloads" -> {
                        try {
                            val files = mutableListOf<Map<String, Any?>>()
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                val projection = arrayOf(
                                    MediaStore.Downloads._ID,
                                    MediaStore.Downloads.DISPLAY_NAME,
                                    MediaStore.Downloads.SIZE,
                                    MediaStore.Downloads.DATE_MODIFIED,
                                    MediaStore.Downloads.MIME_TYPE,
                                    MediaStore.MediaColumns.OWNER_PACKAGE_NAME,
                                )
                                contentResolver.query(
                                    MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                                    projection,
                                    "${MediaStore.Downloads.IS_PENDING} = 0",
                                    null,
                                    "${MediaStore.Downloads.DATE_MODIFIED} DESC",
                                )?.use { cursor ->
                                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
                                    val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads.DISPLAY_NAME)
                                    val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads.SIZE)
                                    val modifiedColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads.DATE_MODIFIED)
                                    val mimeColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads.MIME_TYPE)
                                    val ownerColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.OWNER_PACKAGE_NAME)
                                    while (cursor.moveToNext()) {
                                        if (cursor.getString(ownerColumn) != packageName) continue
                                        val id = cursor.getLong(idColumn)
                                        val uri = Uri.withAppendedPath(
                                            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                                            id.toString(),
                                        )
                                        files.add(
                                            mapOf(
                                                "name" to cursor.getString(nameColumn),
                                                "target" to uri.toString(),
                                                "size" to cursor.getLong(sizeColumn),
                                                "modifiedAt" to cursor.getLong(modifiedColumn) * 1000L,
                                                "mimeType" to (cursor.getString(mimeColumn) ?: "application/octet-stream"),
                                            ),
                                        )
                                    }
                                }
                            } else {
                                val directory = Environment.getExternalStoragePublicDirectory(
                                    Environment.DIRECTORY_DOWNLOADS,
                                )
                                directory.listFiles()?.filter { it.isFile }
                                    ?.sortedByDescending { it.lastModified() }
                                    ?.forEach { file ->
                                        files.add(
                                            mapOf(
                                                "name" to file.name,
                                                "target" to file.absolutePath,
                                                "size" to file.length(),
                                                "modifiedAt" to file.lastModified(),
                                                "mimeType" to guessMimeType(file.name),
                                            ),
                                        )
                                    }
                            }
                            result.success(files)
                        } catch (error: Exception) {
                            result.error("list_failed", error.message, null)
                        }
                    }
                    "deleteDownload" -> {
                        val target = call.argument<String>("target")
                        if (target.isNullOrBlank()) {
                            result.error("invalid_arguments", "Download target is required.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val deleted = if (target.startsWith("content://")) {
                                contentResolver.delete(Uri.parse(target), null, null) > 0
                            } else {
                                File(target).delete()
                            }
                            result.success(deleted)
                        } catch (error: Exception) {
                            result.error("delete_failed", error.message, null)
                        }
                    }
                    "openDownload" -> {
                        val target = call.argument<String>("target")
                        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                        if (target.isNullOrBlank()) {
                            result.error("invalid_arguments", "Download target is required.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            if (!target.startsWith("content://")) {
                                result.success(false)
                                return@setMethodCallHandler
                            }
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(Uri.parse(target), mimeType)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(Intent.createChooser(intent, "Open download"))
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("open_failed", error.message, null)
                        }
                    }
                    "openPdfUri" -> {
                        val uriString = call.argument<String>("uri")
                        if (uriString.isNullOrBlank()) {
                            result.error("invalid_arguments", "Uri is required.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(Uri.parse(uriString), "application/pdf")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(Intent.createChooser(intent, "Open Delivery Challan"))
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("open_failed", e.message, null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun guessMimeType(fileName: String): String = when (fileName.substringAfterLast('.', "").lowercase()) {
        "pdf" -> "application/pdf"
        "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        "xls" -> "application/vnd.ms-excel"
        "csv" -> "text/csv"
        "jpg", "jpeg" -> "image/jpeg"
        "png" -> "image/png"
        "mp4" -> "video/mp4"
        else -> "application/octet-stream"
    }
}
