# Google Play checklist — சுப்புலட்சுமி தங்க மாளிகை (customer app)

**Policies checked on: 23 Oct 2026** (sources at the bottom). Re-check anything older than ~3 months before you submit.

App ID: `com.subbulakshmi.thangamaligai` · versionCode 1 · versionName 1.0.0 · targetSdk 36 · minSdk 24

---

## 🛑 BLOCKER — do not release to real customers yet

- [ ] **C1 (prelaunch-audit-2026-10-21): the payment gateway is in SANDBOX, and sandbox payments are recorded as real installments.**
  The app **must not go to Production** (or to real customers in any track) until C1 is fixed: switch Cashfree to production, and make sure sandbox orders can never become installments.
  Internal / closed testing with **test accounts only** is OK.
- [ ] Remaining items from the pre-launch audit: live DB check (`prelaunch_audit.sql` result), legal / accountant review of the scheme terms.

---

## 1. Technical

- [x] Target API **36** (required for new apps and updates from 31 Aug 2026). Set in `android/app/build.gradle`.
- [x] Signed **AAB** built in GitHub Actions (`android.yml`). Upload key only in GitHub Secrets.
- [ ] Play App Signing **on** (default when you upload the first AAB).
- [ ] `.well-known/assetlinks.json` has **both** SHA-256 values (App signing key + upload key) and is live. Check:
  `https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://gold.thirumalaiyogi.workers.dev&relation=delegate_permission/common.handle_all_urls`
- [ ] On a phone installed from Play: **no address bar**.
- [ ] **Domain decision before the first release.** The app is tied to `gold.thirumalaiyogi.workers.dev`. If the shop will use its own domain (e.g. `subbulakshmigold.in`), switch **before** the first Play release (`android/gradle.properties → twaHost`). Changing later needs new asset links, an app update, and customers logging in again.

## 2. Testing gate (new personal developer account)

- [ ] Personal Play Console accounts created after 13 Nov 2023: a **closed test with at least 12 testers, opted in continuously for at least 14 days**, before you can apply for Production.
  - Testers who leave before 14 days don't count. Re-joining restarts their 14 days.
  - Use family / staff / friendly customers with **test** accounts (C1!).
- [ ] Then: Dashboard → **Apply for production** (answer the questions about the test).
- [ ] (If the account is an **Organization** account, this 12×14 rule does not apply. D-U-N-S number needed to create one.)

## 3. Store listing (Tamil + English)

- [ ] App name: `சுப்புலட்சுமி தங்க மாளிகை` (max 30 characters). English listing name e.g. `Subbulakshmi Thanga Maligai`.
- [ ] Short description (≤80): e.g. `தங்க நகை சேமிப்புத் திட்டம் · Passbook · இன்றைய தங்க விலை`
- [ ] Full description: what the scheme is, Passbook, rates, online installments, shop address. **Do not** call it "investment", "digital gold", "returns" or "interest".
- [ ] App icon 512×512: `android/play-assets/icon-512.png`
- [ ] Feature graphic 1024×500: `android/play-assets/feature-graphic-1024x500.png`
- [ ] Phone screenshots (min 2, 9:16 recommended): take them from the app with a **test** account (no real customer names / numbers).
- [ ] Category: **Shopping** (suggested). Contact email `stmgold2021@gmail.com`, phone, website.
- [ ] Add an **English (en-IN)** translation of the listing.

## 4. App content (Policy → App content)

- [ ] **Privacy policy:** `https://gold.thirumalaiyogi.workers.dev/privacy.html`. ⚠️ Every line marked **DRAFT** must be confirmed by the owner first (retention period, OTP provider, birthday/anniversary fields, 18+).
- [ ] **App access:** "All or some functionality is restricted" → give reviewers a **test** mobile number + mPIN created by the owner, already past OTP setup. **Never a real customer.** Add a note: "Payments are in test mode."
- [ ] **Ads:** No ads.
- [ ] **Content rating (IARC):** Category "All other app types"; no violence, gambling or user-generated content. Mention that the app has online purchases/payments.
- [ ] **Target audience:** **18 and over** only. Not designed for children.
- [ ] **Data safety:** see §5.
- [ ] **Account deletion:** in-app path = Passbook → என் விவரம் → "கணக்கை நீக்க கோரிக்கை". Web URL = `https://gold.thirumalaiyogi.workers.dev/delete-account.html`.
- [ ] **Financial features declaration:** see §6.
- [ ] Government app: No. News app: No. Health: No.

## 5. Data safety form (suggested answers — owner to confirm)

| Question | Answer |
|---|---|
| Does the app collect or share any of the required user data types? | **Yes** |
| Is all user data encrypted in transit? | **Yes** (HTTPS everywhere) |
| Do you provide a way for users to request that their data is deleted? | **Yes** (in-app + web link above) |

Data **collected** (not "shared": Supabase, Cloudflare and Cashfree are service providers acting for the shop):

| Data type | Collected | Required? | Purposes |
|---|---|---|---|
| Personal info → **Name** | Yes | Required | App functionality, Account management |
| Personal info → **Phone number** | Yes | Required | App functionality, Account management, Fraud prevention/security |
| Personal info → **Address** | Yes | Required/Optional (owner to confirm) | App functionality, Account management |
| Personal info → **Other info** (nominee details; birthday/anniversary if collected) | Yes | Optional | App functionality |
| Financial info → **Purchase history** (installments, amounts, dates, gold grams) | Yes | Required | App functionality, Account management |
| Financial info → **User payment info** | Owner to decide. Card/UPI details are entered in Cashfree's checkout and are **not** stored by the shop. The conservative choice is to declare it as collected for "App functionality" | — | — |
| Device or other IDs (push notification subscription) | Yes, if the user turns on notifications | Optional | App functionality (notifications) |
| App activity / Location / Contacts / Photos / Health | **No** | | |

Mark data as "**processed ephemerally**: No" for all of the above (it is stored).

## 6. Financial features declaration

Describe the app **accurately**:

> This app lets existing and new customers of one jewellery shop (Subbulakshmi Thanga Maligai, Puliyangudi) join the shop's own **jewellery purchase savings scheme**, view their passbook, see the shop's daily gold/silver rate, and pay monthly installments online through a licensed payment gateway (Cashfree). At the end of the scheme the saved amount is used to **buy jewellery from the shop**. It is **not** a loan, credit, investment, deposit-taking, trading, chit fund or "digital gold" product. No interest or returns are offered. The app does not hold money and is not a wallet.

- The declaration requires **every** app to answer, even with "My app doesn't provide any financial features".
- The closest options are either **"My app doesn't provide any financial features"** (it is a retail shop's purchase plan, and payments go to the merchant through Cashfree) or **Support services → Other** with the description above.
- Do **not** pick "Crowdfunding and chit funds", "Stock trading and portfolio management" or loan categories unless a legal/accountant review says the scheme is one of those.
- ⚠️ **Owner + accountant/lawyer decide.** Jewellery savings schemes in India can fall under deposit rules (Companies Act / BUDS Act). The pre-launch audit already lists this legal review as open.

## 7. Before each release

- [ ] `versionCode` increased by 1 in `android/app/build.gradle`.
- [ ] Workflow green; AAB uploaded to the right track.
- [ ] Release notes in Tamil + English.
- [ ] Quick phone test (README → "Phone-ல சோதிக்க வேண்டியவை").

## 8. After the app is public

- [ ] Set `const PLAY_ID="com.subbulakshmi.thangamaligai";` in `index.html` (referral messages will then include the Play link).
- [ ] Add the Play badge/link on the website.

---

### Sources (checked 23 Oct 2026)
- Target API level requirements: https://developer.android.com/google/play/requirements/target-sdk
- Testing requirements for new personal developer accounts: https://support.google.com/googleplay/android-developer/answer/14151465
- Account deletion requirements: https://support.google.com/googleplay/android-developer/answer/13327111
- Financial features declaration: https://support.google.com/googleplay/android-developer/answer/13849271
- Financial Services policy: https://support.google.com/googleplay/android-developer/answer/9876821
