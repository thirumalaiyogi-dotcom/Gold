import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'links.dart';
import 'main.dart';
import 'ui.dart';
import 'pay.dart';
import 'share_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentRow extends StatelessWidget {
  const PaymentRow(this.p, {super.key, this.last = false, this.receipt = false});
  final List<Object> p;
  final bool last;
  final bool receipt;
  @override
  Widget build(BuildContext context) {
    final n = p[0] as String, date = p[1] as String, amt = p[2] as int, g = p[3] as double;
    final row = Container(
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
            Row(children: [
              Flexible(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: rupees(amt), style: serif(16.5)),
                  if (g > 0) TextSpan(text: '  ${g.toStringAsFixed(3)} கி', style: sans(12.5, color: C.goldText, weight: FontWeight.w600)),
                ])),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFE6F3EC), borderRadius: BorderRadius.circular(99)),
                child: Text('✓ செலுத்தியது', style: sans(11.5, color: C.green, weight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(date, style: sans(12.5, color: C.mute)),
          ]),
        ),
        if (receipt) ...[
          const SizedBox(width: 6),
          Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.receipt_long_outlined, size: 20, color: C.navy),
            Text('ரசீது', style: sans(11.5, color: C.navy, weight: FontWeight.w600)),
          ]),
        ],
      ]),
    );
    if (!receipt) return row;
    // the whole row opens the receipt (design audit: no button on every line)
    return InkWell(onTap: () => showReceipt(context, n, date, amt, g), child: row);
  }
}

class PassbookTab extends StatefulWidget {
  const PassbookTab({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  State<PassbookTab> createState() => _PassbookTabState();
}

class _PassbookTabState extends State<PassbookTab> {
  int get paid => Demo.paidCount;
  int get total => Demo.total;
  double get grams => Demo.gramsTotal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCertificate());
  }

  /// First time a customer finishes every installment, open the greeting card once.
  Future<void> _maybeCertificate() async {
    if (app.demoPb != null || !app.loggedIn || Demo.silver || !Demo.schemeDone || Demo.paidCount == 0) return;
    try {
      final sp = await SharedPreferences.getInstance();
      final k = 'cert_${app.mobile}_${Demo.schemeKey}_${(app.pb?['start'] ?? '')}';
      if (sp.getBool(k) == true || !mounted) return;
      await sp.setBool(k, true);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShareCardPage(certificate: true)));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return AnimatedBuilder(animation: app, builder: (context, _) => Column(children: [
      Container(
        decoration: velvetDeco(border: const Border(bottom: BorderSide(color: C.gold, width: 2))),
        child: KolamBg(child: Padding(
        padding: EdgeInsets.fromLTRB(12, top + 8, 12, 12),
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
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShareCardPage())),
            tooltip: 'பகிர்',
            style: IconButton.styleFrom(side: const BorderSide(color: Color(0x8CC9A24A))),
            icon: const Icon(Icons.share_outlined, color: C.goldSoft),
          ),
        ]),
      ))),
      Expanded(child: _savings(context)),
      // one-hand use: the pay coin stays at the bottom, in thumb reach
      if (Demo.canPay)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: C.paper,
            border: Border(top: BorderSide(color: C.line)),
            boxShadow: [BoxShadow(color: Color(0x146E1423), blurRadius: 16, offset: Offset(0, -4))],
          ),
          child: SwipeToPay(
            label: 'தவணை செலுத்த',
            amount: Demo.fixed ? rupees(Demo.monthly) : null,
            silver: Demo.silver,
            onDone: () => _pay(context),
          ),
        ),
    ]));
  }

  Widget _savings(BuildContext context) {
    final left = (Demo.months - paid).clamp(0, 99);
    final done = Demo.schemeDone;
    final day = nowIst().day;
    final st = Demo.paidThisMonth
        ? (Demo.silver ? 'இந்த மாசம் சேமிச்சாச்சு' : 'செலுத்தியாச்சு')
        : paid == 0
            ? 'முதல் தவணை'
            : day <= 7
                ? 'நிலுவையில்'
                : 'தாமதம்';
    final stColor = Demo.paidThisMonth ? C.green : (st == 'தாமதம்' ? C.red : C.goldText);
    final canPay = Demo.canPay;
    return RefreshIndicator(color: C.navy, onRefresh: app.refreshPassbook, child: ListView(padding: const EdgeInsets.fromLTRB(16, 22, 16, 28), children: [
      LuxCard(
        inner: true,
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
        child: Column(children: [
          Text('மொத்த சேமிப்பு', style: sans(12, color: C.goldText, weight: FontWeight.w600).copyWith(letterSpacing: 1.6)),
          GoldShine(
            delay: const Duration(milliseconds: 1000),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: total.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(rupees(v), style: serif(46, height: 1.2, weight: FontWeight.w700)),
            ),
          ),
          if (Demo.grams)
            Text.rich(TextSpan(children: [
              TextSpan(text: 'சேர்ந்த தங்கம் ', style: sans(14)),
              TextSpan(text: '${grams.toStringAsFixed(3)} கிராம்', style: sans(14, color: C.goldText, weight: FontWeight.w700)),
            ])),
          const SizedBox(height: 14),
          const SizedBox(height: 4),
          CoinStack(total: Demo.months, paid: paid, silver: Demo.silver, labels: Demo.monthLabels),
          const SizedBox(height: 16),
          const Divider(height: 1, color: C.line),
          const SizedBox(height: 10),
          InfoBox(
            child: IntrinsicHeight(
              child: Row(children: [
                _stat('$paid', 'கட்டியது'),
                const VerticalDivider(width: 1, color: C.line2),
                _stat('$left', 'மீதி'),
                const VerticalDivider(width: 1, color: C.line2),
                _stat('${Demo.months}', 'மொத்தம்'),
              ]),
            ),
          ),
          // referral reward: a separate balance, not part of the savings total
          if (Demo.refCount > 0 || Demo.refEarned > 0) ...[
            const SizedBox(height: 10),
            Material(
              color: const Color(0xFFFFF7E0),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferralPage())),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: C.goldLine)),
                  child: Row(children: [
                    const Icon(Icons.card_giftcard, color: C.navy, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Refer பரிசு', maxLines: 1, style: sans(14, color: C.ink, weight: FontWeight.w700)),
                        Text(Demo.refPending > 0 ? '${Demo.refCount} நண்பர் · ${rupees(Demo.refPending)} வரவு வைக்க வேண்டியது' : '${Demo.refCount} நண்பர் · முழுதும் வரவு வைத்தாச்சு',
                            maxLines: 2, style: sans(12.5, color: C.mute)),
                      ]),
                    ),
                    Text(rupees(Demo.refEarned), style: serif(19, color: C.navy, weight: FontWeight.w700)),
                    const Icon(Icons.chevron_right, color: C.mute),
                  ]),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'நகை வாங்கலாம் : ', style: sans(13.5)),
            TextSpan(text: Demo.buyMonth, style: sans(13.5, weight: FontWeight.w700)),
          ])),
          if (done && !Demo.silver && paid > 0) ...[
            const SizedBox(height: 14),
            GoldShine(
              loop: true,
              child: PrimaryButton('🎉 நிறைவு வாழ்த்து அட்டை', gold: true, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShareCardPage(certificate: true)))),
            ),
          ],
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
          Text(done ? 'எல்லா தவணையும் முடிந்தது' : (Demo.fixed ? rupees(Demo.monthly) : (Demo.silver ? '₹100 முதல்' : 'உங்க விருப்பத் தொகை')), style: serif(done || !Demo.fixed ? 22 : 30)),
          if (!done) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.event_outlined, size: 16, color: C.mute),
              const SizedBox(width: 6),
              Expanded(child: Text(Demo.dueText, style: sans(13, color: C.mute))),
            ]),
          ],
          if (canPay) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.south_rounded, size: 16, color: C.goldText),
              const SizedBox(width: 6),
              Expanded(child: Text('கீழே உள்ள காசை வலப்பக்கம் இழுத்து செலுத்துங்க', style: sans(12.5, color: C.goldText, weight: FontWeight.w600))),
            ]),
          ],
        ]),
      ),
      const SizedBox(height: 20),
      const SectionTitle('தவணை வரலாறு'),
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


  /// Online payment runs on the website (same Cashfree flow, same database checks).
  Future<void> _pay(BuildContext context) async {
    if (app.demoPb != null) {
      showNote(context, 'இது மாதிரி Passbook. உண்மையான பணம் எதுவும் கட்டப்படாது.');
      return;
    }
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const PayPage()));
    if (ok == true) app.refreshPassbook();
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


Widget _page(String title, Widget body) => Builder(
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: C.paper, surfaceTintColor: C.paper, foregroundColor: C.navy, title: Text(title, style: sans(16.5, color: C.ink, weight: FontWeight.w700))),
        body: AnimatedBuilder(animation: app, builder: (_, __) => body),
      ),
    );

/// என் விவரம் — opened from the கணக்கு tab.
class MyDetailsPage extends StatelessWidget {
  const MyDetailsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final m = app.mobile;
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            SizedBox(width: 130, child: Text(k, style: sans(13.5, color: C.mute))),
            Expanded(child: Text(v, style: sans(14.5, weight: FontWeight.w600))),
          ]),
        );
    return _page('என் விவரம்', ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
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
    ]));
  }
}

/// Referral — opened from the கணக்கு tab.
Widget _refStat(String v, String l) => Expanded(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: serif(19, color: C.navy, weight: FontWeight.w700))),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(l, maxLines: 1, textAlign: TextAlign.center, style: sans(13, color: C.ink, weight: FontWeight.w600))),
      ]),
    );

Widget _refStep(String n, String t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 1, right: 10),
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: C.navy, shape: BoxShape.circle),
          child: Text(n, style: sans(12.5, color: Colors.white, weight: FontWeight.w700)),
        ),
        Expanded(child: Text(t, style: sans(13.5, color: C.ink, height: 1.6))),
      ]),
    );

class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});
  @override
  Widget build(BuildContext context) => _page('நண்பரை சேர்க்க', ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
        LuxCard(
          inner: true,
          padding: const EdgeInsets.all(22),
          child: Column(children: [
            const RingIcon(Icons.card_giftcard, size: 60),
            const SizedBox(height: 10),
            Text('நண்பரை சேர்க்க', style: serif(21)),
            const SizedBox(height: 6),
            Text('உங்கள் Reference Code-ஐ உங்களுடைய நண்பர்களுக்கு அனுப்புங்கள்.', style: sans(14.5, color: C.ink, weight: FontWeight.w600, height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: C.goldLine), color: const Color(0xFFFFF7E0)),
              child: Text(Demo.member.isEmpty ? '—' : Demo.member, style: serif(26, color: C.goldText).copyWith(letterSpacing: 4)),
            ),
            const SizedBox(height: 16),
            // how it works (wording from the company owner, 10 Nov 2026)
            InfoBox(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _refStep('1', 'உங்கள் Reference Code-ஐ நண்பருக்கு அனுப்புங்கள்.'),
                _refStep('2', 'அவர்கள் Digigold App-ல் சேரும்போது "Reference code" என்ற box-ல் உங்களுடைய code-ஐ கொடுக்க வேண்டும்.'),
                _refStep('3', 'உங்களுடைய நண்பர் செலுத்தும் முதல் தவணைத் தொகையில் ${Demo.refPct}% உங்களுடைய கணக்கில் பரிசுத் தொகையாக வரவு வைக்கப்படும்.'),
              ]),
            ),
            // live reward numbers from the passbook — shown once a friend has joined
            if (Demo.refCount > 0 || Demo.refEarned > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line2)),
              child: IntrinsicHeight(
                child: Row(children: [
                  _refStat('${Demo.refCount}', 'சேர்ந்த நண்பர்கள்'),
                  const VerticalDivider(width: 1, color: C.line2),
                  _refStat(rupees(Demo.refEarned), 'மொத்த பரிசு'),
                  const VerticalDivider(width: 1, color: C.line2),
                  _refStat(rupees(Demo.refPending), 'பாக்கி'),
                ]),
              ),
            ),
            if (Demo.refGiven > 0) ...[
              const SizedBox(height: 6),
              Text('வரவு வைத்தது: ${rupees(Demo.refGiven)}', style: sans(12.5, color: C.green, weight: FontWeight.w600)),
            ],
            ],
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: PrimaryButton('WhatsApp-ல் பகிர்', icon: Icons.share_outlined, onTap: () => shareWhatsApp(context, 'சுப்புலட்சுமி தங்கமாளிகை தங்கநகை சேமிப்புத் திட்டத்தில் சேருங்கள்! App-ல் சேரும்போது "Reference code" box-ல் என் code ${Demo.member} கொடுங்கள்.\n${Api.site}'))),
          ]),
        ),
      ]));
}
