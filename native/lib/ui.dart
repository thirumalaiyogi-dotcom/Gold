import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// STM Premium tokens (maroon / champagne / ivory) — same values as the website (Style 5).
/// Names kept from the first prototype: `navy` is now the brand maroon.
class C {
  static const navy = Color(0xFF6E1423);
  static const navy2 = Color(0xFF4A0D18);
  static const ivory = Color(0xFFFBF8F1);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF252525);
  static const mute = Color(0xFF777777);
  static const gold = Color(0xFFC9A45C);
  static const goldText = Color(0xFF8A6A2E);
  static const goldLine = Color(0xFFD9C08A);
  static const goldSoft = Color(0xFFE5C98B);
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line2),
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
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFEFE5CB))),
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
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Text(text, style: serif(19))),
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
