package com.subbulakshmi.thangamaligai;

import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.ActivityInfo;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.browser.customtabs.CustomTabsCallback;

import com.android.installreferrer.api.InstallReferrerClient;
import com.android.installreferrer.api.InstallReferrerStateListener;

import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Opens the customer website as a Trusted Web Activity.
 *
 * Extra behaviour on top of android-browser-helper:
 *  1. On the FIRST launch only, reads the Google Play Install Referrer. If it contains
 *     ref=CODE (CODE = 3–12 letters/digits), "&ref=CODE" is added to the launch URL.
 *     The website already stores ?ref= and pre-fills the join form.
 *  2. Never opens /staff, even if a link to it is sent to the app.
 *  3. Debug builds only: `adb shell am start ... --es debug_referrer "ref=TEST123"` simulates
 *     a Play referrer, so the referral flow can be tested without Play.
 */
public class LauncherActivity extends com.google.androidbrowserhelper.trusted.LauncherActivity {
    private static final String TAG = "STMLauncher";
    private static final String PREFS = "stm_launcher";
    private static final String KEY_REF_DONE = "referrer_done";
    private static final String KEY_REF_TRIES = "referrer_tries";
    private static final int MAX_TRIES = 3;               // retry on later launches if Play was busy
    private static final long REFERRER_TIMEOUT_MS = 2500; // never keep the user waiting longer
    private static final Pattern CODE = Pattern.compile("^[A-Z0-9]{3,12}$");

    private final Handler mMain = new Handler(Looper.getMainLooper());
    private InstallReferrerClient mReferrerClient;
    private boolean mLaunchScheduled;
    private String mRefCode; // valid code to add to this launch only

    private final Runnable mTimeout = () -> finishReferrerLookup(null, false);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Same as Bubblewrap: setting orientation on Android 8.0 with a translucent theme crashes.
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.O) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        } else {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);
        }
    }

    @Override
    protected boolean shouldLaunchImmediately() {
        // If the previous run crashed (or Chrome reported a problem), show it once so the owner
        // can copy it and send it to the developer. Then continue normally.
        String last = CrashLog.take(this);
        if (last != null) {
            showProblem(last);
            return false;
        }
        return decideLaunch();
    }

    private void showProblem(final String text) {
        try {
            new AlertDialog.Builder(this)
                    .setTitle("App பிழை தகவல் · Error report")
                    .setMessage("கடந்த முறை app மூடியது. இந்த தகவலை Copy செய்து developer-க்கு அனுப்புங்க.\n\n" + text)
                    .setCancelable(false)
                    .setPositiveButton("Copy & தொடரு", (d, w) -> {
                        try {
                            ClipboardManager cm = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
                            if (cm != null) cm.setPrimaryClip(ClipData.newPlainText("STM app error", text));
                        } catch (Exception ignored) {
                        }
                        continueLaunch();
                    })
                    .setNegativeButton("தொடரு", (d, w) -> continueLaunch())
                    .show();
        } catch (Exception e) {
            continueLaunch();
        }
    }

    private void continueLaunch() {
        if (isFinishing()) return;
        if (decideLaunch()) launchTwa();
    }

    /** true = launch now; false = launchTwa() will be called after the referrer lookup. */
    private boolean decideLaunch() {
        if (BuildConfig.DEBUG) {
            String fake = getIntent() != null ? getIntent().getStringExtra("debug_referrer") : null;
            if (fake != null) {
                mRefCode = parseRefCode(fake);
                Log.d(TAG, "debug_referrer → " + mRefCode);
                return true;
            }
        }
        SharedPreferences p = getSharedPreferences(PREFS, MODE_PRIVATE);
        if (p.getBoolean(KEY_REF_DONE, false) || p.getInt(KEY_REF_TRIES, 0) >= MAX_TRIES) {
            return true;
        }
        p.edit().putInt(KEY_REF_TRIES, p.getInt(KEY_REF_TRIES, 0) + 1).apply();
        startReferrerLookup();
        return false; // launchTwa() is called by finishReferrerLookup()
    }

    private void startReferrerLookup() {
        mMain.postDelayed(mTimeout, REFERRER_TIMEOUT_MS);
        try {
            mReferrerClient = InstallReferrerClient.newBuilder(this).build();
            mReferrerClient.startConnection(new InstallReferrerStateListener() {
                @Override
                public void onInstallReferrerSetupFinished(int responseCode) {
                    switch (responseCode) {
                        case InstallReferrerClient.InstallReferrerResponse.OK:
                            String raw = null;
                            try {
                                raw = mReferrerClient.getInstallReferrer().getInstallReferrer();
                            } catch (Exception e) {
                                Log.w(TAG, "Could not read install referrer", e);
                            }
                            finishReferrerLookup(raw, true);
                            break;
                        case InstallReferrerClient.InstallReferrerResponse.FEATURE_NOT_SUPPORTED:
                        case InstallReferrerClient.InstallReferrerResponse.DEVELOPER_ERROR:
                        case InstallReferrerClient.InstallReferrerResponse.PERMISSION_ERROR:
                            finishReferrerLookup(null, true);   // will never work → don't retry
                            break;
                        default:                                // SERVICE_UNAVAILABLE etc. → retry next launch
                            finishReferrerLookup(null, false);
                    }
                }

                @Override
                public void onInstallReferrerServiceDisconnected() {
                    finishReferrerLookup(null, false);
                }
            });
        } catch (Exception e) {
            Log.w(TAG, "Install referrer unavailable", e);
            finishReferrerLookup(null, false);
        }
    }

    /** Runs once per launch (first of: answer from Play, error, or timeout). */
    private void finishReferrerLookup(String rawReferrer, boolean definitive) {
        mMain.post(() -> {
            if (mLaunchScheduled) return;
            mLaunchScheduled = true;
            mMain.removeCallbacks(mTimeout);
            if (definitive) {
                getSharedPreferences(PREFS, MODE_PRIVATE).edit().putBoolean(KEY_REF_DONE, true).apply();
            }
            mRefCode = parseRefCode(rawReferrer);
            try {
                if (mReferrerClient != null) mReferrerClient.endConnection();
            } catch (Exception ignored) {
            }
            if (!isFinishing()) launchTwa();
        });
    }

    /** "ref=ABC123&utm_source=..." → "ABC123" if it matches ^[A-Z0-9]{3,12}$, otherwise null. */
    static String parseRefCode(String rawReferrer) {
        if (rawReferrer == null || rawReferrer.isEmpty()) return null;
        try {
            String code = Uri.parse("https://x/?" + rawReferrer).getQueryParameter("ref");
            if (code == null) return null;
            code = code.trim().toUpperCase(Locale.ROOT);
            return CODE.matcher(code).matches() ? code : null;
        } catch (Exception e) {
            return null;
        }
    }

    @Override
    protected Uri getLaunchingUrl() {
        Uri uri = super.getLaunchingUrl();
        Uri home = Uri.parse(getString(R.string.launchUrl));

        // The staff page is website-only.
        String path = uri != null ? uri.getPath() : null;
        if (uri == null || (path != null && path.toLowerCase(Locale.ROOT).startsWith("/staff"))) {
            uri = home;
        }

        if (mRefCode != null
                && home.getHost() != null && home.getHost().equalsIgnoreCase(uri.getHost())
                && uri.getQueryParameter("ref") == null) {
            uri = uri.buildUpon().appendQueryParameter("ref", mRefCode).build();
            mRefCode = null; // use once
        }
        return uri;
    }

    /**
     * android-browser-helper's default QualityEnforcer CRASHES the app when Chrome reports a quality
     * problem (asset-links check failed, 404/5xx, offline without a page). Record the reason instead,
     * so the app keeps working (worst case with an address bar) and the reason is shown next launch.
     */
    @Override
    protected CustomTabsCallback getCustomTabsCallback() {
        final Context app = getApplicationContext();
        return new CustomTabsCallback() {
            @Nullable
            @Override
            public Bundle extraCallbackWithResult(@NonNull String callbackName, @Nullable Bundle args) {
                if ("quality_enforcement.crash".equals(callbackName)) {
                    String reason = args != null ? args.getString("crash_reason") : null;
                    Log.w(TAG, "Chrome quality report: " + reason);
                    CrashLog.save(app, "CHROME QUALITY REPORT\n" + reason);
                    Bundle result = new Bundle();
                    result.putBoolean("success", true);
                    return result;
                }
                return Bundle.EMPTY;
            }
        };
    }

    @Override
    protected void onDestroy() {
        mMain.removeCallbacks(mTimeout);
        super.onDestroy();
    }
}
