package io.github.smrrazavian.doomread

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
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
    private const val VIEWS = "views"
    private var channel: MethodChannel? = null

    /** The view ids to look for, by package; read from disk once. */
    private var views: Map<String, List<String>>? = null

    fun listen(context: Context, messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, "doomread/watch")
        this.channel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                // Dart picks the way to watch from these (pickWatchMethod).
                "grants" -> result.success(
                    mapOf(
                        "accessibility" to enabled(context),
                        "usageAccess" to UsageWatch.granted(context),
                        "overlay" to Settings.canDrawOverlays(context),
                    ),
                )
                "openSettings" -> {
                    start(context, Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "openUsageAccess" -> {
                    start(context, Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }
                "openOverlay" -> {
                    start(
                        context,
                        Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:${context.packageName}")),
                    )
                    result.success(null)
                }
                "apps" -> result.success(apps(context))
                "setWatching" -> {
                    // Kept on disk: after a restart, the service has to know
                    // whether to start Dart before Dart has said anything.
                    val ids = call.argument<List<String>>("views").orEmpty()
                    context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                        .putBoolean(WATCHING, call.argument<Boolean>("on")!!)
                        .putStringSet(VIEWS, ids.toSet())
                        .apply()
                    views = parse(ids)
                    UsageWatch.set(context, on = call.argument<Boolean>("poll") == true)
                    result.success(null)
                }
                "bringToFront" -> {
                    // Allowed from the background: the system has this app's
                    // AccessibilityService bound, or, with usage access, the
                    // user let it display over other apps (ADR 0016).
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

    // "package|view id", as Dart sends them.
    private fun parse(ids: Collection<String>) =
        ids.map { it.substringBefore('|') to it.substringAfter('|') }
            .groupBy({ it.first }, { it.second })

    /** The view ids Dart asked to look for in [pkg]'s screens, if any. */
    fun views(context: Context, pkg: String): List<String>? {
        val all = views ?: parse(
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getStringSet(VIEWS, null).orEmpty(),
        ).also { views = it }
        return all[pkg]
    }

    /**
     * Tells Dart [pkg] came to the front, while a Session is open, and which
     * of the view ids it asked for are on its screen.
     */
    fun foreground(context: Context, pkg: String, seen: Set<String>) {
        if (!context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(WATCHING, false)) return
        // Starts Dart if it isn't running; the message waits in Flutter's
        // channel buffer until Dart listens.
        Engine.get(context)
        channel?.invokeMethod(
            "foreground",
            mapOf("package" to pkg, "label" to label(context, pkg), "views" to seen.toList()),
        )
    }
}

/**
 * Hears which app's window comes to the front. In the Work app only, it
 * also looks up the view ids Dart asked for (Shorts in YouTube, ADR 0015):
 * whether each is on screen, never any text. It never acts on other apps,
 * and so can never stop the user disabling or uninstalling anything.
 */
class WatchService : AccessibilityService() {
    /** What was reported last, so each change is reported once. */
    private var last: Pair<String, Set<String>>? = null
    private var checkedAt = 0L
    private val handler = Handler(Looper.getMainLooper())
    private var recheck: Runnable? = null

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val pkg = event.packageName?.toString() ?: return
        val ids = Watch.views(this, pkg)
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) return check(pkg, ids)
        // Content changes only matter inside the Work app, and come many
        // times a second while a video plays: check at most every 500 ms,
        // and once more after a burst, so the last change isn't dropped.
        if (ids == null) return
        val wait = checkedAt + CHECK_EVERY_MS - SystemClock.uptimeMillis()
        if (wait <= 0) return check(pkg, ids)
        if (recheck != null) return
        recheck = Runnable {
            recheck = null
            check(pkg, ids)
        }.also { handler.postDelayed(it, wait) }
    }

    private fun check(pkg: String, ids: List<String>?) {
        checkedAt = SystemClock.uptimeMillis()
        val root = if (ids == null) null else rootInActiveWindow
        // A Work app that isn't the window in front any more.
        if (ids != null && root?.packageName != pkg) return
        val seen = ids.orEmpty().filter { root?.findAccessibilityNodeInfosByViewId(it)?.isNotEmpty() == true }.toSet()
        val report = pkg to seen
        if (report == last) return
        last = report
        Watch.foreground(this, pkg, seen)
    }

    private companion object {
        const val CHECK_EVERY_MS = 500L
    }

    override fun onInterrupt() {}
}
