import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// STM Premium tokens (maroon / champagne / ivory) — same values as the website (Style 5).
/// Names kept from the first prototype: `navy` is now the brand maroon.
class C {
  static const navy = Color(0xFF6E1423);
  static const navy2 = Color(0xFF4A0D18);
  static const ivory = Color(0xFFFAF7EF);
  static const navy3 = Color(0xFF801F32);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF392027);
  static const mute = Color(0xFF81747A);
  static const gold = Color(0xFFD6B56D);
  static const goldText = Color(0xFF8A6A2E);
  static const goldLine = Color(0xFFD9C08A);
  static const goldSoft = Color(0xFFE8D29A);
  static const line = Color(0xFFECE4D0);
  static const line2 = Color(0xFFE3D6B4);
  static const red = Color(0xFFC63C45);
  static const green = Color(0xFF24865B);
  static const navyMute = Color(0xFFEAD9B8);
}

TextStyle serif(double size, {Color color = C.navy, FontWeight weight = FontWeight.w600, double? height}) =>
    GoogleFonts.notoSerifTamil(fontSize: size, color: color, fontWeight: weight, height: height);

TextStyle sans(double size, {Color color = C.ink, FontWeight weight = FontWeight.w400, double? height}) =>
    GoogleFonts.notoSansTamil(fontSize: size, color: color, fontWeight: weight, height: height);

String rupees(num v, {int decimals = 0}) {
  final s = v.toStringAsFixed(decimals);
  final parts = s.split('.');
  var n = parts[0];
  var out = '';
  if (n.length > 3) {
    out = ',${n.substring(n.length - 3)}';
    n = n.substring(0, n.length - 3);
    while (n.length > 2) {
      out = ',${n.substring(n.length - 2)}$out';
      n = n.substring(0, n.length - 2);
    }
    out = '$n$out';
  } else {
    out = n;
  }
  return '₹$out${parts.length > 1 ? '.${parts[1]}' : ''}';
}

void tapFeel() => HapticFeedback.lightImpact();

/// White card with a thin border (Style 4 card).
class LuxCard extends StatelessWidget {
  const LuxCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.topGold = false, this.inner = false});
  final Widget child;
  final EdgeInsets padding;
  final bool topGold;
  final bool inner;
  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: C.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E8D6)),
        boxShadow: const [BoxShadow(color: Color(0x0F6E1423), blurRadius: 20, offset: Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (topGold) Container(height: 3, color: C.gold),
        Padding(padding: padding, child: child),
      ]),
    );
    if (!inner) return card;
    return Stack(children: [
      card,
      Positioned.fill(
        child: IgnorePointer(
          child: Container(
            margin: const EdgeInsets.all(7),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFEFE5CB))),
          ),
        ),
      ),
    ]);
  }
}

/// Circle with a thin gold ring around a navy line icon.
class RingIcon extends StatelessWidget {
  const RingIcon(this.icon, {super.key, this.size = 56, this.color = C.navy, this.ring = C.goldLine, this.bg = C.paper});
  final IconData icon;
  final double size;
  final Color color, ring, bg;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg, border: Border.all(color: ring)),
        child: Icon(icon, size: size * .42, color: color),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, {super.key, required this.onTap, this.gold = false, this.icon});
  final String label;
  final VoidCallback onTap;
  final bool gold;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: gold ? C.gold : C.navy,
            foregroundColor: gold ? C.navy : C.goldSoft,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(0, 50),
            textStyle: sans(15, weight: FontWeight.w700, height: 1.25),
          ),
          onPressed: () {
            tapFeel();
            onTap();
          },
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Flexible(child: Text(label, textAlign: TextAlign.center, maxLines: 2, softWrap: true)),
          ]),
        ),
      );
}

class OutlineBtn extends StatelessWidget {
  const OutlineBtn(this.label, {super.key, required this.onTap, this.light = false, this.icon});
  final String label;
  final VoidCallback onTap;
  final bool light;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: light ? Colors.white : C.navy,
            side: BorderSide(color: light ? const Color(0x73FFFFFF) : const Color(0xFFE2D6BE)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(0, 50),
            textStyle: sans(14.5, weight: FontWeight.w600, height: 1.25),
          ),
          onPressed: onTap,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
            Flexible(child: Text(label, textAlign: TextAlign.center, maxLines: 2, softWrap: true)),
          ]),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(text, style: serif(20, height: 1.3)),
              const SizedBox(height: 5),
              Container(width: 28, height: 2.5, decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(2))),
            ]),
          ),
          if (action != null)
            InkWell(onTap: onAction, child: Padding(padding: const EdgeInsets.all(6), child: Text(action!, style: sans(13.5, color: C.navy, weight: FontWeight.w600)))),
        ]),
      );
}

/// Number keypad used for mobile number and mPIN.
class KeyPad extends StatelessWidget {
  const KeyPad({super.key, required this.onKey});
  final void Function(String key) onKey;
  @override
  Widget build(BuildContext context) {
    Widget key(String k) {
      if (k.isEmpty) return const SizedBox.shrink();
      return Material(
        color: C.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: C.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            onKey(k);
          },
          child: Center(
            child: k == 'del'
                ? const Icon(Icons.backspace_outlined, color: C.navy, semanticLabel: 'அழி')
                : Text(k, style: sans(24, color: C.navy, weight: FontWeight.w600)),
          ),
        ),
      );
    }

    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.75,
      children: keys.map(key).toList(),
    );
  }
}

/// Short horizontal shake used when an mPIN is wrong.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.child, required this.trigger});
  final Widget child;
  final int trigger;
  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  @override
  void didUpdateWidget(covariant Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          final dx = (1 - t) * 10 * ((t * 8).floor().isEven ? 1 : -1) * (t == 0 ? 0 : 1);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: widget.child,
      );
}

void showNote(BuildContext context, String text, {bool ok = true}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, style: sans(14, color: Colors.white)),
      backgroundColor: ok ? C.navy : C.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
}

/// Swipe-to-pay: drag the gold coin to the right to start a payment.
/// Past 85% it locks, gives a firm haptic and calls [onDone]; otherwise it springs back.
class SwipeToPay extends StatefulWidget {
  const SwipeToPay({super.key, required this.label, required this.onDone, this.amount, this.silver = false});
  final String label;
  final bool silver;
  final String? amount;
  final VoidCallback onDone;
  @override
  State<SwipeToPay> createState() => _SwipeToPayState();
}

class _SwipeToPayState extends State<SwipeToPay> with TickerProviderStateMixin {
  static const h = 62.0, pad = 5.0;
  double x = 0;
  bool done = false;
  int _lastTick = 0;
  late final AnimationController back = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final AnimationController shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
  Animation<double>? _a;

  @override
  void dispose() {
    back.dispose();
    shine.dispose();
    super.dispose();
  }

  void _reset() {
    _a = Tween(begin: x, end: 0.0).animate(CurvedAnimation(parent: back, curve: Curves.easeOutBack))
      ..addListener(() => setState(() => x = _a!.value));
    back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final travel = (c.maxWidth - h).clamp(1.0, double.infinity);
      final p = (x / travel).clamp(0.0, 1.0);
      return Semantics(
        button: true,
        label: widget.label,
        onTap: widget.onDone, // accessibility: a plain tap still works for screen readers
        child: Container(
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(h),
            gradient: const LinearGradient(colors: [C.navy2, C.navy]),
            boxShadow: const [BoxShadow(color: Color(0x336E1423), blurRadius: 14, offset: Offset(0, 6))],
          ),
          child: Stack(alignment: Alignment.centerLeft, children: [
            // gold fill that follows the coin
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: x + h,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(h),
                  gradient: LinearGradient(colors: widget.silver ? [const Color(0x40D9DDE2), const Color(0x8CD9DDE2)] : [C.gold.withValues(alpha: .25), C.gold.withValues(alpha: .55)]),
                ),
              ),
            ),
            // label with a moving shine
            Positioned.fill(
              left: h,
              right: 14,
              child: Opacity(
                opacity: (1 - p * 1.4).clamp(0.0, 1.0),
                child: AnimatedBuilder(
                  animation: shine,
                  builder: (_, child) => ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) {
                      final t = shine.value * 2 - .5;
                      return LinearGradient(
                        colors: const [C.goldSoft, Colors.white, C.goldSoft],
                        stops: [(t - .2).clamp(0.0, 1.0), t.clamp(0.0, 1.0), (t + .2).clamp(0.0, 1.0)],
                      ).createShader(r);
                    },
                    child: child,
                  ),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: sans(15, color: Colors.white, weight: FontWeight.w700)),
                      if (widget.amount != null) Text(widget.amount!, maxLines: 1, style: sans(12, color: Colors.white, weight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            ),
            // the coin
            Positioned(
              left: pad + x,
              child: GestureDetector(
                onHorizontalDragUpdate: done
                    ? null
                    : (d) {
                        setState(() => x = (x + d.delta.dx).clamp(0.0, travel));
                        final tick = (x / travel * 5).floor();
                        if (tick != _lastTick) {
                          _lastTick = tick;
                          HapticFeedback.selectionClick();
                        }
                      },
                onHorizontalDragEnd: done
                    ? null
                    : (_) {
                        if (x / travel > .85) {
                          setState(() {
                            x = travel;
                            done = true;
                          });
                          HapticFeedback.heavyImpact();
                          Future.delayed(const Duration(milliseconds: 260), () {
                            widget.onDone();
                            if (mounted) {
                              setState(() => done = false);
                              _reset();
                            }
                          });
                        } else {
                          _lastTick = 0;
                          _reset();
                        }
                      },
                child: Container(
                  width: h - pad * 2,
                  height: h - pad * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.silver ? const Color(0xFFE6E8EB) : C.goldSoft,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Transform.rotate(
                    angle: p * 6.283,
                    child: done
                        ? const Icon(Icons.check_rounded, color: C.navy, size: 28)
                        : ClipOval(
                            child: widget.silver
                                // silver scheme: same Lakshmi coin rendered in silver tones
                                ? ColorFiltered(
                                    colorFilter: const ColorFilter.matrix([
                                      0.30, 0.55, 0.15, 0, 18, //
                                      0.30, 0.55, 0.15, 0, 22, //
                                      0.30, 0.55, 0.15, 0, 30, //
                                      0, 0, 0, 1, 0,
                                    ]),
                                    child: Image.asset('assets/coin.png', fit: BoxFit.cover),
                                  )
                                : Image.asset('assets/coin.png', fit: BoxFit.cover)),
                  ),
                ),
              ),
            ),
            // chevrons hint on the right
            Positioned(
              right: 14,
              child: Opacity(
                opacity: (1 - p * 2).clamp(0.0, 1.0),
                child: const Icon(Icons.keyboard_double_arrow_right_rounded, color: C.goldSoft, size: 26),
              ),
            ),
          ]),
        ),
      );
    });
  }
}


/// Gold shine: a soft light band sweeps across [child] (text, coin or button).
/// Once by default; [loop] repeats it after [pause]. Used only in a few special places.
class GoldShine extends StatefulWidget {
  const GoldShine({super.key, required this.child, this.loop = false, this.delay = const Duration(milliseconds: 500), this.pause = const Duration(milliseconds: 3500), this.color = const Color(0xD9FFF4CF)});
  final Widget child;
  final bool loop;
  final Duration delay, pause;
  final Color color;
  @override
  State<GoldShine> createState() => _GoldShineState();
}

class _GoldShineState extends State<GoldShine> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void initState() {
    super.initState();
    c.addStatusListener((s) {
      if (s == AnimationStatus.completed && widget.loop) {
        Future.delayed(widget.pause, () {
          if (mounted) c.forward(from: 0);
        });
      }
    });
    Future.delayed(widget.delay, () {
      if (mounted) c.forward(from: 0);
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        child: widget.child,
        builder: (_, child) {
          if (c.value == 0 || c.value == 1) return child!;
          final x = -1.6 + 3.2 * Curves.easeInOut.transform(c.value);
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment(x - .8, -1),
              end: Alignment(x + .8, 1),
              colors: [Colors.transparent, widget.color, Colors.transparent],
              stops: const [.35, .5, .65],
            ).createShader(r),
            child: child,
          );
        },
      );
}

/// Small burst of falling gold flakes (payment success).
class GoldConfetti extends StatefulWidget {
  const GoldConfetti({super.key});
  @override
  State<GoldConfetti> createState() => _GoldConfettiState();
}

class _GoldConfettiState extends State<GoldConfetti> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  final rnd = math.Random(7);
  late final parts = List.generate(46, (_) => [rnd.nextDouble(), rnd.nextDouble() * .35, .55 + rnd.nextDouble() * .6, rnd.nextDouble() * 6.28, 3 + rnd.nextDouble() * 5, rnd.nextInt(3).toDouble()]);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(animation: c, builder: (_, __) => CustomPaint(size: Size.infinite, painter: _Flakes(parts, c.value))));
}

class _Flakes extends CustomPainter {
  _Flakes(this.p, this.t);
  final List<List<double>> p;
  final double t;
  static const cols = [Color(0xFFE5C98B), Color(0xFFC9A45C), Color(0xFFFFF1BF)];
  @override
  void paint(Canvas canvas, Size s) {
    final fade = t < .75 ? 1.0 : (1 - (t - .75) / .25);
    for (final q in p) {
      final y = (-.1 + q[1] + t * q[2]) * s.height;
      final x = q[0] * s.width + math.sin(t * 6 + q[3]) * 14;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(q[3] + t * 8);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: q[4], height: q[4] * 1.8), const Radius.circular(1.5)),
          Paint()..color = cols[q[5].toInt()].withValues(alpha: fade));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _Flakes o) => o.t != t;
}


// ======================= v0.9.5 premium UI pieces =======================

/// Today's date in IST as yyyy-mm-dd.
String istToday() => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)).toIso8601String().substring(0, 10);

/// The Lakshmi coin image; silver schemes get the same coin in silver tones.
Widget coinImage({bool silver = false, bool dim = false}) {
  Widget img = Image.asset('assets/coin.png', fit: BoxFit.cover);
  if (silver) {
    img = ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.30, 0.55, 0.15, 0, 18, //
        0.30, 0.55, 0.15, 0, 22, //
        0.30, 0.55, 0.15, 0, 30, //
        0, 0, 0, 1, 0,
      ]),
      child: img,
    );
  }
  return ClipOval(child: dim ? Opacity(opacity: .25, child: img) : img);
}

/// Maroon velvet + gold light (brand reference image), used for hero surfaces.
const _velvet = ResizeImage(AssetImage('assets/velvet.jpg'), width: 1080);

BoxDecoration velvetDeco({BorderRadius? radius, Border? border, Alignment alignment = Alignment.topCenter, BoxBorder? frame, List<BoxShadow>? shadow}) => BoxDecoration(
      color: C.navy2,
      borderRadius: radius,
      border: frame ?? border,
      boxShadow: shadow,
      image: DecorationImage(image: _velvet, fit: BoxFit.cover, alignment: alignment),
    );

/// Faint dot-kolam lattice used behind the maroon headers (shop signature).
class KolamBg extends StatelessWidget {
  const KolamBg({super.key, required this.child, this.festive = false});
  final Widget child;
  final bool festive;
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _Kolam(festive ? .11 : .065), child: child);
}

class _Kolam extends CustomPainter {
  _Kolam(this.a);
  final double a;
  @override
  void paint(Canvas canvas, Size s) {
    const g = 34.0;
    final line = Paint()
      ..color = C.goldSoft.withValues(alpha: a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dot = Paint()..color = C.goldSoft.withValues(alpha: a * 1.6);
    canvas.save();
    canvas.clipRect(Offset.zero & s);
    for (var y = 0.0; y < s.height + g; y += g) {
      for (var x = 0.0; x < s.width + g; x += g) {
        final odd = ((x / g).round() + (y / g).round()).isOdd;
        canvas.drawCircle(Offset(x, y), 1.4, dot);
        if (odd) {
          // diamond loop around the dot, kolam style
          final p = Path()
            ..moveTo(x, y - g / 2)
            ..quadraticBezierTo(x + g / 2, y - g / 2, x + g / 2, y)
            ..quadraticBezierTo(x + g / 2, y + g / 2, x, y + g / 2)
            ..quadraticBezierTo(x - g / 2, y + g / 2, x - g / 2, y)
            ..quadraticBezierTo(x - g / 2, y - g / 2, x, y - g / 2);
          canvas.drawPath(p, line);
        } else {
          canvas.drawCircle(Offset(x, y), g * .18, line);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Kolam o) => o.a != a;
}

/// Festival of the day (Tamil Nadu government holiday list 2026 / 2027).
class Fest {
  const Fest(this.wish);
  final String wish;
  static const _days = {
    '2026-11-08': '🪔  இனிய தீபாவளி நல்வாழ்த்துகள்',
    '2026-12-25': '🎄  கிறிஸ்துமஸ் நல்வாழ்த்துகள்',
    '2027-01-01': '✨  இனிய ஆங்கிலப் புத்தாண்டு நல்வாழ்த்துகள்',
    '2027-01-15': '🌾  இனிய பொங்கல் நல்வாழ்த்துகள்',
    '2027-01-16': '🌾  இனிய பொங்கல் நல்வாழ்த்துகள்',
    '2027-01-17': '🌾  இனிய பொங்கல் நல்வாழ்த்துகள்',
    '2027-04-14': '🌸  இனிய தமிழ்ப் புத்தாண்டு நல்வாழ்த்துகள்',
    '2027-09-04': '🙏  விநாயகர் சதுர்த்தி நல்வாழ்த்துகள்',
    '2027-10-08': '🙏  ஆயுத பூஜை நல்வாழ்த்துகள்',
    '2027-10-09': '🙏  விஜயதசமி நல்வாழ்த்துகள்',
    '2027-10-28': '🪔  இனிய தீபாவளி நல்வாழ்த்துகள்',
    '2027-12-25': '🎄  கிறிஸ்துமஸ் நல்வாழ்த்துகள்',
  };
  static Fest? get today {
    final w = _days[istToday()];
    return w == null ? null : Fest(w);
  }
}

/// Gold ribbon with the festival greeting (only on festival days).
class FestRibbon extends StatelessWidget {
  const FestRibbon({super.key});
  @override
  Widget build(BuildContext context) {
    final f = Fest.today;
    if (f == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GoldShine(
        loop: true,
        delay: const Duration(milliseconds: 700),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: const LinearGradient(colors: [Color(0xFFB8893A), C.goldSoft, Color(0xFFB8893A)]),
          ),
          child: Text(f.wish, textAlign: TextAlign.center, style: sans(13.5, color: C.navy2, weight: FontWeight.w700)),
        ),
      ),
    );
  }
}

/// Twinkling gold sparkles over a header (festival days only).
class Sparkles extends StatefulWidget {
  const Sparkles({super.key});
  @override
  State<Sparkles> createState() => _SparklesState();
}

class _SparklesState extends State<Sparkles> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  final rnd = math.Random(11);
  late final pts = List.generate(22, (_) => [rnd.nextDouble(), rnd.nextDouble(), rnd.nextDouble(), 1 + rnd.nextDouble() * 1.8]);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(animation: c, builder: (_, __) => CustomPaint(size: Size.infinite, painter: _Spark(pts, c.value))));
}

class _Spark extends CustomPainter {
  _Spark(this.p, this.t);
  final List<List<double>> p;
  final double t;
  @override
  void paint(Canvas canvas, Size s) {
    for (final q in p) {
      final v = (math.sin((t + q[2]) * 6.283) + 1) / 2;
      canvas.drawCircle(Offset(q[0] * s.width, q[1] * s.height), q[3] * (.6 + v * .6), Paint()..color = const Color(0xFFFFE9A8).withValues(alpha: v * .8));
    }
  }

  @override
  bool shouldRepaint(covariant _Spark o) => o.t != t;
}

/// Grey shimmer box shown while data loads (instead of a spinner).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width = double.infinity, this.height = 16, this.radius = 8, this.dark = false});
  final double width, height, radius;
  final bool dark;
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.dark ? const Color(0x33FFFFFF) : const Color(0xFFEFE8D8);
    final hi = widget.dark ? const Color(0x66FFFFFF) : const Color(0xFFFAF6EC);
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final x = -1.5 + 3 * c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(begin: Alignment(x - 1, 0), end: Alignment(x + 1, 0), colors: [base, hi, base]),
          ),
        );
      },
    );
  }
}

/// Simple list of skeleton cards (notices, rate history).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});
  final int count;
  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < count; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Skeleton(width: 120 + (i % 3) * 40.0, height: 16),
              const SizedBox(height: 10),
              const Skeleton(height: 12),
              const SizedBox(height: 6),
              const Skeleton(width: 200, height: 12),
            ]),
          ),
      ]);
}

/// Passbook "gold-coin stack": one coin per installment.
/// Paid = shining coin, next = pulsing gold ring, later = faint coin.
/// Coins drop in one after another; the newest paid coin bounces and shines.
class CoinStack extends StatefulWidget {
  const CoinStack({super.key, required this.total, required this.paid, this.silver = false, this.labels = const []});
  final int total, paid;
  final bool silver;
  final List<String> labels;
  @override
  State<CoinStack> createState() => _CoinStackState();
}

class _CoinStackState extends State<CoinStack> with TickerProviderStateMixin {
  late AnimationController drop = _mk();
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  bool _felt = false;

  AnimationController _mk() {
    final c = AnimationController(vsync: this, duration: Duration(milliseconds: 500 + math.min(math.max(widget.paid, 0), 30) * 110));
    c.addListener(() {
      if (!_felt && c.value > .97 && widget.paid > 0) {
        _felt = true;
        HapticFeedback.lightImpact();
      }
    });
    c.forward();
    return c;
  }

  @override
  void didUpdateWidget(covariant CoinStack old) {
    super.didUpdateWidget(old);
    if (widget.paid != old.paid || widget.total != old.total) {
      drop.dispose();
      _felt = false;
      drop = _mk();
    }
  }

  @override
  void dispose() {
    drop.dispose();
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int n = math.min(math.max(widget.total, 1), 60);
    final int paid = math.min(math.max(widget.paid, 0), n);
    return LayoutBuilder(builder: (context, c) {
      final perRow = n <= 12 ? (n / 2).ceil() : (n <= 24 ? 8 : 10);
      const gap = 8.0;
      final size = ((c.maxWidth - gap * (perRow - 1)) / perRow).clamp(22.0, 46.0);
      final showLabels = widget.labels.length >= n && size >= 34;
      return AnimatedBuilder(
        animation: Listenable.merge([drop, pulse]),
        builder: (_, __) => Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: 10,
          children: [
            for (var i = 0; i < n; i++) _coin(i, paid, size, showLabels ? widget.labels[i] : null),
          ],
        ),
      );
    });
  }

  Widget _coin(int i, int paid, double size, String? label) {
    final isPaid = i < paid;
    final isNext = i == paid;
    Widget face;
    if (isPaid) {
      // staggered drop: coin i starts at i / (paid + 1) of the timeline
      final start = paid == 0 ? 0.0 : i / (paid + 1);
      final end = (start + 2 / (paid + 1)).clamp(0.0, 1.0);
      final raw = ((drop.value - start) / (end - start)).clamp(0.0, 1.0);
      final last = i == paid - 1;
      final v = (last ? Curves.elasticOut : Curves.easeOutCubic).transform(raw);
      face = Opacity(
        opacity: raw.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * -size * .9),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: (widget.silver ? const Color(0xFF8C939B) : C.gold).withValues(alpha: .45), blurRadius: last ? 10 : 4, offset: const Offset(0, 2)),
            ]),
            child: last && drop.isCompleted ? GoldShine(loop: true, pause: const Duration(seconds: 4), child: coinImage(silver: widget.silver)) : coinImage(silver: widget.silver),
          ),
        ),
      );
    } else if (isNext) {
      final p = pulse.value;
      face = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFF7E0),
          border: Border.all(color: C.gold.withValues(alpha: .5 + p * .5), width: 1.6 + p),
          boxShadow: [BoxShadow(color: C.gold.withValues(alpha: p * .35), blurRadius: 8 + p * 6)],
        ),
        child: Text('${i + 1}', style: serif(size * .36, color: C.goldText)),
      );
    } else {
      face = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF7F2E6), border: Border.all(color: C.line2)),
        child: Text('${i + 1}', style: sans(size * .3, color: const Color(0xFFB9AE9C), weight: FontWeight.w600)),
      );
    }
    return Semantics(
      label: 'தவணை ${i + 1}: ${isPaid ? 'செலுத்தியது' : (isNext ? 'அடுத்தது' : 'மீதி')}',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        face,
        if (label != null) ...[
          const SizedBox(height: 3),
          Text(label, style: sans(10.5, color: isPaid ? C.goldText : (isNext ? C.navy : C.mute), weight: isPaid || isNext ? FontWeight.w700 : FontWeight.w400)),
        ],
      ]),
    );
  }
}

/// Small row of dots (paid = gold) used in the home savings hero.
class CoinDots extends StatelessWidget {
  const CoinDots({super.key, required this.total, required this.paid, this.silver = false});
  final int total, paid;
  final bool silver;
  @override
  Widget build(BuildContext context) {
    final int n = math.min(math.max(total, 1), 24);
    final on = silver ? const Color(0xFFDDE1E6) : C.goldSoft;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < n; i++)
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: i < paid ? 1.0 : 0.0),
          duration: Duration(milliseconds: 300 + i * 70),
          curve: Curves.easeOut,
          builder: (_, v, __) => Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(const Color(0x33FFFFFF), on, v),
              boxShadow: v > .5 ? [BoxShadow(color: on.withValues(alpha: .6), blurRadius: 4)] : null,
            ),
          ),
        ),
    ]);
  }
}
