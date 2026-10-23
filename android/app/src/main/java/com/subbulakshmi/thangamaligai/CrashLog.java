package com.subbulakshmi.thangamaligai;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;

import java.io.PrintWriter;
import java.io.StringWriter;

/**
 * Keeps the last crash / Chrome quality report so the owner (who has no computer for adb logcat)
 * can see and copy it the next time the app opens.
 */
final class CrashLog {
    private static final String PREFS = "stm_crash";
    private static final String KEY = "last";

    private CrashLog() {}

    static void install(Context context) {
        final Context app = context.getApplicationContext();
        final Thread.UncaughtExceptionHandler previous = Thread.getDefaultUncaughtExceptionHandler();
        Thread.setDefaultUncaughtExceptionHandler((thread, error) -> {
            try {
                StringWriter sw = new StringWriter();
                error.printStackTrace(new PrintWriter(sw));
                save(app, "CRASH\n" + sw);
            } catch (Throwable ignored) {
            }
            if (previous != null) previous.uncaughtException(thread, error);
        });
    }

    static void save(Context context, String text) {
        String info = "v" + BuildConfig.VERSION_NAME + " (" + BuildConfig.VERSION_CODE + ") · Android "
                + Build.VERSION.RELEASE + " (API " + Build.VERSION.SDK_INT + ") · " + Build.MANUFACTURER
                + " " + Build.MODEL + "\n";
        String all = info + text;
        if (all.length() > 3000) all = all.substring(0, 3000);
        prefs(context).edit().putString(KEY, all).commit(); // commit: the process may be dying
    }

    static String take(Context context) {
        SharedPreferences p = prefs(context);
        String s = p.getString(KEY, null);
        if (s != null) p.edit().remove(KEY).apply();
        return s;
    }

    private static SharedPreferences prefs(Context c) {
        return c.getApplicationContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }
}
