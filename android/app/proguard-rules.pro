# ============================================================
# Arrows Pro — R8 / ProGuard keep rules
# ============================================================

# --- Flutter engine/embedding ---
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# --- Google Mobile Ads (google_mobile_ads) ---
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.internal.ads.** { *; }
-dontwarn com.google.android.gms.**

# --- WorkManager + Room ---
# The Ads SDK's OfflinePingSender uses WorkManager, which creates a Room
# database (androidx.work.impl.WorkDatabase). Room generates a *_Impl class
# that WorkManager instantiates by reflection. R8 obfuscates/strips it,
# causing "Failed to create an instance of androidx.work.impl.WorkDatabase"
# at startup. Keep the whole graph.
-keep class androidx.work.** { *; }
-keep interface androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep interface androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Database class * { *; }
-keep class androidx.sqlite.** { *; }
-keep class androidx.startup.** { *; }
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# --- Google Play Billing (in_app_purchase) ---
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.billing.** { *; }

# Keep reflection-relevant metadata.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
