# Android app (TWA) — test report · 23 Oct 2026

PASS means the check was actually run. NOT TESTED means it could not be run in the build environment and must be done on GitHub / a phone.

**Environment limits:** Google Maven (`dl.google.com`), Maven Central and the Gradle distribution server are blocked in the build sandbox, and there is no Android SDK or emulator. The Gradle build therefore **could not be run here**. Its first real run is in GitHub Actions. The web changes were tested with Playwright (Chromium) against a local copy of `dist/`, with **every** non-local request blocked (no Supabase, no Cashfree, no fonts).

| # | Test | Result | Evidence |
|---|---|---|---|
| 1 | Gradle build in GitHub Actions; AAB + APK produced | PASS (debug APK) / **NOT TESTED** (signed AAB) | Actions run 39993870749 on branch `android-twa-app`: wrapper validation ✓, `assembleDebug` ✓, artifact `stm-gold-debug-apk` uploaded. Signed release AAB (R8) runs once the keystore secrets exist. |
| 1a | Java sources type-check | PASS (partial) | `javac -source 8` against API stubs; `LauncherActivity` override signatures copied from android-browser-helper **2.7.4** source (tag `android-browser-helper-2.7.4`) |
| 1b | All XML resources / manifest well-formed; every manifest resource reference exists | PASS | XML parse of all 9 files; resource list cross-checked |
| 1c | Every `trusted.*` meta-data key in the manifest is read by android-browser-helper 2.7.4 / androidx.browser | PASS | grep of library source |
| 1d | Workflows valid | PASS | `actionlint 1.7.12`: no problems in `android.yml`, `android-keystore.yml` |
| 2 | `assetlinks.json` is valid JSON | PASS | `python -m json.tool` on source and on `dist/.well-known/assetlinks.json` |
| 2a | `build.sh` copies `.well-known/`, `privacy.html`, `delete-account.html` into `dist/`; `android/` and `.github/` are **not** published | PASS | ran `sh build.sh`, listed `dist/` |
| 2b | `assetlinks.json` served at `/.well-known/assetlinks.json` with `application/json` after deploy; Google Digital Asset Links API returns the statement | **NOT TESTED** | Needs deploy + real SHA-256 values. `_headers` rule added. URL in README §4 |
| 3 | No address bar | **NOT TESTED** | Needs device + correct assetlinks |
| 4 | Splash shows; icons correct | PASS (images) / **NOT TESTED** (device) | Generated icons and splash checked visually: adaptive foreground fits the 66 dp safe circle, splash logo on navy. Not seen on a real device. |
| 5 | Login with test mPIN | **NOT TESTED** | Live backend not touched |
| 6 | Passbook loads | **NOT TESTED** (live) | Rendered with a mocked RPC only (see 12) |
| 7 | Notification permission prompt + test push | **NOT TESTED** | Needs device |
| 8 | Cashfree sandbox modal opens; UPI hand-off returns to app | **NOT TESTED** | Needs device. ⚠️ C1: sandbox payments are recorded as real installments. Use a test account only |
| 9 | Back button | PASS (web) / **NOT TESTED** (device) | Chromium: first Back on home stays in the app (existing `popstate` trap intact). Device test still needed |
| 10 | Offline overlay appears inside the running app; retry while offline keeps it; hides when online | PASS | Playwright `setOffline`, screenshot `offline_overlay_390.png` |
| 10a | Service worker serves Tamil "இணையம் இல்லை" page on navigation while offline; page contains no ₹ / Passbook data | PASS | screenshot `offline_page_sw_390.png` |
| 10b | Service worker does **not** intercept `/staff` | PASS | offline `/staff.html` → normal browser network error |
| 11 | Referral: Play referrer → `&ref=CODE` | **NOT TESTED** (native) | Needs device (`adb … --es debug_referrer` or Play link) |
| 11a | Web side: `?ref=abc123` stored as `ABC123`, removed from URL, `utm_source` kept | PASS | `localStorage.stm_ref = {"c":"ABC123",…}` |
| 12 | Passbook → என் விவரம் shows "கணக்கை நீக்க கோரிக்கை"; button opens WhatsApp to 919791918344 with name + mobile | PASS | mocked `pbRpc`, `window.open` captured; screenshot `passbook_me_delete_390.png`; no JS errors |
| 13 | `privacy.html`, `delete-account.html` render at 390 px, no horizontal scroll, DRAFT marked | PASS | full-page screenshots |
| 13a | Delete page validates the mobile number and opens a WhatsApp request | PASS | request URL captured |
| 14 | `staff.html` unchanged | PASS | byte-identical to the original (`git diff` empty) |
