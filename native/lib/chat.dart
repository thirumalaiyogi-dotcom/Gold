import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

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
    showNote(context, 'கேள்வி கேட்க முதல்ல mPIN போட்டு உள்நுழையுங்க');
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
      } else {
        setState(() {
          loading = false;
          err = 'உள்நுழைவு சரிபார்க்க முடியல. மறுபடி login செய்யுங்க.';
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
        unawaited(http.post(Uri.parse('${Api.url}/functions/v1/push'),
            headers: {'apikey': Api.anon, 'Authorization': 'Bearer ${Api.anon}', 'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'chat_ask', 'mobile': app.mobile, 'pin': app.pin})).catchError((_) => http.Response('', 500)));
      } else {
        showNote(context, d is Map && d['err'] == 'too_many' ? 'இன்னைக்கு அதிக செய்திகள் அனுப்பியாச்சு. நாளை தொடரலாம் அல்லது கடைக்கு அழைக்கவும்.' : 'அனுப்ப முடியல. மறுபடி முயற்சிக்கவும்.');
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
          SelectableText('${m['b']}', style: sans(15, color: mine ? Colors.white : C.ink, height: 1.5)),
          const SizedBox(height: 2),
          Text(_hm(_t(m)), style: sans(11, color: mine ? const Color(0xFFF1D9DD) : C.mute)),
        ]),
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
          child: Text('வணக்கம் ${Demo.firstName} 🙏\nஉங்க சந்தேகத்தை இங்கே கேளுங்க. கடை ஊழியர் இங்கேயே பதில் தருவார்; பதில் வந்ததும் notification வரும்.\nஇந்த பேச்சு உங்களுக்கும் கடைக்கும் மட்டும்.',
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
              Text(_afterHours ? 'கடை இப்போ மூடியிருக்கு · காலை 9 மணிக்கு மேல் பதில்' : 'பொதுவா சில மணி நேரத்தில் பதில்', style: sans(12, color: C.mute)),
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
                    hintText: 'கேள்வியை இங்கே எழுதுங்க…',
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
                  Text(n > 0 ? 'கடையிலிருந்து $n புது பதில்' : 'சந்தேகமா? இங்கேயே கேளுங்க, பதில் வரும்', style: sans(13, color: n > 0 ? C.navy : C.mute, weight: n > 0 ? FontWeight.w600 : FontWeight.w400)),
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
