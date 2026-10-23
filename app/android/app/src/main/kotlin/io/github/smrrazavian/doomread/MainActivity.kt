package io.github.smrrazavian.doomread

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var asking: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BreakAlarm.listen(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "doomread/session_notification")
        this.channel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "canAsk" -> result.success(
                    Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED,
                )
                "ask" -> if (Build.VERSION.SDK_INT < 33 || asking != null) {
                    result.success(false)
                } else {
                    asking = result
                    requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), ASK)
                }
                "show" -> {
                    SessionNotification.show(
                        this,
                        call.argument<String>("sessionId")!!,
                        call.argument<String>("title")!!,
                        call.argument<String>("text")!!,
                        call.argument<Number>("runningSince")?.toLong(),
                    )
                    result.success(null)
                }
                "cancel" -> {
                    SessionNotification.cancel(this)
                    result.success(null)
                }
                "openedFrom" -> {
                    result.success(intent.getStringExtra(SessionNotification.EXTRA_SESSION))
                    // Once: a later restore of this Activity isn't a tap.
                    intent.removeExtra(SessionNotification.EXTRA_SESSION)
                }
                else -> result.notImplemented()
            }
        }
    }

    // A tap on the notification while the app is alive (singleTop).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.getStringExtra(SessionNotification.EXTRA_SESSION)?.let {
            channel?.invokeMethod("tapped", it)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != ASK) return
        asking?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        asking = null
    }

    private companion object {
        const val ASK = 1
    }
}
