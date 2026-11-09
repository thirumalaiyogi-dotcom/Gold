import 'package:flutter/material.dart';

import 'data.dart';
import 'api.dart';
import 'links.dart';
import 'main.dart';
import 'ui.dart';

/// திட்டங்கள் tab — list of all schemes.
class SchemesTab extends StatelessWidget {
  const SchemesTab({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: app, builder: (context, _) => SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
        Text('சேமிப்பு திட்டங்கள்', style: serif(22, color: C.ink, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('உங்கள் தேவைக்கேற்ற திட்டத்தை தேர்வு செய்யுங்க', style: sans(14, color: C.mute, height: 1.6)),
        const SizedBox(height: 14),
        for (final s in app.schemes) ...[SchemeCard(s), const SizedBox(height: 14)],
      ]),
    ));
  }
}

void openScheme(BuildContext context, Scheme s) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SchemeDetailPage(s)));

void openEnrol(BuildContext context, Scheme s) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EnrolPage(initial: s)));

/// Card used on Home (horizontal) and in the schemes tab.
class SchemeCard extends StatelessWidget {
  const SchemeCard(this.s, {super.key, this.width});
  final Scheme s;
  final double? width;
  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line2)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _grow(InkWell(
          onTap: () => openScheme(context, s),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            decoration: velvetDeco(alignment: Alignment.topLeft),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(color: C.goldSoft, borderRadius: BorderRadius.circular(99)),
                    child: Text('${s.months} மாத திட்டம்', style: sans(11.5, color: C.navy2, weight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                  Text(s.name, softWrap: true, style: serif(20, color: Colors.white, weight: FontWeight.w700, height: 1.3)),
                  const SizedBox(height: 4),
                  Text(s.tag, style: sans(13, color: C.navyMute)),
                  Text(s.amountRange, style: sans(13, color: C.navyMute)),
                ]),
              ),
              const SizedBox(width: 12),
              _Coin(s),
            ]),
          ),
        )),
        Padding(
          padding: const EdgeInsets.all(12),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: OutlineBtn('மேலும் அறியவும்', onTap: () => openScheme(context, s))),
              const SizedBox(width: 10),
              Expanded(child: PrimaryButton('இப்போது சேரவும்', onTap: () => openEnrol(context, s))),
            ]),
          ),
        ),
      ]),
    );
    return width == null ? card : SizedBox(width: width, child: card);
  }

  // In the home carousel all cards share the tallest height: the maroon header takes the extra space.
  Widget _grow(Widget w) => width == null ? w : Expanded(child: w);
}

class _Coin extends StatelessWidget {
  const _Coin(this.s);
  final Scheme s;
  @override
  Widget build(BuildContext context) {
    final img = Image.asset('assets/coin.png', width: 64, height: 64, errorBuilder: (_, __, ___) => const Icon(Icons.circle, size: 64, color: C.gold));
    return Column(mainAxisSize: MainAxisSize.min, children: [
      s.silver ? ColorFiltered(colorFilter: const ColorFilter.matrix(<double>[0.33, 0.33, 0.33, 0, 20, 0.33, 0.33, 0.33, 0, 20, 0.33, 0.33, 0.33, 0, 24, 0, 0, 0, 1, 0]), child: img) : img,
      Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(color: s.silver ? const Color(0xFFE6E9ED) : C.goldSoft, borderRadius: BorderRadius.circular(99)),
        child: Text(s.coin, style: sans(10.5, color: C.navy2, weight: FontWeight.w700)),
      ),
    ]);
  }
}

/// Full scheme page — same sections as the website.
class SchemeDetailPage extends StatelessWidget {
  const SchemeDetailPage(this.s, {super.key});
  final Scheme s;

  void _terms(BuildContext context) {
    final list = s.terms.isNotEmpty ? s.terms : s.acc.map((a) => '${a[0]}: ${a[1]}').toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        maxChildSize: .95,
        builder: (ctx, sc) => ListView(controller: sc, padding: const EdgeInsets.fromLTRB(20, 18, 20, 30), children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.line2, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 14),
          Text('${s.name} · விதிமுறைகள் & நிபந்தனைகள்', style: serif(18, color: C.ink, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final t in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 8, right: 10), child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle))),
                Expanded(child: Text(t, style: sans(14, height: 1.65))),
              ]),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      [Icons.storefront_outlined, 'கடையில் சேர்ந்து Passbook பெறுங்க', 'கடையிலோ இந்த app-லோ பதிவு செய்யலாம்.'],
      [Icons.calendar_month_outlined, s.silver ? '${s.months} மாதம் சேமியுங்க' : 'மாதம் 1–7 தேதிக்குள் தவணை செலுத்துங்க', s.silver ? 'மாதம் பல முறை ₹100 முதல் செலுத்தலாம்.' : 'Passbook-லோ கடையிலோ செலுத்தலாம்.'],
      [Icons.diamond_outlined, s.silver ? '${s.months + 1} வது மாதம் வெள்ளி நகை வாங்குங்கள்' : '${s.months + 1} வது மாதம் நகை / காயின் வாங்குங்கள்', s.fixed ? 'சேர்ந்த தங்க எடைக்கு நகை / காயின்.' : (s.silver ? 'சேமித்த தொகைக்கு வெள்ளி நகை.' : 'அன்றைய தங்க விலைக்கு நகை / காயின்.')],
    ];
    final feats = [
      [Icons.calendar_month_outlined, '${s.months} தவணை'],
      [s.fixed ? Icons.lock_outline : Icons.sync_alt, s.fixed ? 'நிலையான தவணை' : (s.silver ? 'மாதம் பல முறை' : 'தவணை மாற்றலாம்')],
      [s.fixed ? Icons.scale_outlined : Icons.sell_outlined, s.fixed ? 'கிராம் கணக்கு' : (s.silver ? 'வெள்ளி நகை' : 'சேதாரம் & செய்கூலி தள்ளுபடி')],
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: C.paper,
        surfaceTintColor: C.paper,
        foregroundColor: C.navy,
        title: Text('${s.name} திட்டம்', style: sans(16.5, color: C.ink, weight: FontWeight.w700)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: velvetDeco(radius: BorderRadius.circular(20), alignment: Alignment.topLeft, frame: Border.all(color: const Color(0x80D6B56D))),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: serif(24, color: C.goldSoft, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(s.tag, style: sans(14, color: Colors.white)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: C.goldSoft, borderRadius: BorderRadius.circular(99)),
                  child: Text('${rupees(s.minAmount)} முதல்', style: sans(13, color: C.navy2, weight: FontWeight.w700)),
                ),
              ]),
            ),
            _Coin(s),
          ]),
        ),
        const SizedBox(height: 14),
        LuxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              _pill('${s.months} மாத சேமிப்புத் திட்டம்'),
              _pill(s.silver ? 'வெள்ளி' : '22K | 916', gold: true),
            ]),
            const SizedBox(height: 10),
            Text(s.name, style: serif(24, weight: FontWeight.w700)),
            Text(s.amountRange, style: sans(14, color: C.mute)),
            const Divider(height: 26, color: C.line),
            Row(children: [
              for (final f in feats)
                Expanded(
                  child: Column(children: [
                    RingIcon(f[0] as IconData, size: 40),
                    const SizedBox(height: 6),
                    Text(f[1] as String, textAlign: TextAlign.center, style: sans(12.5, weight: FontWeight.w600, height: 1.35)),
                  ]),
                ),
            ]),
          ]),
        ),
        const SizedBox(height: 22),
        Text('ஏன் ${s.name}?', style: serif(19, color: C.ink, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(s.why, style: sans(14.5, height: 1.75)),
        TextButton.icon(
          onPressed: () => _terms(context),
          icon: const Icon(Icons.description_outlined, size: 18, color: C.navy),
          label: Text('முழு விதிமுறைகள் & நிபந்தனைகள்', style: sans(14, color: C.navy, weight: FontWeight.w600)),
        ),
        const SizedBox(height: 10),
        Text('எப்படி வேலை செய்யும்?', style: serif(19, color: C.ink, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RingIcon(steps[i][0] as IconData, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('படி ${i + 1}', style: sans(12, color: C.goldText, weight: FontWeight.w600)),
                  Text(steps[i][1] as String, style: sans(15, weight: FontWeight.w700)),
                  Text(steps[i][2] as String, style: sans(13.5, color: C.mute, height: 1.5)),
                ]),
              ),
            ]),
          ),
        const SizedBox(height: 8),
        Text('திட்ட விவரங்கள்', style: serif(19, color: C.ink, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final a in s.acc) _Acc(a[0], a[1]),
        const SizedBox(height: 14),
        Text('அடிக்கடி கேட்கப்படும் கேள்விகள்', style: serif(19, color: C.ink, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final a in s.faq) _Acc(a[0], a[1]),
        const SizedBox(height: 14),
        LuxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('சந்தேகமா? எங்களை தொடர்பு கொள்ளுங்க', style: sans(15, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlineBtn('97919 18344', icon: Icons.call_outlined, onTap: () => callShop(context))),
              const SizedBox(width: 10),
              Expanded(child: OutlineBtn('93443 95078', icon: Icons.call_outlined, onTap: () => callShop(context, Shop.phone2))),
            ]),
            const SizedBox(height: 10),
            OutlineBtn('WhatsApp-ல் கேட்க', icon: Icons.chat_outlined, onTap: () => whatsApp(context, 'வணக்கம், ${s.name} திட்டம் பற்றி விபரம் வேண்டும்.')),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(color: C.paper, border: Border(top: BorderSide(color: C.line))),
          child: PrimaryButton('இப்போதே சேரவும்', onTap: () => openEnrol(context, s)),
        ),
      ),
    );
  }

  Widget _pill(String t, {bool gold = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: gold ? C.goldSoft : C.ivory2, borderRadius: BorderRadius.circular(99)),
        child: Text(t, style: sans(12.5, color: C.navy2, weight: FontWeight.w600)),
      );
}

class _Acc extends StatelessWidget {
  const _Acc(this.q, this.a);
  final String q, a;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line2)),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            iconColor: C.navy,
            collapsedIconColor: C.navy,
            title: Text(q, style: sans(15, color: C.navy, weight: FontWeight.w700)),
            expandedAlignment: Alignment.centerLeft,
            children: [Text(a, style: sans(14, height: 1.65))],
          ),
        ),
      );
}

/// சேரும் படிவம் — 4 steps like the website (prototype: nothing is sent).
class EnrolPage extends StatefulWidget {
  const EnrolPage({super.key, required this.initial});
  final Scheme initial;
  @override
  State<EnrolPage> createState() => _EnrolPageState();
}

class _EnrolPageState extends State<EnrolPage> {
  int step = 0;
  late Scheme sch = widget.initial;
  final name = TextEditingController(), mobile = TextEditingController(), addr = TextEditingController(), city = TextEditingController(), pin = TextEditingController();
  final amount = TextEditingController(), nominee = TextEditingController();
  String rel = 'கணவர் / மனைவி';
  bool agree = false;
  bool busy = false;
  String err = '';

  @override
  void initState() {
    super.initState();
    if (app.mobile.length == 10) mobile.text = app.mobile;
  }

  @override
  void dispose() {
    for (final c in [name, mobile, addr, city, pin, amount, nominee]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _check() {
    String e = '';
    if (step == 0) {
      if (name.text.trim().length < 2) {
        e = 'பெயர் போடுங்க';
      } else if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile.text.trim())) {
        e = 'சரியான 10 இலக்க மொபைல் எண் போடுங்க';
      }
    } else if (step == 1) {
      if (addr.text.trim().length < 4 || city.text.trim().isEmpty) e = 'முகவரி, ஊர் போடுங்க';
      if (pin.text.trim().isNotEmpty && !RegExp(r'^[0-9]{6}$').hasMatch(pin.text.trim())) e = 'Pincode 6 இலக்கம்';
    } else if (step == 2) {
      final a = int.tryParse(amount.text.trim()) ?? 0;
      if (a < sch.minAmount || a > 100000) e = 'மாத தவணை ${rupees(sch.minAmount)} முதல் ₹1,00,000 வரை';
    } else if (step == 3) {
      if (!agree) e = 'விதிமுறைகளை ஒப்புக்கொள்ளுங்க';
    }
    setState(() => err = e);
    return e.isEmpty;
  }

  Future<void> _next() async {
    if (busy || !_check()) return;
    if (step < 3) {
      setState(() => step++);
      return;
    }
    setState(() => busy = true);
    try {
      await Api.enrol({
        'name': name.text.trim(),
        'mobile': mobile.text.trim(),
        'address': addr.text.trim(),
        'city': city.text.trim(),
        'pincode': pin.text.trim().isEmpty ? null : pin.text.trim(),
        'scheme': sch.key,
        'monthly_amount': int.tryParse(amount.text.trim()),
        'nominee': nominee.text.trim().isEmpty ? null : nominee.text.trim(),
        'nominee_rel': nominee.text.trim().isEmpty ? null : rel,
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => _EnrolDone(name: name.text.trim(), scheme: sch)));
    } on ApiError catch (e) {
      setState(() {
        busy = false;
        err = e.duplicate ? 'இந்த மொபைல் எண்ணுக்கு ஏற்கனவே ஒரு விண்ணப்பம் நிலுவையில் இருக்கு. கடையை தொடர்பு கொள்ளுங்க.' : 'அனுப்ப முடியல. விவரங்களை சரிபார்த்து மறுபடி முயற்சிக்கவும்.';
      });
    } catch (_) {
      setState(() {
        busy = false;
        err = 'இணைய இணைப்பை சரிபார்த்து மறுபடி முயற்சிக்கவும்.';
      });
    }
  }

  InputDecoration _dec(String l, {String? hint}) => formDeco(label: l, hint: hint);

  Widget _field(TextEditingController c, String l, {TextInputType? kb, String? hint, int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(controller: c, keyboardType: kb, maxLines: lines, decoration: _dec(l, hint: hint), style: sans(15)),
      );

  @override
  Widget build(BuildContext context) {
    const titles = ['உங்கள் விவரம்', 'முகவரி', 'திட்டம் & தொகை', 'Nominee & உறுதி'];
    final chips = sch.silver ? [100, 200, 500, 1000] : [1000, 2000, 5000, 10000];
    Widget body;
    if (step == 0) {
      body = Column(children: [
        _field(name, 'பெயர்*'),
        _field(mobile, 'மொபைல் எண்*', kb: TextInputType.phone, hint: '10 இலக்கம்'),
      ]);
    } else if (step == 1) {
      body = Column(children: [
        _field(addr, 'முகவரி*', lines: 2),
        _field(city, 'ஊர்*'),
        _field(pin, 'Pincode', kb: TextInputType.number),
      ]);
    } else if (step == 2) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('திட்டம்', style: sans(13, color: C.mute, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        for (final s in app.schemes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() {
                sch = s;
                amount.clear();
              }),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: s.key == sch.key ? C.ivory2 : C.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: s.key == sch.key ? C.gold : C.line2, width: s.key == sch.key ? 1.6 : 1),
                ),
                child: Row(children: [
                  Icon(s.key == sch.key ? Icons.radio_button_checked : Icons.radio_button_off, color: C.navy),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.name, style: sans(15, weight: FontWeight.w700)),
                      Text('${s.months} மாதம் · ${const {'dhana': 'தவணை உங்கள் விருப்பம்', 'kubera': 'நிலையான தவணை · தங்க எடையில் சேமிப்பு'}[s.key] ?? s.tag} · ${s.amountRange}', style: sans(12.5, color: C.mute)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(sch.silver ? 'தொகை (ஒவ்வொரு முறையும்)' : 'மாத தவணை', style: sans(13, color: C.mute, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in chips)
            ChoiceChip(
              label: Text(rupees(v)),
              selected: amount.text == '$v',
              selectedColor: C.goldSoft,
              onSelected: (_) => setState(() => amount.text = '$v'),
            ),
        ]),
        const SizedBox(height: 10),
        _field(amount, 'அல்லது தொகை போடுங்க', kb: TextInputType.number, hint: '${rupees(sch.minAmount)} – ₹1,00,000'),
        if (sch.fixed) Text('குறிப்பு: குபேரலட்சுமியில் முதல் மாதத் தொகையையே 11 மாதமும் செலுத்த வேண்டும்.', style: sans(12.5, color: C.goldText, height: 1.5)),
      ]);
    } else {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _field(nominee, 'Nominee பெயர்'),
        DropdownButtonFormField<String>(
          initialValue: rel,
          decoration: _dec('உறவு'),
          items: const ['கணவர் / மனைவி', 'மகன்', 'மகள்', 'தந்தை', 'தாய்', 'மற்றவர்'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => rel = v ?? rel),
        ),
        const SizedBox(height: 14),
        LuxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('சுருக்கம்', style: sans(13, color: C.mute, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('${name.text.trim()} · ${mobile.text.trim()}', style: sans(15, weight: FontWeight.w700)),
            Text('${sch.name} · ${rupees(int.tryParse(amount.text) ?? 0)}', style: sans(14)),
          ]),
        ),
        CheckboxListTile(
          value: agree,
          onChanged: (v) => setState(() => agree = v ?? false),
          activeColor: C.navy,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text('திட்ட விதிமுறைகளை படித்து ஒப்புக்கொள்கிறேன்', style: sans(14)),
        ),
      ]);
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: C.paper, surfaceTintColor: C.paper, foregroundColor: C.navy, title: Text('திட்டத்தில் சேர', style: sans(16.5, color: C.ink, weight: FontWeight.w700))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
        Row(children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                decoration: BoxDecoration(color: i <= step ? C.gold : C.line2, borderRadius: BorderRadius.circular(4)),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Text('படி ${step + 1} / 4', style: sans(12.5, color: C.goldText, weight: FontWeight.w600)),
        Text(titles[step], style: serif(21, color: C.ink, weight: FontWeight.w700)),
        const SizedBox(height: 16),
        body,
        if (err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(err, style: sans(13.5, color: C.red))),
        const SizedBox(height: 18),
        Row(children: [
          if (step > 0) ...[
            Expanded(child: OutlineBtn('பின்செல்', onTap: () => setState(() {
                  step--;
                  err = '';
                }))),
            const SizedBox(width: 10),
          ],
          Expanded(flex: 2, child: PrimaryButton(step < 3 ? 'அடுத்து' : (busy ? 'அனுப்புகிறது…' : 'விண்ணப்பம் அனுப்பு'), busy: busy, onTap: _next)),
        ]),
        const SizedBox(height: 14),
        Center(child: Text('விண்ணப்பம் கடைக்கு செல்லும். கடை approve பண்ணியதும் WhatsApp-ல் தகவல் வரும்.', textAlign: TextAlign.center, style: sans(12, color: C.mute))),
      ]),
    );
  }
}

class _EnrolDone extends StatelessWidget {
  const _EnrolDone({required this.name, required this.scheme});
  final String name;
  final Scheme scheme;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Center(child: RingIcon(Icons.check, size: 76, color: C.green)),
              const SizedBox(height: 18),
              Text('விண்ணப்பம் அனுப்பப்பட்டது', textAlign: TextAlign.center, style: serif(22, color: C.ink, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('நன்றி $name! ${scheme.name} திட்டத்துக்கான உங்க விண்ணப்பம் கடைக்கு வந்துவிட்டது. கடை approve பண்ணியதும் WhatsApp-ல் Activation code வரும்.',
                  textAlign: TextAlign.center, style: sans(14.5, color: C.mute, height: 1.7)),
              const SizedBox(height: 24),
              PrimaryButton('முகப்புக்கு செல்ல', onTap: () => Navigator.of(context).pop()),
            ]),
          ),
        ),
      );
}
