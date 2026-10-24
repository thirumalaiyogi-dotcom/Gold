import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login.dart';
import 'main.dart';
import 'passbook.dart';
import 'ui.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  final _key = GlobalKey<ScaffoldState>();

  void go(int i) {
    if (i == 2 && !app.loggedIn) {
      _askLogin();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => tab = i);
  }

  void _askLogin() {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/lock.png', height: 56),
            const SizedBox(height: 8),
            Text('Passbook பார்க்க login செய்யுங்க', style: serif(19)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton('mPIN போட்டு உள்ளே போக', onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MobileScreen()));
              }),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(onOpenMenu: () => _key.currentState?.openEndDrawer(), go: go),
      const _Soon('சேமிப்புத் திட்டங்கள்'),
      PassbookTab(onBack: () => go(0)),
      const _Soon('அறிவிப்புகள்'),
      const _Soon('தொடர்பு'),
    ];
    return PopScope(
      canPop: tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => tab = 0);
      },
      child: Scaffold(
        key: _key,
        endDrawer: SideMenu(go: go),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),
        ),
        bottomNavigationBar: _BottomNav(index: tab, onTap: go),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) {
    const items = [
      [Icons.home_outlined, 'முகப்பு'],
      [Icons.diamond_outlined, 'திட்டங்கள்'],
      [Icons.menu_book_outlined, 'Passbook'],
      [Icons.notifications_none, 'அறிவிப்பு'],
      [Icons.call_outlined, 'தொடர்பு'],
    ];
    return Container(
      decoration: const BoxDecoration(color: C.paper, border: Border(top: BorderSide(color: C.line2))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final on = i == index;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(items[i][0] as IconData, color: on ? C.navy : C.mute, size: 24),
                    const SizedBox(height: 2),
                    Text(items[i][1] as String, style: sans(11.5, color: on ? C.navy : C.mute, weight: on ? FontWeight.w700 : FontWeight.w400)),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: on ? 5 : 0,
                      height: 5,
                      decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle),
                    ),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _Soon extends StatelessWidget {
  const _Soon(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const RingIcon(Icons.hourglass_empty, size: 64),
              const SizedBox(height: 14),
              Text(title, style: serif(22)),
              const SizedBox(height: 6),
              Text('இந்தப் பக்கம் மாதிரி app-ல இன்னும் சேர்க்கல.\nமுழு app-ல வரும்.', style: sans(14, color: C.mute, height: 1.6), textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onOpenMenu, required this.go});
  final VoidCallback onOpenMenu;
  final ValueChanged<int> go;

  String _greet() {
    final h = DateTime.now().hour;
    return h < 12 ? 'காலை வணக்கம்' : h < 16 ? 'மதிய வணக்கம்' : h < 19 ? 'மாலை வணக்கம்' : 'இனிய இரவு';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ListView(padding: EdgeInsets.zero, children: [
      // ---------- Header: flat navy, gold rule ----------
      Container(
        padding: EdgeInsets.fromLTRB(16, top + 8, 16, 16),
        decoration: const BoxDecoration(color: C.navy, border: Border(bottom: BorderSide(color: C.gold, width: 2))),
        child: Column(children: [
          Row(children: [
            const SizedBox(width: 48),
            Expanded(child: Center(child: Hero(tag: 'logo', child: Image.asset('assets/logo.png', height: 46)))),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                tooltip: 'Menu',
                onPressed: () {
                  tapFeel();
                  onOpenMenu();
                },
                style: IconButton.styleFrom(side: const BorderSide(color: Color(0x8CC9A24A))),
                icon: const Icon(Icons.menu, color: C.goldSoft),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(app.loggedIn ? '${_greet()}, ${Demo.name}' : _greet(), style: sans(16, color: Colors.white, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          const _RateBoard(),
          const SizedBox(height: 8),
          Text(Demo.rateStamp, style: sans(12.5, color: C.navyMute)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showNote(context, 'மாதிரி: விலை graph பக்கம்'),
            style: OutlinedButton.styleFrom(
              foregroundColor: C.goldSoft,
              side: const BorderSide(color: Color(0x99C9A24A)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            icon: const Icon(Icons.show_chart, size: 18),
            label: Text('விலை நிலவரம் பார்க்க  ›', style: sans(14, color: C.goldSoft, weight: FontWeight.w600)),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ---------- Quick actions ----------
          Row(children: [
            _quick(context, Icons.menu_book_outlined, 'என்\nPassbook', () => go(2)),
            _quick(context, Icons.credit_card, 'தவணை\nகட்ட', () => go(2)),
            _quick(context, Icons.diamond_outlined, 'சேமிப்பு\nதிட்டங்கள்', () => go(1)),
            _quick(context, Icons.trending_up, 'விலை\nநிலவரம்', () => showNote(context, 'மாதிரி: விலை graph')),
          ]),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip(context, Icons.chat_outlined, 'WhatsApp'),
              _chip(context, Icons.call_outlined, 'கடைக்கு அழை'),
              _chip(context, Icons.place_outlined, 'வழி காட்டு'),
            ]),
          ),
          const SizedBox(height: 20),
          const _SchemeHero(),
          if (app.loggedIn) ...[
            const SizedBox(height: 24),
            SectionTitle('சமீபத்திய தவணைகள்', action: 'அனைத்தும் ›', onAction: () => go(2)),
            LuxCard(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [for (final p in Demo.payments) PaymentRow(p, last: p == Demo.payments.last)])),
          ],
          const SizedBox(height: 24),
          const SectionTitle('சேமிப்புத் திட்டங்கள்'),
          SizedBox(
            height: 196,
            child: ListView(scrollDirection: Axis.horizontal, children: const [
              _SchemeCard('தனலட்சுமி', 'தவணை மாற்றலாம் · ₹1,000 – ₹1,00,000'),
              SizedBox(width: 12),
              _SchemeCard('குபேர லட்சுமி', 'நிலையான தவணை · தங்கமாக சேமிப்பு'),
            ]),
          ),
          const SizedBox(height: 24),
          LuxCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('எங்கள் கடை', style: serif(19)),
              const SizedBox(height: 8),
              Text('51B, கங்கை அம்மன் கோவில் தெரு, காந்தி பஜார், புளியங்குடி – 627855', style: sans(14, height: 1.7)),
              const SizedBox(height: 4),
              Text('திங்கள் – சனி 9:00 – 9:00 · ஞாயிறு 9:00 – 8:00', style: sans(13.5, color: C.mute, height: 1.7)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: PrimaryButton('கடைக்கு அழை', icon: Icons.call_outlined, onTap: () => showNote(context, 'மாதிரி: 97919 18344'))),
                const SizedBox(width: 10),
                Expanded(child: OutlineBtn('வழி காட்டு', icon: Icons.place_outlined, onTap: () => showNote(context, 'மாதிரி: Google Maps'))),
              ]),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _quick(BuildContext context, IconData i, String t, VoidCallback onTap) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            tapFeel();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              RingIcon(i),
              const SizedBox(height: 8),
              Text(t, textAlign: TextAlign.center, style: sans(12.5, height: 1.35)),
            ]),
          ),
        ),
      );

  Widget _chip(BuildContext context, IconData i, String t) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Material(
          color: C.paper,
          shape: StadiumBorder(side: const BorderSide(color: C.line2)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => showNote(context, 'மாதிரி: $t'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
              child: Row(children: [
                RingIcon(i, size: 34),
                const SizedBox(width: 10),
                Text(t, style: sans(14, color: C.navy, weight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );
}

class _RateBoard extends StatelessWidget {
  const _RateBoard();
  @override
  Widget build(BuildContext context) {
    Widget col(String label, String value, String change, bool up, String img) => Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(label, style: sans(13, color: C.mute))),
                Image.asset(img, height: 26),
              ]),
              const SizedBox(height: 2),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: serif(28, height: 1.15))),
              const SizedBox(height: 2),
              Row(children: [
                Text('1 கிராம்', style: sans(12.5, color: C.mute)),
                const Spacer(),
                Text('${up ? '▲' : '▼'} $change', style: sans(12.5, color: up ? C.green : C.red, weight: FontWeight.w700)),
              ]),
            ]),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line2)),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          col('தங்கம் 22K', rupees(Demo.gold22), rupees(Demo.goldChange.abs()), Demo.goldChange > 0, 'assets/gold.png'),
          const VerticalDivider(width: 1, thickness: 1, color: C.line),
          col('வெள்ளி', rupees(Demo.silver, decimals: 2), rupees(Demo.silverChange.abs(), decimals: 2), Demo.silverChange > 0, 'assets/silver.png'),
        ]),
      ),
    );
  }
}

class _SchemeHero extends StatelessWidget {
  const _SchemeHero();
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('சுப்புலட்சுமி தங்க மாளிகை', style: sans(12, color: C.gold, weight: FontWeight.w600).copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('தங்க சேமிப்புத் திட்டம்', style: serif(24, color: Colors.white, height: 1.3)),
          const SizedBox(height: 8),
          Text('மாதம் சிறிது சிறிதாக சேமித்து, 13-வது மாதம் உங்கள் கனவு நகையை எளிதாக வாங்குங்கள்.', style: sans(14.5, color: const Color(0xFFD6DDEB), height: 1.7)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: PrimaryButton('திட்டங்கள் பார்க்க', gold: true, onTap: () => showNote(context, 'மாதிரி: திட்டங்கள்'))),
            const SizedBox(width: 10),
            Expanded(child: OutlineBtn('என் சேமிப்பு', light: true, onTap: () => showNote(context, 'மாதிரி: Passbook'))),
          ]),
        ]),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: Container(
            margin: const EdgeInsets.all(7),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0x99C9A24A))),
          ),
        ),
      ),
    ]);
  }
}

class _SchemeCard extends StatelessWidget {
  const _SchemeCard(this.name, this.sub);
  final String name, sub;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 290,
        child: LuxCard(
          topGold: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: C.goldLine)),
              child: Text('12 மாத திட்டம்', style: sans(12, color: C.goldText, weight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Text(name, style: serif(22)),
            const SizedBox(height: 4),
            Text(sub, style: sans(13.5, color: C.mute), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlineBtn('விவரம்', onTap: () => showNote(context, 'மாதிரி: $name விவரம்'))),
              const SizedBox(width: 8),
              Expanded(child: PrimaryButton('இப்போது சேர', onTap: () => showNote(context, 'மாதிரி: சேரும் படிவம்'))),
            ]),
          ]),
        ),
      );
}

class SideMenu extends StatelessWidget {
  const SideMenu({super.key, required this.go});
  final ValueChanged<int> go;
  @override
  Widget build(BuildContext context) {
    final m = app.mobile;
    void close() => Navigator.of(context).pop();
    Widget item(IconData i, String t, VoidCallback f, {Color color = C.ink, Widget? trailing}) => InkWell(
          onTap: f,
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
            child: Row(children: [
              RingIcon(i, size: 38, color: color == C.ink ? C.navy : color, ring: color == C.ink ? C.goldLine : const Color(0xFFE8B4AF)),
              const SizedBox(width: 14),
              Expanded(child: Text(t, style: sans(15, color: color, weight: FontWeight.w500))),
              if (trailing != null) trailing,
            ]),
          ),
        );
    return Drawer(
      backgroundColor: C.ivory,
      width: 320,
      shape: const RoundedRectangleBorder(),
      child: StatefulBuilder(builder: (context, setLocal) {
        return ListView(padding: EdgeInsets.zero, children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 22, 20, 20),
            decoration: const BoxDecoration(color: C.navy, border: Border(bottom: BorderSide(color: C.gold, width: 2))),
            child: Column(children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.gold, width: 1.5)),
                child: app.loggedIn ? Text(Demo.name.characters.first, style: serif(28, color: C.goldSoft)) : const Icon(Icons.person_outline, color: C.goldSoft, size: 30),
              ),
              const SizedBox(height: 10),
              Text(app.loggedIn ? 'வணக்கம், ${Demo.name}' : 'வணக்கம்!', style: serif(18, color: Colors.white)),
              if (app.loggedIn && m.length == 10) ...[
                const SizedBox(height: 2),
                Text('+91 ${m.substring(0, 5)} ${m.substring(5)}', style: sans(13, color: C.navyMute)),
                Text('உறுப்பினர் எண் : ${Demo.member}', style: sans(13, color: C.navyMute)),
              ],
              if (!app.loggedIn) ...[
                const SizedBox(height: 12),
                PrimaryButton('Passbook-ல் உள்நுழை', gold: true, onTap: () {
                  close();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MobileScreen()));
                }),
              ],
            ]),
          ),
          item(Icons.person_outline, 'என் விவரம்', () {
            close();
            go(2);
          }),
          item(Icons.menu_book_outlined, 'என் Passbook', () {
            close();
            go(2);
          }),
          item(Icons.key_outlined, 'mPIN மாற்ற / மறந்துவிட்டேன்', () => showNote(context, 'மாதிரி: OTP மூலம் புது mPIN')),
          item(Icons.notifications_none, 'அறிவிப்புகள்', () {
            close();
            go(3);
          }),
          item(Icons.card_giftcard, 'நண்பரை சேர்க்க (Referral)', () {
            close();
            go(2);
          }),
          item(Icons.diamond_outlined, 'சேமிப்புத் திட்டங்கள்', () {
            close();
            go(1);
          }),
          item(Icons.call_outlined, 'கடையைத் தொடர்பு கொள்ள', () {
            close();
            go(4);
          }),
          item(Icons.vibration, 'அதிர்வு', () => setLocal(() => app.haptics = !app.haptics),
              trailing: Switch(value: app.haptics, activeThumbColor: C.gold, onChanged: (v) => setLocal(() => app.haptics = v))),
          item(Icons.shield_outlined, 'தனியுரிமைக் கொள்கை', () => showNote(context, 'மாதிரி: privacy.html')),
          item(Icons.delete_outline, 'கணக்கை நீக்க கோரிக்கை', () => showNote(context, 'மாதிரி: WhatsApp கோரிக்கை')),
          if (app.loggedIn)
            item(Icons.logout, 'வெளியேறு', () {
              app.logout();
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
            }, color: C.red),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('சுப்புலட்சுமி தங்க மாளிகை · புளியங்குடி\nமாதிரி app v0.1', textAlign: TextAlign.center, style: sans(12, color: C.mute, height: 1.6)),
          ),
        ]);
      }),
    );
  }
}
