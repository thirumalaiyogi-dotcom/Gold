import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';

import 'api.dart';
import 'main.dart';
import 'ui.dart';

/// Error texts — same as the website (PAYERR).
const payErr = {
  'paid_month': 'இந்த மாசத் தவணை ஏற்கனவே கட்டியாச்சு.',
  'done': 'எல்லா தவணையும் முடிஞ்சாச்சு.',
  'auth': 'மீண்டும் உள்நுழைந்து முயற்சிக்கவும்.',
  'fixed': 'இந்த திட்டத்தில தவணைத் தொகை மாறாது.',
  'no_keys': 'Online payment இன்னும் தயாராகல. கடையை அணுகவும்.',
  'net': 'இணைய இணைப்பு இல்ல. மீண்டும் முயற்சிக்கவும்.',
  'sandbox': 'இது test payment. உண்மையான தவணையா பதியாது.',
  'dup_paid': 'இந்த மாசத் தவணை ஏற்கனவே பதிவாயிருக்கு, அதனால இந்த பணம் தவணையா சேரல. கடை இதை திருப்பித் தரும். கடையை அணுகவும்.',
};

/// In-app payment: amount → Cashfree checkout inside the app → verify → Passbook refresh.
class PayPage extends StatefulWidget {
  const PayPage({super.key});
  @override
  State<PayPage> createState() => _PayPageState();
}

enum _St { form, busy, ok, fail }

class _PayPageState extends State<PayPage> {
  final cf = CFPaymentGatewayService();
  final amount = TextEditingController();
  _St st = _St.form;
  String msg = '';
  String env = 'sandbox';
  String orderId = '';
  int paidAmount = 0;
  bool settling = false;

  int get minAmt => Demo.silver ? 100 : 1000;

  @override
  void initState() {
    super.initState();
    if (Demo.fixed && Demo.monthly > 0) amount.text = '${Demo.monthly}';
    cf.setCallback(_onVerify, _onError);
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  void _onVerify(String oid) => _settle(oid);
  void _onError(CFErrorResponse e, String oid) => _settle(oid, cancelled: true, why: e.getMessage());

  Future<void> _start() async {
    final a = int.tryParse(amount.text.trim()) ?? 0;
    if (a < minAmt || a > 100000) {
      setState(() => msg = 'தொகை ${rupees(minAmt)} முதல் ₹1,00,000 வரை இருக்கணும்.');
      return;
    }
    if (!app.loggedIn || app.pin.isEmpty) {
      setState(() => msg = payErr['auth']!);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      st = _St.busy;
      msg = 'தயார் செய்கிறோம்…';
    });
    final d = await PayApi.call({'action': 'create', 'mobile': app.mobile, 'pin': app.pin, 'amount': a});
    if (!mounted) return;
    if (d['ok'] != true) {
      final e = '${d['err']}';
      setState(() {
        st = _St.form;
        msg = e == 'amount' ? 'தொகை ${rupees(d['min'] ?? minAmt)} முதல் ₹1,00,000 வரை இருக்கணும்.' : (payErr[e] ?? 'Payment தொடங்க முடியல ($e)');
      });
      return;
    }
    orderId = '${d['order_id']}';
    env = '${d['env']}';
    paidAmount = a;
    setState(() => msg = 'Payment பக்கம் திறக்கிறது…');
    try {
      final session = CFSessionBuilder()
          .setEnvironment(env == 'production' ? CFEnvironment.PRODUCTION : CFEnvironment.SANDBOX)
          .setOrderId(orderId)
          .setPaymentSessionId('${d['session']}')
          .build();
      final web = CFWebCheckoutPaymentBuilder().setSession(session).build();
      cf.doPayment(web);
    } on CFException catch (e) {
      setState(() {
        st = _St.form;
        msg = 'Payment திறக்க முடியல: ${e.message}';
      });
    }
  }

  /// Ask the server (cf-pay verify) — never trust the client callback alone.
  Future<void> _settle(String oid, {bool cancelled = false, String? why}) async {
    if (settling) return;
    settling = true;
    if (mounted) setState(() => msg = 'சரிபார்க்கிறோம்…');
    for (var i = 0; i < 4; i++) {
      final d = await PayApi.call({'action': 'verify', 'order_id': oid.isEmpty ? orderId : oid});
      if (d['ok'] == true && d['paid'] == true) {
        HapticFeedback.heavyImpact();
        await app.refreshPassbook();
        if (mounted) setState(() => st = _St.ok);
        settling = false;
        return;
      }
      if (d['ok'] != true && (d['err'] == 'sandbox' || d['err'] == 'dup_paid')) {
        if (mounted) {
          setState(() {
            st = _St.fail;
            msg = payErr[d['err']]!;
          });
        }
        settling = false;
        return;
      }
      if (d['ok'] == true && d['paid'] != true && d['status'] != 'ACTIVE') break;
      if (cancelled && i == 0) break; // closed without paying
      await Future.delayed(const Duration(milliseconds: 2500));
    }
    if (mounted) {
      setState(() {
        st = cancelled ? _St.form : _St.fail;
        msg = cancelled
            ? 'Payment முடியல. மீண்டும் முயற்சிக்கலாம்.'
            : 'பணம் இன்னும் உறுதியாகல. பணம் போயிருந்தா சில நிமிஷத்துல தானா பதியும்; இல்லைன்னா கடையை அணுகவும்.';
      });
    }
    settling = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: C.paper, surfaceTintColor: C.paper, foregroundColor: C.navy, title: Text('தவணை செலுத்த', style: sans(16.5, color: C.ink, weight: FontWeight.w700))),
      body: SafeArea(child: st == _St.ok ? _done() : (st == _St.fail ? _failed() : _form())),
    );
  }

  Widget _form() {
    final chips = Demo.silver ? [100, 200, 500, 1000] : [1000, 2000, 5000, 10000];
    final busy = st == _St.busy;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
      LuxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${Demo.scheme} திட்டம்', style: sans(13, color: C.mute)),
          const SizedBox(height: 4),
          Text(Demo.name, style: serif(20, color: C.ink, weight: FontWeight.w700)),
          const Divider(height: 24, color: C.line),
          Text(Demo.fixed ? 'மாதத் தவணை (நிலையானது)' : 'தொகை', style: sans(13, color: C.mute, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: amount,
            enabled: !busy && !(Demo.fixed && Demo.monthly > 0),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            style: serif(28, color: C.ink, weight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: serif(28, color: C.ink, weight: FontWeight.w700),
              hintText: '${minAmt}',
              filled: true,
              fillColor: C.paper,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.line2)),
            ),
            onChanged: (_) => setState(() => msg = ''),
          ),
          if (!Demo.fixed) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final v in chips)
                ChoiceChip(
                  label: Text(rupees(v)),
                  selected: amount.text == '$v',
                  selectedColor: C.goldSoft,
                  onSelected: busy ? null : (_) => setState(() => amount.text = '$v'),
                ),
            ]),
            const SizedBox(height: 8),
            Text('${rupees(minAmt)} முதல் ₹1,00,000 வரை', style: sans(12.5, color: C.mute)),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      if (msg.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(msg, textAlign: TextAlign.center, style: sans(14, color: busy ? C.mute : C.red, height: 1.5)),
        ),
      busy
          ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: C.navy)))
          : PrimaryButton(amount.text.isEmpty ? 'தொடரவும்' : '${rupees(int.tryParse(amount.text) ?? 0)} செலுத்த', icon: Icons.lock_outline, onTap: _start),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.verified_user_outlined, size: 16, color: C.mute),
        const SizedBox(width: 6),
        Flexible(child: Text('UPI / Card / Net banking · Cashfree மூலம் பாதுகாப்பான payment', textAlign: TextAlign.center, style: sans(12.5, color: C.mute))),
      ]),
    ]);
  }

  Widget _done() => Stack(children: [
        Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, color: C.goldSoft, boxShadow: [BoxShadow(color: C.gold.withValues(alpha: .5), blurRadius: 30)]),
                child: GoldShine(loop: true, pause: const Duration(milliseconds: 1600), child: ClipOval(child: Image.asset('assets/coin.png', fit: BoxFit.cover))),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('பணம் வந்தது ✅', textAlign: TextAlign.center, style: serif(26, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('${rupees(paidAmount)} தவணை Passbook-ல பதிவாச்சு. நன்றி 🙏', textAlign: TextAlign.center, style: sans(15, color: C.mute, height: 1.6)),
          const SizedBox(height: 28),
          PrimaryButton('Passbook பார்க்க', onTap: () => Navigator.of(context).pop(true)),
        ]),
        ),
        const Positioned.fill(child: GoldConfetti()),
      ]);

  Widget _failed() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Center(child: RingIcon(Icons.info_outline, size: 70)),
          const SizedBox(height: 18),
          Text(msg, textAlign: TextAlign.center, style: sans(15, height: 1.6)),
          if (orderId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Order: $orderId', textAlign: TextAlign.center, style: sans(12, color: C.mute)),
          ],
          const SizedBox(height: 24),
          PrimaryButton('சரி', onTap: () => Navigator.of(context).pop(false)),
        ]),
      );
}
