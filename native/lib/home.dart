import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'links.dart';
import 'login.dart';
import 'notices.dart';
import 'rates.dart';
import 'schemes.dart';
import 'main.dart';
import 'passbook.dart';
import 'ui.dart';
import 'notify.dart';
import 'info.dart';

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
    if (i == 3) Notify.markRead();
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
      const SchemesTab(),
      PassbookTab(onBack: () => go(0)),
      const NoticesTab(),
      ProfileTab(go: go),
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
      [Icons.person_outline, 'கணக்கு'],
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
                    i == 3
                        ? ValueListenableBuilder<int>(
                            valueListenable: Notify.unread,
                            builder: (_, n, child) => Badge(isLabelVisible: n > 0, label: Text('$n'), backgroundColor: C.red, child: child),
                            child: Icon(items[i][0] as IconData, color: on ? C.navy : C.mute, size: 24),
                          )
                        : Icon(items[i][0] as IconData, color: on ? C.navy : C.mute, size: 24),
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
    return AnimatedBuilder(animation: app, builder: (context, _) => RefreshIndicator(
      color: C.navy,
      onRefresh: () async {
        await app.loadPublic();
        await app.refreshPassbook();
      },
      child: ListView(padding: EdgeInsets.zero, children: [
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
          Text(app.loggedIn ? '${_greet()}, ${Demo.firstName}' : _greet(), style: sans(16, color: Colors.white, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          _RateBoard(),
          const SizedBox(height: 8),
          Text(Demo.rateStamp, style: sans(12.5, color: C.navyMute)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RatePage())),
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
            _quick(context, Icons.credit_card, 'தவணைத்தொகை\nசெலுத்த', () => go(2)),
            _quick(context, Icons.diamond_outlined, 'சேமிப்பு\nதிட்டங்கள்', () => go(1)),
            _quick(context, Icons.trending_up, 'விலை\nநிலவரம்', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RatePage()))),
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
          _SchemeHero(go: go),
          if (app.loggedIn && Demo.payments.isNotEmpty) ...[
            const SizedBox(height: 24),
            SectionTitle('சமீபத்திய தவணைகள்', action: 'அனைத்தும் ›', onAction: () => go(2)),
            LuxCard(padding: const EdgeInsets.symmetric(horizontal: 16), child: Builder(builder: (_) {
              final ps = Demo.payments.take(3).toList();
              return Column(children: [for (var i = 0; i < ps.length; i++) PaymentRow(ps[i], last: i == ps.length - 1)]);
            })),
          ],
          const SizedBox(height: 24),
          SectionTitle('சேமிப்புத் திட்டங்கள்', action: 'அனைத்தும் ›', onAction: () => go(1)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < app.schemes.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  SchemeCard(app.schemes[i], width: 300),
                ],
              ]),
            ),
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
                Expanded(child: PrimaryButton('கடைக்கு அழை', icon: Icons.call_outlined, onTap: () => callShop(context))),
                const SizedBox(width: 10),
                Expanded(child: OutlineBtn('வழி காட்டு', icon: Icons.place_outlined, onTap: () => openMaps(context))),
              ]),
            ]),
          ),
        ]),
      ),
    ])));
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
            onTap: () => t == 'WhatsApp' ? whatsApp(context) : t == 'வழி காட்டு' ? openMaps(context) : callShop(context),
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
          col('தங்கம் 22K', Demo.gold22 > 0 ? rupees(Demo.gold22) : '—', rupees(Demo.goldChange.abs()), Demo.goldChange > 0, 'assets/gold.png'),
          const VerticalDivider(width: 1, thickness: 1, color: C.line),
          col('வெள்ளி', Demo.silverRate > 0 ? rupees(Demo.silverRate, decimals: 2) : '—', rupees(Demo.silverChange.abs(), decimals: 2), Demo.silverChange > 0, 'assets/silver.png'),
        ]),
      ),
    );
  }
}

class _SchemeHero extends StatelessWidget {
  const _SchemeHero({required this.go});
  final ValueChanged<int> go;
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
          Text('ஒவ்வொரு மாதமும் சிறிது சிறிதாக சேமித்து 12 வது மாதம் உங்கள் கனவு தங்க நகையை சேதாரம், செய்கூலி இல்லாமல் வாங்கிச் செல்லுங்கள்.', style: sans(14.5, color: const Color(0xFFEAD9B8), height: 1.7)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: PrimaryButton('திட்டங்கள் பார்க்க', gold: true, onTap: () => go(1))),
            const SizedBox(width: 10),
            Expanded(child: OutlineBtn('என் சேமிப்பு', light: true, onTap: () => go(2))),
          ]),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => showWhyGold(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Expanded(child: Text('மேலும் அறிய: ஏன் தங்கத்தில் சேமிக்க வேண்டும்?', style: sans(13.5, color: C.goldSoft, weight: FontWeight.w600))),
                const Icon(Icons.info_outline, size: 18, color: C.goldSoft),
              ]),
            ),
          ),
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
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyDetailsPage()));
          }),
          item(Icons.menu_book_outlined, 'என் Passbook', () {
            close();
            go(2);
          }),
          item(Icons.key_outlined, 'mPIN மாற்ற / மறந்துவிட்டேன்', () => whatsApp(context, 'வணக்கம், என் mPIN மாற்ற / புது Activation code வேண்டும்.\nமொபைல்: ${app.mobile}')),
          item(Icons.notifications_none, 'அறிவிப்புகள்', () {
            close();
            go(3);
          }),
          item(Icons.card_giftcard, 'நண்பரை சேர்க்க (Referral)', () {
            close();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferralPage()));
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
          item(Icons.shield_outlined, 'தனியுரிமைக் கொள்கை', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPage()))),
          item(Icons.delete_outline, 'கணக்கை நீக்க கோரிக்கை', () => whatsApp(context, 'வணக்கம், என் கணக்கை நீக்க கோரிக்கை.')),
          if (app.loggedIn)
            item(Icons.logout, 'வெளியேறு', () {
              app.logout();
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
            }, color: C.red),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('சுப்புலட்சுமி தங்க மாளிகை · புளியங்குடி\nApp v0.7', textAlign: TextAlign.center, style: sans(12, color: C.mute, height: 1.6)),
          ),
        ]);
      }),
    );
  }
}


/// கணக்கு (Profile) tab — same items as the website's Profile page.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.go});
  final ValueChanged<int> go;

  Widget _row(IconData icon, String label, VoidCallback onTap, {Widget? trailing, Color color = C.ink, bool first = false}) => InkWell(
        onTap: () {
          tapFeel();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(border: first ? null : const Border(top: BorderSide(color: Color(0xFFF1E9D8)))),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color == C.red ? const Color(0xFFFBEAEA) : const Color(0xFFF6EEDC), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: color == C.red ? C.red : C.navy),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: sans(15, color: color, weight: FontWeight.w500))),
            trailing ?? const Icon(Icons.chevron_right, color: Color(0xFFB9AE9C)),
          ]),
        ),
      );

  Widget _group(List<Widget> rows, {String? title}) => Container(
        margin: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line2)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (title != null) Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(title, style: sans(12, color: C.mute, weight: FontWeight.w600))),
          ...rows,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final m = app.mobile;
        final head = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.navy, C.navy2]),
            border: Border.all(color: const Color(0x66E5C98B)),
          ),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF6EEDC), border: Border.all(color: C.gold, width: 2)),
              child: app.loggedIn ? Text(Demo.name.characters.first, style: serif(24, color: C.navy, weight: FontWeight.w700)) : const Icon(Icons.person_outline, color: C.navy),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.loggedIn ? Demo.name : 'உங்க கணக்கு', style: serif(19, color: Colors.white, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                if (app.loggedIn && m.length == 10) Text('+91 ${m.substring(0, 5)} ${m.substring(5)}', style: sans(12.5, color: C.navyMute)),
                Text(app.loggedIn ? '${Demo.scheme} திட்டம் · ${Demo.member}' : 'Passbook, தவணை, Referral எல்லாம் பார்க்க mPIN போட்டு நுழையுங்கள்.',
                    style: sans(12.5, color: C.navyMute, height: 1.45)),
              ]),
            ),
          ]),
        );
        return SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
            Text('என் கணக்கு', style: serif(22, color: C.ink, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            head,
            if (!app.loggedIn) ...[
              const SizedBox(height: 12),
              PrimaryButton('mPIN போட்டு நுழைய', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MobileScreen()))),
            ],
            if (app.loggedIn)
              _group([
                _row(Icons.person_outline, 'என் விவரம்', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyDetailsPage())), first: true),
                _row(Icons.menu_book_outlined, 'என் Passbook', () => go(2)),
                _row(Icons.key_outlined, 'mPIN மாற்ற / மறந்துவிட்டேன்', () => whatsApp(context, 'வணக்கம், என் mPIN மாற்ற / புது Activation code வேண்டும்.\nமொபைல்: ${app.mobile}')),
                _row(Icons.card_giftcard, 'நண்பரை சேர்க்க (Referral)', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferralPage()))),
              ]),
            StatefulBuilder(builder: (context, setLocal) {
              return _group([
                _row(Icons.vibration, 'அதிர்வு', () => setLocal(() => app.haptics = !app.haptics),
                    first: true, trailing: Switch(value: app.haptics, activeThumbColor: C.green, onChanged: (v) => setLocal(() => app.haptics = v))),
                _row(Icons.notifications_active_outlined, 'Notification அமைப்பு', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotifySettingsPage()))),
                _row(Icons.info_outline, 'எங்களைப் பற்றி', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutPage()))),
                _row(Icons.shield_outlined, 'தனியுரிமைக் கொள்கை', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPage()))),
                if (app.loggedIn) _row(Icons.delete_outline, 'கணக்கை நீக்க கோரிக்கை', () => whatsApp(context, 'வணக்கம், என் கணக்கை நீக்க கோரிக்கை.')),
                if (app.loggedIn)
                  _row(Icons.logout, 'வெளியேறு', () {
                    app.logout();
                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
                  }, color: C.red),
              ], title: 'அமைப்புகள்');
            }),
            _group([
              _row(Icons.call_outlined, 'கடைக்கு அழை · 97919 18344', () => callShop(context), first: true),
              _row(Icons.chat_outlined, 'WhatsApp-ல் பேச', () => whatsApp(context)),
              _row(Icons.location_on_outlined, 'வழி காட்டு', () => openMaps(context)),
            ], title: 'உதவி & தொடர்பு'),
            const SizedBox(height: 18),
            Center(child: Text('சுப்புலட்சுமி தங்க மாளிகை · புளியங்குடி\nApp v0.7', textAlign: TextAlign.center, style: sans(12, color: C.mute, height: 1.6))),
          ]),
        );
      },
    );
  }
}


/// "ஏன் தங்கத்தில் சேமிக்க வேண்டும்?" — same four points as the website.
void showWhyGold(BuildContext context) {
  const pts = [
    'உலகளவில் தங்கம் ஒரு பாதுகாப்பான சேமிப்பு பொருள் ஆகும்.',
    'நீங்கள் சேமிக்க நினைக்கும் மிகக் குறைந்த அளவிலான பணத்தையும் சேமிப்புத் திட்டங்களின் மூலம் தங்கமாக மாற்றி சேமிக்க முடியும்.',
    'இந்த சேமிப்பின் மூலம் தங்கநகை வாங்கும்போது சேதாரம் மற்றும் செய்கூலிக்கு நீங்கள் கொடுக்க வேண்டிய பணத்தை மிச்சப்படுத்தலாம்.',
    'சேமிப்பு கணக்கிற்கான Passbook எப்போதும் உங்கள் உள்ளங்கையிலேயே இருக்கும்.',
  ];
  showModalBottomSheet(
    context: context,
    backgroundColor: C.ivory,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('ஏன் தங்கத்தில் சேமிக்க வேண்டும்?', style: serif(20, color: C.ink, weight: FontWeight.w700)),
          const SizedBox(height: 14),
          for (final p in pts)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.check_circle, size: 18, color: C.gold)),
                const SizedBox(width: 10),
                Expanded(child: Text(p, style: sans(14.5, height: 1.6))),
              ]),
            ),
          const SizedBox(height: 4),
          PrimaryButton('சரி', onTap: () => Navigator.of(ctx).pop()),
        ]),
      ),
    ),
  );
}
