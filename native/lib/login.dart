import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'home.dart';
import 'links.dart';
import 'main.dart';
import 'ui.dart';
import 'info.dart';

/// Navy hero with the logo, ivory sheet below (shared by the login screens).
class _LoginFrame extends StatelessWidget {
  const _LoginFrame({required this.child, this.heroHeight = 250, this.onBack});
  final Widget child;
  final double heroHeight;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: C.navy,
      body: Column(children: [
        Container(
          height: heroHeight + top,
          width: double.infinity,
          padding: EdgeInsets.only(top: top),
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, .1), radius: .8, colors: [Color(0xFF8A2333), C.navy]),
          ),
          child: Stack(children: [
            Center(child: Hero(tag: 'logo', child: Image.asset('assets/logo.png', height: heroHeight * .42))),
            if (onBack != null)
              Positioned(
                left: 8,
                top: 8,
                child: IconButton(onPressed: onBack, tooltip: 'பின் செல்ல', icon: const Icon(Icons.arrow_back_ios_new, color: C.goldSoft)),
              ),
          ]),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: C.ivory, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: SafeArea(top: false, child: child),
          ),
        ),
      ]),
    );
  }
}

/// The mobile number is remembered after the first successful login (like the website),
/// so next time only the mPIN is asked. "எண் மாற்ற" on the mPIN page changes it.
class SavedMobile {
  static Future<String?> get() async {
    try {
      final m = (await SharedPreferences.getInstance()).getString('mobile');
      return (m != null && RegExp(r'^[6-9]\d{9}$').hasMatch(m)) ? m : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> set(String m) async {
    try {
      await (await SharedPreferences.getInstance()).setString('mobile', m);
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      await (await SharedPreferences.getInstance()).remove('mobile');
    } catch (_) {}
  }
}

/// Opens the mPIN page directly when a number is remembered, else the mobile page.
Future<void> openPassbookLogin(BuildContext context) async {
  final m = await SavedMobile.get();
  if (!context.mounted) return;
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => m != null ? PinScreen(mobile: m) : const MobileScreen()));
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    Widget option({required IconData icon, required String title, required String sub, required bool primary, required VoidCallback onTap}) {
      return Material(
        color: primary ? C.navy : C.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: primary ? C.navy : C.line2)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            tapFeel();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
            decoration: primary
                ? BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x99C9A24A)))
                : null,
            child: Row(children: [
              RingIcon(icon, size: 48, color: primary ? C.goldSoft : C.navy, ring: primary ? const Color(0x99C9A24A) : C.goldLine, bg: Colors.transparent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: sans(15, color: primary ? Colors.white : C.navy, weight: FontWeight.w700, height: 1.35)),
                  const SizedBox(height: 2),
                  Text(sub, style: sans(13, color: primary ? C.navyMute : C.mute)),
                ]),
              ),
              Icon(Icons.chevron_right, color: primary ? C.gold : C.goldText),
            ]),
          ),
        ),
      );
    }

    final h = MediaQuery.of(context).size.height;
    return _LoginFrame(
      heroHeight: h < 760 ? 150 : (h < 860 ? 175 : 220),
      child: ListView(padding: const EdgeInsets.fromLTRB(22, 22, 22, 18), children: [
        Text('வணக்கம்.. வருக..!', style: serif(25)),
        const SizedBox(height: 6),
        Text('சுப்புலட்சுமி தங்கமாளிகை தங்கநகை சேமிப்பிற்கான செயலி (App)-க்கு உங்களை அன்புடன் வரவேற்கிறோம்.', style: sans(14, color: C.ink, weight: FontWeight.w600, height: 1.5)),
        const SizedBox(height: 6),
        Text('உங்கள் தங்க சேமிப்பை பார்க்கவோ அல்லது தங்க சேமிப்புத் திட்டங்களைப் பற்றிய விவரங்களைத் தெரிந்து கொள்வதற்கோ கீழே உள்ள விருப்பங்களில் ஒன்றைத் தேர்வு செய்யுங்கள்.', style: sans(13.5, color: C.mute, height: 1.5)),
        const SizedBox(height: 16),
        option(
          icon: Icons.lock_outline,
          title: 'என் சேமிப்பு (Passbook)',
          sub: 'mPIN போட்டு உள்ளே நுழையுங்கள்',
          primary: true,
          onTap: () => openPassbookLogin(context),
        ),
        const SizedBox(height: 10),
        option(
          icon: Icons.diamond_outlined,
          title: 'தங்கசேமிப்புத் திட்டங்களை பற்றி தெரிந்து கொள்வதற்கு',
          sub: '(Login தேவையில்லை)',
          primary: false,
          onTap: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false),
        ),
        const SizedBox(height: 18),
        Center(child: Text('சுப்புலட்சுமி தங்க மாளிகை · புளியங்குடி', style: sans(12, color: C.mute))),
      ]),
    );
  }
}

/// Shared top part of the mobile / mPIN pages: lock image + title.
class _PadHeader extends StatelessWidget {
  const _PadHeader(this.title, this.sub);
  final String title, sub;
  @override
  Widget build(BuildContext context) => Column(children: [
        Image.asset('assets/lock.png', height: 58),
        const SizedBox(height: 4),
        Text(title, style: serif(24)),
        const SizedBox(height: 2),
        Text(sub, style: sans(14, color: C.mute), textAlign: TextAlign.center),
      ]);
}

class _HelpTiles extends StatelessWidget {
  const _HelpTiles();
  @override
  Widget build(BuildContext context) {
    Widget tile(IconData i, String t, VoidCallback onTap) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: C.paper,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: C.line2)),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: SizedBox(
                  height: 66,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(i, color: C.navy, size: 22),
                    const SizedBox(height: 4),
                    Text(t, style: sans(11.5, color: C.navy, weight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2),
                  ]),
                ),
              ),
            ),
          ),
        );
    return Row(children: [
      tile(Icons.chat_outlined, 'WhatsApp', () => whatsApp(context)),
      tile(Icons.info_outline, 'எங்களைப் பற்றி', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutPage(fromLogin: true)))),
      tile(Icons.call_outlined, 'அழைக்க', () => callShop(context)),
      tile(Icons.place_outlined, 'வழி காட்டு', () => openMaps(context)),
    ]);
  }
}

class _Dots extends StatelessWidget {
  const _Dots(this.filled, {this.count = 6});
  final int filled, count;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.symmetric(horizontal: 7),
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? C.navy : Colors.transparent,
              border: Border.all(color: i < filled ? C.navy : C.goldLine, width: 1.6),
            ),
          ),
        ),
      );
}

class MobileScreen extends StatefulWidget {
  const MobileScreen({super.key});
  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  String v = '';
  String err = '';
  int shake = 0;

  void _key(String k) {
    setState(() {
      err = '';
      if (k == 'del') {
        if (v.isNotEmpty) v = v.substring(0, v.length - 1);
      } else if (v.length < 10) {
        v += k;
      }
    });
  }

  bool busy = false;
  Future<void> _next() async {
    if (busy) return;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
      HapticFeedback.heavyImpact();
      setState(() {
        err = 'சரியான 10 இலக்க மொபைல் எண் போடுங்க';
        shake++;
      });
      return;
    }
    setState(() => busy = true);
    bool? ok;
    try {
      ok = await Api.mobileOk(v);
    } catch (_) {
      ok = null; // network problem: let the mPIN step decide
    }
    if (!mounted) return;
    setState(() => busy = false);
    if (ok == false) {
      HapticFeedback.heavyImpact();
      setState(() {
        err = 'இந்த எண் பதிவில் இல்ல. கடையில் பதிவு செய்த எண்ணை போடுங்க.';
        shake++;
      });
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PinScreen(mobile: v)));
  }

  @override
  Widget build(BuildContext context) {
    final shown = v.isEmpty ? '10 இலக்க மொபைல் எண்' : '${v.length > 5 ? '${v.substring(0, 5)} ${v.substring(5)}' : v}';
    return _LoginFrame(
      heroHeight: 130,
      onBack: () => Navigator.of(context).pop(),
      child: ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 16), children: [
        const _PadHeader('மொபைல் எண்', 'கடையில் பதிவு செய்த எண்ணை போடுங்க'),
        const SizedBox(height: 14),
        Shake(
          trigger: shake,
          child: SizedBox(height: 40, child: Center(child: FittedBox(child: Text(shown, maxLines: 1, style: sans(v.isEmpty ? 17 : 26, color: v.isEmpty ? const Color(0xFFB8A690) : C.navy, weight: FontWeight.w600, letterSpacing: v.isEmpty ? 0 : 1.5))))),
        ),
        SizedBox(height: 22, child: Center(child: Text(err, style: sans(13, color: C.red)))),
        KeyPad(onKey: _key),
        const SizedBox(height: 14),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: v.length == 10 ? 1 : .5,
          child: PrimaryButton('தொடரவும்', onTap: _next),
        ),
        const SizedBox(height: 14),
        const _HelpTiles(),
      ]),
    );
  }
}

class PinScreen extends StatefulWidget {
  const PinScreen({super.key, required this.mobile});
  final String mobile;
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String v = '';
  String err = '';
  int shake = 0;
  bool busy = false;

  Future<void> _key(String k) async {
    if (busy) return;
    setState(() {
      err = '';
      if (k == 'del') {
        if (v.isNotEmpty) v = v.substring(0, v.length - 1);
      } else if (v.length < 6) {
        v += k;
      }
    });
    if (v.length == 6) {
      setState(() => busy = true);
      Map<String, dynamic>? d;
      String? fail;
      try {
        d = await Api.login(widget.mobile, v);
      } catch (_) {
        fail = 'இணைய இணைப்பை சரிபார்த்து மறுபடி முயற்சிக்கவும்.';
      }
      if (!mounted) return;
      if (fail == null && d != null && d['locked'] == true) {
        fail = 'பல தவறான முயற்சிகள். ${d['minutes'] ?? ''} நிமிடம் கழித்து முயற்சிக்கவும்.';
      } else if (fail == null && d != null && d['locked_otp'] == true) {
        fail = '5 முறை தவறு. mPIN பூட்டப்பட்டது. "mPIN மறந்துட்டீங்களா?" வழியாக புது mPIN வைங்க.';
      } else if (fail == null && (d == null || d['wrong'] == true || d['name'] == null)) {
        final left = d?['left'];
        fail = left is num ? 'mPIN தவறு. இன்னும் $left முயற்சி மட்டும்.' : 'மொபைல் எண் / mPIN தவறு.';
      }
      if (fail == null && d != null) {
        HapticFeedback.mediumImpact();
        app.login(widget.mobile, v, d);
        SavedMobile.set(widget.mobile);
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 450),
            pageBuilder: (_, __, ___) => const MainShell(),
            transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          ),
          (_) => false,
        );
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          busy = false;
          v = '';
          err = fail ?? 'mPIN தவறு';
          shake++;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mobile;
    return _LoginFrame(
      heroHeight: 130,
      onBack: () => Navigator.of(context).pop(),
      child: ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 16), children: [
        const _PadHeader('mPIN', 'உங்க 6 இலக்க mPIN போடுங்க'),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.line2)),
            child: Text('+91 ••••• •${m.substring(m.length - 4)}', style: sans(15, color: C.navy, weight: FontWeight.w600)),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: () {
              SavedMobile.clear();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MobileScreen()));
            },
            icon: const Icon(Icons.edit_outlined, size: 16, color: C.navy),
            label: Text('எண் மாற்ற', style: sans(13.5, color: C.navy, weight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 14),
        Shake(trigger: shake, child: _Dots(v.length)),
        SizedBox(height: 26, child: Center(child: Text(err, style: sans(12.5, color: C.red)))),
        KeyPad(onKey: _key),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => whatsApp(context, 'வணக்கம், என் mPIN மறந்துட்டேன். புது Activation code வேண்டும்.\nமொபைல் எண்: ${widget.mobile}'),
            child: Text('mPIN மறந்துட்டீங்களா?', style: sans(14, color: C.navy, weight: FontWeight.w700)),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('புதிய வாடிக்கையாளரா? ', style: sans(14, color: C.mute)),
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatePinScreen(mobile: m))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('mPIN உருவாக்க', style: sans(14.5, color: C.navy, weight: FontWeight.w700).copyWith(decoration: TextDecoration.underline)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        const _HelpTiles(),
      ]),
    );
  }
}

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key, required this.mobile});
  final String mobile;
  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  late final _m = TextEditingController(text: widget.mobile);
  final _c = TextEditingController();
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  String err = '';

  @override
  void dispose() {
    for (final c in [_m, _c, _p1, _p2]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec() => InputDecoration(
        filled: true,
        fillColor: C.paper,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.line2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.navy, width: 1.6)),
      );

  Widget _field(String label, TextEditingController c, {int max = 6, bool secret = false, bool focus = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: sans(14, color: C.navy, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            autofocus: focus,
            obscureText: secret,
            keyboardType: TextInputType.number,
            maxLength: max,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: sans(17, color: C.ink, weight: FontWeight.w600),
            decoration: _dec(),
          ),
        ]),
      );

  bool busy = false;
  Future<void> _save() async {
    if (busy) return;
    String? e;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_m.text)) {
      e = 'சரியான மொபைல் எண் போடுங்க';
    } else if (_c.text.length != 6) {
      e = '6 இலக்க Activation code போடுங்க';
    } else if (_p1.text.length != 6) {
      e = '6 இலக்க mPIN போடுங்க';
    } else if (_p1.text != _p2.text) {
      e = 'இரண்டு mPIN-ம் ஒன்னா இல்ல';
    }
    if (e != null) {
      HapticFeedback.heavyImpact();
      setState(() => err = e!);
      return;
    }
    setState(() {
      busy = true;
      err = '';
    });
    Map<String, dynamic>? r;
    try {
      r = await Api.activate(_m.text, _c.text, _p1.text);
    } catch (_) {
      if (mounted) setState(() => err = 'இணைய இணைப்பை சரிபார்த்து மறுபடி முயற்சிக்கவும்.');
    }
    if (!mounted) return;
    if (r != null && r['locked'] == true) {
      setState(() => err = 'பல தவறான முயற்சிகள். ${r!['minutes'] ?? ''} நிமிடம் கழித்து முயற்சிக்கவும்.');
    } else if (r == null || r['ok'] != true) {
      if (err.isEmpty) setState(() => err = 'மொபைல் / code தவறு. கடையை தொடர்பு கொள்ளுங்க.');
    } else {
      HapticFeedback.mediumImpact();
      try {
        final d = await Api.login(_m.text, _p1.text);
        if (!mounted) return;
        if (d != null && d['name'] != null) {
          app.login(_m.text, _p1.text, d);
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
          return;
        }
      } catch (_) {}
      if (!mounted) return;
      showNote(context, 'mPIN அமைக்கப்பட்டது ✓ இப்போ உள்நுழையுங்க');
      Navigator.of(context).pop();
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: C.ivory,
        surfaceTintColor: C.ivory,
        foregroundColor: C.navy,
        title: Text('புது mPIN உருவாக்க', style: serif(19)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 30), children: [
        Center(child: Image.asset('assets/logo.png', height: 70)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFF7E0), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE7D49B))),
          child: Text('கடையில முதல் தவணை கட்டும்போது WhatsApp ரசீதுல 6 இலக்க Activation code வரும். உங்க மொபைல் எண்ணும் அந்த code-ம் போட்டு, உங்க சொந்த 6 இலக்க mPIN வைங்க.',
              style: sans(13.5, color: const Color(0xFF5A4410), height: 1.6)),
        ),
        const SizedBox(height: 16),
        _field('மொபைல் எண்*', _m, max: 10),
        _field('Activation code*', _c, focus: true),
        _field('புது 6 இலக்க mPIN*', _p1, secret: true),
        _field('mPIN மறுபடி*', _p2, secret: true),
        if (err.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(err, style: sans(13.5, color: C.red))),
        PrimaryButton(busy ? 'சரிபார்க்கிறது…' : 'mPIN அமை', onTap: _save),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () => whatsApp(context, 'வணக்கம், எனக்கு Activation code வரல. புது code வேண்டும்.\nமொபைல் எண்: ${_m.text}'),
            child: Text('Code வரலையா? Telegram OTP மூலம் mPIN வைக்க ›', style: sans(14, color: C.navy, weight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
