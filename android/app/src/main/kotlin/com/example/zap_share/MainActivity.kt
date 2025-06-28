package com.example.zap_share
import android.net.Uri
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "zapshare.saf"
    private val inputStreams = mutableMapOf<String, InputStream>()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openReadStream" -> {
                    val uriStr = call.argument<String>("uri")
                    try {
                        val uri = Uri.parse(uriStr)
                        val stream = contentResolver.openInputStream(uri)
                        if (stream != null) {
                            inputStreams[uriStr!!] = stream
                            result.success(true)
                        } else {
                            result.error("STREAM_FAIL", "Could not open input stream", null)
                        }
                    } catch (e: Exception) {
                        result.error("EXCEPTION", e.message, null)
                    }
                }

               "getFileSize" -> {
    val uriStr = call.argument<String>("uri")
    try {
        val uri = Uri.parse(uriStr)
        val size = contentResolver.openAssetFileDescriptor(uri, "r")?.length ?: -1L
        if (size >= 0L) {
            result.success(size) // Send as Long (Dart will get it as double)
        } else {
            result.error("SIZE_FAIL", "Unable to determine size", null)
        }
    } catch (e: Exception) {
        result.error("SIZE_EXCEPTION", e.message, null)
    }
}



                "readChunk" -> {
                    val uriStr = call.argument<String>("uri")
                    val size = call.argument<Int>("size") ?: 65536
                    val stream = inputStreams[uriStr]
                    if (stream == null) {
                        result.error("NO_STREAM", "Stream not opened for URI", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val buffer = ByteArray(size)
                        val bytesRead = stream.read(buffer)
                        if (bytesRead == -1) {
                            result.success(null) // End of file
                        } else {
                            result.success(buffer.copyOf(bytesRead)) // Only return valid portion
                        }
                    } catch (e: Exception) {
                        result.error("READ_ERROR", e.message, null)
                    }
                }

                "closeStream" -> {
                    val uriStr = call.argument<String>("uri")
                    val stream = inputStreams.remove(uriStr)
                    try {
                        stream?.close()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CLOSE_ERROR", e.message, null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}