package io.github.smrrazavian.doomread

import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Process

/**
 * The fallback to WatchService when Accessibility is off, say revoked by
 * Advanced Protection (ADR 0016): polls usage access for the activity that
 * came to the front, and reports its app the same way. It can't see inside
 * an app, so it can't tell Shorts apart.
 */
object UsageWatch {
    fun granted(context: Context): Boolean {
        val ops = context.getSystemService(AppOpsManager::class.java)
        return ops.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName,
        ) == AppOpsManager.MODE_ALLOWED
    }

    /** Starts or stops polling; Dart turns it on only while a Session is open. */
    fun set(context: Context, on: Boolean) {
        val intent = Intent(context, UsageWatchService::class.java)
        if (on) context.startForegroundService(intent) else context.stopService(intent)
    }
}

/**
 * Polls while a Session is open. A foreground service, since a cached
 * process is frozen as soon as the user switches to another app, which is
 * exactly when it has to keep polling.
 */
class UsageWatchService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var last: String? = null
    private var polling = false

    private val poll = object : Runnable {
        override fun run() {
            check()
            handler.postDelayed(this, POLL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(ID, notification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(ID, notification())
        }
        if (!polling) {
            polling = true
            handler.post(poll)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(poll)
        super.onDestroy()
    }

    // The last activity resumed in a short window back, which overlaps the
    // one before so an event logged late isn't missed. `last` keeps each app
    // reported once.
    private fun check() {
        val now = System.currentTimeMillis()
        val events = getSystemService(UsageStatsManager::class.java).queryEvents(now - WINDOW_MS, now)
        val event = UsageEvents.Event()
        var pkg: String? = null
        while (events.getNextEvent(event)) {
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) pkg = event.packageName
        }
        if (pkg == null || pkg == last) return
        last = pkg
        Watch.foreground(this, pkg, emptySet())
    }

    private fun notification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, getString(R.string.usage_channel), NotificationManager.IMPORTANCE_MIN),
        )
        return Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_session)
            .setContentTitle(getString(R.string.usage_text))
            .setOngoing(true)
            .build()
    }

    private companion object {
        const val ID = 3
        const val CHANNEL = "usage_watch"
        const val POLL_MS = 1000L
        const val WINDOW_MS = 5000L
    }
}
