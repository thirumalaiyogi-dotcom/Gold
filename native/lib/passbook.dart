import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';
import 'ui.dart';

class PaymentRow extends StatelessWidget {
  const PaymentRow(this.p, {super.key, this.last = false, this.receipt = false});
  final List<Object> p;
  final bool last;
  final bool receipt;
  @override
  Widget build(BuildContext context) {
    final n = p[0] as String, date = p[1] as String, amt = p[2] as int, g = p[3] as double;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFF0EADB)))),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.goldLine)),
          child: Text(n, style: serif(16, color: C.goldText)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: rupees(amt), style: serif(16.5)),
              TextSpan(text: '  ${g.toStringAsFixed(3)} கி', style: sans(12.5, color: C.goldText, weight: FontWeight.w600)),
            ])),
            const SizedBox(height: 2),
            Text.rich(TextSpan(children: [
              TextSpan(text: '$date · ', style: sans(12.5, color: C.mute)),
              TextSpan(text: '✓ செலுத்தியது', style: sans(12.5, color: C.green, weight: FontWeight.w600)),
            ])),
          ]),
        ),
        if (receipt)
          OutlinedButton(
            onPressed: () => showNote(context, 'மாதிரி: தவணை $n ரசீது'),
            style: OutlinedButton.styleFrom(
              foregroundColor: C.navy,
              side: const BorderSide(color: Color(0xFFC9CFDB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(0, 40),
            ),
            child: Text('ரசீது', style: sans(13, color: C.navy, weight: FontWeight.w600)),
          ),
      ]),
    );
  }
}

class PassbookTab extends StatefulWidget {
  const PassbookTab({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  State<PassbookTab> createState() => _PassbookTabState();
}

class _PassbookTabState extends State<PassbookTab> {
  int sub = 0;

  int get paid => Demo.payments.length;
  int get total => Demo.payments.fold(0, (s, p) => s + (p[2] as int));
  double get grams => Demo.payments.fold(0.0, (s, p) => s + (p[3] as double));

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Column(children: [
      Container(
        padding: EdgeInsets.fromLTRB(12, top + 8, 12, 12),
        decoration: const BoxDecoration(color: C.navy, border: Border(bottom: BorderSide(color: C.gold, width: 2))),
        child: Row(children: [
          IconButton(
            onPressed: widget.onBack,
            tooltip: 'முகப்பு',
            style: IconButton.styleFrom(side: const BorderSide(color: Color(0x8CC9A24A))),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: C.goldSoft),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Passbook', style: serif(22, color: Colors.white)),
              Text('உங்கள் சேமிப்புப் பயணம்', style: sans(12.5, color: C.navyMute)),
            ]),
          ),
          IconButton(
            onPressed: () => showNote(context, 'மாதிரி: Passbook PDF'),
            tooltip: 'Passbook PDF',
            style: IconButton.styleFrom(side: const BorderSide(color: Color(0x8CC9A24A))),
            icon: const Icon(Icons.download_outlined, color: C.goldSoft),
          ),
        ]),
      ),
      Container(
        color: C.paper,
        child: Row(children: [
          for (final (i, t) in const [(0, 'சேமிப்பு'), (1, 'என் விவரம்'), (2, 'Referral')])
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => sub = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: sub == i ? C.gold : C.line2, width: sub == i ? 2.5 : 1))),
                  child: Text(t, style: sans(14.5, color: sub == i ? C.navy : C.mute, weight: sub == i ? FontWeight.w700 : FontWeight.w400)),
                ),
              ),
            ),
        ]),
      ),
      Expanded(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey(sub), child: [_savings(context), _me(context), _referral(context)][sub]),
        ),
      ),
    ]);
  }

  Widget _savings(BuildContext context) {
    final pct = paid / Demo.months;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
      LuxCard(
        inner: true,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(children: [
          Text('மொத்த சேமிப்பு', style: sans(12.5, color: C.goldText, weight: FontWeight.w600).copyWith(letterSpacing: 1)),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: total.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(rupees(v), style: serif(42, height: 1.25)),
          ),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'சேர்ந்த தங்கம் ', style: sans(14)),
            TextSpan(text: '${grams.toStringAsFixed(3)} கிராம்', style: sans(14, color: C.goldText, weight: FontWeight.w700)),
          ])),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: const Color(0xFFF0EADB), color: C.gold),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Text('$paid / ${Demo.months} தவணை', style: sans(12, color: C.mute)),
            const Spacer(),
            Text('${(pct * 100).round()}%', style: sans(12, color: C.mute)),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: C.line),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(children: [
              _stat('$paid', 'கட்டியது'),
              const VerticalDivider(width: 1, color: C.line),
              _stat('${Demo.months - paid}', 'மீதி'),
              const VerticalDivider(width: 1, color: C.line),
              _stat('${Demo.months}', 'மொத்தம்'),
            ]),
          ),
          const SizedBox(height: 10),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'நகை வாங்கலாம் : ', style: sans(13.5)),
            TextSpan(text: 'ஆகஸ்ட் 2027', style: sans(13.5, weight: FontWeight.w700)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      LuxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('அடுத்த தவணை (${paid + 1}/${Demo.months})', style: sans(13, color: C.mute)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0xFFE8B4AF))),
              child: Text('தாமதம்', style: sans(12, color: C.red, weight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(rupees(Demo.monthly), style: serif(30)),
            const Spacer(),
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('7 அக். 2026-க்குள்', style: sans(13, color: C.mute))),
          ]),
          const SizedBox(height: 12),
          PrimaryButton('${rupees(Demo.monthly)} இப்போ online-ல கட்டு', onTap: () => _demoPay(context)),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        _action(context, Icons.picture_as_pdf_outlined, 'PDF'),
        _action(context, Icons.receipt_long_outlined, 'ரசீது'),
        _action(context, Icons.share_outlined, 'பகிர்'),
        _action(context, Icons.list_alt, 'வரலாறு'),
      ]),
      const SizedBox(height: 20),
      const SectionTitle('தவணை விவரம்'),
      LuxCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [for (final p in Demo.payments) PaymentRow(p, last: p == Demo.payments.last, receipt: true)]),
      ),
    ]);
  }

  Widget _stat(String v, String l) => Expanded(
        child: Column(children: [
          Text(v, style: serif(22)),
          Text(l, style: sans(12, color: C.mute)),
        ]),
      );

  Widget _action(BuildContext context, IconData i, String t) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: C.paper,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: C.line)),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => showNote(context, 'மாதிரி: $t'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(children: [
                  Icon(i, color: C.navy, size: 22),
                  const SizedBox(height: 6),
                  Text(t, style: sans(12)),
                ]),
              ),
            ),
          ),
        ),
      );

  void _demoPay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .4, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: C.green),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 12),
            Text('${rupees(Demo.monthly)} சேமிப்பில் சேர்ந்தது ✓', style: serif(20)),
            const SizedBox(height: 6),
            Text('இது மாதிரி மட்டும். உண்மையான payment நடக்கல.', style: sans(13.5, color: C.mute)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: PrimaryButton('சரி', onTap: () => Navigator.of(ctx).pop())),
          ]),
        ),
      ),
    );
    HapticFeedback.mediumImpact();
  }

  Widget _me(BuildContext context) {
    final m = app.mobile;
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            SizedBox(width: 130, child: Text(k, style: sans(13.5, color: C.mute))),
            Expanded(child: Text(v, style: sans(14.5, weight: FontWeight.w600))),
          ]),
        );
    return ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
      LuxCard(
        child: Column(children: [
          Row(children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.gold, width: 1.5)),
              child: Text(Demo.name.characters.first, style: serif(24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Demo.name, style: serif(20)),
                Text('${Demo.scheme} திட்டம்', style: sans(13, color: C.mute)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          const Divider(color: C.line),
          row('மொபைல்', m.length == 10 ? '+91 ${m.substring(0, 5)} ${m.substring(5)}' : '—'),
          row('உறுப்பினர் எண்', Demo.member),
          row('சேர்ந்த நாள்', '1 ஆக. 2026'),
          row('வாரிசுதாரர்', 'மாதிரி பெயர்'),
        ]),
      ),
      const SizedBox(height: 16),
      LuxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('கணக்கை நீக்க கோரிக்கை', style: serif(17)),
          const SizedBox(height: 6),
          Text('உங்கள் கணக்கையும் தகவல்களையும் நீக்க கடைக்கு கோரிக்கை அனுப்பலாம். கடை உங்களை அழைத்து உறுதி செய்யும்.', style: sans(13.5, color: C.mute, height: 1.6)),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: () => showNote(context, 'மாதிரி: WhatsApp கோரிக்கை', ok: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.red,
                side: const BorderSide(color: C.red, width: 1.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('கணக்கை நீக்க கோரிக்கை அனுப்பு', style: sans(14.5, color: C.red, weight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _referral(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
        LuxCard(
          inner: true,
          padding: const EdgeInsets.all(22),
          child: Column(children: [
            const RingIcon(Icons.card_giftcard, size: 60),
            const SizedBox(height: 10),
            Text('நண்பரை சேர்க்க', style: serif(21)),
            const SizedBox(height: 6),
            Text('உங்க code-ல நண்பர் சேர்ந்து முதல் தவணை கட்டியதும், இரண்டு பேருக்கும் தள்ளுபடி.', style: sans(13.5, color: C.mute, height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: C.goldLine), color: const Color(0xFFFFF7E0)),
              child: Text(Demo.member, style: serif(26, color: C.goldText).copyWith(letterSpacing: 4)),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: PrimaryButton('WhatsApp-ல் பகிர்', icon: Icons.share_outlined, onTap: () => showNote(context, 'மாதிரி: பகிர்'))),
          ]),
        ),
      ]);
}
