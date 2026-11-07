import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'data.dart';
import 'ui.dart';

/// விலை நிலவரம் — gold / silver, range chips, line chart, stats, daily list.
class RatePage extends StatefulWidget {
  const RatePage({super.key});
  @override
  State<RatePage> createState() => _RatePageState();
}

class _RatePageState extends State<RatePage> {
  bool silver = false;
  int days = 30;

  @override
  Widget build(BuildContext context) {
    final h = rateHistory(silver: silver, days: days);
    final vals = h.map((e) => e[1].toDouble()).toList();
    final hi = vals.reduce(math.max), lo = vals.reduce(math.min);
    final diff = vals.last - vals.first;
    final dec = silver ? 2 : 0;
    String day(num back) {
      final d = DateTime.now().subtract(Duration(days: back.toInt()));
      const m = ['ஜன.', 'பிப்.', 'மார்.', 'ஏப்.', 'மே', 'ஜூன்', 'ஜூலை', 'ஆக.', 'செப்.', 'அக்.', 'நவ.', 'டிச.'];
      return '${d.day} ${m[d.month - 1]}';
    }

    Widget seg(String t, bool on, VoidCallback f) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: () {
              tapFeel();
              f();
            },
            child: Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: on ? C.navy : Colors.transparent, borderRadius: BorderRadius.circular(99)),
              child: Text(t, style: sans(14, color: on ? Colors.white : C.ink, weight: FontWeight.w700)),
            ),
          ),
        );

    return Scaffold(
      backgroundColor: C.ivory,
      appBar: AppBar(backgroundColor: C.paper, surfaceTintColor: C.paper, foregroundColor: C.navy, title: Text('விலை நிலவரம்', style: sans(16.5, color: C.ink, weight: FontWeight.w700))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(99), border: Border.all(color: C.line2)),
          child: Row(children: [seg('தங்கம் 22K', !silver, () => setState(() => silver = false)), seg('வெள்ளி', silver, () => setState(() => silver = true))]),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          for (final d in [7, 30, 90])
            ChoiceChip(
              label: Text(d == 7 ? '7 நாட்கள்' : d == 30 ? '1 மாதம்' : '3 மாதம்'),
              selected: days == d,
              selectedColor: C.goldSoft,
              onSelected: (_) => setState(() => days = d),
            ),
        ]),
        const SizedBox(height: 12),
        LuxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(silver ? 'வெள்ளி · ₹ / கிராம்' : '22K தங்கம் · ₹ / கிராம்', style: sans(13, color: C.mute)),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(rupees(vals.last, decimals: dec), style: serif(30, color: C.ink, weight: FontWeight.w700)),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${diff >= 0 ? '▲' : '▼'} ${rupees(diff.abs(), decimals: dec)}', style: sans(13.5, color: diff >= 0 ? C.green : C.red, weight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 14),
            SizedBox(height: 180, width: double.infinity, child: CustomPaint(painter: _Chart(vals))),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(day(h.first[0]), style: sans(11.5, color: C.mute)),
              Text(day(0), style: sans(11.5, color: C.mute)),
            ]),
            const SizedBox(height: 6),
            Text('மாதிரி விலைகள் · உண்மையான app கடை பதிவு செய்த விலைகளைக் காட்டும்', style: sans(11.5, color: C.mute)),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _stat('அதிகபட்ச விலை', rupees(hi, decimals: dec)),
          const SizedBox(width: 8),
          _stat('குறைந்தபட்ச விலை', rupees(lo, decimals: dec)),
          const SizedBox(width: 8),
          _stat('மாற்றம்', '${diff >= 0 ? '+' : '−'}${rupees(diff.abs(), decimals: dec)}', color: diff >= 0 ? C.green : C.red),
        ]),
        const SizedBox(height: 18),
        Text('தேதி வாரியான விலை', style: serif(18, color: C.ink, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        LuxCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: [
            for (final e in h.reversed.take(10))
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1E9D8)))),
                child: Row(children: [
                  Expanded(child: Text(day(e[0]), style: sans(14))),
                  Text(rupees(e[1], decimals: dec), style: sans(14.5, weight: FontWeight.w700)),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(String l, String v, {Color color = C.ink}) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line2)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: sans(11.5, color: C.mute)),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: sans(15, color: color, weight: FontWeight.w700))),
          ]),
        ),
      );
}

class _Chart extends CustomPainter {
  _Chart(this.v);
  final List<double> v;
  @override
  void paint(Canvas canvas, Size size) {
    if (v.length < 2) return;
    final hi = v.reduce(math.max), lo = v.reduce(math.min);
    final span = (hi - lo).abs() < 1e-6 ? 1.0 : hi - lo;
    Offset pt(int i) => Offset(size.width * i / (v.length - 1), size.height - 8 - (v[i] - lo) / span * (size.height - 16));
    final grid = Paint()
      ..color = const Color(0xFFF1E9D8)
      ..strokeWidth = 1;
    for (var k = 0; k < 4; k++) {
      final y = size.height * k / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < v.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x55C9A45C), Color(0x00C9A45C)])
              .createShader(Offset.zero & size));
    canvas.drawPath(
        path,
        Paint()
          ..color = C.navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round);
    canvas.drawCircle(pt(v.length - 1), 4.5, Paint()..color = C.gold);
  }

  @override
  bool shouldRepaint(covariant _Chart old) => old.v != v;
}
