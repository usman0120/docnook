# google_mlkit_text_recognition references the optional Chinese, Devanagari,
# Japanese and Korean models. DocNook bundles only the Latin model
# (BLUEPRINT 4.3), so those classes are absent on purpose.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Tesseract4Android calls back into these from native code (direct flavor).
-keep class com.googlecode.tesseract.android.** { *; }
