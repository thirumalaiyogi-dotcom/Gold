import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'links.dart';
import 'main.dart';
import 'rates.dart';
import 'ui.dart';

/// Stories the customer has already opened (gold ring → grey ring).
final ValueNotifier<Set<String>> storySeen = ValueNotifier(<String>{});
bool _seenLoaded = false;
Future<void> _loadSeen() async {
  if (_seenLoaded) return;
  _seenLoaded = true;
  try {
    final sp = await SharedPreferences.getInstance();
    storySeen.value = (sp.getStringList('story_seen') ?? const []).toSet();
  } catch (_) {}
}

Future<void> _markSeen(String id) async {
  if (storySeen.value.contains(id)) return;
  storySeen.value = {...storySeen.value, id};
  try {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList('story_seen', storySeen.value.take(60).toList());
  } catch (_) {}
}

/// "✨ புதுசு என்ன" — round story bubbles (staff panel adds them).
class StoryRow extends StatefulWidget {
  const StoryRow({super.key, required this.go});
  final ValueChanged<int> go;
  @override
  State<StoryRow> createState() => _StoryRowState();
}

class _StoryRowState extends State<StoryRow> {
  @override
  void initState() {
    super.initState();
    _loadSeen();
  }

  @override
  Widget build(BuildContext context) {
    final list = app.stories;
    return SizedBox(
      height: 126,
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: storySeen,
        builder: (context, seen, _) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, i) {
            final s = list[i];
            final isSeen = seen.contains('${s['id']}');
            return Semantics(
              button: true,
              label: '${s['title']}',
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => openStories(context, i, widget.go),
                child: SizedBox(
                  width: 76,
                  child: Column(children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isSeen ? null : const LinearGradient(colors: [Color(0xFFF3D68A), C.gold, Color(0xFF9E7A2E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        color: isSeen ? const Color(0xFFD9D0C4) : null,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: ClipOval(child: Image.network('${s['image_url']}', fit: BoxFit.cover, width: 62, height: 62, errorBuilder: (_, __, ___) => Container(color: C.ivory2))),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${s['title']}', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: sans(12, color: isSeen ? C.mute : C.ink, weight: FontWeight.w600, height: 1.3)),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> openStories(BuildContext context, int start, ValueChanged<int> go) {
  tapFeel();
  return Navigator.of(context).push(PageRouteBuilder(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => StoryViewer(start: start, go: go),
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: .96, end: 1.0).animate(a), child: child)),
  ));
}

/// Full-screen story viewer: progress bars, 6 s per story, tap left/right, swipe down to close.
class StoryViewer extends StatefulWidget {
  const StoryViewer({super.key, required this.start, required this.go});
  final int start;
  final ValueChanged<int> go;
  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late int i = widget.start;
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 6))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _next();
    });
  double _drag = 0;

  List<Map<String, dynamic>> get list => app.stories;

  @override
  void initState() {
    super.initState();
    _show();
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _show() {
    if (i >= list.length) return;
    _markSeen('${list[i]['id']}');
    _t.forward(from: 0);
  }

  void _next() {
    if (i < list.length - 1) {
      setState(() => i++);
      _show();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    if (i > 0) {
      setState(() => i--);
    }
    _show();
  }

  void _action(Map<String, dynamic> s) {
    final l = '${s['btn_link'] ?? ''}';
    _t.stop();
    if (l == 'wa') {
      whatsApp(context, 'வணக்கம், App-ல் பார்த்த "${s['title']}" பற்றி விபரம் வேண்டும்.');
    } else if (l == 'schemes') {
      Navigator.of(context).pop();
      widget.go(1);
    } else if (l == 'rate') {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RatePage()));
    } else if (l.startsWith('https://')) {
      openLink(context, l);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty || i >= list.length) return const Scaffold(backgroundColor: Colors.black);
    final s = list[i];
    final pad = MediaQuery.of(context).padding;
    final hasBtn = '${s['btn_link'] ?? ''}'.isNotEmpty && '${s['btn_link']}' != 'null';
    final body = '${s['body'] ?? ''}';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0509),
        body: GestureDetector(
          onLongPressStart: (_) => _t.stop(),
          onLongPressEnd: (_) => _t.forward(),
          onVerticalDragUpdate: (d) => setState(() => _drag = (_drag + d.delta.dy).clamp(0, 400)),
          onVerticalDragEnd: (d) {
            if (_drag > 120 || (d.primaryVelocity ?? 0) > 700) {
              Navigator.of(context).maybePop();
            } else {
              setState(() => _drag = 0);
            }
          },
          onTapUp: (d) {
            final w = MediaQuery.of(context).size.width;
            d.globalPosition.dx < w * .3 ? _prev() : _next();
          },
          child: Transform.translate(
            offset: Offset(0, _drag),
            child: Stack(fit: StackFit.expand, children: [
              // same picture, blurred, fills the bands around a non-tall photo (design audit)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Image.network('${s['image_url']}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
              const ColoredBox(color: Color(0x66000000)),
              Image.network('${s['image_url']}', key: ValueKey(s['id']), fit: BoxFit.contain,
                  loadingBuilder: (c, w, p) => p == null ? w : const Center(child: CircularProgressIndicator(color: C.gold)),
                  errorBuilder: (_, __, ___) => Center(child: Text('படம் திறக்க முடியல', style: sans(14, color: Colors.white70)))),
              // top: progress + title + close
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(12, pad.top + 8, 6, 18),
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xAA000000), Color(0x00000000)])),
                  child: Column(children: [
                    Row(children: [
                      for (var k = 0; k < list.length; k++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: AnimatedBuilder(
                                animation: _t,
                                builder: (_, __) => LinearProgressIndicator(
                                  minHeight: 3,
                                  value: k < i ? 1 : k > i ? 0 : _t.value,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      ClipOval(child: Image.asset('assets/coin.png', width: 32, height: 32, errorBuilder: (_, __, ___) => const SizedBox(width: 32))),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${s['title']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(15.5, color: Colors.white, weight: FontWeight.w700))),
                      IconButton(
                        tooltip: 'மூடு',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      ),
                    ]),
                  ]),
                ),
              ),
              // bottom: text + button
              if (body.isNotEmpty || hasBtn)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(18, 40, 18, pad.bottom + 18),
                    decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xDD000000), Color(0x00000000)])),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (body.isNotEmpty) Text(body, style: sans(15, color: Colors.white, height: 1.55)),
                      if (hasBtn) ...[
                        const SizedBox(height: 14),
                        PrimaryButton('${s['btn_label'] ?? 'மேலும் பார்க்க'}', gold: true, onTap: () => _action(s)),
                      ],
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// "💍 நகை வகைகள்" — swipeable shop-photo cards; tap → WhatsApp enquiry for that category.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({super.key});
  @override
  Widget build(BuildContext context) {
    final list = app.cats;
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = list[i];
          final name = '${c['name']}';
          final wa = '${c['wa_text'] ?? ''}';
          return Semantics(
            button: true,
            label: '$name — WhatsApp-ல் கேட்க',
            child: GestureDetector(
              onTap: () => whatsApp(context, wa.isNotEmpty && wa != 'null' ? wa : 'வணக்கம், $name டிசைன்கள் பார்க்கணும். புகைப்படங்கள் அனுப்ப முடியுமா?'),
              child: Container(
                width: 148,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: C.line2),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(fit: StackFit.expand, children: [
                  Image.network('${c['image_url']}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: C.ivory2)),
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [.45, 1], colors: [Color(0x00000000), Color(0xCC2A0610)])),
                  ),
                  Positioned(
                    left: 12,
                    right: 10,
                    bottom: 10,
                    child: Row(children: [
                      Expanded(child: Text(name, maxLines: 2, style: sans(15, color: Colors.white, weight: FontWeight.w700, height: 1.3))),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(color: Color(0xE6FFFFFF), shape: BoxShape.circle),
                        child: const Icon(Icons.chat_outlined, size: 16, color: C.navy),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Back on the home tab → "போறீங்களா?" sheet. true = really exit.
Future<bool> askExit(BuildContext context, ValueChanged<int> go) async {
  HapticFeedback.selectionClick();
  final s = app.stories.isNotEmpty ? app.stories.first : null;
  final r = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(color: C.formBg, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(ctx).padding.bottom + 18),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: C.line2, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        if (s != null)
          GestureDetector(
            onTap: () => Navigator.of(ctx).pop('story'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(fit: StackFit.expand, children: [
                  Image.network('${s['image_url']}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: C.ivory2)),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [.5, 1], colors: [Color(0x00000000), Color(0xCC2A0610)]))),
                  Positioned(left: 14, right: 14, bottom: 12, child: Text('✨ ${s['title']}  ›', style: sans(15.5, color: Colors.white, weight: FontWeight.w700))),
                ]),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: velvetDeco(radius: BorderRadius.circular(18)),
            child: Row(children: [
              Image.asset('assets/coin.png', width: 54, height: 54, errorBuilder: (_, __, ___) => const SizedBox(width: 54)),
              const SizedBox(width: 14),
              Expanded(child: Text('மாதம் சிறிது சேமித்து\nதங்க நகை வாங்குங்கள்', style: sans(15.5, color: Colors.white, weight: FontWeight.w700, height: 1.45))),
            ]),
          ),
        const SizedBox(height: 18),
        Text('அதுக்குள்ள போறீங்களா? 🙏', textAlign: TextAlign.center, style: serif(21)),
        const SizedBox(height: 6),
        Text(
          Demo.gold22 > 0 ? 'இன்றைய 22K விலை ${rupees(Demo.gold22)} / கிராம்' : 'புது offer-கள், விலை மாற்றம் எல்லாம் இங்கே தான்',
          textAlign: TextAlign.center,
          style: sans(14.5, color: C.mute),
        ),
        const SizedBox(height: 18),
        PrimaryButton(s != null ? 'புதுசு பார்க்கலாம்' : 'சேமிப்புத் திட்டங்கள் பார்க்க', onTap: () => Navigator.of(ctx).pop(s != null ? 'story' : 'schemes')),
        const SizedBox(height: 10),
        OutlineBtn('App-ஐ விட்டு வெளியேறு', onTap: () => Navigator.of(ctx).pop('exit')),
      ]),
    ),
  );
  if (!context.mounted) return false;
  if (r == 'story') {
    openStories(context, 0, go);
  } else if (r == 'schemes') {
    go(1);
  }
  return r == 'exit';
}
