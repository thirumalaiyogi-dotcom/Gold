# சுப்புலட்சுமி தங்க மாளிகை — Android app (customer மட்டும்)

இந்த app ஒரு **Trusted Web Activity (TWA)**. Phone-ல app-ஐ திறந்தா, நம்ம customer website (`gold.thirumalaiyogi.workers.dev`) **address bar இல்லாமல்**, முழு app மாதிரி Chrome-ல திறக்கும்.

- Website-ல நீங்க செய்யும் மாற்றம் (GitHub push → Cloudflare) **உடனே app-லயும் வரும்**. Play Store update தேவையில்லை.
- Play Store update **தேவைப்படுவது** இந்த `android/` folder-ல மாற்றம் செய்யும்போது மட்டும் (பெயர், icon, நிறம், domain).
- Staff app (`/staff`) app-ல வராது; website-லயே இருக்கும்.
- எல்லா build-ம் GitHub Actions-ல (cloud) நடக்கும். Laptop / Android Studio தேவையில்லை. எல்லா படியும் phone browser-லயே செய்யலாம்.

> ⚠️ **முக்கியம்:** Payment இன்னும் **sandbox**. Sandbox payment-கள் உண்மையான தவணையாகப் பதிவாகுது (audit-ல **C1**). **C1 சரி செய்யும் வரை app-ஐ உண்மையான customers-க்கு (Production) வெளியிடக் கூடாது.** Internal / closed testing மட்டும் செய்யலாம்.

---

## Folder-ல என்ன இருக்கு

| File / folder | என்ன |
|---|---|
| `android/` | Android project (Gradle). `app/build.gradle`-ல version, `gradle.properties`-ல domain |
| `android/play-assets/` | Play Store-க்கு 512px icon, 1024×500 feature graphic |
| `.github/workflows/android.yml` | AAB + APK build செய்யும் workflow |
| `.github/workflows/android-keystore.yml` | ஒரே ஒரு தடவை: upload key உருவாக்கும் workflow |
| `.well-known/assetlinks.json` | Address bar மறைய website-ல இருக்க வேண்டிய file |
| `privacy.html`, `delete-account.html` | Play Store-க்கு தேவையான privacy policy, account deletion பக்கங்கள் (DRAFT) |

**App ID (மாற்ற முடியாது):** `com.subbulakshmi.thangamaligai`

---

## படி 1 — Files-ஐ GitHub-க்கு அனுப்புங்க

இந்த ZIP-ல `app/` உள்ளே இருக்கும் எல்லாமும் `thirumalaiyogi-dotcom/Gold` repo-வின் root-ல போகணும் (`android/`, `.github/`, `.well-known/` folder-கள் உட்பட).

**எளிய வழி:** Claude-கிட்ட *"இந்த மாற்றங்களை Gold repo-க்கு ஒரு branch-ஆ push செய்து PR திற"* என்று சொல்லுங்க. PR-ஐ phone-லயே பார்த்து **Merge** செய்யலாம்.

Merge ஆனதும்:
- Cloudflare தானா website-ஐ update செய்யும் (privacy, delete-account பக்கங்கள், offline திரை, "கணக்கை நீக்க கோரிக்கை" button).
- GitHub Actions-ல **Android app build** தானா ஓடும். இந்த முதல் run-ல key இல்லாததால debug APK மட்டும் வரும். அது சரிதான்.

---

## படி 2 — Upload key (ஒரே ஒரு தடவை)

Play Store-ல app-ஐ update செய்ய ஒவ்வொரு தடவையும் இதே key தேவை. **தொலைச்சா பெரிய சிக்கல்.** கவனமா செய்யுங்க.

1. Phone browser-ல GitHub → `Gold` repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.
2. இந்த 3 secret-ஐ சேருங்க:
   - `ANDROID_KEYSTORE_PASSWORD`: நீங்களே ஒரு நீளமான password (குறைந்தது 12 எழுத்து). **காகிதத்தில் எழுதி பத்திரமாக வைங்க.**
   - `ANDROID_KEY_PASSWORD`: **அதே** password.
   - `ANDROID_KEY_ALIAS`: `upload`
3. **Actions** tab → இடது பக்கம் **One-time - create upload keystore** → **Run workflow**.
   - `confirm` பெட்டியில் `CREATE` என்று type செய்யுங்க.
   - Repo **Public**-ஆ இருந்தா workflow நிற்கும். Settings → General → கடைசியில் *Change visibility* → Private ஆக்கிட்டு ஓட்டுங்க (பிறகு மீண்டும் Public ஆக்கலாம்). அல்லது `public_repo_ok`-ல `yes` கொடுங்க.
4. Run முடிஞ்சதும் (பச்சை ✓) அதைத் திறந்து கீழே **Artifacts → upload-keystore**-ஐ download செய்யுங்க (ZIP).
5. ZIP-ஐ phone-ல திறந்தா 3 file இருக்கும்:
   - `upload-keystore.jks`: **இதுதான் key.** Google Drive-ல ஒரு தனி folder-லயும், pen drive / இன்னொரு phone-லயும் வைங்க.
   - `ANDROID_KEYSTORE_BASE64.txt`: இதைத் திறந்து **முழு text-ஐயும்** copy செய்யுங்க (Select all → Copy).
   - `KEEP-SAFE-README.txt`: Upload key-ன் **SHA-256** இதுல இருக்கும்.
6. மீண்டும் Secrets → New secret → பெயர் `ANDROID_KEYSTORE_BASE64`, value = copy செய்த text.
7. Run page-ல artifact பக்கத்தில் 🗑️ அழுத்தி **delete** செய்யுங்க (1 நாளில் தானாகவும் நீங்கும்).

> Keystore, password எதுவும் repo-வில் **commit ஆகாது**. `.gitignore` `.jks` file-களைத் தடுக்கும்.

---

## படி 3 — App build (AAB + APK)

1. **Actions** → **Android app build** → **Run workflow** → பச்சை பொத்தான்.
2. 5–10 நிமிடம். முடிஞ்சதும் run-ஐத் திறந்தா **Artifacts**:
   - `stm-gold-release-aab` → `app-release.aab`: **Play Console-ல upload செய்ய.**
   - `stm-gold-debug-apk` → `app-debug.apk`: Phone-ல நேரடியா install செய்து சோதிக்க.
3. Run summary-ல **Upload key SHA-256** தெரியும்.

`android/` folder-ல மாற்றம் push செய்தாலும் இது தானா ஓடும்.

---

## படி 4 — assetlinks.json (address bar மறைய)

App திறக்கும்போது மேலே address bar தெரிஞ்சா, இந்தப் படி இன்னும் முடியல என்று அர்த்தம்.

`.well-known/assetlinks.json`-ல 2 SHA-256 போடணும்:

| Placeholder | எங்கிருந்து |
|---|---|
| `PLAY_APP_SIGNING_SHA256_REPLACE_ME` | Play Console → உங்க app → **Test and release → Setup → App signing** → *App signing key certificate* → **SHA-256 certificate fingerprint** (முதல் AAB upload-க்குப் பிறகுதான் தெரியும்) |
| `UPLOAD_KEY_SHA256_REPLACE_ME` | படி 2-ன் `KEEP-SAFE-README.txt` / படி 3 run summary. (Play Console-ல *Upload key certificate* பகுதியிலும் இதே எண் இருக்கும்) |

- Play Store-ல இருந்து install ஆகும் app Google-ன் **App signing key**-ல sign ஆகும். நீங்க நேரடியா install செய்யும் debug APK **upload key**-ல sign ஆகும். அதனால ரெண்டும் வேணும்.
- GitHub-ல file-ஐ ✏️ edit செய்து `AB:CD:...` மாதிரி முழு எண்ணை (மேற்கோள் `" "` உள்ளே) போட்டு Commit செய்யுங்க. Cloudflare 1–2 நிமிடத்தில் update செய்யும்.
- **சரிபார்க்க:** phone browser-ல இந்த link திறங்க. `"statements"` உள்ளே உங்க app ID தெரிஞ்சா சரி:
  `https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://gold.thirumalaiyogi.workers.dev&relation=delegate_permission/common.handle_all_urls`
- Phone-ல ஏற்கனவே app திறந்திருந்தா: Settings → Apps → app → Storage → **Clear storage**, பிறகு மீண்டும் திறங்க (Chrome பழைய சரிபார்ப்பை நினைவில் வைக்கும்).

---

## படி 5 — Play Console-ல app உருவாக்கி Internal testing

1. https://play.google.com/console → **Create app**
   - App name: `சுப்புலட்சுமி தங்க மாளிகை`
   - Default language: **Tamil – ta-IN**
   - App or game: **App** · Free or paid: **Free**
   - Declarations ✓ → **Create app**
2. **Test and release → Testing → Internal testing → Create new release**
   - *Play App Signing*: Google-ஏ manage செய்யட்டும் (default) → Continue.
   - `app-release.aab`-ஐ upload செய்யுங்க → Release name `1.0.0 (1)` → **Next → Save → Start rollout**.
3. **Testers** tab → email list உருவாக்கி உங்க Gmail-ஐ சேருங்க → **Copy link** → அதை phone-ல திறந்து *Accept* → Play Store-ல install.
4. இப்போ **படி 4**-ஐ முடியுங்க (App signing SHA-256 இப்போதான் தெரியும்).
5. Debug APK-ஐ ஏற்கனவே install செய்திருந்தா, Play version install செய்யும் முன் அதை **uninstall** செய்யுங்க (key வேற).

## படி 6 — Store listing, Data safety, மற்ற படிவங்கள்

விவரமான பட்டியல்: **[PLAY_CHECKLIST.md](PLAY_CHECKLIST.md)**. சுருக்கமா:
- **Privacy policy URL:** `https://gold.thirumalaiyogi.workers.dev/privacy.html`
- **Account deletion URL:** `https://gold.thirumalaiyogi.workers.dev/delete-account.html`
- **App access:** reviewer-க்கு ஒரு **test** மொபைல் எண் + mPIN (நீங்களே உருவாக்கியது; உண்மையான customer கிடையாது).
- **Data safety:** PLAY_CHECKLIST-ல உள்ள அட்டவணைப்படி.
- **Closed testing:** புதிய personal account என்றால் **12 testers × 14 தொடர்ச்சியான நாள்** closed test முடிஞ்சாதான் Production கேட்க முடியும்.

---

## படி 7 — Referral link-ல Play Store link

App Play Store-ல **public-ஆ வந்த பிறகு** மட்டும், `index.html`-ல:

```js
const PLAY_ID=""; 
```
இதை இப்படி மாத்துங்க:
```js
const PLAY_ID="com.subbulakshmi.thangamaligai";
```
அப்போ referral share message-ல `https://play.google.com/store/apps/details?id=com.subbulakshmi.thangamaligai&referrer=ref%3DCODE` link சேரும். அந்த link வழியா install செய்தவருக்கு, app முதல் தடவை திறக்கும்போது referral code join படிவத்தில் **தானா நிரம்பும்**. (முன்னாடியே மாத்தினா, Play-ல app இல்லாததால link வேலை செய்யாது.)

---

## பின்னர் update செய்ய

| என்ன மாற்றம் | என்ன செய்யணும் |
|---|---|
| Website (index.html, design, விலை…) | GitHub push மட்டும். App தானா update ஆகும் |
| App பெயர் / icon / நிறம் / Android settings | `android/app/build.gradle`-ல `versionCode`-ஐ +1 (2, 3…), `versionName` (1.0.1…) → push → Actions-ல AAB → Play Console-ல புது release |
| **Domain மாற்றம்** (உதா: subbulakshmigold.in) | கீழே பாருங்க |

### சொந்த domain வாங்கினா (முதல் Play release-க்கு **முன்னாடியே** செய்வது நல்லது)
1. Cloudflare-ல domain-ஐ Worker-க்கு இணைங்க. `https://<புது-domain>/.well-known/assetlinks.json` திறக்குதா பாருங்க.
2. `android/gradle.properties`-ல `twaHost=gold.thirumalaiyogi.workers.dev` → `twaHost=<புது-domain>`.
3. `versionCode` +1 → push → புது AAB → Play-ல release.
4. Privacy / deletion URL-களை Play Console-ல புது domain-க்கு மாத்துங்க.
5. பழைய workers.dev முகவரியிலிருந்து customers-ஐ புது domain-க்கு redirect செய்யுங்க. (Login, referral போன்றவை browser-ல domain வாரியாக சேமிக்கப்படுவதால், customers ஒரு தடவை மீண்டும் login செய்ய வேண்டி வரும்.)

---

## Phone-ல சோதிக்க வேண்டியவை (debug APK அல்லது Internal test)

1. App திறக்கும்போது navy splash + கடை logo வருதா; பிறகு **address bar இல்லாமல்** முகப்பு வருதா.
2. Launcher-ல icon சரியா (வட்டம் / சதுரம்), பெயர் "தங்க மாளிகை".
3. **Test** மொபைல் + mPIN-ல login → Passbook திறக்குதா.
4. Passbook → என் விவரம் → **கணக்கை நீக்க கோரிக்கை** → WhatsApp-ல கடைக்கு செய்தி தயாரா வருதா (அனுப்ப வேண்டாம்).
5. Notification-ஐ on செய்ய → Android "Allow notifications?" கேட்குதா → staff app-ல இருந்து test notification அனுப்பி வருதா, app பெயர் / வைர icon-உடன்.
6. **Sandbox** payment: தவணை கட்டு → Cashfree திரை → UPI app-க்குப் போய் திரும்ப app-க்கு வருதா. ⚠️ C1 காரணமா இது ஒரு "உண்மையான" தவணையா பதிவாகும். **Test account-ல மட்டும்**, staff app-ல பிறகு சரி செய்யுங்க.
7. Back பொத்தான்: உள் பக்கங்களில் பின்னால் போகுதா; முகப்பில் ஒரு தடவை அழுத்தினா "வெளியேற மீண்டும் Back அழுத்தவும்"; 2 விநாடிக்குள் மீண்டும் அழுத்தினா app மூடுதா.
   *(குறிப்பு: app திறந்தவுடனே திரையைத் தொடாமல் Back அழுத்தினா நேரடியா மூடலாம். இது Chrome-ன் விதி, website-லயும் இப்படித்தான்.)*
8. Airplane mode on → app-ல "இணையம் இல்லை" திரை வருதா; பழைய தொகை எதுவும் தெரியக் கூடாது. Off செய்ததும் "மீண்டும் முயற்சி".
9. Referral (debug APK மட்டும், computer இருந்தா): `adb shell am start -n com.subbulakshmi.thangamaligai/.LauncherActivity --es debug_referrer "ref=TEST123"` → join படிவத்தில் TEST123 வருதா. Computer இல்லைன்னா: test account (uninstall செய்து) `https://play.google.com/store/apps/details?id=com.subbulakshmi.thangamaligai&referrer=ref%3DTEST123` link வழியா install செய்து பாருங்க. Testing track-ல referrer சில நேரம் வராமல் போகலாம்; app public-ஆன பிறகு உறுதியா சோதிக்கலாம்.

## பிரச்சனை வந்தா

| அறிகுறி | காரணம் / தீர்வு |
|---|---|
| மேலே address bar தெரியுது | assetlinks.json-ல SHA-256 தவறு / இன்னும் போடல (படி 4). Clear storage செய்து மீண்டும் திறங்க |
| Workflow சிவப்பு ✗ "keystore" | `ANDROID_KEYSTORE_BASE64` முழுசா copy ஆகல. Text-ஐ மீண்டும் முழுசா copy செய்யுங்க |
| "Chrome தேவை" செய்தி | Phone-ல Chrome இல்லை / disable. Play Store-ல Chrome install / enable |
| Notification வரல | Phone Settings → Apps → தங்க மாளிகை → Notifications on; website-லயும் notification on செய்திருக்கணும் |
