# No Google services or proprietary SDKs in the app

The app ships without Firebase/FCM, Google Play services, Google sign-in, or any closed-source SDK (including Iranian push SDKs). Most users are inside Iran, where Google services are unreliable, and F-Droid only accepts fully free builds. Push goes through UnifiedPush to a self-hosted ntfy instead. Play-only additions, if ever added, must live in the `play` flavour and stay optional.
