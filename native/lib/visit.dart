import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.dart';
import 'chat.dart';
import 'login.dart';
import 'main.dart';
import 'ui.dart';

/// நகை வாங்க கடை வருகை — customer picks a day + காலை / மாலை.
/// The booking is saved (gold_visits) and also appears in the customer's chat, so staff get a push and confirm there.
class VisitPage extends StatefulWidget {
  const VisitPage({super.key});
  @override
  State<VisitPage> createState() => _VisitPageState();
}

class _VisitPageState extends State<VisitPage> {
  late final List<DateTime> _days;
  DateTime? _day;
  String _slot = 'm';
  final _note = TextEditingController();
  bool _busy = false, _loading = true;
  List<dynamic> _mine = [];

  @override
  void initState() {
    super.initState();
    final t = nowIst();
    final d0 = DateTime(t.year, t.month, t.day);
    _days = [for (var i = 0; i < 21; i++) d0.add(Duration(days: i))];
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load({int? cancel}) async {
    if (!app.loggedIn) {
      setState(() => _loading = false);
      return;
    }
    try {
      final d = await Api.rpc('gold_visit_mine', {'p_mobile': app.mobile, 'p_pin': app.pin, if (cancel != null) 'p_cancel': cancel});
      if (d is Map && d['ok'] == true) _mine = (d['visits'] as List?) ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _iso(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static const _wd = ['திங்', 'செவ்', 'புத', 'வியா', 'வெள்', 'சனி', 'ஞாயி'];

  void _pingStaff() {
    unawaited(http
        .post(Uri.parse('${Api.url}/functions/v1/push'),
            headers: {'apikey': Api.anon, 'Authorization': 'Bearer ${Api.anon}', 'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'chat_ask', 'mobile': app.mobile, 'pin': app.pin}))
        .then((_) {}, onError: (_) {}));
  }

  Future<void> _book() async {
    if (_busy) return;
    if (_day == null) {
      showNote(context, 'வர விரும்பும் நாளைத் தேர்ந்தெடுக்கவும்.', ok: false);
      return;
    }
    tapFeel();
    setState(() => _busy = true);
    String err = '';
    try {
      final d = await Api.rpc('gold_visit_book', {
        'p_mobile': app.mobile,
        'p_pin': app.pin,
        'p_date': _iso(_day!),
        'p_slot': _slot,
        'p_note': _note.text.trim(),
      });
      if (d is Map && d['ok'] == true) {
        _pingStaff();
        _note.clear();
        _day = null;
        await _load();
        if (mounted) showNote(context, 'வருகை பதிவு செய்யப்பட்டது. கடை உறுதி செய்ததும் "கடையிடம் கேளுங்க"-ல் பதில் வரும்.');
      } else {
        err = '${(d is Map ? d['err'] : '') ?? ''}';
      }
    } catch (_) {
      err = 'net';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (err.isNotEmpty) {
      showNote(
          context,
          err == 'too_many'
              ? 'ஏற்கனவே 2 வருகை பதிவு உள்ளது. பழையதை ரத்து செய்த பிறகு புதியது பதியலாம்.'
              : err == 'date'
                  ? 'இந்த நாளைத் தேர்ந்தெடுக்க இயலாது.'
                  : 'பதிவு செய்ய இயலவில்லை. மீண்டும் முயற்சிக்கவும்.',
          ok: false);
    }
  }

  Future<void> _cancel(int id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('வருகையை ரத்து செய்யவா?', style: sans(16.5, weight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('வேண்டாம்')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('ரத்து செய்')),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _loading = true);
    await _load(cancel: id);
    _pingStaff();
  }

  Widget _chip(String label, bool on, VoidCallback tap, {String? sub}) => GestureDetector(
        onTap: () {
          tapFeel();
          tap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: on ? C.navy : C.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? C.navy : C.line2),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (sub != null) Text(sub, style: sans(11.5, color: on ? const Color(0xFFF1D9DD) : C.mute)),
            Text(label, style: sans(15, color: on ? Colors.white : C.ink, weight: FontWeight.w700)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.ivory,
      appBar: AppBar(backgroundColor: C.paper, surfaceTintColor: C.paper, foregroundColor: C.navy, title: Text('நகை வாங்க வருகை', style: sans(16.5, color: C.ink, weight: FontWeight.w700))),
      body: !app.loggedIn
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('வருகை பதிவு செய்ய Passbook-ல் உள்நுழையவும்.', style: sans(14.5, color: C.mute, height: 1.6), textAlign: TextAlign.center),
                const SizedBox(height: 14),
                PrimaryButton('உள்நுழைய', onTap: () => openPassbookLogin(context)),
              ]),
            )
          : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
              Text('உங்கள் சேமிப்பில் நகை வாங்க கடைக்கு வரும் நாளைப் பதிவு செய்யுங்கள். கடை உங்களுக்காக நேரம் ஒதுக்கி உறுதி செய்யும்.',
                  style: sans(14, color: C.mute, height: 1.6)),
              if (_mine.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('உங்கள் வருகைகள்', style: sans(15, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (final v in _mine)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                    decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.goldLine)),
                    child: Row(children: [
                      const Icon(Icons.event_available, color: C.goldText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${taDate('${v['d']}')} · ${v['s'] == 'm' ? 'காலை' : 'மாலை'}', style: sans(14.5, weight: FontWeight.w700)),
                          Text(v['st'] == 'ok' ? 'கடை உறுதி செய்தது ✓' : 'கடையின் உறுதிக்காக காத்திருக்கிறது',
                              style: sans(12.5, color: v['st'] == 'ok' ? C.green : C.mute)),
                        ]),
                      ),
                      TextButton(onPressed: () => _cancel((v['id'] as num).toInt()), child: Text('ரத்து', style: sans(13.5, color: C.red, weight: FontWeight.w600))),
                    ]),
                  ),
              ],
              const SizedBox(height: 18),
              Text('எந்த நாள்?', style: sans(15, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final d = _days[i];
                    final on = _day == d;
                    return _chip('${d.day}', on, () => setState(() => _day = d), sub: i == 0 ? 'இன்று' : i == 1 ? 'நாளை' : _wd[d.weekday - 1]);
                  },
                ),
              ),
              if (_day != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(taDate(_iso(_day!)), style: sans(13, color: C.goldText, weight: FontWeight.w600))),
              const SizedBox(height: 16),
              Text('எந்த நேரம்?', style: sans(15, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _chip('காலை', _slot == 'm', () => setState(() => _slot = 'm'))),
                const SizedBox(width: 10),
                Expanded(child: _chip('மாலை', _slot == 'e', () => setState(() => _slot = 'e'))),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: _note,
                maxLines: 3,
                minLines: 2,
                maxLength: 300,
                style: sans(15),
                decoration: InputDecoration(
                  hintText: 'என்ன நகை பார்க்க வருகிறீர்கள்? (விருப்பம்)',
                  hintStyle: sans(14, color: C.mute),
                  filled: true,
                  fillColor: C.paper,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line2)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line2)),
                ),
              ),
              const SizedBox(height: 6),
              PrimaryButton(_busy ? 'பதிவு செய்கிறது…' : 'வருகையைப் பதிவு செய்', icon: Icons.event_available, busy: _busy, onTap: _book),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: () => openChat(context),
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: Text('கடையிடம் கேளுங்க', style: sans(13.5, weight: FontWeight.w600)),
                ),
              ),
              if (_loading) const Padding(padding: EdgeInsets.only(top: 8), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            ]),
    );
  }
}

/// Passbook card — shown in the last month of a scheme and after it is complete.
Widget visitCard(BuildContext context) => LuxCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const RingIcon(Icons.diamond_outlined, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(Demo.schemeDone ? 'சேமிப்பு நிறைவு 🎉' : 'சேமிப்பு நிறைவை நெருங்குகிறது', style: serif(18)),
              const SizedBox(height: 2),
              Text('நகை தேர்ந்தெடுக்க கடைக்கு வரும் நாளைப் பதிவு செய்யுங்கள்.', style: sans(13, color: C.mute, height: 1.5)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        PrimaryButton('வருகை பதிவு', gold: true, icon: Icons.event_available, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VisitPage()))),
      ]),
    );
