# Tone lines are copy packs in core, and Voice keeps every Tone kind after a Slip

The app speaks in the user's Tone (Chill, Spicy or Mom mode) at each moment: the Urge, after a Slip, the Planned break, break over, End of the evening and a new Longest stretch (#9). `voice(moment, tone, locale, facts)` in core returns the line. Screens call it through `say`, and the break-over alarm calls it directly.

The lines are copy packs: a `CopyPack` per locale (`voice_en.dart`, `voice_fa.dart`), with each Tone's lines per moment, first choice first. They're kept apart from the ARB UI strings, which hold labels, buttons and facts. So the jokes can be swapped without touching screens, and core can test them. They're Dart data in core, not ARB, for three reasons. Core can't read ARB. The rule below needs the packs where Voice is. And gen_l10n would turn every line into a getter the screens could call directly, past Voice. They stay inside the app, with no remote code, as the design asks. Updating packs between releases isn't built yet. Facts arrive already formatted, Persian digits included, so core stays free of locale formatting. Voice picks the first line whose facts are all given, so an Urge whose app is unknown still has a line.

After a Slip, Voice ignores the Tone and says Chill's line. A roast there starts the what-the-hell spiral, and the owner chose one kind line over a kind line per Tone. Because the rule is in Voice, no screen or pack can break it, and the core test is exact: every Tone's after-slip line equals Chill's.

The Tone is picked in the first-run intro, where each Tone says the same real Urge line in a speech bubble, and in Settings, whose Tone screen shows those lines too.
