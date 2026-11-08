import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import 'links.dart';
import 'main.dart';
import 'ui.dart';

/// Captures the widget under [key] as a PNG and opens the phone's share sheet (WhatsApp etc.).
Future<void> shareImage(BuildContext context, GlobalKey key, String text, String file) async {
  try {
    final b = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) throw 'no card';
    final img = await b.toImage(pixelRatio: 3);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw 'no data';
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(data.buffer.asUint8List(), mimeType: 'image/png', name: file)],
      text: text,
    ));
  } catch (_) {
    if (context.mounted) shareWhatsApp(context, text); // fallback: text only
  }
}

String passbookText() =>
    'சுப்புலட்சுமி தங்க மாளிகை · ${Demo.scheme} திட்டம்\nபெயர்: ${Demo.name}\nமொத்த சேமிப்பு: ${rupees(Demo.total)}\nதவணை: ${Demo.paidCount}/${Demo.months}${Demo.grams ? '\nதங்கம்: ${Demo.gramsTotal.toStringAsFixed(3)} கி' : ''}';

/// Static coin row for the share images (no animation, so the capture is complete).
Widget _coins(double size) => Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
      for (var i = 0; i < Demo.months; i++)
        i < Demo.paidCount
            ? SizedBox(width: size, height: size, child: coinImage(silver: Demo.silver))
            : Container(
                width: size,
                height: size,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF7F2E6), border: Border.all(color: C.line2)),
              ),
    ]);

/// Passbook summary as a picture card.
class PassbookCard extends StatelessWidget {
  const PassbookCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: 340,
        decoration: BoxDecoration(color: C.ivory, borderRadius: BorderRadius.circular(22), border: Border.all(color: C.goldLine)),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: double.infinity,
            decoration: velvetDeco(alignment: Alignment.topLeft),
            child: KolamBg(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(children: [
                  Image.asset('assets/logo.png', height: 46),
                  const SizedBox(height: 6),
                  Text('என் தங்க சேமிப்பு', style: sans(13, color: C.goldSoft, weight: FontWeight.w600).copyWith(letterSpacing: 1.2)),
                ]),
              ),
            ),
          ),
          Container(height: 2, color: C.gold),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(children: [
              Text(Demo.name, style: serif(18)),
              Text('${Demo.scheme} திட்டம்', style: sans(13, color: C.mute)),
              const SizedBox(height: 10),
              Text(rupees(Demo.total), style: serif(40, weight: FontWeight.w700, height: 1.2)),
              if (Demo.grams) Text('${Demo.gramsTotal.toStringAsFixed(3)} கிராம் தங்கம்', style: sans(14, color: C.goldText, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              _coins(30),
              const SizedBox(height: 10),
              Text('${Demo.paidCount} / ${Demo.months} ${Demo.silver ? 'மாதம்' : 'தவணை'} · நகை வாங்கலாம்: ${Demo.buyMonth}', textAlign: TextAlign.center, style: sans(12.5, color: C.mute)),
            ]),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: const Color(0xFFF6EEDC),
            child: Text('சுப்புலட்சுமி தங்க மாளிகை · புளியங்குடி · 97919 18344', textAlign: TextAlign.center, style: sans(11.5, color: C.goldText, weight: FontWeight.w600)),
          ),
        ]),
      );
}

/// Completion greeting card (all installments paid). A greeting only, not a receipt.
class CertificateCard extends StatelessWidget {
  const CertificateCard({super.key});
  @override
  Widget build(BuildContext context) {
    final ps = Demo.payments;
    final last = ps.isEmpty ? '' : ps.first[1] as String;
    return Container(
      width: 340,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: C.navy2, borderRadius: BorderRadius.circular(22)),
      child: Container(
        decoration: velvetDeco(radius: BorderRadius.circular(16), alignment: Alignment.center, frame: Border.all(color: C.gold, width: 1.5)),
        clipBehavior: Clip.antiAlias,
        child: KolamBg(
          festive: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image.asset('assets/logo.png', height: 50),
              const SizedBox(height: 12),
              Text('சேமிப்பு நிறைவு', style: serif(26, color: C.goldSoft, weight: FontWeight.w700)),
              Text('வாழ்த்து அட்டை', style: sans(12, color: C.navyMute).copyWith(letterSpacing: 2)),
              const SizedBox(height: 14),
              Container(
                width: 92,
                height: 92,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, color: C.goldSoft, boxShadow: [BoxShadow(color: C.gold.withValues(alpha: .5), blurRadius: 24)]),
                child: coinImage(silver: Demo.silver),
              ),
              const SizedBox(height: 14),
              Text(Demo.name, textAlign: TextAlign.center, style: serif(22, color: Colors.white, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('${Demo.scheme} திட்டத்தின் ${Demo.months} தவணைகளையும்\nவெற்றிகரமாக நிறைவு செய்துள்ளார்', textAlign: TextAlign.center, style: sans(14, color: C.navyMute, height: 1.6)),
              const SizedBox(height: 12),
              Text(rupees(Demo.total), style: serif(32, color: C.goldSoft, weight: FontWeight.w700)),
              if (Demo.grams) Text('${Demo.gramsTotal.toStringAsFixed(3)} கிராம் தங்கம்', style: sans(14, color: C.goldSoft, weight: FontWeight.w700)),
              if (last.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('நிறைவு: $last', style: sans(12.5, color: C.navyMute)),
              ],
              const SizedBox(height: 14),
              Text('🎉 வாழ்த்துகள்! 🎉', style: sans(16, color: Colors.white, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0x66E5C98B)),
              const SizedBox(height: 8),
              Text('சுப்புலட்சுமி தங்க மாளிகை · புளியங்குடி', style: sans(12, color: C.goldSoft, weight: FontWeight.w600)),
              Text('இது வாழ்த்து அட்டை மட்டும்; கணக்கு விவரம் கடை ரசீதில்', style: sans(10.5, color: C.navyMute)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Preview page: the picture card + share buttons.
class ShareCardPage extends StatefulWidget {
  const ShareCardPage({super.key, this.certificate = false});
  final bool certificate;
  @override
  State<ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends State<ShareCardPage> {
  final key = GlobalKey();
  bool busy = false;

  String get _text => widget.certificate
      ? 'சுப்புலட்சுமி தங்க மாளிகை · ${Demo.scheme} திட்டம்\n${Demo.name} அவர்கள் ${Demo.months} தவணைகளையும் நிறைவு செய்தார்கள் 🎉\nமொத்த சேமிப்பு: ${rupees(Demo.total)}'
      : passbookText();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: widget.certificate ? C.navy2 : C.ivory,
        appBar: AppBar(
          backgroundColor: widget.certificate ? C.navy2 : C.paper,
          surfaceTintColor: Colors.transparent,
          foregroundColor: widget.certificate ? C.goldSoft : C.navy,
          title: Text(widget.certificate ? 'நிறைவு வாழ்த்து அட்டை' : 'Passbook பகிர', style: sans(16.5, color: widget.certificate ? Colors.white : C.ink, weight: FontWeight.w700)),
        ),
        body: Stack(children: [
          ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.9, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: FittedBox(
                  child: RepaintBoundary(key: key, child: widget.certificate ? const CertificateCard() : const PassbookCard()),
                ),
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(busy ? 'தயாராகிறது…' : 'படமாக பகிர் (WhatsApp)', gold: widget.certificate, icon: Icons.share_outlined, busy: busy, onTap: () async {
              if (busy) return;
              setState(() => busy = true);
              await shareImage(context, key, _text, widget.certificate ? 'stm_vazhthu.png' : 'stm_passbook.png');
              if (mounted) setState(() => busy = false);
            }),
            const SizedBox(height: 10),
            OutlineBtn('எழுத்தாக மட்டும் அனுப்பு', light: widget.certificate, onTap: () => shareWhatsApp(context, _text)),
          ]),
          if (widget.certificate) const Positioned.fill(child: GoldConfetti()),
        ]),
      );
}
