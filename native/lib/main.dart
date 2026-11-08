import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api.dart';
import 'data.dart';
import 'login.dart';
import 'notify.dart';
import 'onboard.dart';
import 'ui.dart';

const _taMon = ['ஜன.', 'பிப்.', 'மார்.', 'ஏப்.', 'மே', 'ஜூன்', 'ஜூலை', 'ஆக.', 'செப்.', 'அக்.', 'நவ.', 'டிச.'];
const _taMonLong = ['ஜனவரி', 'பிப்ரவரி', 'மார்ச்', 'ஏப்ரல்', 'மே', 'ஜூன்', 'ஜூலை', 'ஆகஸ்ட்', 'செப்டம்பர்', 'அக்டோபர்', 'நவம்பர்', 'டிசம்பர்'];
String taDate(String iso) {
  final d = DateTime.tryParse(iso.length >= 10 ? iso.substring(0, 10) : iso);
  return d == null ? iso : '${d.day} ${_taMon[d.month - 1]} ${d.year}';
}

String taMonth(int m) => _taMon[(m - 1) % 12];

DateTime nowIst() => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

/// Live values (from Supabase) with the old Demo names, so screens stay simple.
class Demo {
  static Map<String, dynamic> get _pb => app.pb ?? const {};
  static Map<String, dynamic> get _rt => app.rate ?? const {};
  static String get name => (_pb['name'] ?? '').toString().trim().isEmpty ? 'வாடிக்கையாளர்' : _pb['name'].toString().trim();
  static String get firstName => name.split(RegExp(r'\s+')).first;
  static String get member => ((_pb['refer'] is Map) ? (_pb['refer']['code'] ?? '') : '').toString();
  static String get schemeKey => (_pb['scheme'] ?? '').toString();
  static String get scheme => app.schemeName(schemeKey);
  static int get months => app.schemeMonths(schemeKey);
  static bool get silver => app.schemeSilver(schemeKey);
  static bool get grams => app.schemeGrams(schemeKey);
  static bool get fixed => app.schemeFixed(schemeKey);
  static List<Map<String, dynamic>> get _ps =>
      ((_pb['payments'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  /// newest first: [number, date, amount, grams]
  static List<List<Object>> get payments {
    final p = _ps;
    return [
      for (var i = p.length - 1; i >= 0; i--)
        ['${i + 1}', taDate((p[i]['on'] ?? '').toString()), (num.tryParse('${p[i]['amount']}') ?? 0).round(), (num.tryParse('${p[i]['grams'] ?? 0}') ?? 0).toDouble()]
    ];
  }

  static Set<String> get _months => _ps.map((e) => (e['on'] ?? '').toString().padRight(7).substring(0, 7)).toSet();
  static String get _cur => nowIst().toIso8601String().substring(0, 7);
  static int get paidCount => silver ? _months.length : _ps.length;
  static bool get paidThisMonth => _months.contains(_cur);
  static int get total => _ps.fold(0, (s, p) => s + (num.tryParse('${p['amount']}') ?? 0).round());
  static double get gramsTotal => _ps.fold(0.0, (s, p) => s + (num.tryParse('${p['grams'] ?? 0}') ?? 0).toDouble());
  static int get monthly {
    final p = _ps;
    if (fixed && p.isNotEmpty) return (num.tryParse('${p.first['amount']}') ?? 0).round();
    final m = (num.tryParse('${_pb['monthly_amount'] ?? 0}') ?? 0).round();
    if (m > 0) return m;
    return p.isNotEmpty ? (num.tryParse('${p.last['amount']}') ?? 0).round() : (silver ? 100 : 1000);
  }

  static String get buyMonth {
    final s = DateTime.tryParse((_pb['start'] ?? '').toString());
    if (s == null) return '—';
    final d = DateTime(s.year, s.month + months);
    return '${_taMonLong[d.month - 1]} ${d.year}';
  }

  /// Every installment paid (silver keeps saving monthly).
  static bool get schemeDone => (months - paidCount) <= 0 && !(silver && paidThisMonth);
  static bool get canPay => !schemeDone && (!paidThisMonth || silver);

  /// Short month name for each installment, from the start date.
  static List<String> get monthLabels {
    final s = DateTime.tryParse((_pb['start'] ?? '').toString());
    if (s == null) return const [];
    return [for (var i = 0; i < months; i++) taMonth(s.month + i)];
  }

  static String get dueText {
    final n = nowIst();
    final d = DateTime(n.year, n.month + (paidThisMonth ? 1 : 0), 7);
    return '${d.day} ${_taMon[d.month - 1]} ${d.year}-க்குள்';
  }

  static int get gold22 => (num.tryParse('${_rt['rate22'] ?? 0}') ?? 0).round();
  static int get goldChange => _rt['prev_rate22'] == null ? 0 : gold22 - (num.tryParse('${_rt['prev_rate22']}') ?? gold22).round();
  static double get silverRate => (num.tryParse('${_rt['silver'] ?? 0}') ?? 0).toDouble();
  static double get silverChange => _rt['prev_silver'] == null ? 0 : silverRate - (num.tryParse('${_rt['prev_silver']}') ?? silverRate).toDouble();
  /// True only when the shop has entered the rate for today's IST date.
  static bool get rateIsToday {
    final u = '${_rt['updated_on'] ?? ''}';
    if (u.length < 10) return false;
    final today = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)).toIso8601String().substring(0, 10);
    return u.substring(0, 10) == today;
  }

  static String get rateStamp => _rt['updated_on'] == null
      ? (app.rateError ? 'விலை இப்போ கிடைக்கல' : 'விலை ஏற்றுகிறது…')
      : (rateIsToday ? 'இன்றைய விலை · ${taDate(_rt['updated_on'].toString())}' : 'கடைசி விலை · ${taDate(_rt['updated_on'].toString())} · இன்று இன்னும் புதுப்பிக்கல');
}

/// App state: live rate / notices / schemes for everyone, passbook after mPIN login.
class AppState extends ChangeNotifier {
  String mobile = '';
  String pin = '';
  bool loggedIn = false;
  bool haptics = true;
  Map<String, dynamic>? pb;
  Map<String, dynamic>? rate;
  bool rateError = false;
  List<Map<String, dynamic>> notices = [];
  bool noticesLoaded = false;
  List<Scheme> schemes = List.of(offlineSchemes);

  Scheme? _s(String k) {
    for (final s in schemes) {
      if (s.key == k) return s;
    }
    return null;
  }

  String schemeName(String k) => _s(k)?.name ?? k;
  int schemeMonths(String k) => _s(k)?.months ?? 11;
  bool schemeSilver(String k) => _s(k)?.silver ?? false;
  bool schemeGrams(String k) => _s(k)?.grams ?? (k == 'kubera');
  bool schemeFixed(String k) => _s(k)?.fixed ?? (k == 'kubera');

  Future<void> loadPublic() async {
    try {
      rate = await Api.rate();
      rateError = rate == null;
    } catch (_) {
      rateError = true;
    }
    notifyListeners();
    try {
      notices = await Api.notices();
      noticesLoaded = true;
    } catch (_) {}
    notifyListeners();
    try {
      final ex = await Api.extraSchemes();
      schemes = [...baseSchemes, ...ex.map(Scheme.fromDb)];
    } catch (_) {}
    notifyListeners();
  }

  void login(String m, String p, Map<String, dynamic> data) {
    mobile = m;
    pin = p;
    pb = data;
    loggedIn = true;
    notifyListeners();
    _syncNotify();
    Notify.linkFcm(mobile: m, pin: p);
  }

  void _syncNotify() {
    try {
      Notify.saveAccount(paidThisMonth: Demo.paidThisMonth, done: Demo.paidCount >= Demo.months, silver: Demo.silver, firstName: Demo.firstName);
    } catch (_) {}
  }

  Future<void> refreshPassbook() async {
    if (!loggedIn) return;
    try {
      final d = await Api.login(mobile, pin);
      if (d != null && d['name'] != null && d['wrong'] != true && d['locked'] != true && d['locked_otp'] != true) {
        pb = d;
        notifyListeners();
        _syncNotify();
      }
    } catch (_) {}
  }

  void logout() {
    loggedIn = false;
    pin = '';
    pb = null;
    notifyListeners();
  }
}

final app = AppState();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: C.navy,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: C.paper,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  app.loadPublic();
  runApp(const StmApp());
  WidgetsBinding.instance.addPostFrameCallback((_) => Notify.start());
}

class StmApp extends StatelessWidget {
  const StmApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: C.navy, primary: C.navy, surface: C.ivory),
      scaffoldBackgroundColor: C.ivory,
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
    return MaterialApp(
      title: 'சுப்புலட்சுமி தங்க மாளிகை',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(textTheme: GoogleFonts.notoSansTamilTextTheme(base.textTheme)),
      home: const Boot(),
    );
  }
}
