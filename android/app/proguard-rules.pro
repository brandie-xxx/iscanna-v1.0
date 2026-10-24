# Google ML Kit text recognition references optional script models (Chinese, Devanagari,
# Japanese, Korean) that this app doesn't bundle; only Latin is used. Let R8 drop them.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep ML Kit text recognition whole in release builds. R8 (full mode) can strip classes the
# recognizer reaches by reflection, which makes scans silently return no text in release only.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
