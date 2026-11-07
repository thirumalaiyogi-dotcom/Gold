import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'links.dart';
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
              if (g > 0) TextSpan(text: '  ${g.toStringAsFixed(3)} கி', style: sans(12.5, color: C.goldText, weight: FontWeight.w600)),
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
            onPressed: () => showReceipt(context, n, date, amt, g),
            style: OutlinedButton.styleFrom(
              foregroundColor: C.navy,
              side: const BorderSide(color: Color(0xFFE2D6BE)),
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

  int get paid => Demo.paidCount;
  int get total => Demo.total;
  double get grams => Demo.gramsTotal;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return AnimatedBuilder(animation: app, builder: (context, _) => Column(children: [
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
            onPressed: () => openLink(context, Api.site),
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
    ]));
  }

  Widget _savings(BuildContext context) {
    final pct = (paid / Demo.months).clamp(0.0, 1.0);
    final left = (Demo.months - paid).clamp(0, 99);
    final done = left == 0 && !(Demo.silver && Demo.paidThisMonth);
    final day = nowIst().day;
    final st = Demo.paidThisMonth
        ? (Demo.silver ? 'இந்த மாசம் சேமிச்சாச்சு' : 'செலுத்தியாச்சு')
        : paid == 0
            ? 'முதல் தவணை'
            : day <= 7
                ? 'நிலுவையில்'
                : 'தாமதம்';
    final stColor = Demo.paidThisMonth ? C.green : (st == 'தாமதம்' ? C.red : C.goldText);
    final canPay = !done && (!Demo.paidThisMonth || Demo.silver);
    return RefreshIndicator(color: C.navy, onRefresh: app.refreshPassbook, child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
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
          if (Demo.grams)
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
            Text('$paid / ${Demo.months} ${Demo.silver ? 'மாதம்' : 'தவணை'}', style: sans(12, color: C.mute)),
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
              _stat('$left', 'மீதி'),
              const VerticalDivider(width: 1, color: C.line),
              _stat('${Demo.months}', 'மொத்தம்'),
            ]),
          ),
          const SizedBox(height: 10),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'நகை வாங்கலாம் : ', style: sans(13.5)),
            TextSpan(text: Demo.buyMonth, style: sans(13.5, weight: FontWeight.w700)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      LuxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(done ? 'திட்டம்' : (Demo.paidThisMonth && !Demo.silver ? 'அடுத்த தவணை (${paid + 1}/${Demo.months})' : 'தவணை (${Demo.paidThisMonth ? paid : paid + 1}/${Demo.months})'), style: sans(13, color: C.mute))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: stColor.withValues(alpha: .45))),
              child: Text(done ? 'முடிந்தது ✓' : st, style: sans(12, color: done ? C.green : stColor, weight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(child: Text(done ? 'எல்லா தவணையும் முடிந்தது' : (Demo.fixed ? rupees(Demo.monthly) : (Demo.silver ? '₹100 முதல்' : 'உங்க விருப்பத் தொகை')), style: serif(done || !Demo.fixed ? 20 : 30))),
            const SizedBox(width: 8),
            if (!done) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(Demo.dueText, style: sans(13, color: C.mute))),
          ]),
          if (canPay) ...[
            const SizedBox(height: 12),
            PrimaryButton('Online-ல கட்டு', icon: Icons.open_in_new, onTap: () => _pay(context)),
          ],
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
        child: Demo.payments.isEmpty
            ? Padding(padding: const EdgeInsets.all(18), child: Text('இன்னும் தவணை எதுவும் இல்லை. முதல் தவணை கட்டியதும் இங்கே தெரியும்.', style: sans(13.5, color: C.mute, height: 1.6)))
            : Builder(builder: (_) {
                final ps = Demo.payments;
                return Column(children: [for (var i = 0; i < ps.length; i++) PaymentRow(ps[i], last: i == ps.length - 1, receipt: true)]);
              }),
      ),
    ]));
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
              onTap: () => t == 'பகிர்' ? shareWhatsApp(context, _shareText()) : t == 'PDF' ? openLink(context, Api.site) : showNote(context, 'கீழே உள்ள தவணை விவரத்தில் ஒவ்வொரு தவணைக்கும் ரசீது இருக்கு'),
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

  String _shareText() =>
      'சுப்புலட்சுமி தங்க மாளிகை · ${Demo.scheme} திட்டம்\nபெயர்: ${Demo.name}\nமொத்த சேமிப்பு: ${rupees(Demo.total)}\nதவணை: ${Demo.paidCount}/${Demo.months}${Demo.grams ? '\nதங்கம்: ${Demo.gramsTotal.toStringAsFixed(3)} கி' : ''}';

  /// Online payment runs on the website (same Cashfree flow, same database checks).
  void _pay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Center(child: RingIcon(Icons.lock_outline, size: 60)),
            const SizedBox(height: 12),
            Text('பாதுகாப்பான online payment', textAlign: TextAlign.center, style: serif(20)),
            const SizedBox(height: 6),
            Text('Payment எங்கள் website-ல Cashfree மூலம் நடக்கும். அங்கே உங்க மொபைல் எண் + mPIN போட்டு Passbook-ல் "online-ல கட்டு" அழுத்துங்க. பணம் வந்ததும் இந்த app-லயும் தானா தெரியும்.',
                textAlign: TextAlign.center, style: sans(13.5, color: C.mute, height: 1.6)),
            const SizedBox(height: 16),
            PrimaryButton('Website திறக்க', icon: Icons.open_in_new, onTap: () {
              Navigator.of(ctx).pop();
              openLink(context, Api.site);
            }),
          ]),
        ),
      ),
    );
  }

  // ignore: unused_element
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
          row('சேர்ந்த நாள்', taDate((app.pb?['start'] ?? '').toString())),
          row('நகை வாங்கலாம்', Demo.buyMonth),
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
              onPressed: () => whatsApp(context, 'வணக்கம், என் கணக்கையும் தகவல்களையும் நீக்க கோரிக்கை.\nபெயர்: ${Demo.name}\nமொபைல்: ${app.mobile}'),
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
            Text('உங்க code-ஐ நண்பருக்கு அனுப்புங்க. அவங்க சேரும்போது இந்த code-ஐ கொடுத்தா உங்களுக்கு பரிசு. விவரம் கடையில்.', style: sans(13.5, color: C.mute, height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: C.goldLine), color: const Color(0xFFFFF7E0)),
              child: Text(Demo.member.isEmpty ? '—' : Demo.member, style: serif(26, color: C.goldText).copyWith(letterSpacing: 4)),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: PrimaryButton('WhatsApp-ல் பகிர்', icon: Icons.share_outlined, onTap: () => shareWhatsApp(context, 'சுப்புலட்சுமி தங்க மாளிகை தங்க சேமிப்புத் திட்டத்தில் சேருங்க! சேரும்போது என் code ${Demo.member} கொடுங்க.\n${Api.site}'))),
          ]),
        ),
      ]);
}


void showReceipt(BuildContext context, String n, String date, int amt, double g) {
  showModalBottomSheet(
    context: context,
    backgroundColor: C.ivory,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Image.asset('assets/logo.png', height: 52)),
          const SizedBox(height: 8),
          Text('தவணை ரசீது', textAlign: TextAlign.center, style: serif(20)),
          const Divider(height: 24, color: C.line),
          for (final r in [
            ['பெயர்', Demo.name],
            ['திட்டம்', Demo.scheme],
            ['தவணை எண்', Demo.silver ? n : '$n / ${Demo.months}'],
            ['தேதி', date],
            ['தொகை', rupees(amt)],
            if (g > 0) ['தங்கம்', '${g.toStringAsFixed(3)} கிராம்'],
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(width: 110, child: Text(r[0], style: sans(13.5, color: C.mute))),
                Expanded(child: Text(r[1], style: sans(14.5, weight: FontWeight.w700))),
              ]),
            ),
          const SizedBox(height: 14),
          PrimaryButton('WhatsApp-ல் பகிர்', icon: Icons.share_outlined, onTap: () {
            Navigator.of(ctx).pop();
            shareWhatsApp(context, 'சுப்புலட்சுமி தங்க மாளிகை · தவணை ரசீது\n${Demo.name} · ${Demo.scheme}\nதவணை $n · $date\nதொகை ${rupees(amt)}${g > 0 ? '\nதங்கம் ${g.toStringAsFixed(3)} கி' : ''}');
          }),
        ]),
      ),
    ),
  );
}
