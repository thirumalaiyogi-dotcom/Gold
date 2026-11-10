import 'package:flutter/material.dart';

import 'home.dart';
import 'links.dart';
import 'notify.dart';
import 'ui.dart';

Widget _scaffold(String title, Widget body) => Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: C.paper, surfaceTintColor: C.paper, foregroundColor: C.navy, title: Text(title, style: sans(16.5, color: C.ink, weight: FontWeight.w700))),
      body: body,
    );

/// எங்களைப் பற்றி — shop info inside the app (same details as the website).
class AboutPage extends StatelessWidget {
  const AboutPage({super.key, this.fromLogin = false});
  final bool fromLogin;
  @override
  Widget build(BuildContext context) {
    Widget row(IconData i, String t, {VoidCallback? onTap}) => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(i, size: 20, color: C.navy),
              const SizedBox(width: 12),
              Expanded(child: Text(t, style: sans(14.5, height: 1.6))),
              if (onTap != null) const Icon(Icons.chevron_right, color: C.mute),
            ]),
          ),
        );
    return _scaffold(
      'எங்களைப் பற்றி',
      ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: velvetDeco(radius: BorderRadius.circular(18), alignment: Alignment.center),
          child: Column(children: [
            Image.asset('assets/logo.png', height: 64),
            const SizedBox(height: 10),
            Text('சுப்புலட்சுமி தங்க மாளிகை', textAlign: TextAlign.center, style: serif(22, color: C.goldSoft, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('தங்கநகை சேமிப்புத் திட்டம் · புளியங்குடி', textAlign: TextAlign.center, style: sans(13.5, color: C.navyMute)),
          ]),
        ),
        const SizedBox(height: 14),
        LuxCard(
          child: Column(children: [
            row(Icons.place_outlined, '51B, கங்கை அம்மன் கோவில் தெரு, காந்தி பஜார், புளியங்குடி – 627855', onTap: () => openMaps(context)),
            const Divider(height: 1, color: C.line),
            row(Icons.schedule, 'திங்கள் – சனி: 9:00 AM – 9:00 PM\nஞாயிறு: 9:00 AM – 8:00 PM'),
            const Divider(height: 1, color: C.line),
            row(Icons.call_outlined, '97919 18344', onTap: () => callShop(context)),
            const Divider(height: 1, color: C.line),
            row(Icons.call_outlined, '93443 95078', onTap: () => callShop(context, Shop.phone2)),
            const Divider(height: 1, color: C.line),
            row(Icons.chat_outlined, 'WhatsApp-ல் பேச', onTap: () => whatsApp(context)),
            const Divider(height: 1, color: C.line),
            row(Icons.mail_outline, 'stmgold2021@gmail.com', onTap: () => openLink(context, 'mailto:stmgold2021@gmail.com')),
          ]),
        ),
        if (fromLogin) ...[
          const SizedBox(height: 16),
          PrimaryButton('சேமிப்புத் திட்டங்களை பார்க்க', onTap: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false)),
        ],
      ]),
    );
  }
}

/// தனியுரிமைக் கொள்கை — in-app copy of privacy.html (Tamil parts). DRAFT lines kept as DRAFT.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});
  static const _sec = [
    ['1. நாங்கள் யார்', 'சுப்புலட்சுமி தங்க மாளிகை, 51B, கங்கை அம்மன் கோவில் தெரு, காந்தி பஜார், புளியங்குடி, தமிழ்நாடு – 627855. இந்த app / website-ல் நீங்கள் தரும் தகவல்களுக்கு கடையே பொறுப்பு.\nதொடர்பு: stmgold2021@gmail.com · +91 97919 18344'],
    ['2. என்ன தகவல் சேகரிக்கிறோம்', '• பெயர், மொபைல் எண், முகவரி / ஊர்\n• வாரிசுதாரர் (nominee) விவரம்\n• தேதிகள்: திட்டத்தில் சேர்ந்த நாள், தவணை தேதிகள்; DRAFT நீங்கள் கொடுத்தால் பிறந்த நாள் / திருமண நாள்\n• தவணை / பணம் செலுத்திய பதிவுகள்: தொகை, தேதி, ரசீது / order எண், சேர்ந்த தங்கம் (கிராம்)\n• Login: மொபைல் எண் + 6 இலக்க mPIN; முதல் முறை OTP\n• Referral code (நீங்கள் யாரை அழைத்தீர்கள் / யார் உங்களை அழைத்தார்கள்)\n• Notification அனுமதி கொடுத்தால்: உங்கள் browser-ன் push subscription (தொலைபேசி எண் அல்ல)\nCard / UPI / வங்கி விவரங்களை நாங்கள் சேமிப்பதில்லை. அவற்றை Cashfree Payments நேரடியாகக் கையாள்கிறது.'],
    ['3. எதற்காக', '• சேமிப்புத் திட்டக் கணக்கை நடத்த, Passbook காட்ட, ரசீது தர\n• Online-ல் தவணை செலுத்த\n• நினைவூட்டல், விலை / அறிவிப்புகள் அனுப்ப (நீங்கள் அனுமதித்தால் மட்டும்)\n• Referral தள்ளுபடி கணக்கிட\n• சட்டப்படி கணக்கு / வரி பதிவுகள் வைக்க\nஉங்கள் தகவலை விற்பதில்லை; விளம்பரத்துக்குப் பயன்படுத்துவதில்லை.'],
    ['4. எங்களுக்கு உதவும் சேவைகள்', '• Supabase: தரவுத்தளம் (database), login / OTP சரிபார்ப்பு\n• Cloudflare: website / app hosting\n• Cashfree Payments: online பணம் செலுத்துதல்\n• Browser push service (Android-ல் Google): notifications அனுப்ப\n• DRAFT OTP அனுப்பும் சேவை (SMS / Telegram / email; எது பயன்படுகிறது என்று உரிமையாளர் உறுதி செய்ய வேண்டும்)'],
    ['5. பாதுகாப்பு', 'App-க்கும் server-க்கும் இடையிலான எல்லா தகவலும் HTTPS மூலம் encrypt செய்யப்படுகிறது. Passbook-ஐ உங்கள் mPIN மட்டுமே திறக்கும். mPIN-ஐ யாரிடமும் (கடை ஊழியர் உட்பட) சொல்லாதீர்கள்.'],
    ['6. எவ்வளவு காலம் வைத்திருப்போம்', 'DRAFT கணக்கு இருக்கும் வரை உங்கள் தகவலை வைத்திருப்போம். கணக்கை நீக்கினால் பெயர், முகவரி, nominee, login, notification விவரங்கள் நீக்கப்படும். ஆனால் பணம் செலுத்திய / திட்டப் பதிவுகளை வரி மற்றும் கணக்குச் சட்டங்கள் கேட்கும் காலம் வரை வைத்திருக்க வேண்டியிருக்கும். அந்தக் காலத்தை உரிமையாளர் / கணக்காளர் உறுதி செய்ய வேண்டும்.'],
    ['7. கணக்கை நீக்க', 'App-ல்: கணக்கு → என் விவரம் → “கணக்கை நீக்க கோரிக்கை”. அல்லது stmgold2021@gmail.com-க்கு email அனுப்புங்கள்.'],
    ['8. உங்கள் உரிமைகள்', 'உங்கள் தகவலைப் பார்க்க, திருத்த, நீக்கக் கோரலாம். Notifications-ஐ phone settings-ல் எப்போதும் நிறுத்தலாம்.'],
    ['9. வயது', 'DRAFT இந்த சேவை 18 வயதுக்கு மேற்பட்டவர்களுக்கு மட்டும்.'],
    ['10. மாற்றங்கள்', 'இந்தக் கொள்கையை மாற்றினால் தேதியுடன் வெளியிடுவோம்.'],
  ];
  @override
  Widget build(BuildContext context) => _scaffold(
        'தனியுரிமைக் கொள்கை',
        ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF4D6), borderRadius: BorderRadius.circular(12), border: Border.all(color: C.goldSoft)),
            child: Text('DRAFT — நிறுவன உரிமையாளர் சரிபார்க்க வேண்டும். கடைசியாக மாற்றியது: 23 Oct 2026', style: sans(12.5, color: const Color(0xFF5A4410), height: 1.5)),
          ),
          const SizedBox(height: 12),
          for (final s in _sec)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s[0], style: serif(17, color: C.ink, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(s[1], style: sans(14, height: 1.65)),
              ]),
            ),
          TextButton(onPressed: () => openLink(context, Shop.privacy), child: Text('முழு கொள்கை (English உட்பட) — website', style: sans(13, color: C.navy))),
        ]),
      );
}


/// Notification அமைப்பு — three switches + a test button.
class NotifySettingsPage extends StatefulWidget {
  const NotifySettingsPage({super.key});
  @override
  State<NotifySettingsPage> createState() => _NotifySettingsPageState();
}

class _NotifySettingsPageState extends State<NotifySettingsPage> {
  final v = <String, bool>{'n_due': true, 'n_notice': true, 'n_rate': true, 'n_greet': true};
  bool exact = true;
  String? next;
  String? gerr;
  bool loaded = false;

  Future<void> _status() async {
    final e = await exactAlarmsOk();
    final n = await nextGreeting();
    final ge = n == null ? await greetError() : null;
    if (!mounted) return;
    setState(() {
      exact = e;
      next = n;
      gerr = ge;
      loaded = true;
    });
  }

  // back from the Android permission page → re-schedule and refresh the status
  late final AppLifecycleListener _life = AppLifecycleListener(onResume: () => scheduleGreetings().then((_) => _status()));

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _life;
    () async {
      for (final k in v.keys.toList()) {
        v[k] = await Notify.isOn(k);
      }
      if (mounted) setState(() {});
      await scheduleGreetings(); // make sure the greetings are really in Android's queue
      await _status();
    }();
  }

  @override
  Widget build(BuildContext context) {
    Widget sw(String k, IconData i, String t, String sub) => SwitchListTile(
          value: v[k]!,
          secondary: Icon(i, color: C.navy),
          title: Text(t, style: sans(15, weight: FontWeight.w700)),
          subtitle: Text(sub, style: sans(12.5, color: C.mute, height: 1.4)),
          onChanged: (x) {
            setState(() => v[k] = x);
            Notify.setOn(k, x).then((_) {
              if (k == 'n_greet') scheduleGreetings().then((_) => _status());
            });
          },
        );
    return _scaffold(
      'Notification அமைப்பு',
      ListView(padding: const EdgeInsets.fromLTRB(12, 14, 12, 24), children: [
        LuxCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            sw('n_due', Icons.event_available_outlined, 'தவணை நினைவூட்டல்', 'மாதம் 1, 4, 7 தேதிகளில் — தவணை செலுத்தவில்லை என்றால் மட்டும்'),
            const Divider(height: 1, color: C.line),
            sw('n_notice', Icons.campaign_outlined, 'நிறுவன அறிவிப்புகள்', 'சலுகைகள், புதிய திட்டங்கள், நிறுவனம் தொடர்பான செய்திகள்'),
            const Divider(height: 1, color: C.line),
            sw('n_rate', Icons.trending_up, 'இன்றைய தங்க விலை', 'நிறுவனம் விலையை பதிவு செய்தவுடன் தினமும் ஒருமுறை'),
            const Divider(height: 1, color: C.line),
            sw('n_greet', Icons.wb_sunny_outlined, 'தினசரி வணக்கம்', 'காலை 7, மதியம் 1, இரவு 8 மணி · Internet இல்லாமலும் வரும்'),
          ]),
        ),
        if (v['n_greet']! && loaded) ...[
          const SizedBox(height: 14),
          LuxCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(next != null ? Icons.check_circle_outline : Icons.error_outline, color: next != null ? C.green : C.red, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(next != null ? 'அடுத்த வணக்கம்: $next' : 'வணக்கம் திட்டமிடப்படல. App-ஐ மூடி திறந்து பாருங்க.', style: sans(13.5, color: C.ink, height: 1.5))),
              ]),
              if (next == null && gerr != null) ...[
                const SizedBox(height: 8),
                SelectableText('விவரம்: ${gerr!.length > 220 ? gerr!.substring(0, 220) : gerr}', style: sans(11.5, color: C.mute, height: 1.5)),
              ],
              if (!exact) ...[
                const SizedBox(height: 12),
                Text('சரியான நேரத்துக்கு வர, phone-ல "Alarms & reminders" அனுமதி தேவை. இல்லைன்னா phone வணக்கத்தை தள்ளிப்போடலாம் அல்லது விட்டுடலாம்.',
                    style: sans(13, color: C.mute, height: 1.6)),
                const SizedBox(height: 10),
                PrimaryButton('அனுமதி கொடுக்க', icon: Icons.alarm_on_outlined, onTap: () async {
                  await askExactAlarms();
                  await scheduleGreetings();
                  await _status();
                }),
              ],
            ]),
          ),
        ],
      ]),
    );
  }
}
