# Doomread

Doomread (Persian: باز گوشی؟!) helps a person finish what they start reading or watching. It does this by adding company, a planned break, and visible progress toward the end, without banning social apps.

## Language

### What you're getting through

**Work**:
One thing the user intends to finish: a book, an ebook, a series, a film or a podcast. It has a total length, measured in pages, episodes or minutes.
_Avoid_: Book (when the kind doesn't matter), item, title, content, media

**Position**:
How far the user is in a **Work**, in its own unit: a page, an episode, or a timestamp.
_Avoid_: Progress (that means the ratio), bookmark

**Checkpoint**:
A natural stopping place inside a **Work**, such as the end of a chapter, an episode or a segment.
_Avoid_: Chapter (when the Work isn't a book), milestone, marker

**Road**:
The path from the start of a **Work** to its end, with its **Checkpoints** and the user's current **Position**.
_Avoid_: Progress bar, timeline

**Finish**:
Reaching the end of a **Work**. This is the outcome the product exists for.
_Avoid_: Complete, done (when you mean the whole Work)

**Note**:
The one sentence the user writes after a **Session** about what happened in the part they just got through, in their own words.
_Avoid_: Summary, review, journal entry

### An evening

**Session**:
One sitting with one **Work**, from Start to Stop. A Session can contain several **Stretches**, **Pauses**, **Urges** and **Planned breaks**.
_Avoid_: Evening (an evening can hold several Sessions), focus session, timer

**Stretch**:
Unbroken Session time with the timer running. It ends at a **Pause**, a **Slip**, the start of the **Planned break**, or Stop. Letting an **Urge** pass does not end it.
_Avoid_: Streak, focus block, interval

**Longest stretch**:
The user's longest single **Stretch** for a kind of Work (reading or watching). It is the one number that measures attention span.
_Avoid_: Best time, record, score

**Aim**:
The Stretch length the app suggests for tonight: the **Longest stretch** plus one minute.
_Avoid_: Goal, target (Goal is reserved for the Finish)

**Pause**:
A deliberate, legitimate stop inside a **Session**, like a glass of water or the door. It ends the current **Stretch** but never counts as a **Slip**.
_Avoid_: Break (that's the Planned break)

**Planned break**:
A break the app offers in advance and the user accepts, tied to a **Checkpoint** and with a fixed length. A Session can earn several. During it, social apps are explicitly allowed ("legal brainrot").
_Avoid_: Pause, reward, cheat time

### The pull toward the phone

**Watched app**:
An app or site the user has said tends to pull them away, such as Instagram, TikTok or YouTube Shorts. Opening it while a **Stretch** runs (so not on a **Pause** or the **Planned break**) raises an **Urge**.
_Avoid_: Blocked app, distraction, bad app

**Work app**:
An app that holds the **Work** itself for this Session, such as an ebook reader or YouTube for a podcast. Switching to it is never an **Urge**.
_Avoid_: Allowed app, whitelist

**Urge**:
One moment where the user opens a **Watched app** while a **Stretch** runs, shown as the "not yet" screen. A **Pause** has no Stretch for a **Slip** to end, so it raises none. It ends either as **Let pass** or as a **Slip**.
_Avoid_: Distraction, temptation, violation

**Let pass**:
The user returns to the Work from an **Urge**.
_Avoid_: Resisted, win, blocked

**Slip**:
The user goes on into the **Watched app** from an **Urge**. It's never punished, and the app is kind right after it.
_Avoid_: Fail, relapse, give up, cheat

**Tone**:
The voice the app speaks in, chosen by the user: Chill, Spicy, or Mom mode (مامان‌مود). It roasts the Urge, never the person, and is always kind after a Slip.
_Avoid_: Personality, theme, mode (alone)

### Company and progress

**House**:
The shared apartment block of lit windows showing who is reading now and who read earlier tonight. It is how company is shown.
_Avoid_: Building (that's the user's own), room, lobby

**Window**:
One person's presence in the **House**. It is live, earlier tonight, or the user's own. Windows are never invented.
_Avoid_: Avatar, presence dot, user

**Building**:
The user's own tower, with one floor added per **Finish**.
_Avoid_: House, trophy case, level

**Reading night**:
A planned time when **Friends** agree to start Sessions together.
_Avoid_: Event, meetup, party

**Friend**:
Another user the user has linked with, who sees their name and **Window**. Strangers in the public **House** are anonymous Windows, not Friends.
_Avoid_: Follower, contact, buddy

**Reading week**:
The count of nights in the current week with at least one **Session**. It restarts each week, never "breaks", and starts on Saturday in Persian.
_Avoid_: Streak, chain

**Reading month**:
The nights of the current month, one **Window** each: lit if it had a **Session**, brighter the longer the user read, measured only against their own brightest night that month. It's a count that never breaks: a dark night is just dark. In Persian the month is Solar Hijri and its weeks start on Saturday.
_Avoid_: Streak, chain, heatmap

### First run

**Intro**:
The three cards a new user sees once, before anything else: the movie-night story, the company coming back, and the Tone picked by hearing each one. Then the first Work, and its first Session. It can be replayed from Settings.
_Avoid_: Onboarding (when you mean these cards), tutorial, walkthrough

**Hint**:
A one-line explainer shown in place the first time its thing appears (the Aim, the Urge, the Planned break), with "Got it", and never again. Never an overlay.
_Avoid_: Tooltip, coach mark, tip

**Demo Urge**:
The real "not yet" screen, shown on request during the first Session as a demo. It records nothing: no **Urge**, no **Slip**, no journal event.
_Avoid_: Fake urge, test urge, preview

## Relationships

- A **Work** has a **Road** made of **Checkpoints**, and the user's **Position** sits on it.
- A **Session** is about exactly one **Work** and moves its **Position** forward. It can end with one **Note**.
- A **Session** is made of **Stretches**, separated by **Pauses**, **Slips** and the **Planned break**.
- An **Urge** ends either as **Let pass** or as a **Slip**.
- A **Planned break** is anchored to one **Checkpoint**. After a Planned break, the same **Session** continues toward the next one.
- Each **Finish** adds a floor to the user's **Building**.
- A **Session** lights the user's **Window** in the **House**.

## Example dialogue

> **Dev:** "When the user opens YouTube during a **Session**, is that an **Urge**?"
> **Domain expert:** "Only if YouTube isn't the **Work app** tonight. If they're watching a podcast on YouTube, only Shorts is **Watched**. Opening Shorts raises an **Urge**, and going back is **Let pass**."
> **Dev:** "And if they tap 'Open anyway'?"
> **Domain expert:** "That's a **Slip**. The **Stretch** ends, and the next screen is kind, whatever the **Tone**."

## Flagged ambiguities

- "Building" was used for both the shared apartment block and the user's own tower. Resolved: the shared one is the **House**, and the user's own is the **Building**.
- "Break" was used for both quick stops and the committed break. Resolved: **Pause** and **Planned break**.
- "Chapter" was used for any stopping place. Resolved: **Checkpoint**. The UI still says "chapter" or "episode" depending on the **Work**.
- "Goal" was used for tonight's minutes and for finishing. Resolved: **Aim** means tonight's minutes. The goal is always the **Finish**.
