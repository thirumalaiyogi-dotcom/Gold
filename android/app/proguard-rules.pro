# Activities/services referenced from AndroidManifest.xml are kept automatically by AAPT.
# Play Install Referrer talks to the Play Store over AIDL; keep its interface intact.
-keep class com.google.android.finsky.externalreferrer.** { *; }
-keep class com.android.installreferrer.** { *; }
