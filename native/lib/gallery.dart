import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'chat.dart';
import 'likes.dart';
import 'links.dart';
import 'ui.dart';

/// நகை வகை → photos added by staff (gold_category_photos). Tap a photo → full screen + "WhatsApp-ல் கேள்".
class CategoryGallery extends StatefulWidget {
  const CategoryGallery({super.key, required this.cat});
  final Map<String, dynamic> cat;
  @override
  State<CategoryGallery> createState() => _CategoryGalleryState();
}

class _CategoryGalleryState extends State<CategoryGallery> {
  List<Map<String, dynamic>> photos = [];
  bool loading = true, failed = false;

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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    Widget body;
    if (loading) {
      body = GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .8,
        children: List.generate(6, (_) => const Skeleton(height: 200, radius: 16)),
      );
    } else if (photos.isEmpty) {
      body = ListView(padding: const EdgeInsets.fromLTRB(24, 60, 24, 24), children: [
        const Icon(Icons.photo_library_outlined, size: 54, color: C.goldText),
        const SizedBox(height: 14),
        Text(failed ? 'படங்களை ஏற்ற முடியல' : '$name டிசைன்கள் விரைவில்', textAlign: TextAlign.center, style: serif(20)),
        const SizedBox(height: 8),
        Text(failed ? 'இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.' : 'புதிய டிசைன் படங்களுக்கு WhatsApp-ல் எங்களைத் தொடர்பு கொள்ளுங்கள்.',
            textAlign: TextAlign.center, style: sans(15, color: C.mute, height: 1.5)),
        const SizedBox(height: 22),
        if (failed) OutlineBtn('மீண்டும் முயற்சி', icon: Icons.refresh, onTap: _load) else PrimaryButton('கடையிடம் கேட்க', icon: Icons.chat_outlined, onTap: _askWa),
      ]);
    } else {
      body = RefreshIndicator(
        color: C.navy,
        onRefresh: _load,
        child: GridView.builder(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 90),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .8),
          itemCount: photos.length,
          itemBuilder: (context, i) => _tile(i),
        ),
      );
    }
    return Scaffold(
      backgroundColor: C.ivory,
      appBar: AppBar(
        backgroundColor: C.ivory,
        surfaceTintColor: C.ivory,
        foregroundColor: C.navy,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: serif(20)),
          if (photos.isNotEmpty) Text('${photos.length} டிசைன்கள்', style: sans(12.5, color: C.mute)),
        ]),
      ),
      body: body,
      floatingActionButton: photos.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: C.navy,
              foregroundColor: Colors.white,
              onPressed: _askWa,
              icon: const Icon(Icons.chat_outlined),
              label: Text('கடையிடம் கேட்க', style: sans(15, color: Colors.white, weight: FontWeight.w700)),
            ),
    );
  }

  Widget _tile(int i) {
    final p = photos[i];
    final t = '${p['title'] ?? ''}';
    final hasT = t.isNotEmpty && t != 'null';
    return Semantics(
      button: true,
      label: hasT ? t : '$name டிசைன் ${i + 1}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black,
            pageBuilder: (_, __, ___) => PhotoViewer(photos: photos, start: i, category: name),
            transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          ));
        },
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
              Hero(
                tag: 'catp${p['id']}',
                child: Image.network('${p['image_url']}', fit: BoxFit.cover,
                    loadingBuilder: (c, w, e) => e == null ? w : Container(color: C.ivory2),
                    errorBuilder: (_, __, ___) => Container(color: C.ivory2, child: const Icon(Icons.image_not_supported_outlined, color: C.mute))),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: Likes.keys,
                  builder: (_, __, ___) => Likes.has('photo', p['id'])
                      ? Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: Color(0xE6FFFFFF), shape: BoxShape.circle),
                          child: const Icon(Icons.favorite, size: 16, color: Color(0xFFE0245E)),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              ]),
            ),
            if (hasT)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(14, weight: FontWeight.w600)),
              ),
          ]),
        ),
      ),
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
