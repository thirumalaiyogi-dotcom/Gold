import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';
import 'ui.dart';

/// First screen decider: gold splash, then intro slides once, then the welcome screen.
class Boot extends StatefulWidget {
  const Boot({super.key});
  @override
  State<Boot> createState() => _BootState();
}

class _BootState extends State<Boot> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    final r = await Future.wait([_seenIntro(), Future.delayed(const Duration(milliseconds: 1700), () => true)]);
    if (!mounted) return;
    final seen = r[0];
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => seen ? const WelcomeScreen() : const Onboarding(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.navy,
        body: KolamBg(
          child: SizedBox.expand(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, child) => Opacity(opacity: v, child: Transform.scale(scale: .85 + v * .15, child: child)),
                child: GoldShine(delay: const Duration(milliseconds: 650), child: Image.asset('assets/logo.png', width: 210)),
              ),
              const SizedBox(height: 18),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (_, v, child) => Opacity(opacity: v, child: child),
                child: Text('சுப்புலட்சுமி தங்க மாளிகை · புளியங்குடி', style: sans(14, color: C.goldSoft, weight: FontWeight.w600).copyWith(letterSpacing: 1)),
              ),
            ]),
          ),
        ),
      );
}

Future<bool> _seenIntro() async {
  try {
    return (await SharedPreferences.getInstance()).getBool('ob_seen') ?? false;
  } catch (_) {
    return true;
  }
}

/// 4 intro slides — same content as the website's first-open slides.
class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final pc = PageController();
  int page = 0;
  static const n = 4;

  Future<void> _done() async {
    try {
      await (await SharedPreferences.getInstance()).setBool('ob_seen', true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => const WelcomeScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  TextStyle get _h => serif(28, color: C.goldSoft, weight: FontWeight.w700).copyWith(height: 1.35);

  Widget _slide1() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: .6, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (_, v, c) => Transform.scale(scale: v, child: c),
          child: Container(
            width: 150,
            height: 150,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(shape: BoxShape.circle, color: C.goldSoft, boxShadow: [BoxShadow(color: C.gold.withValues(alpha: .45), blurRadius: 40)]),
            child: ClipOval(child: Image.asset('assets/coin.png', fit: BoxFit.cover)),
          ),
        ),
        const SizedBox(height: 34),
        Text('11 மாதம் சேமியுங்கள்,\n12 ஆம் மாதம்\nதங்க நகையாக வாங்குங்கள்', textAlign: TextAlign.center, style: _h),
        const SizedBox(height: 18),
        Text('தங்கநகை சேமிப்புத் திட்டம்', style: sans(16, color: Colors.white, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('தனலட்சுமி · குபேரலட்சுமி', style: sans(14.5, color: C.navyMute)),
      ]);

  Widget _slide2() {
    Widget b(String big, String small) => Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x66C9A45C)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            FittedBox(child: Text(big, style: serif(26, color: C.goldSoft, weight: FontWeight.w700))),
            const SizedBox(height: 6),
            Text(small, textAlign: TextAlign.center, style: sans(13.5, color: Colors.white, height: 1.4)),
          ]),
        );
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('உங்களுக்கான\nசலுகைகள்', textAlign: TextAlign.center, style: _h),
      const SizedBox(height: 26),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
        children: [
          b('₹1,000', 'முதல் சேமிக்கலாம்'),
          b('11 மாதம்', 'எளிய தவணை'),
          b('0 சேதாரம்', 'செய்கூலி தள்ளுபடி'),
          b('GST இல்லை', 'தங்க காயினுக்கு'),
        ],
      ),
    ]);
  }

  Widget _slide3() {
    Widget step(int i, String t) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [C.goldSoft, C.gold])),
              child: Text('$i', style: serif(20, color: C.navy, weight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(t, style: sans(15.5, color: Colors.white, weight: FontWeight.w600, height: 1.5))),
          ]),
        );
    return Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('எப்படி\nவேலை செய்யும்?', textAlign: TextAlign.center, style: _h),
      const SizedBox(height: 30),
      step(1, 'கடையில் சேர்ந்து Passbook பெறுங்க'),
      step(2, 'மாதம் 1 முதல் 7 ஆம் தேதிக்குள் தவணை கட்டுங்க'),
      step(3, '12 வது மாதம் நகை / காயின் வாங்குங்கள்'),
    ]);
  }

  Widget _slide4() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('உங்க Passbook\nமொபைல்ல', textAlign: TextAlign.center, style: _h),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: C.ivory, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 10))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('மொத்த சேமிப்பு', style: sans(13, color: C.goldText, weight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: C.goldLine)),
                child: Text('மாதிரி', style: sans(11, color: C.goldText)),
              ),
            ]),
            const SizedBox(height: 4),
            Text('₹ — —', style: serif(30, color: C.navy, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: const LinearProgressIndicator(value: 3 / 11, minHeight: 8, backgroundColor: Color(0xFFF1E9D8), color: C.gold)),
            const SizedBox(height: 8),
            Text('தவணை 3/11 · நகை வாங்கலாம்: மாதம்', style: sans(12.5, color: C.mute)),
          ]),
        ),
        const SizedBox(height: 22),
        for (final t in ['சேமிப்பு எவ்வளவு', 'எத்தனை தவணை', 'இன்றைய தங்க விலை'])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_circle, color: C.goldSoft, size: 20),
              const SizedBox(width: 8),
              Text(t, style: sans(15, color: Colors.white, weight: FontWeight.w600)),
            ]),
          ),
      ]);

  @override
  Widget build(BuildContext context) {
    final last = page == n - 1;
    return Scaffold(
      backgroundColor: C.navy,
      body: Container(
        decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, -.3), radius: 1.1, colors: [Color(0xFF8A2333), C.navy, C.navy2])),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: last ? 0 : 1,
                child: TextButton(onPressed: last ? null : _done, child: Text('Skip', style: sans(15, color: C.goldSoft, weight: FontWeight.w600))),
              ),
            ),
            Expanded(
              child: PageView(
                controller: pc,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => page = i);
                },
                children: [
                  for (final w in [_slide1(), _slide2(), _slide3(), _slide4()])
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * .62),
                        child: w,
                      ),
                    ),
                ],
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < n; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == page ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(color: i == page ? C.goldSoft : const Color(0x55E5C98B), borderRadius: BorderRadius.circular(99)),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: C.goldSoft, foregroundColor: C.navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () => last ? _done() : pc.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic),
                  child: Text(last ? 'தொடங்குவோம்' : 'அடுத்து', style: sans(16.5, color: C.navy, weight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
