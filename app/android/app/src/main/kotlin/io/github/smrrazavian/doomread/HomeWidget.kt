package io.github.smrrazavian.doomread

import android.content.Context
import android.content.Intent
import android.view.View
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import androidx.datastore.preferences.preferencesDataStoreFile
import androidx.glance.Button
import androidx.glance.ButtonDefaults
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.updateAll
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.io.File

/**
 * The home screen widget (ADR 0011): the current Work's Road, whether
 * tonight's Window is lit, and Start.
 *
 * Every word and number on it is worked out in Dart, in the app's language,
 * and pushed over the channel; this side only keeps the last push and draws
 * it. The app language can differ from the phone's, so the layout direction
 * comes with the push too, instead of from the launcher.
 */
object HomeWidget {
    /** On the launch intent: the Work whose Start was tapped. */
    const val EXTRA_START = "io.github.smrrazavian.doomread.START"

    private val Context.store: DataStore<Preferences> by preferencesDataStore(name = "home_widget")
    private val PUSHED = stringPreferencesKey("pushed")

    fun register(activity: MainActivity, messenger: BinaryMessenger): MethodChannel {
        val context = activity.applicationContext
        val channel = MethodChannel(messenger, "doomread/home_widget")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    val pushed = JSONObject(call.arguments as Map<*, *>).toString()
                    CoroutineScope(Dispatchers.Default).launch {
                        context.store.edit { it[PUSHED] = pushed }
                        Widget().updateAll(context)
                    }
                    result.success(null)
                }
                "openedFrom" -> {
                    result.success(activity.intent.getStringExtra(EXTRA_START))
                    // Once: a later restore of the Activity isn't a tap.
                    activity.intent.removeExtra(EXTRA_START)
                }
                else -> result.notImplemented()
            }
        }
        return channel
    }

    /** All widgets share the one last push. */
    private object State : GlanceStateDefinition<Preferences> {
        override suspend fun getDataStore(context: Context, fileKey: String) = context.store

        override fun getLocation(context: Context, fileKey: String): File =
            context.preferencesDataStoreFile("home_widget")
    }

    class Widget : GlanceAppWidget() {
        override val stateDefinition: GlanceStateDefinition<*> = State

        override suspend fun provideGlance(context: Context, id: GlanceId) = provideContent {
            Content(currentState<Preferences>()[PUSHED]?.let(::JSONObject))
        }
    }

    class Receiver : GlanceAppWidgetReceiver() {
        override val glanceAppWidget = Widget()
    }

    // The app's night palette (lib/ui/core/theme.dart).
    private val night = ColorProvider(Color(0xFF18213A))
    private val unlit = ColorProvider(Color(0xFF1A2238))
    private val lamp = ColorProvider(Color(0xFFF6C453))
    private val paper = ColorProvider(Color(0xFFEDE6D6))
    private val soft = ColorProvider(Color(0xFFC9C3B6))
    private val mute = ColorProvider(Color(0xFF9AA3BD))

    @Composable
    private fun Content(pushed: JSONObject?) {
        val context = LocalContext.current
        val rtl = pushed?.optBoolean("rtl") ?: false
        // Rows follow the launcher's direction, so they're turned around
        // when the app's language reads the other way.
        val flip = rtl != (context.resources.configuration.layoutDirection == View.LAYOUT_DIRECTION_RTL)
        val align = if (rtl) TextAlign.Right else TextAlign.Left
        fun text(key: String) = pushed?.takeUnless { it.isNull(key) }?.optString(key)

        val launch = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        // Back into the open Session the way its notification does, or Start.
        text("sessionId")?.let { launch.putExtra(SessionNotification.EXTRA_SESSION, it) }
            ?: text("workId")?.let { launch.putExtra(EXTRA_START, it) }

        // Tonight's Window goes dark again when the evening turns over.
        val until = pushed?.optLong("litUntil") ?: 0
        val lit = System.currentTimeMillis() < until

        Column(
            modifier = GlanceModifier.fillMaxSize().background(night).cornerRadius(16.dp).padding(16.dp),
        ) {
            if (pushed != null) {
                Row(modifier = GlanceModifier.fillMaxWidth()) {
                    val window = @Composable {
                        Box(
                            modifier = GlanceModifier.size(14.dp).cornerRadius(3.dp)
                                .background(if (lit) lamp else unlit),
                        ) {}
                    }
                    val label = @Composable {
                        Text(
                            text = text(if (lit) "lit" else "dark") ?: "",
                            modifier = GlanceModifier.defaultWeight(),
                            style = TextStyle(color = mute, fontSize = 12.sp, textAlign = align),
                        )
                    }
                    val gap = @Composable { Spacer(GlanceModifier.width(8.dp)) }
                    if (flip) { label(); gap(); window() } else { window(); gap(); label() }
                }
                Spacer(GlanceModifier.height(8.dp))
            }
            Text(
                text = text("title") ?: context.getString(R.string.app_name),
                modifier = GlanceModifier.fillMaxWidth(),
                maxLines = 1,
                style = TextStyle(color = paper, fontSize = 16.sp, fontWeight = FontWeight.Bold, textAlign = align),
            )
            for (key in listOf("road", "evenings")) {
                text(key)?.let {
                    Text(
                        text = it,
                        modifier = GlanceModifier.fillMaxWidth(),
                        maxLines = 1,
                        style = TextStyle(
                            color = if (key == "road") soft else mute,
                            fontSize = 13.sp,
                            textAlign = align,
                        ),
                    )
                }
            }
            Spacer(GlanceModifier.defaultWeight())
            Button(
                text = text("button") ?: context.getString(R.string.app_name),
                onClick = actionStartActivity(launch),
                modifier = GlanceModifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(backgroundColor = lamp, contentColor = night),
            )
        }
    }
}
