import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'chat.dart';
import 'likes.dart';
import 'links.dart';
import 'ui.dart';
import 'visit.dart';

String _sv(dynamic v) {
  final t = '${v ?? ''}'.trim();
  return t == 'null' ? '' : t;
}

/// "22K 916 · 24.5 கி" from a design row (empty parts skipped).
String designSpec(Map<String, dynamic> p) {
  final w = num.tryParse(_sv(p['weight_g']));
  final ws = w == null ? '' : '${w == w.roundToDouble() ? w.toInt() : double.parse(w.toStringAsFixed(3))} கி';
  return [_sv(p['purity']), ws].where((e) => e.isNotEmpty).join(' · ');
}

List<String> designImages(Map<String, dynamic> p) => [
      '${p['image_url']}',
      ...((p['more_images'] as List?) ?? const []).map((e) => '$e').where((e) => e.startsWith('http')),
    ];

Widget designBadge(String b) {
  if (b != 'new' && b != 'best') return const SizedBox.shrink();
  final best = b == 'best';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: best ? null : C.navy,
      gradient: best ? const LinearGradient(colors: [Color(0xFFF3D68A), C.gold]) : null,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(best ? 'அதிகம் விற்பனை' : 'புதுசு', style: sans(11, color: best ? const Color(0xFF4C0F1A) : Colors.white, weight: FontWeight.w700)),
  );
}

/// நகை வகை → designs added by staff (gold_category_photos): cover header, filter chips, sort, 2-column cards.
/// Tap a card → DesignPage (photos, details, similar designs, enquire / visit).
class CategoryGallery extends StatefulWidget {
  const CategoryGallery({super.key, required this.cat});
  final Map<String, dynamic> cat;
  @override
  State<CategoryGallery> createState() => _CategoryGalleryState();
}

class _CategoryGalleryState extends State<CategoryGallery> {
  List<Map<String, dynamic>> photos = [];
  bool loading = true, failed = false;
  String chip = '';
  int sort = 0; // 0 புதியவை முதலில் · 1 எடை ↑ · 2 எடை ↓

  String get name => '${widget.cat['name']}';

  @override
  void initState() {
    super.initState();
    _load();
    Likes.load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final p = await Api.categoryPhotos(widget.cat['id']);
      if (mounted) setState(() => photos = p);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
    if (mounted) setState(() => loading = false);
  }

  void _askWa() {
    final wa = '${widget.cat['wa_text'] ?? ''}';
    askShop(context, message: wa.isNotEmpty && wa != 'null' ? wa : 'வணக்கம், $name டிசைன்களின் படங்களை அனுப்ப முடியுமா?');
  }

  bool _isNew(Map<String, dynamic> p) {
    if (_sv(p['badge']) == 'new') return true;
    final t = DateTime.tryParse(_sv(p['created_at']));
    return t != null && DateTime.now().difference(t).inDays <= 30;
  }

  List<String> get _tags {
    final s = <String>[];
    for (final p in photos) {
      final t = _sv(p['tag']);
      if (t.isNotEmpty && !s.contains(t)) s.add(t);
    }
    return s;
  }

  bool get _hasWeights => photos.any((p) => num.tryParse(_sv(p['weight_g'])) != null);

  List<Map<String, dynamic>> get _shown {
    var l = photos.where((p) => chip.isEmpty || (chip == '__new' ? _isNew(p) : _sv(p['tag']) == chip)).toList();
    if (sort == 0) {
      l = l.reversed.toList();
    } else {
      double w(Map<String, dynamic> p) => (num.tryParse(_sv(p['weight_g'])) ?? (sort == 1 ? 1e9 : -1)).toDouble();
      l.sort((a, b) => sort == 1 ? w(a).compareTo(w(b)) : w(b).compareTo(w(a)));
    }
    return l;
  }

  void _open(List<Map<String, dynamic>> list, int i) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DesignPage(design: list[i], all: photos, category: name)));
  }

  Widget _chip(String label, String key) {
    final on = chip == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => chip = key);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: on ? C.navy : C.paper,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? C.navy : C.line2),
          ),
          child: Text(label, style: sans(13.5, color: on ? Colors.white : C.mute, weight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _header(double top) {
    final cover = _sv(widget.cat['image_url']);
    final anyHuid = photos.any((p) => p['hallmark'] == true);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: SizedBox(
        height: 236 + top,
        child: Stack(fit: StackFit.expand, children: [
          if (cover.startsWith('http'))
            Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: C.navy))
          else
            Container(color: C.navy),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, .35, 1], colors: [Color(0x662A0610), Color(0x002A0610), Color(0xE62A0610)]),
            ),
          ),
          Positioned(
            top: top + 8,
            left: 12,
            child: _roundBtn(Icons.arrow_back_rounded, 'பின் செல்', () => Navigator.of(context).maybePop()),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: serif(32, color: Colors.white, height: 1.2)),
              const SizedBox(height: 4),
              Text(loading ? ' ' : '${photos.length} டிசைன்கள்', style: sans(14, color: Colors.white.withOpacity(.9))),
              if (anyHuid) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF3D68A), C.gold]), borderRadius: BorderRadius.circular(999)),
                  child: Text('BIS HUID முத்திரையுடன்', style: sans(12, color: const Color(0xFF4C0F1A), weight: FontWeight.w700)),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final shown = _shown;
    final tags = _tags;
    final slivers = <Widget>[SliverToBoxAdapter(child: _header(pad.top))];
    if (loading) {
      slivers.add(SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid.count(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .66, children: List.generate(4, (_) => const Skeleton(height: 240, radius: 18))),
      ));
    } else if (photos.isEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(children: [
            const Icon(Icons.photo_library_outlined, size: 54, color: C.goldText),
            const SizedBox(height: 14),
            Text(failed ? 'படங்களை ஏற்ற முடியல' : '$name டிசைன்கள் விரைவில்', textAlign: TextAlign.center, style: serif(20)),
            const SizedBox(height: 8),
            Text(failed ? 'இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.' : 'புதிய டிசைன்கள் பற்றி எங்களிடம் கேளுங்கள்.', textAlign: TextAlign.center, style: sans(15, color: C.mute, height: 1.5)),
            const SizedBox(height: 22),
            if (failed) OutlineBtn('மீண்டும் முயற்சி', icon: Icons.refresh, onTap: _load) else PrimaryButton('எங்களிடம் கேளுங்கள்', icon: Icons.chat_outlined, onTap: _askWa),
          ]),
        ),
      ));
    } else {
      final hasNew = photos.any(_isNew);
      slivers.add(SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
          child: Row(children: [
            _chip('அனைத்தும்', ''),
            if (hasNew) _chip('புதியவை', '__new'),
            for (final t in tags) _chip(t, t),
          ]),
        ),
      ));
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 8, 2),
          child: Row(children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: '${shown.length}', style: sans(13.5, color: C.ink, weight: FontWeight.w700)),
              TextSpan(text: ' டிசைன்கள்', style: sans(13.5, color: C.mute)),
            ])),
            const Spacer(),
            if (_hasWeights)
              PopupMenuButton<int>(
                initialValue: sort,
                onSelected: (v) => setState(() => sort = v),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 0, child: Text('புதியவை முதலில்', style: sans(14))),
                  PopupMenuItem(value: 1, child: Text('எடை: குறைவு → அதிகம்', style: sans(14))),
                  PopupMenuItem(value: 2, child: Text('எடை: அதிகம் → குறைவு', style: sans(14))),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(['புதியவை முதலில்', 'எடை ↑', 'எடை ↓'][sort], style: sans(13.5, color: C.mute)),
                    const Icon(Icons.arrow_drop_down, color: C.mute),
                  ]),
                ),
              ),
          ]),
        ),
      ));
      slivers.add(SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, pad.bottom + 96),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 12, childAspectRatio: .62),
          delegate: SliverChildBuilderDelegate((context, i) => _card(shown, i), childCount: shown.length),
        ),
      ));
    }
    return Scaffold(
      backgroundColor: C.ivory,
      body: RefreshIndicator(color: C.navy, onRefresh: _load, child: CustomScrollView(slivers: slivers)),
      floatingActionButton: photos.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: C.navy,
              foregroundColor: Colors.white,
              onPressed: _askWa,
              icon: const Icon(Icons.chat_outlined),
              label: Text('எங்களிடம் கேளுங்கள்', style: sans(15, color: Colors.white, weight: FontWeight.w700)),
            ),
    );
  }

  Widget _card(List<Map<String, dynamic>> list, int i) {
    final p = list[i];
    final t = _sv(p['title']);
    final spec = designSpec(p);
    final extra = designImages(p).length - 1;
    return Semantics(
      button: true,
      label: t.isNotEmpty ? t : '$name டிசைன் ${i + 1}',
      child: GestureDetector(
        onTap: () => _open(list, i),
        child: Container(
          decoration: BoxDecoration(
            color: C.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEFE3CB)),
            boxShadow: const [BoxShadow(color: Color(0x123C0A14), blurRadius: 14, offset: Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                Hero(
                  tag: 'catp${p['id']}',
                  child: Image.network('${p['image_url']}', fit: BoxFit.cover,
                      loadingBuilder: (c, w, e) => e == null ? w : Container(color: C.ivory2),
                      errorBuilder: (_, __, ___) => Container(color: C.ivory2, child: const Icon(Icons.image_not_supported_outlined, color: C.mute))),
                ),
                Positioned(left: 8, top: 12, right: 46, child: Align(alignment: Alignment.centerLeft, child: FittedBox(fit: BoxFit.scaleDown, child: designBadge(_sv(p['badge']))))),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    decoration: const BoxDecoration(color: Color(0xF2FFFFFF), shape: BoxShape.circle),
                    child: SizedBox(width: 38, height: 38, child: Center(child: LikeButton(type: 'photo', id: p['id'], onDark: false, size: 19))),
                  ),
                ),
                if (extra > 0)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(999)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Text('${extra + 1}', style: sans(11, color: Colors.white, weight: FontWeight.w700)),
                      ]),
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.isNotEmpty ? t : '$name டிசைன்', maxLines: 2, overflow: TextOverflow.ellipsis, style: sans(14, weight: FontWeight.w700, height: 1.3)),
                if (spec.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(spec, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(12.5, color: C.goldText, weight: FontWeight.w600))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

Widget _roundBtn(IconData icon, String tip, VoidCallback onTap) => Semantics(
      button: true,
      label: tip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(color: Color(0xEBFFFFFF), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3))]),
          child: Icon(icon, color: C.navy, size: 22),
        ),
      ),
    );

/// One design: swipe photos (tap → full screen zoom), code, name, weight / purity / size, HUID, similar designs,
/// and two actions: book a shop visit · enquire about this design (photo goes with the message).
class DesignPage extends StatefulWidget {
  const DesignPage({super.key, required this.design, required this.all, required this.category});
  final Map<String, dynamic> design;
  final List<Map<String, dynamic>> all;
  final String category;
  @override
  State<DesignPage> createState() => _DesignPageState();
}

class _DesignPageState extends State<DesignPage> {
  late Map<String, dynamic> d = widget.design;
  int img = 0;
  final _pc = PageController();
  final _sc = ScrollController();

  @override
  void dispose() {
    _pc.dispose();
    _sc.dispose();
    super.dispose();
  }

  void _show(Map<String, dynamic> x) {
    HapticFeedback.selectionClick();
    setState(() {
      d = x;
      img = 0;
    });
    if (_pc.hasClients) _pc.jumpToPage(0);
    _sc.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  void _zoom(List<String> imgs, int start) {
    final list = <Map<String, dynamic>>[for (var k = 0; k < imgs.length; k++) {'id': k == 0 ? d['id'] : '${d['id']}_$k', 'image_url': imgs[k], 'title': d['title'], 'note': '', '_type': 'photo'}];
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => PhotoViewer(photos: list, start: start, category: widget.category),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  Widget _spec(String label, String v) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEFE3CB))),
          child: Column(children: [
            Text(label, style: sans(12, color: C.mute)),
            const SizedBox(height: 3),
            Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(15.5, color: C.ink, weight: FontWeight.w700)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final imgs = designImages(d);
    final title = _sv(d['title']).isNotEmpty ? _sv(d['title']) : '${widget.category} டிசைன்';
    final code = _sv(d['code']), note = _sv(d['note']), purity = _sv(d['purity']), size = _sv(d['size']);
    final w = num.tryParse(_sv(d['weight_g']));
    final weight = w == null ? '' : '${w == w.roundToDouble() ? w.toInt() : double.parse(w.toStringAsFixed(3))} கி';
    final specs = <List<String>>[if (weight.isNotEmpty) ['எடை', weight], if (purity.isNotEmpty) ['தூய்மை', purity], if (size.isNotEmpty) ['அளவு', size]];
    final similar = widget.all.where((x) => x['id'] != d['id']).toList();
    final tag = _sv(d['tag']);
    if (tag.isNotEmpty) similar.sort((a, b) => (_sv(b['tag']) == tag ? 1 : 0) - (_sv(a['tag']) == tag ? 1 : 0));
    final imgH = MediaQuery.of(context).size.width * 1.1;
    return Scaffold(
      backgroundColor: C.ivory,
      body: Stack(children: [
        ListView(controller: _sc, padding: EdgeInsets.only(bottom: pad.bottom + 110), children: [
          SizedBox(
            height: imgH,
            child: Stack(fit: StackFit.expand, children: [
              Container(color: const Color(0xFF2A0610)),
              PageView.builder(
                controller: _pc,
                itemCount: imgs.length,
                onPageChanged: (n) => setState(() => img = n),
                itemBuilder: (_, n) => GestureDetector(
                  onTap: () => _zoom(imgs, n),
                  child: n == 0
                      ? Hero(tag: 'catp${d['id']}', child: Image.network(imgs[n], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: C.ivory2)))
                      : Image.network(imgs[n], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: C.ivory2)),
                ),
              ),
              if (imgs.length > 1)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var k = 0; k < imgs.length; k++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: k == img ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(color: k == img ? Colors.white : Colors.white54, borderRadius: BorderRadius.circular(4)),
                      ),
                  ]),
                ),
              Positioned(
                right: 14,
                top: pad.top + 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0x73000000), borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('தொட்டு பெரிதாக்க', style: sans(11.5, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
          ),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              decoration: const BoxDecoration(color: C.ivory, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (code.isNotEmpty || _sv(d['badge']).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      if (code.isNotEmpty) Text(code, style: sans(12.5, color: C.goldText, weight: FontWeight.w700)),
                      if (code.isNotEmpty) const SizedBox(width: 8),
                      designBadge(_sv(d['badge'])),
                    ]),
                  ),
                Text(title, style: serif(25, height: 1.3)),
                if (note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(note, style: sans(14.5, color: C.mute, height: 1.5))),
                if (specs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    for (var k = 0; k < specs.length; k++) ...[
                      if (k > 0) const SizedBox(width: 8),
                      _spec(specs[k][0], specs[k][1]),
                    ],
                  ]),
                ],
                if (d['hallmark'] == true) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.goldLine)),
                    child: Row(children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFF3D68A), Color(0xFF9E7A2E)])),
                        alignment: Alignment.center,
                        child: Text('BIS', style: sans(12, color: Colors.white, weight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('HUID முத்திரை உள்ளது', style: sans(14.5, weight: FontWeight.w700)),
                          Text('BIS CARE app-ல் சரிபார்க்கலாம்', style: sans(12.5, color: C.mute)),
                        ]),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.info_outline, size: 17, color: C.goldText),
                  const SizedBox(width: 6),
                  Expanded(child: Text('விலை, கிடைக்கும் அளவுகள் பற்றி எங்களிடம் கேளுங்கள்.', style: sans(13.5, color: C.mute, height: 1.5))),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  LikeButton(type: 'photo', id: d['id'], onDark: false, size: 24),
                  Text('விருப்பம்', style: sans(13.5, color: C.mute)),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () => shareJewel(context, imageUrl: imgs.first, title: _sv(d['title']), category: widget.category),
                    icon: const Icon(Icons.share_outlined, size: 20, color: C.navy),
                    label: Text('பகிர', style: sans(13.5, color: C.mute)),
                  ),
                ]),
                if (similar.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('இதே மாதிரி டிசைன்கள்', style: serif(18)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 176,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: similar.length > 12 ? 12 : similar.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, k) {
                        final x = similar[k];
                        return GestureDetector(
                          onTap: () => _show(x),
                          child: SizedBox(
                            width: 120,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network('${x['image_url']}', width: 120, height: 140, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 120, height: 140, color: C.ivory2)),
                              ),
                              const SizedBox(height: 5),
                              Text(_sv(x['title']).isNotEmpty ? _sv(x['title']) : designSpec(x), maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(12.5, weight: FontWeight.w600)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ]),
        Positioned(top: pad.top + 8, left: 12, child: _roundBtn(Icons.arrow_back_rounded, 'பின் செல்', () => Navigator.of(context).maybePop())),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(14, 12, 14, pad.bottom + 12),
            decoration: const BoxDecoration(color: C.paper, border: Border(top: BorderSide(color: Color(0xFFEFE3CB))), boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -3))]),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: C.goldLine, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    foregroundColor: C.navy,
                  ),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VisitPage())),
                  icon: const Icon(Icons.event_available, size: 19),
                  label: Text('நேரில் பார்க்க', style: sans(14.5, color: C.navy, weight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: C.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final label = _sv(d['title']).isNotEmpty ? '"${_sv(d['title'])}"' : 'இந்த டிசைன்';
                    final c = code.isNotEmpty ? ' ($code)' : '';
                    askShop(context, message: 'வணக்கம், ${widget.category} — $label$c பற்றி விவரம் வேண்டும்.', imageUrl: imgs.first);
                  },
                  icon: const Icon(Icons.chat_outlined, size: 19, color: Colors.white),
                  label: Text('விசாரிக்க', style: sans(14.5, color: Colors.white, weight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Full-screen swipe + pinch zoom, with "இந்த நகை பற்றி கேள்" (WhatsApp, includes the photo link).
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.photos, required this.start, required this.category});
  final List<Map<String, dynamic>> photos;
  final int start;
  final String category;
  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late int i = widget.start;
  late final PageController _pc = PageController(initialPage: widget.start);
  final _burst = ValueNotifier(0);

  @override
  void dispose() {
    _pc.dispose();
    _burst.dispose();
    super.dispose();
  }

  String _type(Map<String, dynamic> p) => '${p['_type'] ?? 'photo'}';

  void _doubleTapLike(Map<String, dynamic> p) {
    _burst.value++;
    if (!Likes.has(_type(p), p['id'])) Likes.toggle(context, _type(p), p['id']);
  }

  String _s(dynamic v) {
    final t = '${v ?? ''}';
    return t == 'null' ? '' : t;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.photos[i];
    final title = _s(p['title']), note = _s(p['note']);
    final pad = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _pc,
          itemCount: widget.photos.length,
          onPageChanged: (n) => setState(() => i = n),
          itemBuilder: (_, n) {
            final x = widget.photos[n];
            return GestureDetector(
              onDoubleTap: () => _doubleTapLike(x),
              child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Hero(
                  tag: 'catp${x['id']}',
                  child: Image.network('${x['image_url']}', fit: BoxFit.contain,
                      loadingBuilder: (c, w, e) => e == null ? w : const Center(child: CircularProgressIndicator(color: C.gold)),
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 48)),
                ),
              ),
            ));
          },
        ),
        HeartBurst(trigger: _burst),
        Positioned(
          top: pad.top + 6,
          left: 6,
          right: 12,
          child: Row(children: [
            IconButton(
              tooltip: 'மூடு',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(20)),
              child: Text('${i + 1} / ${widget.photos.length}', style: sans(14, color: Colors.white, weight: FontWeight.w600)),
            ),
          ]),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(18, 40, 18, pad.bottom + 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xDD000000)]),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (title.isNotEmpty) Text(title, style: serif(21, color: Colors.white)),
                    if (note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(note, style: sans(15, color: Colors.white70, height: 1.4))),
                  ]),
                ),
                LikeButton(type: _type(p), id: p['id']),
                IconButton(
                  tooltip: 'பகிர',
                  onPressed: () => shareJewel(context, imageUrl: '${p['image_url']}', title: title, category: widget.category),
                  icon: const Icon(Icons.share_outlined, color: Colors.white, size: 26),
                ),
              ]),
              const SizedBox(height: 12),
              PrimaryButton('இந்த நகை பற்றி விசாரிக்க', gold: true, icon: Icons.chat_outlined, onTap: () {
                final label = title.isNotEmpty ? '"$title"' : 'இந்த டிசைன்';
                final cat = widget.category.isNotEmpty ? '${widget.category} — ' : '';
                askShop(context, message: 'வணக்கம், $cat$label பற்றி விவரம் வேண்டும் (எடை / விலை).', imageUrl: '${p['image_url']}');
              }),
            ]),
          ),
        ),
      ]),
    );
  }
}
