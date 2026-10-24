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
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.updateAll
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
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
 * The home screen widgets (ADR 0011): the current Work's Road, whether
 * tonight's Window is lit, and Start; and the user's Building, one floor per
 * Finish, with tonight's Window on top, lit or dark.
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
                        BuildingWidget().updateAll(context)
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

    /** The Building: drawn from the same push, sized to the cell it's given. */
    class BuildingWidget : GlanceAppWidget() {
        override val stateDefinition: GlanceStateDefinition<*> = State
        override val sizeMode = SizeMode.Exact

        override suspend fun provideGlance(context: Context, id: GlanceId) = provideContent {
            Building(currentState<Preferences>()[PUSHED]?.let(::JSONObject))
        }
    }

    class BuildingReceiver : GlanceAppWidgetReceiver() {
        override val glanceAppWidget = BuildingWidget()
    }

    // The app's night palette (lib/ui/core/theme.dart).
    private val night = ColorProvider(Color(0xFF18213A))
    private val wall = ColorProvider(Color(0xFF222C49))
    private val deep = ColorProvider(Color(0xFF141B2F))
    private val newFloor = ColorProvider(Color(0xFF2B3758))
    private val unlit = ColorProvider(Color(0xFF1A2238))
    private val lamp = ColorProvider(Color(0xFFF6C453))
    private val me = ColorProvider(Color(0xFFFFE29A))
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

        val lit = litTonight(pushed)

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

    /** Tonight's Window goes dark again when the evening turns over. */
    private fun litTonight(pushed: JSONObject?) =
        System.currentTimeMillis() < (pushed?.optLong("litUntil") ?: 0)

    /** Whether the app's language runs the other way to the launcher's. */
    private fun flipped(context: Context, pushed: JSONObject?) =
        (pushed?.optBoolean("rtl") ?: false) !=
            (context.resources.configuration.layoutDirection == View.LAYOUT_DIRECTION_RTL)

    // The Building's measures, a small copy of BuildingView's tower.
    private val towerWidth = 96.dp
    private const val FLOOR = 22
    private const val GAP = 3
    private const val WINDOWS = 4

    /**
     * The user's tower at night, like the Building screen: tonight's floor on
     * top with its one Window lit or dark, then a lit floor per Finish, the
     * ground with its door, a neighbour and the moon. When the floors don't
     * fit, the top ones are drawn and the tower runs on below the frame. The
     * door and the neighbour sit on the start side and the moon on the end,
     * so they swap sides in Persian. A tap opens the app.
     */
    @Composable
    private fun Building(pushed: JSONObject?) {
        val context = LocalContext.current
        val flip = flipped(context, pushed)
        val rtl = pushed?.optBoolean("rtl") ?: false
        val lit = litTonight(pushed)
        val floors = pushed?.optInt("floors") ?: 0
        val label = pushed?.takeUnless { it.isNull(if (lit) "lit" else "dark") }
            ?.optString(if (lit) "lit" else "dark") ?: ""

        // What's left under the top row and tonight's floor, for the rest.
        val room = LocalSize.current.height.value.toInt() - 12 - 18 - 8 - (FLOOR + GAP)
        val fits = room / (FLOOR + GAP)
        val whole = floors + 1 <= fits // every floor and the ground
        val shown = if (whole) floors else (fits - 1).coerceIn(0, floors)

        val open = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

        Box(
            modifier = GlanceModifier.fillMaxSize().background(night).cornerRadius(16.dp)
                .clickable(actionStartActivity(open)),
            contentAlignment = if (flip) Alignment.BottomEnd else Alignment.BottomStart,
        ) {
            // The neighbour, on the start side.
            Box(modifier = GlanceModifier.width(28.dp).height(48.dp).background(deep)) {}
            Column(
                modifier = GlanceModifier.fillMaxSize().padding(start = 12.dp, top = 12.dp, end = 12.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Row(
                    modifier = GlanceModifier.fillMaxWidth().height(18.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    val text = @Composable {
                        Text(
                            text = label,
                            modifier = GlanceModifier.defaultWeight(),
                            maxLines = 1,
                            style = TextStyle(
                                color = mute,
                                fontSize = 12.sp,
                                textAlign = if (rtl) TextAlign.Right else TextAlign.Left,
                            ),
                        )
                    }
                    val moon = @Composable {
                        Box(modifier = GlanceModifier.size(16.dp).cornerRadius(8.dp).background(paper)) {}
                    }
                    if (flip) { moon(); text() } else { text(); moon() }
                }
                Spacer(GlanceModifier.defaultWeight())
                // Tonight's floor: one Window, lit once tonight has a Session.
                Box(
                    modifier = GlanceModifier.width(towerWidth).height(FLOOR.dp).background(newFloor),
                    contentAlignment = Alignment.Center,
                ) {
                    Box(
                        modifier = GlanceModifier.width(12.dp).height(14.dp).cornerRadius(2.dp)
                            .background(if (lit) me else unlit),
                    ) {}
                }
                Spacer(GlanceModifier.height(GAP.dp))
                repeat(shown) {
                    Floor(FLOOR)
                    Spacer(GlanceModifier.height(GAP.dp))
                }
                if (whole) {
                    Row(
                        modifier = GlanceModifier.width(towerWidth).height(FLOOR.dp).background(wall),
                        verticalAlignment = Alignment.Bottom,
                    ) {
                        val door = @Composable {
                            Box(modifier = GlanceModifier.width(14.dp).height(16.dp).background(deep)) {}
                        }
                        val side = @Composable { Spacer(GlanceModifier.width(14.dp)) }
                        val rest = @Composable { Spacer(GlanceModifier.defaultWeight()) }
                        if (flip) { rest(); door(); side() } else { side(); door(); rest() }
                    }
                } else {
                    // More floors than fit: the tower runs on below the frame.
                    Floor(FLOOR / 2)
                }
            }
        }
    }

    /** One finished floor, its windows lit; cut to [height] dp at the frame. */
    @Composable
    private fun Floor(height: Int) {
        val cut = height < FLOOR
        Row(
            modifier = GlanceModifier.width(towerWidth).height(height.dp).background(wall)
                .padding(top = if (cut) 4.dp else 0.dp),
            verticalAlignment = if (cut) Alignment.Top else Alignment.CenterVertically,
        ) {
            repeat(WINDOWS) {
                Spacer(GlanceModifier.defaultWeight())
                Box(
                    modifier = GlanceModifier.width(12.dp).height(minOf(14, height - 4).dp)
                        .cornerRadius(2.dp).background(lamp),
                ) {}
            }
            Spacer(GlanceModifier.defaultWeight())
        }
    }
}
