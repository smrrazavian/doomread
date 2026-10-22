# Sessions stored as an append-only event journal in drift (SQLite)

Session activity is stored as timestamped events in a drift (SQLite) database, and all derived state (Stretches, Longest stretch, tallies) comes from a pure reducer in `core`. Sync then becomes "exchange events I don't have", with almost no conflicts. Mutable records such as Works and Notes use last-write-wins.

drift was chosen because it is maintained, MIT-licensed, supports Linux, turns queries into streams and has migration tooling. Isar is effectively unmaintained upstream, and ObjectBox's native core licence is unclear. sqlite3 is built from source (`source: source`), so the app has no downloaded binaries and stays F-Droid-friendly.
