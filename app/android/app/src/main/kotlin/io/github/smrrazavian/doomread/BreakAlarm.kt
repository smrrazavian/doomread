package io.github.smrrazavian.doomread

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The "break's over" notification at the end of a Planned break, set as an
 * alarm so it comes even after the app was killed (ADR 0009's pattern).
 *
 * It's exact when the user allows exact alarms. Otherwise (the default on
 * Android 14+) it's inexact: setAndAllowWhileIdle lets the system deliver it
 * a little late, but still while the phone dozes. We don't use setWindow:
 * its docs warn that from Android 12 short windows may be stretched to 10
 * minutes, longer than most breaks.
 */
object BreakAlarm {
    private const val CHANNEL = "break_over"
    private const val ID = 2
    private const val EXTRA_TITLE = "io.github.smrrazavian.doomread.TITLE"
    private const val EXTRA_TEXT = "io.github.smrrazavian.doomread.TEXT"

    fun listen(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, "doomread/break_over").setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    schedule(
                        context,
                        call.argument<String>("sessionId")!!,
                        call.argument<Number>("at")!!.toLong(),
                        call.argument<String>("title")!!,
                        call.argument<String>("text")!!,
                    )
                    result.success(null)
                }
                "cancel" -> {
                    cancel(context)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun schedule(context: Context, sessionId: String, at: Long, title: String, text: String) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        val fire = alarm(
            context,
            Intent(context, BreakOverReceiver::class.java)
                .putExtra(SessionNotification.EXTRA_SESSION, sessionId)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_TEXT, text),
        )
        if (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, fire)
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, fire)
        }
    }

    private fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java)
            .cancel(alarm(context, Intent(context, BreakOverReceiver::class.java)))
        context.getSystemService(NotificationManager::class.java).cancel(ID)
    }

    // One alarm at a time: the same request code and component replace it.
    private fun alarm(context: Context, intent: Intent) = PendingIntent.getBroadcast(
        context,
        0,
        intent,
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    fun notify(context: Context, intent: Intent) {
        val manager = context.getSystemService(NotificationManager::class.java)
        // Default importance: unlike the Session timer, this one should be
        // heard. Creating it again is a no-op.
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL,
                context.getString(R.string.break_channel),
                NotificationManager.IMPORTANCE_DEFAULT,
            ),
        )
        val tap = PendingIntent.getActivity(
            context,
            1,
            Intent(context, MainActivity::class.java)
                .putExtra(SessionNotification.EXTRA_SESSION, intent.getStringExtra(SessionNotification.EXTRA_SESSION))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        manager.notify(
            ID,
            Notification.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_session)
                .setContentTitle(intent.getStringExtra(EXTRA_TITLE))
                .setContentText(intent.getStringExtra(EXTRA_TEXT))
                .setContentIntent(tap)
                .setAutoCancel(true)
                .build(),
        )
    }
}

/** Posts the "break's over" notification when its alarm goes off. */
class BreakOverReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) = BreakAlarm.notify(context, intent)
}
