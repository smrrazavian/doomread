# GPL-3.0, shipped as three build flavours (F-Droid deferred)

The app is GPL-3.0 and ships as three Android flavours from one codebase:

- `apk`: direct download, with its own update check
- `play`: carries the Accessibility declaration and disclosure
- `bazaar`: Cafe Bazaar

F-Droid is deferred, not rejected. It adds a fourth flavour, metadata and reproducible-build upkeep for little gain at launch. The code stays F-Droid-friendly anyway, because ADR-0002 already bans Google and proprietary SDKs. A closed push SDK may be added in phase 2, but only behind a seam and only in `bazaar` and `apk`, if UnifiedPush proves too clunky in Iran. Changing to a permissive licence later would need every contributor's agreement.
