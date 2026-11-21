import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'main.dart';
import 'share_card.dart' show shareBytes;
import 'ui.dart';

/// கணக்கு அறிக்கை — the whole passbook on one sheet, shared as a PDF.
/// The sheet is drawn by Flutter (so Tamil letters are shaped correctly) and placed in the PDF as pictures.
class StatementPage extends StatefulWidget {
  const StatementPage({super.key});
  @override
  State<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends State<StatementPage> {
  final _key = GlobalKey();
  bool _busy = false;

  String _today() {
    final n = nowIst();
    return taDate(n.toIso8601String());
  }

  Future<void> _sharePdf() async {
    setState(() => _busy = true);
    String step = 'capture';
    try {
      final b = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (b == null) throw 'no sheet';
      final img = await b.toImage(pixelRatio: 2.5);
      final w = img.width.toDouble(), pageH = (w * 1.414).floorToDouble();
      step = 'pages';
      // ASCII metadata only (the PDF info dictionary is not safe for Tamil text)
      final doc = pw.Document(title: 'Account statement', author: 'Subbulakshmi Thanga Maaligai', compress: true);
      for (double y = 0; y < img.height; y += pageH) {
        final h = (img.height - y).clamp(1, pageH).toDouble();
        final rec = ui.PictureRecorder();
        final cv = Canvas(rec);
        cv.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
        cv.drawImageRect(img, Rect.fromLTWH(0, y, w, h), Rect.fromLTWH(0, 0, w, h), Paint()..filterQuality = FilterQuality.high);
        final part = await rec.endRecording().toImage(w.toInt(), h.toInt());
        // raw pixels → no PNG decoding inside the pdf package
        final raw = await part.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (raw == null) continue;
        final pic = pw.RawImage(bytes: raw.buffer.asUint8List(), width: part.width, height: part.height);
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(22),
          build: (_) => pw.Align(alignment: pw.Alignment.topCenter, child: pw.Image(pic, fit: pw.BoxFit.contain)),
        ));
      }
      step = 'save';
      final bytes = await doc.save();
      step = 'share';
      final name = 'STM-statement-${Demo.member.isEmpty ? 'passbook' : Demo.member}.pdf';
      await shareBytes(bytes, name, 'application/pdf', text: 'சுப்புலட்சுமி தங்க மாளிகை · கணக்கு அறிக்கை · ${Demo.name}');
    } catch (e) {
      debugPrint('statement pdf failed at $step: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF உருவாக்க இயலவில்லை ($step). மீண்டும் முயற்சிக்கவும்.')));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ps = Demo.payments.reversed.toList(); // oldest first on paper
    final grams = Demo.grams;
    const ink = Color(0xFF2A1A1F), mute = Color(0xFF6A5B61), line = Color(0xFFE6DCC6);
    TextStyle t(double s, {FontWeight w = FontWeight.w400, Color c = ink}) => sans(s, color: c, weight: w, height: 1.35);
    Widget info(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 122, child: Text(k, style: t(11.5, c: mute))),
            Expanded(child: Text(v, style: t(12, w: FontWeight.w700))),
          ]),
        );
    Widget cell(String s, {int flex = 2, TextAlign a = TextAlign.left, bool head = false}) =>
        Expanded(flex: flex, child: Text(s, textAlign: a, style: t(head ? 11 : 11.5, w: head ? FontWeight.w700 : FontWeight.w500, c: head ? mute : ink)));
    Widget tr(List<Widget> c, {bool head = false}) => Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: head ? const Color(0xFFF6EFDF) : null,
            border: const Border(bottom: BorderSide(color: line)),
          ),
          child: Row(children: c),
        );

    final sheet = Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Image.asset('assets/logo.png', height: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('சுப்புலட்சுமி தங்க மாளிகை', style: t(15, w: FontWeight.w700, c: C.navy)),
              Text('51B, கங்கை அம்மன் கோவில் தெரு, காந்தி பஜார், புளியங்குடி – 627855 · 97919 18344', style: t(10, c: mute)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Container(height: 2, color: C.gold),
        const SizedBox(height: 10),
        Text('கணக்கு அறிக்கை', textAlign: TextAlign.center, style: t(16, w: FontWeight.w700)),
        Text('உருவாக்கிய நாள்: ${_today()}', textAlign: TextAlign.center, style: t(10.5, c: mute)),
        const SizedBox(height: 12),
        info('பெயர்', Demo.name),
        if (app.mobile.isNotEmpty) info('மொபைல்', app.mobile),
        if (Demo.member.isNotEmpty) info('கணக்கு எண்', Demo.member),
        info('திட்டம்', Demo.scheme),
        info('சேர்ந்த நாள்', Demo.startText),
        info('நகை வாங்கலாம்', Demo.buyMonth),
        const SizedBox(height: 12),
        tr([
          cell('#', flex: 1, head: true),
          cell('தேதி', flex: 3, head: true),
          cell('தொகை', flex: 3, a: TextAlign.right, head: true),
          if (grams) cell('விலை/கி', flex: 3, a: TextAlign.right, head: true),
          if (grams) cell('கிராம்', flex: 2, a: TextAlign.right, head: true),
        ], head: true),
        for (final p in ps)
          tr([
            cell(p[0] as String, flex: 1),
            cell(p[1] as String, flex: 3),
            cell(rupees(p[2] as int), flex: 3, a: TextAlign.right),
            if (grams) cell((p.length > 4 && (p[4] as double) > 0) ? rupees((p[4] as double).round()) : '—', flex: 3, a: TextAlign.right),
            if (grams) cell((p[3] as double).toStringAsFixed(3), flex: 2, a: TextAlign.right),
          ]),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(flex: 4, child: Text(Demo.silver ? 'மொத்தம் (${ps.length} முறை · ${Demo.paidCount} / ${Demo.months} மாதம்)' : 'மொத்தம் (${Demo.paidCount} / ${Demo.months} தவணை)', style: t(12, w: FontWeight.w700))),
            Expanded(flex: 3, child: Text(rupees(Demo.total), textAlign: TextAlign.right, style: t(12.5, w: FontWeight.w700))),
            if (grams) const Expanded(flex: 3, child: SizedBox()),
            if (grams) Expanded(flex: 2, child: Text(Demo.gramsTotal.toStringAsFixed(3), textAlign: TextAlign.right, style: t(12.5, w: FontWeight.w700))),
          ]),
        ),
        const SizedBox(height: 14),
        Text('இந்த அறிக்கை App-ல் உள்ள பதிவுகளிலிருந்து தானாக உருவாக்கப்பட்டது. ஏதேனும் வேறுபாடு இருந்தால் கடையின் பதிவே இறுதியானது. தொடர்புக்கு: 97919 18344 / 93443 95078.',
            style: t(10, c: mute)),
      ]),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEDE6D6),
      appBar: AppBar(backgroundColor: C.paper, surfaceTintColor: C.paper, foregroundColor: C.navy, title: Text('கணக்கு அறிக்கை', style: sans(16.5, color: C.ink, weight: FontWeight.w700))),
      body: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 110), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedBox(
              decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4))]),
              child: RepaintBoundary(key: _key, child: sheet),
            ),
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: PrimaryButton('PDF ஆக பகிர் / சேமி', icon: Icons.picture_as_pdf_outlined, busy: _busy, onTap: _sharePdf),
        ),
      ),
    );
  }
}
