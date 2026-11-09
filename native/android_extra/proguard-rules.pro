# flutter_local_notifications: scheduled notifications are stored with Gson.
# Without these rules R8 strips the generic type info in release builds and
# zonedSchedule() fails ("Missing type parameter"), so timed greetings never get queued.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
