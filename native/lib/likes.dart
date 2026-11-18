import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import 'api.dart';
import 'gallery.dart';
import 'main.dart';
import 'ui.dart';

/// பிடித்தவை (likes) — stories + category photos. Kept per device (gold_likes via RPC);
/// when the customer is logged in the like also carries their name for the shop.
class Likes {
  static final ValueNotifier<Set<String>> keys = ValueNotifier(<String>{});
  static String _dev = '';
  static bool _loaded = false;

  static String key(String type, dynamic id) => '$type:$id';
  static bool has(String type, dynamic id) => keys.value.contains(key(type, id));

  static Future<String> device() async {
    if (_dev.isNotEmpty) return _dev;
    try {
      final sp = await SharedPreferences.getInstance();
      var d = sp.getString('device_id') ?? '';
      if (!RegExp(r'^[A-Za-z0-9-]{16,64}$').hasMatch(d)) {
        final r = Random.secure();
        d = List.generate(32, (_) => '0123456789abcdef'[r.nextInt(16)]).join();
        await sp.setString('device_id', d);
      }
      _dev = d;
    } catch (_) {}
    return _dev;
  }

  /// Liked items with picture + title (for "என் பிடித்தவை"). Also refreshes [keys].
  static Future<List<Map<String, dynamic>>> mine() async {
    final d = await Api.rpc('gold_likes_mine', {'p_device': await device()});
    final list = (d is List ? d : const []).map((e) => Map<String, dynamic>.from(e)).toList();
    keys.value = {for (final m in list) key('${m['type']}', m['id'])};
    _loaded = true;
    return list;
  }

  static Future<void> load() async {
    if (_loaded) return;
    try {
      await mine();
    } catch (_) {}
  }

  /// Optimistic toggle; rolls back if the server refuses.
  static Future<void> toggle(BuildContext context, String type, dynamic id) async {
    final k = key(type, id);
    final was = keys.value.contains(k);
    HapticFeedback.lightImpact();
    keys.value = was ? ({...keys.value}..remove(k)) : {...keys.value, k};
    try {
      final d = await Api.rpc('gold_like_toggle', {
        'p_type': type,
        'p_id': id is int ? id : int.tryParse('$id') ?? 0,
        'p_device': await device(),
        'p_mobile': app.loggedIn ? app.mobile : null,
        'p_pin': app.loggedIn ? app.pin : null,
      });
      if (d is! Map || d['ok'] != true) throw 'x';
      final liked = d['liked'] == true;
      keys.value = liked ? {...keys.value, k} : ({...keys.value}..remove(k));
    } catch (_) {
      keys.value = was ? {...keys.value, k} : ({...keys.value}..remove(k));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('இப்போது சேமிக்க இயலவில்லை. மீண்டும் முயற்சிக்கவும்.')));
      }
    }
  }
}

/// Heart button that follows [Likes.keys].
class LikeButton extends StatelessWidget {
  const LikeButton({super.key, required this.type, required this.id, this.onDark = true, this.size = 28});
  final String type;
  final dynamic id;
  final bool onDark;
  final double size;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: Likes.keys,
      builder: (context, _, __) {
        final on = Likes.has(type, id);
        return IconButton(
          tooltip: on ? 'பிடித்தவையிலிருந்து நீக்க' : 'பிடித்தவையில் சேர்க்க',
          onPressed: () => Likes.toggle(context, type, id),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              on ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(on),
              size: size,
              color: on ? const Color(0xFFE0245E) : (onDark ? Colors.white : C.navy),
            ),
          ),
        );
      },
    );
  }
}

/// Big heart that pops in the middle on double-tap.
class HeartBurst extends StatefulWidget {
  const HeartBurst({super.key, required this.trigger});
  final ValueNotifier<int> trigger;
  @override
  State<HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<HeartBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  @override
  void initState() {
    super.initState();
    widget.trigger.addListener(_go);
  }

  void _go() => _a.forward(from: 0);

  @override
  void dispose() {
    widget.trigger.removeListener(_go);
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _a,
        builder: (_, __) {
          if (_a.value == 0 || _a.value == 1) return const SizedBox.shrink();
          final t = _a.value;
          final scale = t < .3 ? Curves.easeOutBack.transform(t / .3) : 1.0;
          final op = t < .7 ? 1.0 : 1 - (t - .7) / .3;
          return Center(
            child: Opacity(
              opacity: op.clamp(0, 1),
              child: Transform.scale(
                scale: scale,
                child: const Icon(Icons.favorite, size: 110, color: Color(0xEEFFFFFF), shadows: [Shadow(color: Color(0x66000000), blurRadius: 24)]),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One link for every share: today it opens the website (install as app);
/// once the app is on Play Store, the same link sends Android phones there. Carries the referral code.
String appLink() {
  final code = app.loggedIn ? Demo.member.trim() : '';
  return '${Api.site}/app${code.isNotEmpty ? '?ref=${Uri.encodeQueryComponent(code)}' : ''}';
}

ui.Image? _logo;
Future<ui.Image?> _loadLogo() async {
  if (_logo != null) return _logo;
  try {
    final b = await rootBundle.load('assets/logo.png');
    final c = await ui.instantiateImageCodec(b.buffer.asUint8List(), targetWidth: 360);
    _logo = (await c.getNextFrame()).image;
  } catch (_) {}
  return _logo;
}

/// Shares the jewel photo itself with a small shop watermark + caption + app link.
Future<void> shareJewel(BuildContext context, {required String imageUrl, String title = '', String category = ''}) async {
  final name = [title, category].where((e) => e.isNotEmpty && e != 'null').toSet().join(' · ');
  final text = '${name.isNotEmpty ? '$name — ' : ''}சுப்புலட்சுமி தங்க மாளிகை, புளியங்குடி\n'
      'மேலும் டிசைன்கள், இன்றைய தங்க விலை App-ல்: ${appLink()}';
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(content: Text('பகிரத் தயாராகிறது…'), duration: Duration(seconds: 2)));
  try {
    final r = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw 'img';
    final codec = await ui.instantiateImageCodec(r.bodyBytes, targetWidth: 1280);
    final src = (await codec.getNextFrame()).image;
    final w = src.width.toDouble(), h = src.height.toDouble();
    final band = (w * .11).clamp(64.0, 150.0);
    final rec = ui.PictureRecorder();
    final cv = Canvas(rec);
    cv.drawImage(src, Offset.zero, Paint());
    // watermark band at the bottom
    final rect = Rect.fromLTWH(0, h - band, w, band);
    cv.drawRect(rect, Paint()..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [const Color(0x00000000), const Color(0xB3000000)]));
    final logo = await _loadLogo();
    var x = band * .28;
    if (logo != null) {
      final lh = band * .62, lw = lh * logo.width / logo.height;
      cv.drawImageRect(logo, Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()), Rect.fromLTWH(x, h - band + (band - lh) / 2, lw, lh), Paint()..filterQuality = FilterQuality.high);
      x += lw + band * .2;
    }
    final tp = TextPainter(
      text: TextSpan(children: [
        TextSpan(text: 'சுப்புலட்சுமி தங்க மாளிகை\n', style: sans(band * .22, color: Colors.white, weight: FontWeight.w700)),
        TextSpan(text: 'புளியங்குடி · 97919 18344', style: sans(band * .17, color: const Color(0xFFF1E3BF))),
      ]),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: w - x - band * .2);
    tp.paint(cv, Offset(x, h - band + (band - tp.height) / 2));
    final out = await rec.endRecording().toImage(src.width, src.height);
    final png = await out.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) throw 'png';
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(png.buffer.asUint8List(), mimeType: 'image/png', name: 'subbulakshmi-design.png')],
      text: text,
    ));
  } catch (_) {
    if (context.mounted) await SharePlus.instance.share(ShareParams(text: '$text\n$imageUrl'));
  }
}

/// "என் பிடித்தவை" — everything this phone has hearted.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> items = [];
  bool loading = true, failed = false;

  @override
  void initState() {
    super.initState();
    _load();
    Likes.keys.addListener(_sync);
  }

  @override
  void dispose() {
    Likes.keys.removeListener(_sync);
    super.dispose();
  }

  // un-hearting inside the viewer removes it here too
  void _sync() {
    if (!mounted) return;
    setState(() => items = items.where((m) => Likes.has('${m['type']}', m['id'])).toList());
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final l = await Likes.mine();
      if (mounted) setState(() => items = l);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator(color: C.navy));
    } else if (items.isEmpty) {
      body = ListView(padding: const EdgeInsets.fromLTRB(24, 70, 24, 24), children: [
        const Icon(Icons.favorite_border, size: 54, color: C.goldText),
        const SizedBox(height: 14),
        Text(failed ? 'பிடித்தவைகளைப் பெற இயலவில்லை' : 'இன்னும் எதுவும் சேர்க்கவில்லை', textAlign: TextAlign.center, style: serif(20)),
        const SizedBox(height: 8),
        Text(failed ? 'இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.' : 'நகை படங்களில் ♡ அழுத்தினால் அவை இங்கே சேமிக்கப்படும்.',
            textAlign: TextAlign.center, style: sans(15, color: C.mute, height: 1.5)),
        if (failed) ...[const SizedBox(height: 20), OutlineBtn('மீண்டும் முயற்சி', icon: Icons.refresh, onTap: _load)],
      ]);
    } else {
      final photos = [
        for (final m in items) {'id': m['id'], 'image_url': m['image'], 'title': m['title'], 'note': m['cat'], '_type': m['type']}
      ];
      body = RefreshIndicator(
        color: C.navy,
        onRefresh: _load,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .8),
          itemCount: photos.length,
          itemBuilder: (context, i) {
            final p = photos[i];
            final t = '${p['title'] ?? ''}';
            return GestureDetector(
              onTap: () => Navigator.of(context).push(PageRouteBuilder(
                opaque: false,
                barrierColor: Colors.black,
                pageBuilder: (_, __, ___) => PhotoViewer(photos: photos, start: i, category: ''),
                transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
              )),
              child: Container(
                decoration: BoxDecoration(
                  color: C.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: C.line2),
                  boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    child: Stack(fit: StackFit.expand, children: [
                      Image.network('${p['image_url']}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: C.ivory2)),
                      Positioned(right: 0, top: 0, child: LikeButton(type: '${p['_type']}', id: p['id'], size: 24)),
                    ]),
                  ),
                  if (t.isNotEmpty && t != 'null')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                      child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(14, weight: FontWeight.w600)),
                    ),
                ]),
              ),
            );
          },
        ),
      );
    }
    return Scaffold(
      backgroundColor: C.ivory,
      appBar: AppBar(backgroundColor: C.ivory, surfaceTintColor: C.ivory, foregroundColor: C.navy, title: Text('என் பிடித்தவை', style: serif(20))),
      body: body,
    );
  }
}

/// Opens "என் பிடித்தவை".
void openFavorites(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesPage()));
