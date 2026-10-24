import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Style 4 (Luxury) tokens — the same values as the website.
class C {
  static const navy = Color(0xFF092A63);
  static const navy2 = Color(0xFF061D45);
  static const ivory = Color(0xFFFBF8F1);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B2233);
  static const mute = Color(0xFF5F6677);
  static const gold = Color(0xFFC9A24A);
  static const goldText = Color(0xFF8A6A1F);
  static const goldLine = Color(0xFFD9C08A);
  static const goldSoft = Color(0xFFF3E2B3);
  static const line = Color(0xFFECE4D0);
  static const line2 = Color(0xFFE3D6B4);
  static const red = Color(0xFFB3261E);
  static const green = Color(0xFF1E6B42);
  static const navyMute = Color(0xFFC9D3E6);
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
  Widget build(BuildContext context) => SizedBox(
        height: 50,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: gold ? C.gold : C.navy,
            foregroundColor: gold ? C.navy : C.goldSoft,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: sans(15.5, weight: FontWeight.w700),
          ),
          onPressed: () {
            tapFeel();
            onTap();
          },
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
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
  Widget build(BuildContext context) => SizedBox(
        height: 46,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: light ? Colors.white : C.navy,
            side: BorderSide(color: light ? const Color(0x73FFFFFF) : const Color(0xFFC9CFDB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: sans(14.5, weight: FontWeight.w600),
          ),
          onPressed: onTap,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
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
