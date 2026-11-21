import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'links.dart';
import 'main.dart';
import 'ui.dart';
import 'pay.dart';
import 'share_card.dart';
import 'statement.dart';
import 'chat.dart' show requestAccountDeletion;
import 'likes.dart' show appLink;
import 'package:shared_preferences/shared_preferences.dart';

String _inr(double v) => rupees(v.round());

/// One instalment: "தவணை 7 · நவம்பர் 2026 … ₹10,000" / "09 நவ. 2026 · ₹13,255/கி · 0.754 கி".
class PaymentRow extends StatelessWidget {
  const PaymentRow(this.p, {super.key, this.last = false, this.receipt = false});
  final List<Object> p;
  final bool last;
  final bool receipt;
  @override
  Widget build(BuildContext context) {
    final n = p[0] as String, date = p[1] as String, amt = p[2] as int, g = p[3] as double;
    final rate = p.length > 4 ? p[4] as double : 0.0;
    final mon = p.length > 6 ? p[6] as String : (p.length > 5 ? p[5] as String : '');
    final sub = [date, if (g > 0 && rate > 0) '${_inr(rate)}/கி', if (g > 0) '${g.toStringAsFixed(3)} கி'].join(' · ');
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFF0EADB)))),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFF7E0), border: Border.all(color: C.goldLine)),
          child: Text(n, style: serif(16, color: C.goldText)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(Demo.silver || mon.isEmpty ? (mon.isEmpty ? 'தவணை $n' : mon) : 'தவணை $n · $mon',
                      maxLines: 1, style: sans(14.5, weight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Text(rupees(amt), style: serif(17, weight: FontWeight.w700)),
            ]),
            const SizedBox(height: 3),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(12.5, color: C.mute)),
          ]),
        ),
        if (receipt) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.chevron_right, color: C.mute)),
      ]),
    );
    if (!receipt) return row;
    // the whole row opens the receipt (design audit: no button on every line)
    return InkWell(onTap: () => showReceipt(context, p), child: row);
  }
}

enum _Box { paid, late, due, next }

/// 11-month grid: ✓ paid · ! pending from earlier months · ● this month · ○ coming.
class MonthGrid extends StatelessWidget {
  const MonthGrid({super.key});
  @override
  Widget build(BuildContext context) {
    final total = Demo.months, paid = Demo.paidCount, cur = Demo.currentIndex, s = Demo.startDate;
    _Box st(int k) {
      if (k < paid) return _Box.paid;
      if (cur < 0) return k == paid ? _Box.due : _Box.next;
      if (k < cur) return Demo.silver ? _Box.next : _Box.late;
      if (k == cur) return Demo.paidThisMonth ? (Demo.silver ? _Box.next : _Box.late) : _Box.due;
      return _Box.next;
    }

    Widget box(int k) {
      final b = st(k);
      final lbl = s == null ? '${k + 1}' : taMonth(s.month + k).replaceAll('.', '');
      final (Color bg, Color bd, Color fg, Widget mark) = switch (b) {
        _Box.paid => (const Color(0xFFF6E7BE), C.gold, C.goldText, const Icon(Icons.check_rounded, size: 18, color: C.goldText)),
        _Box.late => (const Color(0xFFFFF1DC), const Color(0xFFE0A33A), const Color(0xFF9A5B00), const Icon(Icons.priority_high_rounded, size: 17, color: Color(0xFF9A5B00))),
        _Box.due => (C.paper, C.navy, C.navy, Container(width: 10, height: 10, decoration: const BoxDecoration(color: C.navy, shape: BoxShape.circle))),
        _Box.next => (C.paper, C.line2, C.mute, const SizedBox(height: 18)),
      };
      return Semantics(
        label: '${k + 1} ஆம் தவணை, ${switch (b) { _Box.paid => 'செலுத்தப்பட்டது', _Box.late => 'நிலுவை', _Box.due => 'இந்த மாதம்', _Box.next => 'இனி வரும்' }}',
        child: Container(
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: bd, width: b == _Box.due ? 1.6 : 1)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(height: 18, child: Center(child: mark)),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(lbl, maxLines: 1, style: sans(11.5, color: fg, weight: FontWeight.w600))),
            ),
          ]),
        ),
      );
    }

    final late = [for (var k = 0; k < total; k++) st(k)].where((b) => b == _Box.late).length;
    Widget legend(Color c, String t, {bool ring = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: ring ? C.paper : c, shape: BoxShape.circle, border: Border.all(color: c, width: 1.4))),
          const SizedBox(width: 5),
          Text(t, style: sans(12, color: C.mute)),
        ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GridView.count(
        crossAxisCount: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        childAspectRatio: .95,
        children: [for (var k = 0; k < total; k++) box(k)],
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 14, runSpacing: 6, alignment: WrapAlignment.center, children: [
        legend(C.gold, 'செலுத்தியது'),
        if (late > 0) legend(const Color(0xFFE0A33A), 'நிலுவை ($late)'),
        legend(C.navy, 'இந்த மாதம்', ring: true),
        legend(C.line2, 'இனி வரும்', ring: true),
      ]),
    ]);
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
      // white status-bar icons (time, battery) over the maroon header
      AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Container(
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
              Text('சேமிப்பு விவரம்', style: sans(12.5, color: C.navyMute)),
            ]),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShareCardPage())),
            tooltip: 'பகிர்',
            style: IconButton.styleFrom(side: const BorderSide(color: Color(0x8CC9A24A))),
            icon: const Icon(Icons.share_outlined, color: C.goldSoft),
          ),
        ]),
      )))),
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
            label: Demo.silver && Demo.paidThisMonth ? 'மேலும் சேமிக்க' : 'தவணை செலுத்த',
            amount: Demo.fixed ? rupees(Demo.monthly) : null,
            silver: Demo.silver,
            onDone: () => _pay(context),
          ),
        ),
    ]));
  }

  int _tab = 0;

  Widget _savings(BuildContext context) {
    final left = (Demo.months - paid).clamp(0, 99);
    final done = Demo.schemeDone;
    final day = nowIst().day;
    final st = Demo.paidThisMonth
        ? (Demo.silver ? 'சேமித்தது ✓' : 'செலுத்தப்பட்டது')
        : paid == 0
            ? 'முதல் தவணை'
            : day <= 7
                ? 'நிலுவையில்'
                : 'தாமதம்';
    final stColor = Demo.paidThisMonth ? C.green : (st == 'தாமதம்' ? C.red : C.goldText);
    final canPay = Demo.canPay;
    final avg = Demo.avgRate;
    Widget kv(String k, String v) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: sans(12, color: C.mute)),
            const SizedBox(height: 2),
            Text(v, style: sans(14, weight: FontWeight.w700)),
          ]),
        );
    return RefreshIndicator(color: C.navy, onRefresh: app.refreshPassbook, child: ListView(padding: const EdgeInsets.fromLTRB(16, 22, 16, 28), children: [
      // 1. summary
      LuxCard(
        inner: true,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(children: [
          Text('${Demo.scheme} திட்டம்', textAlign: TextAlign.center, style: sans(15, color: C.goldText, weight: FontWeight.w700, height: 1.35)),
          if (Demo.member.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('கணக்கு எண் ${Demo.member}', textAlign: TextAlign.center, style: sans(13, color: C.mute, weight: FontWeight.w600)),
            ),
          const SizedBox(height: 12),
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
          // progress
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: Demo.months == 0 ? 0 : (paid / Demo.months).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF1E8D2),
              valueColor: const AlwaysStoppedAnimation(C.gold),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Text('$paid / ${Demo.months} ${Demo.silver ? 'மாதம்' : 'தவணை'}', style: sans(13, weight: FontWeight.w700)),
            const Spacer(),
            Text(done ? 'நிறைவு ✓' : 'மீதி $left', style: sans(13, color: C.mute)),
          ]),
          const SizedBox(height: 16),
          const MonthGrid(),
          const SizedBox(height: 14),
          const Divider(height: 1, color: C.line),
          const SizedBox(height: 12),
          Row(children: [
            kv('சேர்ந்த நாள்', Demo.startText),
            kv('நகை வாங்கலாம்', Demo.buyMonth),
          ]),
          // 6. average rate (gram schemes) — a plain fact, no promise
          if (Demo.grams && avg > 0) ...[
            const SizedBox(height: 12),
            InfoBox(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(children: [
                const Icon(Icons.scale_outlined, size: 20, color: C.goldText),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('நீங்கள் தங்கம் சேர்த்த சராசரி விலை', style: sans(12.5, color: C.mute)),
                    Text('${_inr(avg)} / கிராம்', style: sans(15, weight: FontWeight.w700)),
                    if (Demo.gold22 > 0) Text('இன்றைய 22K விலை ${rupees(Demo.gold22)} / கிராம்', style: sans(12, color: C.mute, height: 1.5)),
                  ]),
                ),
              ]),
            ),
          ],
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
      // next instalment
      LuxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Text(
                    done
                        ? 'திட்டம்'
                        : Demo.silver
                            ? 'இந்த மாதம் (${Demo.paidThisMonth ? paid : paid + 1}/${Demo.months})'
                            : (Demo.paidThisMonth ? 'அடுத்த தவணை (${paid + 1}/${Demo.months})' : 'தவணை (${paid + 1}/${Demo.months})'),
                    style: sans(13, color: C.mute))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: stColor.withValues(alpha: .45))),
              child: Text(done ? 'முடிந்தது ✓' : st, style: sans(12, color: done ? C.green : stColor, weight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
              done
                  ? 'எல்லா தவணையும் முடிந்தது'
                  : (Demo.fixed
                      ? rupees(Demo.monthly)
                      : (Demo.silver ? (Demo.paidThisMonth ? rupees(Demo.thisMonthTotal) : '₹100 முதல்') : 'உங்க விருப்பத் தொகை')),
              style: serif(done || (!Demo.fixed && !(Demo.silver && Demo.paidThisMonth)) ? 22 : 30)),
          if (!done && Demo.silver) ...[
            const SizedBox(height: 4),
            Text(Demo.paidThisMonth ? 'இந்த மாதம் எத்தனை முறை வேண்டுமானாலும் மேலும் சேர்க்கலாம் (₹100 முதல்).' : 'இந்த மாதம் ₹100 முதல் எத்தனை முறை வேண்டுமானாலும் சேர்க்கலாம்.',
                style: sans(13, color: C.mute, height: 1.5)),
          ],
          if (!done && !Demo.silver) ...[
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
              Expanded(child: Text('செலுத்த, காசை வலப்பக்கமாக இழுக்கவும்', style: sans(12.5, color: C.goldText, weight: FontWeight.w600))),
            ]),
          ],
        ]),
      ),
      const SizedBox(height: 18),
      // 4. tabs
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: const Color(0xFFF1E8D2), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          for (final (i, t) in [(0, 'தவணைகள் (${Demo.payments.length})'), (1, 'Referral பரிசு')])
            Expanded(
              child: Semantics(
                selected: _tab == i,
                button: true,
                child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _tab == i ? C.paper : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: _tab == i ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))] : null,
                    ),
                    child: Text(t, textAlign: TextAlign.center, style: sans(14, color: _tab == i ? C.navy : C.mute, weight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      if (_tab == 0) ...[
        LuxCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Demo.payments.isEmpty
              ? Padding(padding: const EdgeInsets.all(18), child: Text('இன்னும் தவணை எதுவும் இல்லை. முதல் தவணை கட்டியதும் இங்கே தெரியும்.', style: sans(13.5, color: C.mute, height: 1.6)))
              : Builder(builder: (_) {
                  final ps = Demo.payments;
                  return Column(children: [for (var i = 0; i < ps.length; i++) PaymentRow(ps[i], last: i == ps.length - 1, receipt: true)]);
                }),
        ),
        // 5. full statement
        if (Demo.payments.isNotEmpty) ...[
          const SizedBox(height: 14),
          OutlineBtn('கணக்கு அறிக்கை (PDF)', icon: Icons.picture_as_pdf_outlined, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatementPage()))),
        ],
      ] else
        referralCard(context),
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
            Text('இது மாதிரி மட்டும். உண்மையான பணப் பரிவர்த்தனை நடைபெறவில்லை.', style: sans(13.5, color: C.mute)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: PrimaryButton('சரி', onTap: () => Navigator.of(ctx).pop())),
          ]),
        ),
      ),
    );
    HapticFeedback.mediumImpact();
  }

}


void showReceipt(BuildContext context, List<Object> p) {
  final n = p[0] as String, date = p[1] as String, amt = p[2] as int, g = p[3] as double;
  final rate = p.length > 4 ? p[4] as double : 0.0;
  final mon = p.length > 5 ? p[5] as String : '';
  final key = GlobalKey();
  final rows = [
    ['பெயர்', Demo.name],
    if (Demo.member.isNotEmpty) ['கணக்கு எண்', Demo.member],
    ['திட்டம்', Demo.scheme],
    ['தவணை எண்', Demo.silver ? n : '$n / ${Demo.months}'],
    if (mon.isNotEmpty && !Demo.silver) ['தவணை மாதம்', mon],
    ['செலுத்திய தேதி', date],
    ['தொகை', rupees(amt)],
    if (g > 0 && rate > 0) ['அன்றைய விலை', '${_inr(rate)} / கிராம்'],
    if (g > 0) ['சேர்ந்த தங்கம்', '${g.toStringAsFixed(3)} கிராம்'],
  ];
  final text = 'சுப்புலட்சுமி தங்க மாளிகை · தவணை ரசீது\n${Demo.name} · ${Demo.scheme}\nதவணை $n · $date\nதொகை ${rupees(amt)}${g > 0 ? '\nதங்கம் ${g.toStringAsFixed(3)} கி' : ''}';
  showModalBottomSheet(
    context: context,
    backgroundColor: C.ivory,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          RepaintBoundary(
            key: key,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line2)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(child: Image.asset('assets/logo.png', height: 48)),
                const SizedBox(height: 6),
                Text('தவணை ரசீது', textAlign: TextAlign.center, style: serif(19)),
                const Divider(height: 22, color: C.line),
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 132, child: Text(r[0], style: sans(13.5, color: C.mute))),
                      Expanded(child: Text(r[1], style: sans(14.5, weight: FontWeight.w700))),
                    ]),
                  ),
                const Divider(height: 22, color: C.line),
                Text('சுப்புலட்சுமி தங்க மாளிகை · புளியங்குடி · 97919 18344', textAlign: TextAlign.center, style: sans(11.5, color: C.mute)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton('படமாக பகிர்', icon: Icons.share_outlined, onTap: () => shareImage(context, key, text, 'receipt-$n.png')),
          const SizedBox(height: 8),
          OutlineBtn('எழுத்தாக WhatsApp-ல் அனுப்ப', onTap: () {
            Navigator.of(ctx).pop();
            shareWhatsApp(context, text);
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
          Text('உங்கள் கணக்கையும் தகவல்களையும் நீக்க App வழியாகவே கடைக்கு கோரிக்கை அனுப்பலாம். கடை உங்களைத் தொடர்பு கொண்டு உறுதி செய்யும்.', style: sans(13.5, color: C.mute, height: 1.6)),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: () => requestAccountDeletion(context),
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
        referralCard(context),
      ]));
}

/// Referral card — used on the referral page and in the Passbook "Referral பரிசு" tab.
Widget referralCard(BuildContext context) => LuxCard(
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
            SizedBox(width: double.infinity, child: PrimaryButton('WhatsApp-ல் பகிர்', icon: Icons.share_outlined, onTap: () => shareWhatsApp(context, 'சுப்புலட்சுமி தங்கமாளிகை தங்கநகை சேமிப்புத் திட்டத்தில் சேருங்கள்! App-ல் சேரும்போது "Reference code" box-ல் என் code ${Demo.member} கொடுங்கள்.\n${appLink()}'))),
          ]),
        );
