import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api.dart';
import 'links.dart';
import 'login.dart';
import 'main.dart';
import 'ui.dart';

/// Unread shop replies (badge on the "கடையிடம் கேளுங்க" entries).
final ValueNotifier<int> chatUnread = ValueNotifier(0);

/// Cheap unread check (no messages returned, nothing marked as read).
Future<void> refreshChatUnread() async {
  if (!app.loggedIn || app.mobile.isEmpty || app.pin.isEmpty) {
    chatUnread.value = 0;
    return;
  }
  try {
    final d = await Api.rpc('gold_chat_get', {'p_mobile': app.mobile, 'p_pin': app.pin, 'p_after': 9000000000000000, 'p_mark': false});
    if (d is Map && d['ok'] == true) chatUnread.value = (d['unread'] as num?)?.toInt() ?? 0;
  } catch (_) {}
}

void openChat(BuildContext context) {
  tapFeel();
  if (!app.loggedIn) {
    showNote(context, 'கேள்வி கேட்க mPIN மூலம் உள்நுழையவும்');
    openPassbookLogin(context);
    return;
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
}

/// WhatsApp-style private chat with the shop. Staff reply from the staff panel → push to this phone.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _in = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, dynamic>> _msgs = [];
  bool loading = true, sending = false;
  String err = '';
  Timer? _poll;
  final Map<String, String> _urls = {}; // storage path → signed link (1 h)

  static const _quick = [
    'இந்த மாத தவணை எப்போ கட்டணும்?',
    'என் தவணை வரவு வைக்கப்பட்டதா?',
    'நகை எப்போ வாங்கலாம்?',
    'திட்டத் தொகையை மாற்றலாமா?',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _in.dispose();
    _scroll.dispose();
    super.dispose();
  }

  int get _lastId => _msgs.isEmpty ? 0 : (_msgs.last['id'] as num).toInt();

  Future<void> _load({bool quiet = false}) async {
    try {
      final d = await Api.rpc('gold_chat_get', {'p_mobile': app.mobile, 'p_pin': app.pin, 'p_after': _lastId, 'p_mark': true});
      if (!mounted) return;
      if (d is Map && d['ok'] == true) {
        final add = (d['msgs'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).where((m) => !_msgs.any((x) => x['id'] == m['id'])).toList();
        setState(() {
          _msgs.addAll(add);
          loading = false;
          err = '';
        });
        chatUnread.value = 0;
        if (add.isNotEmpty) _toEnd();
        _signImages();
      } else {
        setState(() {
          loading = false;
          err = 'உள்நுழைவு காலாவதியானது. மீண்டும் உள்நுழையவும்.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        if (!quiet) err = 'இணைய இணைப்பை சரிபார்க்கவும்';
      });
    }
  }

  Future<Map<String, dynamic>> _fn(String name, Map<String, dynamic> body) async {
    try {
      final r = await http.post(Uri.parse('${Api.url}/functions/v1/$name'),
          headers: {'apikey': Api.anon, 'Authorization': 'Bearer ${Api.anon}', 'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 40));
      final d = jsonDecode(utf8.decode(r.bodyBytes));
      return d is Map ? Map<String, dynamic>.from(d) : {'ok': false};
    } catch (_) {
      return {'ok': false, 'err': 'net'};
    }
  }

  Future<void> _signImages() async {
    final need = _msgs.map((m) => '${m['i'] ?? ''}').where((p) => p.isNotEmpty && p != 'null' && !_urls.containsKey(p)).toSet().toList();
    if (need.isEmpty) return;
    final d = await _fn('chat-img', {'action': 'sign', 'mobile': app.mobile, 'pin': app.pin, 'paths': need});
    final u = d['urls'];
    if (u is Map && mounted) setState(() => u.forEach((k, v) => _urls['$k'] = '$v'));
  }

  Future<void> _pickPhoto() async {
    if (sending) return;
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: C.formBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(leading: const Icon(Icons.photo_library_outlined, color: C.navy), title: Text('Gallery-லிருந்து', style: sans(15.5)), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          ListTile(leading: const Icon(Icons.photo_camera_outlined, color: C.navy), title: Text('Camera-வில் எடுக்க', style: sans(15.5)), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (src == null) return;
    XFile? f;
    try {
      f = await ImagePicker().pickImage(source: src, maxWidth: 1280, maxHeight: 1280, imageQuality: 72);
    } catch (_) {
      if (mounted) showNote(context, 'படத்தைத் திறக்க இயலவில்லை');
      return;
    }
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      if (mounted) showNote(context, 'படம் மிகப் பெரியது (2 MB-க்கு மேல்)');
      return;
    }
    setState(() => sending = true);
    final d = await _fn('chat-img', {'action': 'upload', 'mobile': app.mobile, 'pin': app.pin, 'data': base64Encode(bytes), 'caption': _in.text.trim()});
    if (!mounted) return;
    if (d['ok'] == true) {
      _in.clear();
      await _load(quiet: true);
      unawaited(_fn('push', {'action': 'chat_ask', 'mobile': app.mobile, 'pin': app.pin}));
    } else {
      showNote(context, d['err'] == 'too_many' ? 'இன்றைக்கான படம் அனுப்பும் வரம்பு முடிந்தது. நாளை மீண்டும் அனுப்பலாம்.' : 'படத்தை அனுப்ப இயலவில்லை. மீண்டும் முயற்சிக்கவும்.');
    }
    setState(() => sending = false);
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });

  Future<void> _send() async {
    final t = _in.text.trim();
    if (t.isEmpty || sending) return;
    setState(() => sending = true);
    HapticFeedback.selectionClick();
    try {
      final d = await Api.rpc('gold_chat_send', {'p_mobile': app.mobile, 'p_pin': app.pin, 'p_body': t});
      if (!mounted) return;
      if (d is Map && d['ok'] == true) {
        _in.clear();
        await _load(quiet: true);
        // tell the shop's phones (fire and forget)
        unawaited(_fn('push', {'action': 'chat_ask', 'mobile': app.mobile, 'pin': app.pin}));
      } else {
        showNote(context, d is Map && d['err'] == 'too_many' ? 'இன்றைக்கான செய்தி வரம்பு முடிந்தது. அவசரம் என்றால் கடைக்கு அழைக்கவும்.' : 'அனுப்ப இயலவில்லை. மீண்டும் முயற்சிக்கவும்.');
      }
    } catch (_) {
      if (mounted) showNote(context, 'இணைய இணைப்பை சரிபார்க்கவும்');
    }
    if (mounted) setState(() => sending = false);
  }

  static DateTime _t(Map m) => DateTime.tryParse('${m['t']}')?.toUtc().add(const Duration(hours: 5, minutes: 30)) ?? DateTime.now();
  static String _hm(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  static String _day(DateTime d) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final today = DateTime(now.year, now.month, now.day), dd = DateTime(d.year, d.month, d.day);
    if (dd == today) return 'இன்று';
    if (dd == today.subtract(const Duration(days: 1))) return 'நேற்று';
    return '${d.day} ${taMonth(d.month)} ${d.year}';
  }

  bool get _afterHours {
    final h = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)).hour;
    return h < 9 || h >= 21;
  }

  Widget _bubble(Map<String, dynamic> m) {
    final mine = m['s'] == 'c';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: mine ? C.navy : C.paper,
          border: mine ? null : Border.all(color: C.line2),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if ('${m['i'] ?? ''}'.isNotEmpty && '${m['i']}' != 'null') _photo('${m['i']}'),
          // catalogue enquiry: show the jewel picture instead of its long link
          if (chatBodyParts('${m['b']}').$2 != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(chatBodyParts('${m['b']}').$2!, width: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            ),
          if (!('${m['i'] ?? ''}'.isNotEmpty && '${m['i']}' != 'null' && '${m['b']}' == '📷 படம்') && chatBodyParts('${m['b']}').$1.isNotEmpty)
            SelectableText(chatBodyParts('${m['b']}').$1, style: sans(15, color: mine ? Colors.white : C.ink, height: 1.5)),
          const SizedBox(height: 2),
          Text(_hm(_t(m)), style: sans(11, color: mine ? const Color(0xFFF1D9DD) : C.mute)),
        ]),
      ),
    );
  }

  Widget _photo(String path) {
    final u = _urls[path];
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: u == null
            ? Container(width: 200, height: 150, color: const Color(0x22000000), alignment: Alignment.center, child: const Icon(Icons.image_outlined, color: Colors.white70))
            : GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
                          body: Center(child: InteractiveViewer(child: Image.network(u))),
                        ))),
                child: Image.network(u, width: 220, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 200, height: 60)),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      // welcome note from the shop
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .82),
          decoration: BoxDecoration(color: const Color(0xFFFFF7E0), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7D49B))),
          child: Text('வணக்கம் ${Demo.firstName},\nசேமிப்புத் திட்டம், தவணை, நகைகள் தொடர்பான உங்கள் கேள்விகளை இங்கே கேட்கலாம். பதில் வந்ததும் அறிவிப்பு வரும்.\nஇந்த உரையாடல் உங்களுக்கும் கடைக்கும் மட்டுமே தெரியும்.',
              style: sans(13.5, color: const Color(0xFF5A4410), height: 1.6)),
        ),
      ),
    ];
    String? lastDay;
    for (final m in _msgs) {
      final d = _day(_t(m));
      if (d != lastDay) {
        lastDay = d;
        items.add(Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: C.ivory2, borderRadius: BorderRadius.circular(99)),
            child: Text(d, style: sans(12, color: C.mute)),
          ),
        ));
      }
      items.add(_bubble(m));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: C.ivory,
        surfaceTintColor: C.ivory,
        foregroundColor: C.navy,
        titleSpacing: 0,
        title: Row(children: [
          ClipOval(child: Image.asset('assets/coin.png', width: 36, height: 36, errorBuilder: (_, __, ___) => const SizedBox(width: 36))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('கடையிடம் கேளுங்க', style: serif(18)),
              Text(_afterHours ? 'கடை நேரம் முடிந்தது · காலை 9 மணிக்குப் பிறகு பதில்' : 'வழக்கமாக சில மணி நேரத்தில் பதில்', style: sans(12, color: C.mute)),
            ]),
          ),
        ]),
        actions: [IconButton(tooltip: 'கடைக்கு அழை', onPressed: () => callShop(context), icon: const Icon(Icons.call_outlined))],
      ),
      body: Column(children: [
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: C.navy))
              : RefreshIndicator(
                  color: C.navy,
                  onRefresh: () => _load(),
                  child: ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(12, 12, 12, 12), children: [
                    ...items,
                    if (err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err, textAlign: TextAlign.center, style: sans(13, color: C.red))),
                  ]),
                ),
        ),
        if (!loading && _msgs.isEmpty)
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quick.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(_quick[i], style: sans(13, color: C.navy, weight: FontWeight.w600)),
                backgroundColor: C.paper,
                side: const BorderSide(color: C.line2),
                onPressed: () => setState(() => _in.text = _quick[i]),
              ),
            ),
          ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            decoration: const BoxDecoration(color: C.paper, border: Border(top: BorderSide(color: C.line2))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              SizedBox(
                width: 44,
                height: 50,
                child: IconButton(tooltip: 'படம் அனுப்ப', onPressed: sending ? null : _pickPhoto, icon: const Icon(Icons.photo_camera_outlined, color: C.navy)),
              ),
              Expanded(
                child: TextField(
                  controller: _in,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  style: sans(15.5),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'உங்கள் கேள்வி…',
                    hintStyle: sans(14.5, color: C.mute),
                    filled: true,
                    fillColor: C.ivory,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: C.line2)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: C.line2)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: C.navy, width: 1.4)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                height: 50,
                child: IconButton.filled(
                  tooltip: 'அனுப்பு',
                  onPressed: sending ? null : _send,
                  style: IconButton.styleFrom(backgroundColor: C.navy, disabledBackgroundColor: C.mute),
                  icon: sending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Entry tile used on Home / Account: "கடையிடம் கேளுங்க" with unread badge.
class ChatEntry extends StatelessWidget {
  const ChatEntry({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: chatUnread,
      builder: (context, n, _) => Material(
        color: C.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: C.line2)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => openChat(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: Color(0xFFF6EAD0), shape: BoxShape.circle),
                child: Badge(isLabelVisible: n > 0, label: Text('$n'), backgroundColor: C.red, child: const Icon(Icons.forum_outlined, color: C.navy)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('கடையிடம் கேளுங்க', style: sans(15.5, color: C.ink, weight: FontWeight.w700)),
                  Text(n > 0 ? 'கடையிலிருந்து $n புது பதில்' : 'உங்கள் கேள்விகளுக்கு கடையே நேரடியாகப் பதில் அளிக்கும்', style: sans(13, color: n > 0 ? C.navy : C.mute, weight: n > 0 ? FontWeight.w600 : FontWeight.w400)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: C.mute),
            ]),
          ),
        ),
      ),
    );
  }
}

/// கணக்கை நீக்க கோரிக்கை — sent inside the app as a chat message to the shop (no WhatsApp).
/// The shop sees it under "கேள்விகள்" and replies in the same chat.
Future<void> requestAccountDeletion(BuildContext context) async {
  tapFeel();
  if (!app.loggedIn) {
    showNote(context, 'கோரிக்கை அனுப்ப mPIN மூலம் உள்நுழையவும்');
    openPassbookLogin(context);
    return;
  }
  const reasons = ['இனி App பயன்படுத்தவில்லை', 'திட்டம் முடிந்தது', 'தகவல் பாதுகாப்பு', 'வேறு காரணம்'];
  String? reason;
  bool busy = false;
  final sent = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: C.ivory,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('கணக்கை நீக்க கோரிக்கை', style: serif(20)),
            const SizedBox(height: 8),
            Text('உங்கள் கோரிக்கை App வழியாகவே கடைக்குச் செல்லும். கடை உங்களைத் தொடர்பு கொண்டு உறுதி செய்யும்; பதில் "கடையிடம் கேளுங்க" பகுதியில் வரும்.',
                style: sans(13.5, color: C.mute, height: 1.6)),
            const SizedBox(height: 14),
            Text('காரணம் (விருப்பம்)', style: sans(13, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final r in reasons)
                ChoiceChip(
                  label: Text(r, style: sans(13, color: reason == r ? Colors.white : C.ink)),
                  selected: reason == r,
                  selectedColor: C.navy,
                  backgroundColor: C.paper,
                  side: BorderSide(color: reason == r ? C.navy : C.line2),
                  showCheckmark: false,
                  onSelected: (_) => set(() => reason = reason == r ? null : r),
                ),
            ]),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: busy
                    ? null
                    : () async {
                        set(() => busy = true);
                        final body = '🗑 கணக்கை நீக்க கோரிக்கை\nபெயர்: ${Demo.name}${Demo.member.isNotEmpty ? ' · உறுப்பினர் எண்: ${Demo.member}' : ''}\nதிட்டம்: ${Demo.scheme}${reason != null ? '\nகாரணம்: $reason' : ''}';
                        bool ok = false;
                        try {
                          final d = await Api.rpc('gold_chat_send', {'p_mobile': app.mobile, 'p_pin': app.pin, 'p_body': body});
                          ok = d is Map && d['ok'] == true;
                        } catch (_) {}
                        if (ok) {
                          // tell the shop's phones (same push as a new question)
                          unawaited(http
                              .post(Uri.parse('${Api.url}/functions/v1/push'),
                                  headers: {'apikey': Api.anon, 'Authorization': 'Bearer ${Api.anon}', 'Content-Type': 'application/json'},
                                  body: jsonEncode({'action': 'chat_ask', 'mobile': app.mobile, 'pin': app.pin}))
                              .then((_) {}, onError: (_) {}));
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop(ok);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text('கோரிக்கை அனுப்பு', style: sans(15.5, color: Colors.white, weight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('வேண்டாம்', style: sans(14.5, color: C.navy, weight: FontWeight.w600))),
          ]),
        ),
      ),
    ),
  );
  if (!context.mounted || sent == null) return;
  if (sent) {
    showNote(context, 'கோரிக்கை அனுப்பப்பட்டது. கடையின் பதில் இங்கே வரும்.');
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
  } else {
    showNote(context, 'அனுப்ப இயலவில்லை. மீண்டும் முயற்சிக்கவும்.');
  }
}

/// Catalogue / story / scheme enquiries go to the shop inside the app (chat + push to staff phones),
/// not to WhatsApp. Shows the photo and an editable message first.
/// Not logged in → choose: log in, or WhatsApp as before.
final _slidesImg = RegExp(r'https://\S+/storage/v1/object/public/slides/\S+');

/// Splits a chat body into (text without the catalogue picture link, picture URL or null).
(String, String?) chatBodyParts(String body) {
  final m = _slidesImg.firstMatch(body);
  if (m == null) return (body, null);
  return (body.replaceFirst(m.group(0)!, '').trim(), m.group(0));
}

Future<void> askShop(BuildContext context, {required String message, String? imageUrl, String? whatsAppText}) async {
  tapFeel();
  if (!app.loggedIn) {
    final go = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: C.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('கடையிடம் கேட்க', style: serif(20)),
            const SizedBox(height: 6),
            Text('Passbook-ல் உள்நுழைந்தால் App-லேயே கேட்கலாம்; கடையின் பதில் இங்கே அறிவிப்பாக வரும்.', style: sans(13.5, color: C.mute, height: 1.6)),
            const SizedBox(height: 16),
            PrimaryButton('உள்நுழைந்து App-ல் கேட்க', icon: Icons.lock_open_rounded, onTap: () => Navigator.pop(ctx, 'login')),
            const SizedBox(height: 8),
            OutlineBtn('WhatsApp-ல் கேட்க', icon: Icons.chat_outlined, onTap: () => Navigator.pop(ctx, 'wa')),
          ]),
        ),
      ),
    );
    if (!context.mounted) return;
    if (go == 'login') openPassbookLogin(context);
    if (go == 'wa') whatsApp(context, whatsAppText ?? '$message${imageUrl != null ? '\n$imageUrl' : ''}');
    return;
  }
  final ctl = TextEditingController(text: message);
  bool busy = false;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: C.ivory,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 64, height: 64)),
                  ),
                if (imageUrl != null) const SizedBox(width: 12),
                Expanded(child: Text('கடையிடம் கேட்க', style: serif(20))),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: ctl,
                minLines: 2,
                maxLines: 5,
                maxLength: 600,
                style: sans(15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: C.paper,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line2)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line2)),
                ),
              ),
              Text('கடையின் பதில் "கடையிடம் கேளுங்க" பகுதியில் வரும்; அறிவிப்பும் வரும்.', style: sans(12.5, color: C.mute, height: 1.5)),
              const SizedBox(height: 12),
              PrimaryButton(busy ? 'அனுப்புகிறது…' : 'அனுப்பு', icon: Icons.send_rounded, onTap: () async {
                if (busy || ctl.text.trim().isEmpty) return;
                set(() => busy = true);
                final body = '${ctl.text.trim()}${imageUrl != null ? '\n$imageUrl' : ''}';
                bool sent = false;
                try {
                  final d = await Api.rpc('gold_chat_send', {'p_mobile': app.mobile, 'p_pin': app.pin, 'p_body': body});
                  sent = d is Map && d['ok'] == true;
                } catch (_) {}
                if (sent) {
                  unawaited(http
                      .post(Uri.parse('${Api.url}/functions/v1/push'),
                          headers: {'apikey': Api.anon, 'Authorization': 'Bearer ${Api.anon}', 'Content-Type': 'application/json'},
                          body: jsonEncode({'action': 'chat_ask', 'mobile': app.mobile, 'pin': app.pin}))
                      .then((_) {}, onError: (_) {}));
                }
                if (ctx.mounted) Navigator.of(ctx).pop(sent);
              }),
            ]),
          ),
        ),
      ),
    ),
  );
  if (!context.mounted || ok == null) return;
  if (ok) {
    showNote(context, 'கேள்வி கடைக்கு அனுப்பப்பட்டது. பதில் வந்ததும் அறிவிப்பு வரும்.');
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
  } else {
    showNote(context, 'அனுப்ப இயலவில்லை. மீண்டும் முயற்சிக்கவும்.');
  }
}
