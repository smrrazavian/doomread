# Tasks, Today and the calendar: design

Date: 2026-10-24. Status: approved by the owner in the visual companion; issues to follow.
Mockups: `docs/mockups/tasks-and-calendar.html` (Today with the time-of-day sky, a Task Session with the Done moment, and the calendar in English and Persian). The key screens are described below so this document stands alone.

## 1. Intent and why

Doomread helps people finish what they read or watch by guarding them from the urge to grab the phone. The owner wants the same help for **people who work**: company tasks ("write the Q3 report", "review the PRs") and daily ones ("call the bank"). The phone pulls them away from those as much as from a novel.

Asked to choose, the owner said the app should do **both, but mostly A**:
- **A (main):** keep the user focused *while doing* a task, with the same Session, Urge screen and Planned breaks as a book.
- **B (smaller):** a place to jot today's tasks and look back on days in a beautiful calendar.

It should feel delightful, with "wow" moments worth sharing, in the existing Windows look (night ink, lamplight). It must not look like a generic AI template (spec 2026-10-22 §8).

## 2. Goals, non-goals, anti-goals

**Goals**
- Starting focused work on a task takes one tap from Today.
- A Task Session gives the same protection as a book: the Stretch, the Aim, the Urge screen and Planned breaks.
- Finishing a task feels good: the Done moment.
- One calendar shows each day's focus, tasks done, reading nights and Finishes.
- English and Persian are both first-class, as everywhere else.

**Non-goals**
- Becoming a to-do app: no projects, sub-tasks, tags, priorities, due times, recurring tasks, or sharing tasks with coworkers. Todoist and Jira own that.
- Importing tasks from other tools.
- Time tracking or reports for an employer.

**Anti-goals (a failure even if it works)**
- Red "overdue" states, overdue counters, or guilt notifications about unfinished tasks.
- Task reminders that turn the app into one more interruption.
- Comparing focus with other people, or productivity scores.
- Streaks: the calendar shows lit and dark days, and a dark day is just dark.

## 3. Domain (to add to CONTEXT.md)

- **Task:** a new kind of **Work**, something the user intends to get done in one or a few sittings. It has a name and, optionally, a **day** it's planned for and a rough **estimate** in minutes. It has no Position, no Checkpoints and no Road. _Avoid:_ to-do, todo item, ticket.
- **Done:** the Finish of a Task. It lights a window, but does **not** add a floor to the Building, because floors stay for finished books, series, films and podcasts.
- **Working** joins reading and watching as the third kind of attention. The **Longest stretch** and the **Aim** are kept separately for each of the three. In code, `WorkKind.watched` (`packages/core/lib/src/work.dart`) grows into a three-way split.
- **Today:** the home screen, formerly **Tonight**. It holds today's Tasks and tonight's book. "Tonight" stays as the label of the book card on it.
- **The calendar:** a month of days, each showing that day's focus time, Tasks done, whether the user read that night, and any Finish.

## 4. The experience (decided with the owner via mockups)

### 4.1 Today (replaces Tonight)
- **The sky follows the real time.** A header strip shows the sky over a small skyline: warm morning, blue midday, dusk at six, night with the moon. As evening comes, the neighbours' windows light one by one. The greeting matches the time ("Saturday afternoon" / «شنبه عصر»), with a sub-line like "3 things today, then your book".
- **Today's Tasks** are a list. Each row has a small **window** glyph (dark, lit when Done), the name, and a quiet meta line: the estimate ("About 45 min"), or for a Done task "Done at 11:40, 38 min in one go".
  - The next undone task gets a filled **Start**, and the others an outlined one.
- **Tonight's book** is a card under the tasks: the moon, the title, a mini Road and "91 pages left".
- **Add a task** is a dashed row at the bottom of the list. It needs only a name. The day defaults to today, and the estimate is optional.
- **Unfinished Tasks from earlier days show on Today with no marking.** There is no "overdue", no count and no colour change. They simply carry over.
- **Bottom navigation:** Today, Library, Calendar, Building. Friends leaves the bar until it ships (phase 2) and comes back then. This settles the Friends part of #30.

### 4.2 A Task Session
- It's the same Session machinery as a book: Start, the Stretch, Pause, the Urge screen, Planned breaks and Stop. Events go to the same journal.
- **Copy uses the Task's name:** "Working on / Write the Q3 report", and on the Urge screen "Back to the report" instead of "Back to the book". Every Tone gets task variants in the voice copy packs (ADR-0017).
- **The scene is a desk at night,** not the House. It shows a window with the night skyline, a desk lamp casting warm light, a laptop with a softly glowing screen and a blinking caret, a mug, and the phone face down on the desk. It is painted in the Windows palette, like `_HousePainter`.
- **A big clock, which is also the pause button.** Tapping it pauses; the paused state goes muted and says "Paused. Tap to keep going, no harm done". This is the same idea as #28, and the Task Session ships with it.
- **The Aim card** reads "Aim: 25 min of work in one go" with a filling bar and "6 min to go", then "Aim beaten".
- **The hint line** reads "Your phone is face down. Instagram can wait for the break at 25 min."
- **Planned breaks** are time-based, using the existing ratio and interval rules (spec 2026-10-22 §6.1). Tasks have no Checkpoints, so the copy never mentions chapters.
- **The bottom actions** are "Stop for now" (outlined) and **"Done"** (filled).
  - "Stop for now" ends the Session and returns to Today. It asks no Position and no Note, and the Task stays undone.
  - "Done" ends the Session and plays the Done moment.

### 4.3 The Done moment
A full-screen overlay plays once:
- a big window lights up from dark to lamplight, with a soft glow and faint rays;
- the title "Report: done." (the Task's short name);
- a line in the user's Tone, for example Spicy: "Locked in. 52 minutes, phone stayed face down.";
- three stats: minutes, Longest stretch in one go, and Urges let pass;
- the actions **"Next: <next task>"** (filled, starts it) and **"Take a breather"**.

It comes with a firm haptic, and the Task's window on Today is lit afterwards. With reduced motion, it shows the end state at once.

### 4.4 The calendar (option B, "a calm grid that glows", with a legend)
- **A month grid** with weekday headers. English starts the week on Monday and uses Gregorian months. Persian starts on Saturday (ش ی د س چ پ ج), uses Solar Hijri months («مهر ۱۴۰۵») and Persian digits, and mirrors.
- **The title is the month,** with a sub-line summary such as "19 nights lit, 41 tasks done, one Finish" / «۱۹ شب روشن، ۴۱ تا کار، یه کتاب تموم». It's a summary, never a streak.
- **Each day cell is a rounded tile** with the date. It glows from the bottom in lamplight, and both the height and the brightness grow with that day's focus time (all kinds), capped at 2h+. Today's tile has a `me`-coloured outline.
- **The marks on a tile:**
  - a small lamp-coloured **dot per Task done**, at most 4;
  - a small red **book spine** if the user read or watched that night (any Session on a non-Task Work);
  - a small **flag** if a book, series, film or podcast was Finished that day.
- **The legend** is a dark card under the grid, "What the marks mean" / «نشونه‌ها یعنی چی».
  - It has a glow scale from "none" to "2h+" (mirrored in RTL). Tapping it reveals the 30m / 1h / 2h ticks.
  - Below the scale it lists the dot (Task done), the spine (Read that night) and the flag (Finished something).
- **Opening the month is the one orchestrated moment:** each tile's glow rises in sequence.
- **Tapping a day** opens a bottom sheet with:
  - the date, e.g. "Saturday 24 October" / «۲ آبان»;
  - the focus time, e.g. "1h 40m focused";
  - the number of Tasks done;
  - what was read and how far, e.g. "Read Dune, 18 pages";
  - that night's Note, if any.
- Swiping between months is expected. Future days show only planned Tasks, as dots with an outline and no glow.

## 5. Constraints
- Offline-first, with no new network dependency and no Google services (ADR-0002, ADR-0003).
- Tasks, Done and their Sessions go through the drift event journal and sync (ADR-0006), so they appear on Linux too. A schema migration is expected.
- MVVM with provider (ADR-0005).
- Motion: at most one orchestrated moment per screen, and nothing animates during a running Stretch except the Window pulse and the caret. Everything respects `MediaQuery.disableAnimationsOf`. Haptics use `HapticFeedback`.
- All Persian copy is native spoken Persian and is reviewed by the owner (spec 2026-10-22 §8.1).
- None of the banned AI-template tells (spec 2026-10-22 §8): no uppercase eyebrows, no "A · B · C" strings, no emoji icons, and no arrows on buttons.

## 6. Calls I made (owner to check)
- A Task is a kind of Work, not a separate entity, so the Session, Urge and sync code is reused.
- Done adds no floor to the Building.
- Working gets its own Longest stretch and Aim.
- "Stop for now" on a Task asks nothing. There is no Evening screen for Tasks.
- Friends leaves the bottom bar until phase 2.
- Today replaces Tonight as the home screen's name; the book card keeps "Tonight".
- The Task Session shows the desk instead of the House. The House stays for books and media.
- A Task's estimate is optional, and only shown as meta text. It is not an Aim and not a deadline.
- Calendar focus time adds up all three kinds of attention.
- **Changing a Task:**
  - Swipe a Task away to delete it, with Undo, the same as Works in the Library (commit da1791b).
  - Tap a Task's name to edit its name, day and estimate.
  - Un-done comes only from the Undo on the Done moment's snackbar.
  - Moving a Task to another day means editing its day.
- **Task Sessions stay out of reading:**
  - They do not count toward the Reading week, they do not light Windows in the House, and they do not add a spine on the calendar.
  - "Nights lit" in the calendar summary means Reading-week nights.
  - When Friends ship, Task names never leave the device. At most, Friends see that someone is working.
- **Day buckets:** Today, carry-over and the calendar use the existing evening rollover (`eveningOf`, 4am). A Task done at 1am belongs to the day before.
- **Planning ahead:**
  - The Add row has a small day chip, Today by default, offering Tomorrow or a picked date.
  - Today lists undone Tasks whose day is today or earlier, plus today's Done ones.
  - Future Tasks appear only as outlined dots on the calendar.
- **Tasks stay out of the book model's places:**
  - Tasks never appear in the Library and never become the current Work (ADR-0012), so Tonight's book is never replaced.
  - Done is an explicit stored state, not derived from a Position. Whether Tasks share the Works table is the builder's call (see §7), as long as the length, author and Checkpoint fields don't leak into Task UI.
- **Notes:** only book and media Sessions have Notes. The day sheet shows that night's Note from those.
- **One Session at a time, as now:**
  - Starting a Task while another Session runs asks to stop that one first.
  - Done is offered on the Task Session screen and in its live notification, not on the Urge screen or during a Planned break.

## 7. Left to the builder
- The schema shape and migration.
- The exact sky gradients and their stops.
- How the sky time is updated (on resume is enough; it doesn't need to tick live).
- The painted desk's details.
- Calendar month navigation (swipe or arrows).
- How Linux shows Today and the calendar (it may reuse the same screens).
- Splitting the work into tickets.
