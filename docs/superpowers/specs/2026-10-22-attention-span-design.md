# Doomread (باز گوشی؟!): design

Date: 2026-10-22. Status: draft for review.
Mockups: `docs/mockups/doomread-mockups.html` (current: all screens with the name and tones, English and Persian side by side), `docs/mockups/app-final-v2.html` (the spacing and type system sheet) and `docs/mockups/urge-moment-tide-vs-windows.html` (the two urge-screen directions).

> **Name (decided):** **Doomread** (Latin brand, everywhere) and **باز گوشی؟!** (*baaz gooshi?!*, "phone AGAIN?!", the classic Iranian mom line) as the Persian name. Audience: **Gen Z**, mostly Persian speakers in Iran.

## 1. Intent and why

The owner is a developer with a short attention span. They can't stay with a novel, a tech book, a podcast or a YouTube talk alone. About every five minutes they pause and switch to Reels, TikTok or music. One hour with a novel yields maybe 5 minutes of reading in one go. They are not tired; the urge just keeps returning.

The key evidence: they watched *Paris, Texas* (2.5 h) with friends without a single pause. They **felt** the urge to check the phone but **held back because others were watching**. So their attention works; what's missing when alone is the outside push that helps them not act on the urge.

The app recreates that movie-night feeling when the user is alone. It does this with **company** (a sense that others are reading too), a **planned break** that replaces the impulsive one, and **visible progress toward finishing**.

**Success = finishing the thing**: the last page of the book, the last episode, the end of the podcast. Minutes in one go are a means, not the goal.

The app is first for the owner, then for others: Gen Z, mostly Persian speakers inside Iran.

## 2. Grounding in research (and its limits)

The design leans on these findings. The builder should keep the copy honest to them and not overclaim.

| Idea | Evidence | How it's used |
|---|---|---|
| Friction at the moment of opening a distracting app | one sec field study, PNAS 2023 (Grüning et al., N=280, 6 weeks): 36% of open attempts were dismissed and opens fell 57%. The easy "go back" option was the active ingredient, not a lecture. Authors are linked to the app maker. | The urge screen, with one big "Back to the book" and a non-shaming "Open now". |
| Body doubling / social presence | Anecdotally strong, scientifically thin: a 12-person VR study shows benefit, and no controlled trials exist. The owner's own movie-night experience is the strongest evidence here. | The "house" of lit windows, friends, and reading nights. |
| Urge surfing | Tested mainly in smoking. There is **no solid source for how long an urge lasts**. | The urge is described as a wave that passes. **Never promise a duration.** |
| Testing effect / retrieval practice | Well established. | One sentence after each session: "what happened?" |
| Goal-gradient effect | Kivetz et al. 2006: people speed up near a goal. | The road to the last page, and "about four evenings left". |
| Implementation intentions | Gollwitzer, well established. | A planned break: "after chapter 6, five minutes of anything". |
| Fresh-start effect | Dai, Milkman, Riis 2014. | The week resets every week; there are no unbroken streak chains. |
| Self-Determination Theory (competence, autonomy, relatedness) | Deci & Ryan. | Progress is shown as mastery and finished works; the user chooses; friends. |
| Overjustification, variable rewards, what-the-hell effect | Well known. | The anti-goals below. |

## 3. Goals, non-goals, anti-goals

**Goals**
- Help the user **finish** books, series, films and podcasts.
- Make each evening's reading or watching longer in one go, starting from the user's real baseline (about 5 minutes).
- Make the alone case work well; friends are a bonus.
- Feel delightful, calm and warm. Nothing should look like a generic AI template (the owner rejected the first mockup for exactly that).
- English (default) and Persian, both first-class, with Persian designed and not just mirrored.

**Non-goals**
- Quitting or banning Instagram, TikTok, YouTube Shorts, messengers or social media. They stay in the user's life; they just wait for the planned break.
- Being an e-reader or a media player. The content lives elsewhere: a paper book, another app, YouTube, a TV.
- Any AI or LLM features. The reading buddy is a question plus the user's own sentence.

**Anti-goals (a failure even if it technically works)**
- Becoming a second slot machine: no random rewards, loot boxes, spins, or surprise chests.
- Shaming or lecturing copy, and guilt notifications.
- Harsh streaks that "break" and make the user quit.
- Leaderboards or comparing minutes with other people.
- Faking live presence. Earlier readers are shown as *earlier*, never as live.
- Many notifications. The app must not become one more interruption.
- A dependency on Google services or foreign infrastructure that breaks the app inside Iran.

## 4. Platforms, distribution, licence (decided)

- **Minimum Android version: 10 (API 29)**, decided by the owner. It gives `UsageEvents` `ACTIVITY_RESUMED` for the fallback watcher, and targets the latest stable SDK.
- **Android and Linux desktop first. iOS later.** iOS is constrained further by Apple sanctions for Iran-based developers and by the Screen Time entitlement process.
- **Built with Flutter** (the owner's call was delegated; this is my call, see section 11). Native code is used only where Flutter can't reach: widgets, Android app detection, live notifications, and later the iOS Screen Time extensions.
- **Distribution:** direct APK, Google Play, Cafe Bazaar. F-Droid is deferred (see ADR-0004); the code stays F-Droid-friendly. These are separate build flavours of one codebase:
  - **play**: the Accessibility declaration and an in-app prominent disclosure (see section 7.1).
  - **bazaar**: updates through Cafe Bazaar. **Its rules on accessibility services are not yet verified.**
  - **apk**: includes a "new version available" check against our server.
- **Licence: GPL-3.0**, open source from day one. The server may live in a separate repository.

## 5. Context: users inside Iran (decided, with consequences)

Most users are inside Iran. Therefore:
- **Offline first.** The core works with no internet at all: sessions, books, the road, notes, the building, the urge screen and planned breaks. Social features sync when a connection exists, and the app tolerates international links being down.
- **Our own small server,** reachable from inside Iran (hosting location left to the builder, but it must keep working on the domestic network).
- **Accounts (decided).** One account syncs the library, sessions and notes between the phone and the Linux app. The app works fully without signing in, and without a connection, then syncs when it can. There's no Google or Apple sign-in. The sign-in method is left to the builder, but it must work inside Iran (for example email or a username with a passkey/password; SMS would need an Iranian provider).
- **No Firebase/FCM.** Push uses **UnifiedPush with a self-hosted ntfy** server by default (phase 2 may add a closed Iranian push SDK behind a seam in `bazaar`/`apk` only; see ADR-0004). While the app is open, it uses its own live connection. Linux push is deferred.
- **All assets bundled:** fonts, illustrations, everything. No Google Fonts and no CDNs at runtime.
- **The Persian calendar (Solar Hijri) and a Saturday-first week** are the default in the Persian locale.

## 6. The experience

### 6.1 Core loop (one evening)
1. **Tonight:** the user picks their current work (book, ebook, podcast, video, film or series) and sees the road to its end ("103 pages left, about four evenings at your pace"). They also set tonight's **planned break** ("after chapter 6, 5 minutes of anything") and see the **aim**: minutes in one go, starting at their best plus one minute. They tap Start.
2. **Reading:** a quiet timer, the aim, the distance to the planned break, "turn the phone face down", and the user's lit window with other readers nearby. Pausing (water, the door) never counts against them.
3. **The urge:** if the user opens a watched app (Instagram, TikTok, YouTube Shorts, user-configurable) during a session, the urge screen appears. It says "Not yet. Instagram is waiting at the end of chapter 6. About 9 pages. You planned this break yourself." There is a big "Back to the book" and a full-size "Open Instagram now" that is always allowed. Going back counts as an urge let pass.
4. **The planned break:** at the break point the user is told the break is earned, gets a timer for its length, and sees the return time named in advance ("Back to chapter 7 at 21:42"). A notification calls them back when it ends.
5. **End of the evening:** "Which page did you stop at?" (a large numeric field; for podcasts and videos, a timestamp or episode), one sentence about what happened, and a tally of urges let pass and breaks taken. **Phase 1 notes are typed only.** Offline Persian speech-to-text would mean bundling a large on-device model, so voice notes wait until later and the microphone button is left out of phase 1 (my call).
6. **The last page:** the finishing ceremony. The building grows a lit floor, alongside the totals (pages, evenings, longest stretch, notes) and a button to "read the story in your words". The user can tell friends.

**Stretch rules (my call; these define the competence number, so they are fixed from day one):**
- A *stretch* is continuous session time with the timer running.
- A stretch **ends** when the user pauses, gives in to a watched app (taps "Open now"), starts the planned break, or stops.
- **Letting an urge pass does not end the stretch.** The seconds spent on the urge screen count as part of it, because riding out the urge is the point.
- A pause is never shown as a failure. It just starts a new stretch when the user resumes.
- **Longest stretch** = the longest single stretch. **The aim** = the previous longest stretch for that kind of work (reading vs watching), plus one minute.
- Store raw events (start, pause, resume, urge shown, urge passed, gave in, break start/end, stop) with timestamps, so the definition can be recomputed later.

**Several works at once (my call):** any number can be in progress, for example a novel and a series. Tonight shows the most recently used one with a switcher. The widget shows the most recently used work. Pace and "about N evenings" are worked out per work.

**Content on the phone itself (decided: in phase 1).** The work can live in another app on the same phone: an ebook reader, YouTube, a podcast app, Telegram audio. So:
- The user can mark an app as **the work** for a session. Switching to it never counts as an urge, and the session keeps running in the background with its live notification.
- **YouTube is both a possible work and the home of Shorts.** While YouTube is the work, only Shorts triggers the urge screen. This makes Shorts detection (section 7.1) a phase 1 requirement, not an extra.
- "Turn the phone face down" appears only when the work isn't on the phone.

**Planned breaks are offered by the app (decided by the owner; numbers are my call from the research):**
- The app proposes each Planned break, and the user accepts it or nudges it later. The user never plans breaks from scratch. Research basis: Biwer et al. 2023, *Br J Educ Psychol*, where systematic breaks (6/24, 3/12) beat self-chosen breaks on fatigue, concentration and motivation for the same output; and Albulescu et al. 2022, *PLOS ONE*, where micro-breaks gave small gains in energy and less fatigue. Later results are mixed, so every number here is a tunable default.
- **Ratio:** 1 minute of break per 4 minutes of reading.
- **Interval:** starts at 12 minutes of reading with a 3-minute break, and grows toward 24 minutes with a 6-minute break as the Longest stretch grows. Breaks are 10 minutes at most.
- **Placement:** each break lands at the first Checkpoint after the interval. If the next Checkpoint is too far away, it falls at the end of the current page or segment instead.
- **Several per Session:** a Session can earn several breaks.

How the user marks a break point (chapter end, page number, timestamp) and how the app knows it has been reached (the user taps "chapter done", or a page update) is **left to the builder**. The mockups assume the user taps when they reach the end of the chapter.

### 6.2 Screens (all in the mockup)
Tonight; Reading; Urge; After a slip (kind in every tone); Planned break; End of the evening; Book (road and the user's notes, newest first, as "the story so far in your words"); The last page; Building (one floor per finished work, plus a list); Friends; plus Tone settings, the lock screen (Live Update and notifications), the home screen widget, and the Linux desktop companion panel. The app icon is a lit window in the night building.

Bottom navigation: **Tonight, Books, Building, Friends**.

### 6.3 Progress, motivation and rewards
- **The road** to the last page, with chapter marks, a "you are here" marker and a finish flag. Its estimate ("about N evenings") uses the user's own pace.
- **Your building:** every finished work adds a floor. The month view shows one window per day, brighter for longer reading.
- **Reading nights per week** (e.g. 4 of 7). A missed night just stays dark, and each week starts fresh.
- **Longest stretch** is the one competence number, shown as a gently rising line.
- **Your notes** become a keepsake of the book, in the user's own words.
- **Shared light:** if friends read on the same night, a light joins their buildings.
- **No points, coins, badges for their own sake, random rewards or rankings.**

### 6.4 Company (the house)
- **The house** is an apartment block at night. Bright windows are people reading right now (friends, later anyone opted in), dim windows with an amber outline read earlier tonight, and the user's own window pulses slowly.
- **With no one around,** it shows only honest data: the user's own past evenings, and friends' earlier sessions. **Never invent readers.** If the house is empty, it says so kindly.
- **Strangers (phase 2):** the owner said quiet company from strangers would work for them. So phase 2 includes an opt-in public house, where anonymous readers appear as windows only: no names, no profiles, no messaging, and nothing to abuse. Friends see names. The server must be sized for that anonymous presence, not just for friends.
- **Friends:** add by invite link, see "Ali is reading Dune, page 212", plan a reading night, and get one reminder 10 minutes before.

### 6.5 Notifications (kept few)
- **Break over:** "chapter 7 is waiting". It may arrive up to about a minute late, since exact alarms are off by default on Android 14+.
- **Reading night reminder:** 10 minutes before.
- **A friend started reading:** **off by default, user opt-in** (my call).
- **Usual-time nudge:** opt-in only.
- **During a session:** a live ongoing notification with a countdown chip (Android 16 Live Updates when available, otherwise a normal ongoing notification with a chronometer).

### 6.6 Widgets
- **Home screen widget:** the current work's road ("p. 156 of 245, about three evenings left"), tonight's window lit or dark, and a one-tap Start.
- **Linux:** a tray item with the session timer.

### 6.7 Linux desktop
- **The companion panel** is a slim window beside whatever the user watches or reads, showing the same road, timer, planned break and house.
- **The urge screen on desktop** is triggered by a small **browser extension** that detects Shorts, Reels and TikTok tabs (the transport to the desktop app is left to the builder). The extension is part of the project (my call: Firefox and Chromium).
- **My call:** during a session, the extension covers the page itself with the same "not yet" card ("Back to the book" / "Open now", in both languages), because that's where the user is looking. The desktop panel records the urge. If the desktop app isn't running, the extension does nothing.

## 7. Platform specifics (verified against docs, 2026-10)

### 7.1 Android: detecting the distracting app
- **Primary method: an AccessibilityService** (the same approach as one sec). We are **not** an accessibility tool (`isAccessibilityTool` = false).
  - On Play this needs the Accessibility declaration in Play Console (including a short video) and an in-app prominent disclosure that requires an affirmative tap. Review risk is moderate.
  - The service must never stop the user from disabling or uninstalling anything.
- **Fallback: UsageStatsManager** (`PACKAGE_USAGE_STATS`, granted in Settings) polling `ACTIVITY_RESUMED`, plus an overlay window. It's needed because Android 17 Advanced Protection reportedly revokes accessibility access for non-tool apps.
- **YouTube Shorts** uses the same package as YouTube and can only be told apart by heuristics on the accessibility node tree. These are fragile, so **the detection rules must be data that can be updated without an app release**. The update channel is left to the builder.
- **Onboarding** explains each permission plainly, in both languages, before asking.

### 7.2 Android: timer, alarms, notifications
- **The session timer doesn't need a foreground service:** store the start/end timestamps, show an ongoing notification with a chronometer, and use an alarm for the break end. Use `mediaPlayback` only if the app ever plays audio itself; avoid `specialUse`.
- **`POST_NOTIFICATIONS`** is requested in context (Android 13+).
- **Exact alarms:** check `canScheduleExactAlarms()`. If it's denied, fall back to a window or allow-while-idle alarm. Do **not** use `USE_EXACT_ALARM` (it's meant for alarm clock and calendar apps).
- **Live Updates (Android 16+)** need `POST_PROMOTED_NOTIFICATIONS`, `setRequestPromotedOngoing(true)`, an ongoing notification with a title, a standard or ProgressStyle template and no custom views. Check `canPostPromotedNotifications()`.

### 7.3 Widgets from Flutter
`home_widget` passes the data. The widget UI is native: Jetpack Glance on Android, and SwiftUI WidgetKit later on iOS. The app pushes a widget update whenever progress changes; periodic updates are limited to 30 minutes at best.

### 7.4 Linux
- **Supported targets:** Ubuntu 20.04–24.04 and Debian 10–13.
- **Packaging:** Snap (official guide) and Flatpak (community tooling; Flathub builds offline, so all sources must be declared).
- **Tray:** `tray_manager`. GNOME needs the AppIndicator extension, so document this. The tray shows the menu but sends no click events.
- **Notifications:** `flutter_local_notifications` can't schedule on Linux, so the app keeps its own timer while it runs.

### 7.5 iOS (later; record of constraints only)
- **Screen Time** (FamilyControls `.individual` on iOS 16+) is allowed on the user's own device, but the distribution entitlement needs Apple's approval, which reportedly takes days to weeks. There are three extensions.
- **The shield card is fixed:** an icon, title, subtitle and two buttons. Its buttons can't open our app (the workaround is a notification). A new `openParentalControlsApp` response in iOS 26.5 is untested for `.individual`. Shielding an app also silences its notifications.
- **Alternative:** Shortcuts "App opened" automations, which is what one sec mainly does.
- **Live Activities** via the `live_activities` package need a Swift widget extension.
- **An Apple developer account** is constrained by sanctions for developers in Iran.

## 8. Visual design (decided through mockups)

- **Direction: "Windows".** Night ink, warm lamplight, an apartment block of lit windows. The "Tide" direction was explored for the urge screen and dropped. The owner asked for final mockups and reviewed them, and they use Windows throughout, so Windows is final (my call). Build the urge screen once.
- **Colour tokens:**

  | Token | Hex | Token | Hex |
  |---|---|---|---|
  | night | `#18213A` | lamp | `#F6C453` |
  | wall | `#222C49` | me | `#FFE29A` |
  | deep | `#141B2F` | paper | `#EDE6D6` |
  | panel | `#1F2945` | soft | `#C9C3B6` |
  | raise | `#2A3456` | mute | `#9AA3BD` |
  | line | `#2E3A5E` | | |

  Earlier-tonight windows are an outline in `#E2B65A` at 60%. Text contrast is AA or better.
- **A light theme** isn't designed yet (left to the builder, keeping the same tokens' roles). Dark is the default, since reading happens in the evening.
- **Type:**
  - **English:** Literata (book titles, headings, notes, clocks) and Bricolage Grotesque (UI).
  - **Persian:** Vazirmatn, using its **UI variant** for the interface, and Noto Naskh Arabic for book titles and notes.
- **Type scale:**
  - **English:** heading 26/1.2, title 19, body 16/1.5, small 15, caption 13, clock 72.
  - **Persian:** heading 23/1.55, body 16/1.8, book text 15/1.85, clock 68.
- **Spacing:** a 4-point grid (4, 8, 12, 16, 24, 32, 48). The screen gutter is 24, card padding 16, list rows 12 and gaps between buttons 8. Touch targets are at least 48dp. The primary action is always at the bottom, in reach of the thumb.
- **Motion:** one orchestrated moment per screen at most (windows lighting up in sequence, the new floor on finishing) and a slow pulse on the user's window. Respect reduced motion.
- **Banned "AI template" tells:** small uppercase eyebrow labels, "A · B · C" middle-dot strings, an accent on one word of a headline, identical card grids, emoji icons, and arrows appended to buttons.
- **Icons:** one stroke family, 1.7px, rounded.

### 8.1 Persian rules
- **Layout uses start/end, never left/right** (`EdgeInsetsDirectional`, `AlignmentDirectional`). The road, chevrons, finish flag, illustrations and book cover spine all mirror. Persian books are bound on the right.
- **Clocks, digit order and media icons don't mirror.**
- **Persian digits everywhere** in the Persian locale (verify that `intl` output gives ۰–۹; force it if needed), plus the ٪ sign and Persian page ranges ("ص ۱۴۲ تا ۱۵۶").
- **Dates use the Solar Hijri calendar** (`shamsi_date`), e.g. "شروع ۱۷ مهر". The week starts on Saturday: ش ی د س چ پ ج.
- **Persian text never gets** letter spacing, italics or uppercase-style transforms.
- **Use correct half-spaces (ZWNJ):** می‌خوانند، کتاب‌ها.
- **Titles go in «guillemets»** and are bidi-isolated where they mix with Latin text.
- **Copy is written natively in Persian,** not machine-translated. The mockup strings are a starting point. The owner is a native Persian speaker and reviews all Persian copy and the Persian design at each milestone (my call).
- **Localization** uses Flutter `gen_l10n` with ARB files, importing the generated code from the source tree (the `flutter_gen` synthetic package is gone).

### 8.2 Voice and tone (decided)
- **Funny, a bit rude, meme-aware, for Gen Z.** The model is the Duolingo owl's "balance between nice and mean". Second person, sentence case, and slang where it fits (aura, skill issue, lock in, lowkey; in Persian: دمت گرم، پایه، حلالت، اسکیل ایشو).
- **The rule behind the jokes: roast the urge, never the person.** **Never roast right after a slip.** After the user gives in, every tone is kind ("Fumbled. It happens. Back in?" / «اشکال نداره، برگرد.»), because a roast there triggers the what-the-hell spiral.
- The urge screen says "not yet", never "don't".
- **Three tones, chosen by the user in Settings and offered at onboarding:**
  - **Chill:** gentle, no roasting. "Instagram can wait until chapter 6 ends."
  - **Spicy (default):** a light roast before the slip, kind after it. "Skill issue. 9 pages left."
  - **Mom mode / مامان‌مود:** full Iranian mom. «باز گوشی دستته؟! ۹ صفحه مونده!» … «دمت گرم! حالا پاشو یه چایی بخور.»
- **Persian copy is written in everyday spoken Persian** (محاوره: می‌خونن، مونده). The mockups show that register. Mom mode exists in English too, translated in spirit ("Phone. AGAIN?!").
- **Hard limits for every tone:** no insults about intelligence, body, family or identity; no swearing; no guilt about Reels during the planned break, which is "legal brainrot".
- **The jokes live in a swappable copy pack per tone and locale,** so memes can be refreshed without code changes. They stay in the app's own string files (no remote code). Whether a refreshed pack can arrive between releases is left to the builder, with the same channel as the detection rules.
- **Errors and empty states give direction,** for example "No one's reading right now. Be the first light tonight." 

## 9. Data (minimum the experience needs)
- **Work:** title, author/creator, kind (paper book, ebook, podcast, video, film or series), total length (pages, minutes or episodes), optional chapter marks, start and finish dates.
- **Session:** work, start, end, longest stretch in one go, pauses, urges let pass, urges given in to, the planned breaks (a session can earn several, one per reached checkpoint) and whether each was taken, the position at the end (page, timestamp or episode), and the note.
- **Settings:** watched apps, locale, notifications opt-ins, aim adjustment.
- **Social (synced):** friend links, presence ("reading now", "earlier tonight"), finished-work events, planned reading nights. Only what's needed to show windows and the friends list, and only shared by the user's choice.
- **Storage** is local first, with IDs that can be synced from day one. Changes sync to the user's own account for other devices, so the phone and the laptop share one library, notes and best stretches. The local database, sync protocol and conflict handling are left to the builder. Notes and reading history are private to the account. They are shown to friends only by the user's choice, and synced data is encrypted in transit (my call).

## 10. Phasing (my call)
1. **Phase 1: the core, offline first, synced across your devices.** Android and Linux, English and Persian, every screen except Friends. This covers:
   - content on the phone itself, including Shorts detection;
   - the urge screen on Android, and the browser extension on Linux;
   - break-over notifications, the session live notification, and the home widget;
   - the build flavours (apk, play, bazaar);
   - **accounts and a small server for syncing the user's own data between the phone and the laptop**.

   The house shows the user's own past evenings only.
2. **Phase 2: company.** Friends, presence in the house (friends and the anonymous opt-in public house), reading nights, UnifiedPush/ntfy, and the finished-work note to friends, all on the phase 1 server.
3. **Phase 3: iOS,** subject to the developer-account and entitlement constraints in section 7.5.

## 11. Calls I made (for the owner to check)
- Flutter as the framework (delegated by the owner, and reinforced by the iOS-later and Linux needs).
- The phasing above: the server and accounts in phase 1 for personal sync, friends and presence in phase 2.
- "A friend started reading" notifications off by default.
- The browser extension targets Firefox and Chromium.
- Notes are private and local by default.
- The aim starts at the user's best plus one minute.
- The bottom nav labels: Tonight, Books, Building, Friends.
- The stretch rules, and several works in progress at once (section 6.1).
- Phase 1 notes are typed only; voice comes later.
- The browser extension covers the distracting page with the "not yet" card.
- Windows is the final visual direction; Tide is dropped.
- The owner reviews the Persian copy.
- Spicy is the default tone, and Mom mode exists in English too.
- An "after a slip" screen, shown when the user comes back from giving in.

## 12. Open
- **Cafe Bazaar's policy** on accessibility services, which must be checked before release.

## 13. Left to the builder
Architecture, state management, local database, sync protocol, server stack and hosting, the remotely updatable detection-rule channel, the extension-to-desktop transport, how break points are marked and detected, the light theme, the test strategy and CI.
