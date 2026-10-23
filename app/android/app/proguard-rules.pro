# Release builds are shrunk by R8. WorkManager, which Glance (the home
# screen widget, ADR 0011) pulls in, builds its Room database by reflection
# on the generated WorkDatabase_Impl, so R8 must keep it; without this the
# release app crashes at start-up.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
