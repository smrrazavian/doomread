package io.github.smrrazavian.doomread

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The app's one Flutter engine, cached so it outlives MainActivity: once
 * the user swipes Doomread away, WatchService still needs Dart to decide
 * whether the app in front raises an Urge (ADR 0014). Whichever of the
 * Activity or the service needs it first starts it.
 */
object Engine {
    private const val ID = "main"

    fun running(): FlutterEngine? = FlutterEngineCache.getInstance().get(ID)

    fun get(context: Context): FlutterEngine = running() ?: FlutterEngine(context.applicationContext).also {
        val app = context.applicationContext
        // Channels that need no Activity, so they work with none attached.
        BreakAlarm.listen(app, it.dartExecutor.binaryMessenger)
        Watch.listen(app, it.dartExecutor.binaryMessenger)
        it.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        FlutterEngineCache.getInstance().put(ID, it)
    }
}

/**
 * The native half of AppWatch: reports which app came to the front, and
 * nothing else. Whether that app is Watched is decided in Dart, in core.
 */
object Watch {
    private const val PREFS = "watch"
    private const val WATCHING = "watching"
    private var channel: MethodChannel? = null

    fun listen(context: Context, messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, "doomread/watch")
        this.channel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enabled" -> result.success(enabled(context))
                "openSettings" -> {
                    start(context, Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "apps" -> result.success(apps(context))
                "setWatching" -> {
                    // Kept on disk: after a restart, the service has to know
                    // whether to start Dart before Dart has said anything.
                    context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                        .putBoolean(WATCHING, call.arguments as Boolean).apply()
                    result.success(null)
                }
                "bringToFront" -> {
                    // Allowed from the background: the system has this app's
                    // AccessibilityService bound.
                    start(
                        context,
                        Intent(context, MainActivity::class.java)
                            .addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                    )
                    result.success(null)
                }
                "open" -> {
                    context.packageManager.getLaunchIntentForPackage(call.arguments as String)
                        ?.let { start(context, it) }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun start(context: Context, intent: Intent) =
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))

    private fun enabled(context: Context) = context.getSystemService(AccessibilityManager::class.java)
        .getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        .any { it.resolveInfo.serviceInfo.packageName == context.packageName }

    // Launchable apps only, which the <queries> entry in the manifest makes
    // visible; no QUERY_ALL_PACKAGES.
    private fun apps(context: Context): List<Map<String, String>> {
        val pm = context.packageManager
        return pm.queryIntentActivities(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER), 0)
            .map { it.activityInfo.packageName to it.loadLabel(pm).toString() }
            .filter { it.first != context.packageName }
            .distinctBy { it.first }
            .map { mapOf("package" to it.first, "label" to it.second) }
    }

    private fun label(context: Context, pkg: String) = try {
        val pm = context.packageManager
        pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
    } catch (_: PackageManager.NameNotFoundException) {
        pkg
    }

    /** Tells Dart [pkg] came to the front, while a Session is open. */
    fun foreground(context: Context, pkg: String) {
        if (!context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(WATCHING, false)) return
        // Starts Dart if it isn't running; the message waits in Flutter's
        // channel buffer until Dart listens.
        Engine.get(context)
        channel?.invokeMethod("foreground", mapOf("package" to pkg, "label" to label(context, pkg)))
    }
}

/**
 * Hears which app's window comes to the front. It reads no window content
 * (canRetrieveWindowContent is false), never acts on other apps, and so can
 * never stop the user disabling or uninstalling anything.
 */
class WatchService : AccessibilityService() {
    private var last: String? = null

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val pkg = event.packageName?.toString() ?: return
        if (pkg == last) return
        last = pkg
        Watch.foreground(this, pkg)
    }

    override fun onInterrupt() {}
}
