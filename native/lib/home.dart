import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'api.dart';
import 'bio.dart';
import 'info.dart';
import 'pay.dart';
import 'stories.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  final _key = GlobalKey<ScaffoldState>();

  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), _poster);
    Notify.refresh();
    // back from the background: pick up notifications that arrived while the app was closed
    _life = AppLifecycleListener(onResume: () {
      Notify.refresh();
      app.loadPublic();
    });
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  /// Website-style opening poster: once a day per poster, within its start / end dates.
  Future<void> _poster() async {
    try {
      final today = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)).toIso8601String().substring(0, 10);
      final rows = await Api.popups();
      Map<String, dynamic>? r;
      for (final x in rows) {
        final s = '${x['starts_on'] ?? ''}', e = '${x['ends_on'] ?? ''}';
        if ((s.isEmpty || s == 'null' || s.compareTo(today) <= 0) && (e.isEmpty || e == 'null' || e.compareTo(today) >= 0)) {
          r = x;
          break;
        }
      }
      if (r == null || '${r['image_url'] ?? ''}'.isEmpty || !mounted) return;
      final sp = await SharedPreferences.getInstance();
      final key = 'pop_${r['id']}';
      if (sp.getString(key) == today) return;
      final img = NetworkImage('${r['image_url']}');
      await precacheImage(img, context);
      if (!mounted) return;
      await sp.setString(key, today);
      final link = '${r['link'] ?? '/'}';
      final go2 = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'poster',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 320),
        transitionBuilder: (_, a, __, child) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: FadeTransition(opacity: a, child: child)),
        pageBuilder: (ctx, _, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(clipBehavior: Clip.none, children: [
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(true),
                child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image(image: img, fit: BoxFit.contain)),
              ),
              Positioned(
                right: -10,
                top: -14,
                child: Material(
                  color: C.navy,
                  shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
                  child: IconButton(onPressed: () => Navigator.of(ctx).pop(false), tooltip: 'மூட', icon: const Icon(Icons.close, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      );
      if (go2 == true && mounted) {
        if (link.contains('#p')) {
          go(2);
        } else if (link.contains('#scx')) {
          go(1);
        } else if (link.contains('#n')) {
          go(3);
        }
      }
    } catch (_) {}
  }

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
                openPassbookLogin(context);
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
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (tab != 0) return setState(() => tab = 0);
        if (await askExit(context, go)) SystemNavigator.pop();
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
      [Icons.home_outlined, 'முகப்பு', Icons.home_rounded],
      [Icons.diamond_outlined, 'திட்டங்கள்', Icons.diamond],
      [Icons.menu_book_outlined, 'Passbook', Icons.menu_book_rounded],
      [Icons.notifications_none, 'அறிவிப்பு', Icons.notifications],
      [Icons.person_outline, 'கணக்கு', Icons.person],
    ];
    return Container(
      decoration: const BoxDecoration(color: C.ivory, border: Border(top: BorderSide(color: Color(0xFFE9DCBC))), boxShadow: [BoxShadow(color: Color(0x0F4A0D18), blurRadius: 12, offset: Offset(0, -3))]),
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(horizontal: on ? 16 : 10, vertical: 3),
                      decoration: BoxDecoration(color: on ? const Color(0xFFF6EAD0) : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey('nav$i$on'),
                        tween: Tween<double>(begin: on ? 0.8 : 1.0, end: 1.0),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.elasticOut,
                        builder: (_, v, child) => Transform.scale(scale: v, child: child),
                        child: i == 3
                            ? ValueListenableBuilder<int>(
                                valueListenable: Notify.unread,
                                builder: (_, n, child) => Badge(isLabelVisible: n > 0, label: Text('$n'), backgroundColor: C.red, child: child),
                                child: Icon((on ? items[i][2] : items[i][0]) as IconData, color: on ? C.navy : C.mute, size: 24),
                              )
                            : Icon((on ? items[i][2] : items[i][0]) as IconData, color: on ? C.navy : C.mute, size: 24),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(items[i][1] as String, style: sans(11.5, color: on ? C.navy : C.mute, weight: on ? FontWeight.w700 : FontWeight.w400)),
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
      // ---------- Header: warm ivory; only the savings card / promos wear velvet ----------
      Container(
        child: Stack(children: [
        KolamBg(festive: Fest.today != null, child: Padding(
        padding: EdgeInsets.fromLTRB(16, top + 8, 16, 18),
        child: Column(children: [
          Row(children: [
            const SizedBox(width: 48),
            Expanded(child: Center(child: Hero(tag: 'logo', child: Image.asset('assets/logo.png', height: 46)))),
            SizedBox(
              width: 48,
              height: 48,
              // ☰ menu duplicated the கணக்கு tab → bell with unread count instead (design audit)
              child: ValueListenableBuilder<int>(
                valueListenable: Notify.unread,
                builder: (_, n, __) => IconButton(
                  tooltip: 'அறிவிப்புகள்',
                  onPressed: () {
                    tapFeel();
                    go(3);
                  },
                  style: IconButton.styleFrom(backgroundColor: C.paper, side: const BorderSide(color: C.line2)),
                  icon: Badge(isLabelVisible: n > 0, label: Text('$n'), backgroundColor: C.red, child: const Icon(Icons.notifications_none, color: C.navy)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(app.loggedIn ? '${_greet()}, ${Demo.firstName} 🙏' : _greet(), style: sans(16.5, color: C.ink, weight: FontWeight.w700)),
          const FestRibbon(),
          const SizedBox(height: 14),
          if (app.loggedIn && app.pb != null) ...[
            _SavingsHero(go: go),
            const SizedBox(height: 12),
            const _RateBoard(),
          ] else
            const _RateBoard(),
          const SizedBox(height: 8),
          Demo.rateIsToday || Demo.gold22 == 0
              ? Text(Demo.rateStamp, textAlign: TextAlign.center, style: sans(12.5, color: C.mute))
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFFFF4D6), borderRadius: BorderRadius.circular(99)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.info_outline, size: 15, color: Color(0xFF8A6512)),
                    const SizedBox(width: 6),
                    Flexible(child: Text(Demo.rateStamp, textAlign: TextAlign.center, style: sans(12, color: const Color(0xFF5A4410), weight: FontWeight.w600))),
                  ]),
                ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RatePage())),
            style: OutlinedButton.styleFrom(
              foregroundColor: C.navy,
              backgroundColor: C.paper,
              side: const BorderSide(color: C.line2),
              shape: const StadiumBorder(),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            ),
            icon: const Icon(Icons.show_chart, size: 18),
            label: Text('விலை நிலவரம் பார்க்க  ›', style: sans(14, color: C.navy, weight: FontWeight.w700)),
          ),
        ]),
      )),
      ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Order (design audit): saver → due card first; guest → scheme hero. Quick-action row and contact chips removed (same as bottom tabs / shop card).
          if (app.loggedIn && app.pb != null) ...[
            const _NextDue(),
            const SizedBox(height: 26),
          ],
          // ---------- புதுசு என்ன (stories) ----------
          if (app.stories.isNotEmpty) ...[
            const SectionTitle('புதுசு என்ன'),
            StoryRow(go: go),
            const SizedBox(height: 22),
          ],
          if (!(app.loggedIn && app.pb != null)) ...[
            _SchemeHero(go: go),
            const SizedBox(height: 4),
          ],
          // ---------- நகை வகைகள் (shop photos, swipe) ----------
          if (app.cats.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionTitle('நகை வகைகள்'),
            const CategoryStrip(),
          ],
          if (app.loggedIn && Demo.payments.isNotEmpty) ...[
            const SizedBox(height: 28),
            SectionTitle('சமீபத்திய தவணைகள்', action: 'அனைத்தும் ›', onAction: () => go(2)),
            LuxCard(padding: const EdgeInsets.symmetric(horizontal: 16), child: Builder(builder: (_) {
              final ps = Demo.payments.take(3).toList();
              return Column(children: [for (var i = 0; i < ps.length; i++) PaymentRow(ps[i], last: i == ps.length - 1)]);
            })),
          ],
          if (app.notices.isNotEmpty) ...[
            const SizedBox(height: 28),
            SectionTitle('அறிவிப்புகள்', action: 'அனைத்தும் ›', onAction: () => go(3)),
            _NoticePreview(app.notices.first, onTap: () => go(3)),
          ],
          const SizedBox(height: 28),
          LuxCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('எங்கள் கடை', style: serif(19)),
              const SizedBox(height: 8),
              Text('51B, கங்கை அம்மன் கோவில் தெரு, காந்தி பஜார், புளியங்குடி – 627855', style: sans(14, height: 1.7)),
              const SizedBox(height: 4),
              Text('திங்கள் – சனி 9:00 – 9:00 · ஞாயிறு 9:00 – 8:00', style: sans(13.5, color: C.mute, height: 1.7)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: PrimaryButton('அழை', icon: Icons.call_outlined, onTap: () => callShop(context))),
                const SizedBox(width: 8),
                Expanded(child: OutlineBtn('WhatsApp', icon: Icons.chat_outlined, onTap: () => whatsApp(context))),
              ]),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlineBtn('வழி காட்டு', icon: Icons.place_outlined, onTap: () => openMaps(context))),
            ]),
          ),
        ]),
      ),
    ])));
  }

}

class _RateBoard extends StatelessWidget {
  const _RateBoard();
  static int _dec(double v) => (v * 100).round() % 100 == 0 ? 0 : 2;
  @override
  Widget build(BuildContext context) {
    void open() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RatePage()));
    Widget tile(String label, String value, num change, int dec, String img) => Expanded(
          child: Material(
            color: C.paper,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: C.line2)),
            shadowColor: const Color(0x334A0D18),
            elevation: 1.5,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: open,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                child: Row(children: [
                  Image.asset(img, width: 38, height: 34, fit: BoxFit.contain),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(label, maxLines: 1, style: sans(12.5, color: C.head, weight: FontWeight.w700))),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: value, style: serif(22, color: C.navy, weight: FontWeight.w700, height: 1.25)),
                          TextSpan(text: '/g', style: sans(13, color: C.mute)),
                        ])),
                      ),
                      // always one line, so both cards keep the same height
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(change == 0 ? '● நேற்றைய விலையே' : '${change > 0 ? '▲' : '▼'} ${rupees(change.abs(), decimals: dec)} நேற்றைவிட',
                            maxLines: 1, style: sans(12.5, color: change == 0 ? C.mute : C.navy, weight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        );
    if (Demo.gold22 == 0 && !app.rateError && app.rate == null) {
      Widget sk() => Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.line2)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Skeleton(width: 60, height: 12), SizedBox(height: 10), Skeleton(width: 90, height: 22), SizedBox(height: 8), Skeleton(width: 50, height: 10)]),
            ),
          );
      return Row(children: [sk(), const SizedBox(width: 12), sk()]);
    }
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      tile('தங்கம் 22K', Demo.gold22 > 0 ? rupees(Demo.gold22) : '—', Demo.goldChange, 0, 'assets/gold.png'),
      const SizedBox(width: 12),
      tile('வெள்ளி', Demo.silverRate > 0 ? rupees(Demo.silverRate, decimals: _dec(Demo.silverRate)) : '—', Demo.silverChange, _dec(Demo.silverChange.toDouble()), 'assets/silver.png'),
    ]));
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
        decoration: velvetDeco(radius: BorderRadius.circular(18), alignment: Alignment.center, shadow: const [BoxShadow(color: Color(0x336E1423), blurRadius: 18, offset: Offset(0, 8))]),
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
            decoration: velvetDeco(border: const Border(bottom: BorderSide(color: C.gold, width: 2))),
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
                  openPassbookLogin(context);
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
              trailing: Switch(value: app.haptics, onChanged: (v) => setLocal(() => app.haptics = v))),
          item(Icons.shield_outlined, 'தனியுரிமைக் கொள்கை', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPage()))),
          item(Icons.delete_outline, 'கணக்கை நீக்க கோரிக்கை', () => whatsApp(context, 'வணக்கம், என் கணக்கை நீக்க கோரிக்கை.')),
          if (app.loggedIn)
            item(Icons.logout, 'வெளியேறு', () {
              app.logout();
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
            }, color: C.red),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('சுப்புலட்சுமி தங்க மாளிகை · புளியங்குடி\nApp v0.9.31', textAlign: TextAlign.center, style: sans(12, color: C.mute, height: 1.6)),
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
              decoration: BoxDecoration(color: color == C.red ? const Color(0xFFFBEAEA) : C.ivory2, borderRadius: BorderRadius.circular(12)),
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
          decoration: velvetDeco(radius: BorderRadius.circular(20), alignment: Alignment.topLeft, frame: Border.all(color: const Color(0x80D6B56D))),
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
              PrimaryButton('mPIN போட்டு நுழைய', onTap: () => openPassbookLogin(context)),
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
                    first: true, trailing: Switch(value: app.haptics, onChanged: (v) => setLocal(() => app.haptics = v))),
                if (app.loggedIn) const _BioRow(),
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
            // hidden for customers: long-press the version line to open the sample passbook
            GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DemoPassbookPage()));
              },
              child: Center(child: Text('சுப்புலட்சுமி தங்க மாளிகை · புளியங்குடி\nApp v0.9.31', textAlign: TextAlign.center, style: sans(12, color: C.mute, height: 1.6))),
            ),
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


/// Home hero for logged-in customers: their own savings first, the rate second.
class _SavingsHero extends StatelessWidget {
  const _SavingsHero({required this.go});
  final ValueChanged<int> go;
  @override
  Widget build(BuildContext context) {
    final paid = Demo.paidCount, months = Demo.months;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          tapFeel();
          go(2);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: velvetDeco(
            radius: BorderRadius.circular(20),
            alignment: Alignment.center,
            frame: Border.all(color: const Color(0xA6D6B56D)),
            shadow: const [BoxShadow(color: Color(0x406E1423), blurRadius: 22, offset: Offset(0, 10))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('உங்க சேமிப்பு', style: sans(13, color: C.goldSoft, weight: FontWeight.w700).copyWith(letterSpacing: 1.1)),
                  Text(Demo.scheme, style: sans(14, color: Colors.white, weight: FontWeight.w600, height: 1.4)),
                ]),
              ),
              SizedBox(width: 58, height: 58, child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: C.gold.withValues(alpha: .45), blurRadius: 16)]),
                child: GoldShine(loop: true, pause: const Duration(seconds: 5), child: coinImage(silver: Demo.silver)),
              )),
            ]),
            const SizedBox(height: 2),
            GoldShine(
              delay: const Duration(milliseconds: 1100),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: Demo.total.toDouble()),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(rupees(v), style: serif(40, color: Colors.white, weight: FontWeight.w700, height: 1.2)),
                ),
              ),
            ),
            if (Demo.grams)
              Text('${Demo.gramsTotal.toStringAsFixed(3)} கிராம் தங்கம் சேர்ந்தது', style: sans(13.5, color: C.goldSoft, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: CoinDots(total: months, paid: paid, silver: Demo.silver)),
            const SizedBox(height: 8),
            Text('$paid / $months ${Demo.silver ? 'மாதம்' : 'தவணை'} · நகை வாங்கலாம்: ${Demo.buyMonth}', style: sans(12.5, color: C.navyMute)),
            if (Demo.fixed && !Demo.schemeDone) ...[
              const SizedBox(height: 10),
              Container(height: 1, color: const Color(0x40E8D29A)),
              const SizedBox(height: 10),
              Row(children: [
                Text('மாதத் தவணை', style: sans(12.5, color: C.navyMute)),
                const Spacer(),
                Text(rupees(Demo.monthly), style: serif(16, color: C.goldSoft, weight: FontWeight.w700)),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Next installment card on home (logged-in): due date + swipe to pay, in thumb reach.
class _NextDue extends StatelessWidget {
  const _NextDue();
  @override
  Widget build(BuildContext context) {
    final paid = Demo.paidCount;
    final done = Demo.schemeDone;
    final title = done
        ? 'எல்லா தவணையும் முடிந்தது ✓'
        : Demo.paidThisMonth && !Demo.silver
            ? 'இந்த மாத தவணை செலுத்தியாச்சு ✓'
            : (Demo.silver ? 'இந்த மாத சேமிப்பு' : 'தவணை ${paid + 1} / ${Demo.months}');
    return LuxCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(title, style: serif(18, color: done || (Demo.paidThisMonth && !Demo.silver) ? C.green : C.navy))),
          if (!done && Demo.fixed) Text(rupees(Demo.monthly), style: serif(20, weight: FontWeight.w700)),
        ]),
        if (!done) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.event_outlined, size: 16, color: C.mute),
            const SizedBox(width: 6),
            Expanded(child: Text(Demo.paidThisMonth && !Demo.silver ? 'அடுத்த தவணை ${Demo.dueText}' : Demo.dueText, style: sans(13, color: C.mute))),
          ]),
        ],
        if (Demo.canPay) ...[
          const SizedBox(height: 14),
          SwipeToPay(
            label: 'தவணை செலுத்த',
            silver: Demo.silver,
            onDone: () async {
              final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const PayPage()));
              if (ok == true) app.refreshPassbook();
            },
          ),
        ],
      ]),
    );
  }
}


/// Sample passbook (owner preview): pick a scheme and how many installments are paid.
/// Data lives only in memory; nothing is written to the shop database and no payment runs.
class DemoPassbookPage extends StatefulWidget {
  const DemoPassbookPage({super.key});
  @override
  State<DemoPassbookPage> createState() => _DemoPassbookPageState();
}

class _DemoPassbookPageState extends State<DemoPassbookPage> {
  late Scheme sc = app.schemes.first;
  int paid = 11;

  @override
  void initState() {
    super.initState();
    paid = sc.months;
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void dispose() {
    app.demoPb = null; // back to the real passbook
    WidgetsBinding.instance.addPostFrameCallback((_) => app.setDemo(null));
    super.dispose();
  }

  void _apply() {
    final now = nowIst();
    final int p = paid > sc.months ? sc.months : (paid < 0 ? 0 : paid);
    final start = DateTime(now.year, now.month - (p > 0 ? p - 1 : 0), 5);
    final amt = sc.silver ? 500 : (sc.fixed ? 2000 : 1000);
    final rate = sc.silver ? 210 : 13160;
    String d(DateTime x) => '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    app.setDemo({
      'name': 'மாதிரி வாடிக்கையாளர்',
      'scheme': sc.key,
      'start': d(start),
      'monthly_amount': amt,
      'refer': {'code': 'DEMO01'},
      'payments': [
        for (var i = 0; i < p; i++)
          {'on': d(DateTime(start.year, start.month + i, 5)), 'amount': amt, 'grams': sc.grams ? double.parse((amt / rate).toStringAsFixed(3)) : 0},
      ],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Expanded(child: PassbookTab(onBack: () => Navigator.of(context).pop())),
        Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(color: Color(0xFFFFF4D6), border: Border(top: BorderSide(color: C.goldLine))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Text('மாதிரி Passbook · database-ல எதுவும் சேமிக்காது', style: sans(12.5, color: const Color(0xFF5A4410), weight: FontWeight.w700)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final s in app.schemes)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s.name, style: sans(13, weight: FontWeight.w600)),
                      selected: s.key == sc.key,
                      selectedColor: C.goldSoft,
                      onSelected: (_) {
                        setState(() {
                          sc = s;
                          paid = paid > s.months ? s.months : paid;
                        });
                        _apply();
                      },
                    ),
                  ),
              ]),
            ),
            Row(children: [
              Text('கட்டியது: $paid / ${sc.months}', style: sans(13.5, weight: FontWeight.w700)),
              Expanded(
                child: Slider(
                  value: paid.toDouble(),
                  min: 0,
                  max: sc.months.toDouble(),
                  divisions: sc.months,
                  activeColor: C.navy,
                  onChanged: (v) => setState(() => paid = v.round()),
                  onChangeEnd: (_) => _apply(),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}



/// Latest notice on home (important updates).
class _NoticePreview extends StatelessWidget {
  const _NoticePreview(this.n, {required this.onTap});
  final Map<String, dynamic> n;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final body = (n['body'] ?? '').toString().trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          tapFeel();
          onTap();
        },
        child: LuxCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const RingIcon(Icons.campaign_outlined, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((n['title'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: sans(15, weight: FontWeight.w700, height: 1.4)),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: sans(13.5, color: C.mute, height: 1.5)),
                ],
                const SizedBox(height: 6),
                Text(taDate((n['created_at'] ?? '').toString()), style: sans(12, color: C.goldText, weight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}


/// கணக்கு → அமைப்புகள்: fingerprint login on / off (shown only on phones with a fingerprint).
class _BioRow extends StatefulWidget {
  const _BioRow();
  @override
  State<_BioRow> createState() => _BioRowState();
}

class _BioRowState extends State<_BioRow> {
  bool? can, on;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await Bio.available();
    final o = await Bio.enabledFor(app.mobile);
    if (mounted) {
      setState(() {
        can = c;
        on = o;
      });
    }
  }

  Future<void> _set(bool v) async {
    if (v) {
      final ok = await Bio.enable(app.mobile, app.pin);
      if (!ok && mounted) showNote(context, 'கைரேகை சரிபார்ப்பு முடியல. மறுபடி முயற்சிக்கவும்.');
    } else {
      await Bio.disable();
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (can != true) return const SizedBox.shrink();
    return InkWell(
      onTap: () => _set(!(on ?? false)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1E9D8)))),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: C.ivory2, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.fingerprint, color: C.navy, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('கைரேகை login', style: sans(15.5, color: C.ink)),
              Text('mPIN போடாம விரல் வெச்சே திறக்க', style: sans(12.5, color: C.mute)),
            ]),
          ),
          Switch(value: on ?? false, onChanged: _set),
        ]),
      ),
    );
  }
}
