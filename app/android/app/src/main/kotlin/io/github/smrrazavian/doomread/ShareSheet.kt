package io.github.smrrazavian.doomread

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hands an image the app drew (the Finish poster) to the system share sheet:
 * a plain ACTION_SEND through a FileProvider, so no plugin and no Google
 * services (ADR 0002, ADR 0009's pattern). The image lives in the cache, and
 * only the newest one is kept.
 */
object ShareSheet {
    private const val DIR = "share"

    fun register(activity: Activity, messenger: BinaryMessenger) {
        MethodChannel(messenger, "doomread/share").setMethodCallHandler { call, result ->
            when (call.method) {
                "sharePng" -> {
                    share(
                        activity,
                        call.argument<ByteArray>("png")!!,
                        call.argument<String>("name")!!,
                        call.argument<String>("title")!!,
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun share(activity: Activity, png: ByteArray, name: String, title: String) {
        val dir = File(activity.cacheDir, DIR)
        dir.deleteRecursively()
        dir.mkdirs()
        // The name only, never a path out of the folder.
        val file = File(dir, File(name).name)
        file.writeBytes(png)
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.share", file)
        val send = Intent(Intent.ACTION_SEND)
            .setType("image/png")
            .putExtra(Intent.EXTRA_STREAM, uri)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        // The chooser shows a preview of the image, and the grant carries over.
        send.clipData = ClipData.newRawUri(null, uri)
        activity.startActivity(Intent.createChooser(send, title))
    }
}
