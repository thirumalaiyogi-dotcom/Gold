# Staff Roles + Audit Log + KYC: திட்டம் (PROPOSED, இன்னும் apply ஆகல)

**Files:**
- `2026-11-07_roles_audit_kyc.sql`: migration
- `2026-11-07_roles_audit_kyc_ROLLBACK.sql`: பழைய நிலைக்கு திரும்ப

**சோதனை:** உள்ளூர் Postgres 16-ல, live database மாதிரியான ஒரு stub schema-ல ஓட்டிப் பார்த்தது.
- Migration ✓, rollback ✓, மறுபடி apply ✓, இரண்டு தடவை apply ✓.
- Live Supabase-ல **ஓட்டல**.

## 1. Roles: யாருக்கு என்ன உரிமை

| உரிமை | Super Admin | Admin | Manager | Accounts | Support |
|---|:-:|:-:|:-:|:-:|:-:|
| எல்லாத்தையும் பார்க்க | ✓ | ✓ | ✓ | ✓ | ✓ |
| Customer சேர்க்க / திருத்த (`cust.write`) | ✓ | ✓ | ✓ | – | – |
| Customer நீக்க (`cust.delete`) | ✓ | ✓ | – | – | – |
| கோரிக்கை approve (`req.handle`) | ✓ | ✓ | ✓ | – | ✓ |
| தவணை பதிய / திருத்த (`pay.write`) | ✓ | ✓ | ✓ | ✓ | – |
| தவணை நீக்க (`pay.delete`) | ✓ | ✓ | – | ✓ | – |
| தங்க / வெள்ளி விலை (`rate.write`) | ✓ | ✓ | ✓ | ✓ | – |
| படங்கள், திட்டங்கள், Poster, Refer அமைப்பு (`settings.write`) | ✓ | ✓ | ✓ | – | – |
| அறிவிப்பு அனுப்ப (`notify.send`) | ✓ | ✓ | ✓ | – | ✓ |
| KYC சரிபார்க்க (`kyc.review`) | ✓ | ✓ | ✓ | – | பார்க்க மட்டும் |
| Audit log பார்க்க (`audit.read`) | ✓ | ✓ | ✓ | ✓ | – |
| Staff சேர்க்க / role மாற்ற (`staff.manage`) | ✓ | – | – | – | – |

- **ஏற்கனவே இருக்கிற staff:** தானா `super_admin` ஆவாங்க. அதனால இன்னைக்கு வேலை செய்யறது எதுவும் உடையாது.
- **எங்கே அமல்:** எல்லாமே **database-ல (RLS) அமல்**. Button-ஐ மறைச்சா மட்டும் போதாது, அனுமதி இல்லாதவங்க நேரடியா API அழைச்சாலும் database தடுக்கும்.
- **Inactive staff:** `active=false` போட்டா அந்த staff-க்கு எந்த access-உம் இருக்காது. Account-ஐ நீக்க வேண்டியதில்லை.

**உள்ளூர் சோதனை முடிவுகள்:**
- Support → தவணை பதிவு: **மறுக்கப்பட்டது** ✓
- Support → விலை மாற்றம்: **மறுக்கப்பட்டது** ✓
- Accounts → அறிவிப்பு: **மறுக்கப்பட்டது** ✓
- Accounts → customer நீக்கம்: **0 வரி நீங்கியது** ✓
- Staff அல்லாதவர் → customers படிக்க: **0 வரி** ✓
- Accounts → தவணை பதிவு: அனுமதி ✓
- Owner → தவணை பதிவு: அனுமதி ✓

## 2. Audit log (`gold_audit`)

- **என்ன பதியும்:** Customers, payments, requests, விலை, திட்டங்கள், staff, Refer அமைப்பு, KYC. இதுல எதை யார் எப்போ மாத்தினாங்க, பழைய மதிப்பு, புது மதிப்பு எல்லாம் தானா பதியும்.
- **யார் பதிஞ்சாங்க:** Edge Function / cron மாத்தினா actor "system"-ன்னு வரும்.
- **PIN பாதுகாப்பு:** PIN, activation code மாதிரியானவை **log-ல சேராது** (சோதித்தது).
- **தவணை பதிவு:** `gold_payments.created_by`-ல யார் பதிஞ்சாங்கன்னு இருக்கும்.

## 3. KYC

- **Table:** `gold_kyc`. ஆவண வகை (aadhaar / pan / voter / dl / passport), **கடைசி 4 எழுத்து மட்டும்**, படம் path, நிலை (pending / verified / rejected), குறிப்பு, யார் சரிபார்த்தாங்க.
- **Bucket `kyc`:** **Private**. 5 MB வரம்பு, JPG / PNG / WebP / PDF மட்டும். Staff (kyc.review / kyc.view) மட்டும் பார்க்க முடியும். Public link கிடையாது.
- **Customer upload:** Customer-களுக்கு Supabase login இல்லை, அதனால **`kyc-submit` Edge Function** தேவை. அது mobile + mPIN சரிபார்த்து, service role மூலமா மட்டும் பதிவேற்றும். இந்த function இன்னும் எழுதல, ஒப்புதலுக்குப் பிறகு எழுதுவேன்.
- **Customer நிலை பார்க்க:** `gold_kyc_status(mobile, pin)` தன்னோட KYC நிலையை மட்டும் காட்டும் (சோதித்தது).

**⚠️ DRAFT: owner / CA உறுதிப்படுத்தணும்:**
- **முழு Aadhaar எண் சேமிக்கக் கூடாது:** UIDAI விதிகள் அனுமதிக்காது. அதனால கடைசி 4 இலக்கம் மட்டும் சேமிக்கிறோம். Customer-கிட்ட **masked Aadhaar** (முதல் 8 இலக்கம் மறைச்சது) தான் கேட்கணும்.
- **எந்த ஆவணம் கட்டாயம்:** அதை கடை முடிவு பண்ணணும். நகைச் சீட்டு / சேமிப்புத் திட்டத்துக்கு KYC சட்டப்படி தேவையான்னு கடை auditor சொல்லணும்.
- **எவ்வளவு நாள் வைக்கணும், யார் பார்க்கலாம்:** Privacy policy-ல சேர்க்கணும்.

## 4. Apply பண்ண வரிசை (ஒப்புதல் கிடைச்ச பிறகு)

1. Supabase-ல ஒரு **branch / staging** உருவாக்கி, அதுல migration ஓட்டி சோதிக்கணும்.
2. Live-ல ஓட்டறதுக்கு முன்னாடி Supabase backup எடுக்கணும்.
3. Migration ஓட்டணும். அப்புறம் staff panel-ல "Staff Management" பகுதி: role மாற்றம், active on/off (super_admin மட்டும்).
4. `kyc-submit` Edge Function, customer app-ல KYC பக்கம், staff panel-ல KYC review பகுதி.
5. `push` Edge Function-லயும் `notify.send` உரிமை சரிபார்ப்பு சேர்க்கணும்.
6. பிரச்சனை வந்தா ROLLBACK SQL ஓட்டணும். KYC files இருந்தா முதல்ல dashboard-ல நீக்கணும்.
