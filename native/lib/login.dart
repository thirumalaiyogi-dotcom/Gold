import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home.dart';
import 'main.dart';
import 'ui.dart';

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
            gradient: RadialGradient(center: Alignment(0, .1), radius: .8, colors: [Color(0xFF173B78), C.navy]),
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
            padding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
            decoration: primary
                ? BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x99C9A24A)))
                : null,
            child: Row(children: [
              RingIcon(icon, size: 48, color: primary ? C.goldSoft : C.navy, ring: primary ? const Color(0x99C9A24A) : C.goldLine, bg: Colors.transparent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: sans(16, color: primary ? Colors.white : C.navy, weight: FontWeight.w700)),
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

    return _LoginFrame(
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 30, 24, 24), children: [
        Text('வணக்கம், வருக!', style: serif(26)),
        const SizedBox(height: 6),
        Text('உங்க தங்க சேமிப்பை பார்க்கவோ, புது திட்டங்களை தெரிஞ்சுக்கவோ கீழே தேர்ந்தெடுங்க.', style: sans(14.5, color: C.mute, height: 1.6)),
        const SizedBox(height: 22),
        option(
          icon: Icons.lock_outline,
          title: 'என் சேமிப்பு (Passbook)',
          sub: 'mPIN போட்டு உள்ளே போங்க',
          primary: true,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MobileScreen())),
        ),
        const SizedBox(height: 12),
        option(
          icon: Icons.diamond_outlined,
          title: 'திட்டங்களை மட்டும் பார்க்க',
          sub: 'Login இல்லாமல்',
          primary: false,
          onTap: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false),
        ),
        const SizedBox(height: 26),
        Center(child: Text('மாதிரி app · Test data மட்டும்', style: sans(12, color: C.mute))),
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
    Widget tile(IconData i, String t, String msg) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: C.paper,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: C.line2)),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => showNote(context, msg),
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
      tile(Icons.chat_outlined, 'WhatsApp', 'மாதிரி: கடையின் WhatsApp திறக்கும்'),
      tile(Icons.info_outline, 'எங்களைப் பற்றி', 'மாதிரி: கடை விவரப் பக்கம்'),
      tile(Icons.call_outlined, 'அழைக்க', 'மாதிரி: 97919 18344 அழைக்கும்'),
      tile(Icons.place_outlined, 'வழி காட்டு', 'மாதிரி: Google Maps திறக்கும்'),
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

  void _next() {
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
      HapticFeedback.heavyImpact();
      setState(() {
        err = 'சரியான 10 இலக்க மொபைல் எண் போடுங்க';
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
          child: Center(child: Text(shown, style: sans(24, color: v.isEmpty ? const Color(0xFFB7BFCD) : C.navy, weight: FontWeight.w600))),
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
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      if (v == Demo.pin) {
        HapticFeedback.mediumImpact();
        app.login(widget.mobile);
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
          err = 'mPIN தவறு. (மாதிரி app-ல mPIN: 123456)';
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
        const SizedBox(height: 14),
        Shake(trigger: shake, child: _Dots(v.length)),
        SizedBox(height: 26, child: Center(child: Text(err, style: sans(12.5, color: C.red)))),
        KeyPad(onKey: _key),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => showNote(context, 'மாதிரி: Telegram OTP மூலம் புது mPIN'),
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

  void _save() {
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
    HapticFeedback.mediumImpact();
    showNote(context, 'மாதிரி: mPIN அமைக்கப்பட்டது ✓ (உண்மையில் சேமிக்கப்படவில்லை)');
    Navigator.of(context).pop();
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
        PrimaryButton('mPIN அமை', onTap: _save),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () => showNote(context, 'மாதிரி: Telegram OTP வழி'),
            child: Text('Code வரலையா? Telegram OTP மூலம் mPIN வைக்க ›', style: sans(14, color: C.navy, weight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
