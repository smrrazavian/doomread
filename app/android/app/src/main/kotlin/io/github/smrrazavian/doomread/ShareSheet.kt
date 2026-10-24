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
 * services (ADR 0018). The image lives only in the cache, and only the app
 * the user picks may read it.
 */
object ShareSheet {
    private const val DIR = "share"

    /** Whether this process has cleared the last poster yet. */
    private var cleared = false

    fun register(activity: Activity, messenger: BinaryMessenger) {
        // A poster may carry a private Note: it goes when the app next starts,
        // not while the app the user shared to may still be reading it.
        if (!cleared) {
            File(activity.cacheDir, DIR).deleteRecursively()
            cleared = true
        }
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
        // Only the newest poster is kept.
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
