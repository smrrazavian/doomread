# Flutter for the app, native code only at the platform edges

We build one Flutter app for Android first, then Linux, then iOS. Native code (Kotlin and later Swift) is limited to what Flutter can't reach: watched-app detection (an AccessibilityService, with a UsageStats fallback), home screen widgets (Glance), live notifications, and later the iOS Screen Time extensions. We chose this over native Kotlin with Compose Multiplatform because one UI codebase with first-class RTL covers all three targets. The cost is maintaining platform channels for the edges.
