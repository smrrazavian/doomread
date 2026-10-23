package io.github.smrrazavian.doomread

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * The ongoing notification while a Session runs (ADR 0009).
 *
 * No foreground service: the system's own chronometer counts up from the
 * running Stretch's start, so nothing in the app has to stay alive. On
 * Android 16+ it asks to be promoted to a Live Update; when the user or the
 * system doesn't allow that, it stays an ordinary ongoing notification.
 */
object SessionNotification {
    const val EXTRA_SESSION = "io.github.smrrazavian.doomread.SESSION"
    private const val CHANNEL = "session"
    private const val ID = 1

    fun show(context: Context, sessionId: String, title: String, text: String, runningSince: Long?) {
        val manager = context.getSystemService(NotificationManager::class.java)
        // Low importance: silent, no heads-up. Creating it again is a no-op.
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL,
                context.getString(R.string.session_channel),
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
        val tap = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java)
                .putExtra(EXTRA_SESSION, sessionId)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        // A Live Update needs a title, no custom views, the standard
        // template and no colorizing; this notification keeps to all four.
        val builder = Notification.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_session)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(tap)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(runningSince != null)
            .setUsesChronometer(runningSince != null)
        if (runningSince != null) builder.setWhen(runningSince)
        if (Build.VERSION.SDK_INT >= 36) {
            builder.setFlag(Notification.FLAG_PROMOTED_ONGOING, true)
        }
        manager.notify(ID, builder.build())
    }

    fun cancel(context: Context) {
        context.getSystemService(NotificationManager::class.java).cancel(ID)
    }
}
