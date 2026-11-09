import 'dart:convert';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'api.dart';

/// Phone notifications without any server change:
/// the app itself checks (every few hours, also in the background) for
///   • new shop notices (gold_notices)   • today's rate   • installment due (1–7 of the month)
/// and shows a normal Android notification. The unread count goes on the notification,
/// so launchers that support badges show the red number on the app icon.
class Notify {
  static final _p = FlutterLocalNotificationsPlugin();
  static final unread = ValueNotifier<int>(0);
  static const _task = 'stm-check';

  static const _icon = 'ic_stat_stm';
  static AndroidNotificationDetails _ch(String id, String name, int number, [String body = '']) => AndroidNotificationDetails(
        id,
        name,
        importance: Importance.high,
        priority: Priority.high,
        icon: _icon,
        color: const Color(0xFF6E1423),
        number: number,
        channelShowBadge: true,
        styleInformation: BigTextStyleInformation(body),
      );

  static Future<void> _show(int id, String title, String body, String ch, String chName, int n) =>
      _p.show(id, title, body, NotificationDetails(android: _ch(ch, chName, n, body)));

  /// Red number on the app icon (vivo / oppo / samsung / huawei launchers).
  static Future<void> badge(int n) async {
    try {
      await AppBadgePlus.updateBadge(n);
    } catch (_) {}
  }

  static bool _tzReady = false;
  static Future<void> init() async {
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      _tzReady = true;
    }
    await _p.initialize(const InitializationSettings(android: AndroidInitializationSettings(_icon)));
    // Channels created up-front so Firebase (FCM) messages land in the same named channels.
    final a = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    for (final c in const [
      ['stm_notice', 'கடை அறிவிப்புகள்'],
      ['stm_due', 'தவணை நினைவூட்டல்'],
      ['stm_rate', 'இன்றைய விலை'],
      ['stm_greet', 'தினசரி வணக்கம்'],
    ]) {
      await a?.createNotificationChannel(AndroidNotificationChannel(c[0], c[1], importance: Importance.high, showBadge: true));
    }
  }

  // ---------- Firebase (FCM): instant push from the shop ----------
  static const fbOptions = FirebaseOptions(
    apiKey: 'AIzaSyAkwonB9H8DxoLdeA0ZJ36qkJ759jRcDTk',
    appId: '1:742720250332:android:b5b66132e6ca609f5bef19',
    messagingSenderId: '742720250332',
    projectId: 'stm-gold',
    storageBucket: 'stm-gold.firebasestorage.app',
  );
  static bool _fcmReady = false;

  static Future<void> startFcm() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: fbOptions);
      FirebaseMessaging.onBackgroundMessage(fcmBackground);
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      FirebaseMessaging.onMessage.listen((m) async {
        final n = m.notification;
        if (n == null) return;
        final sp = await SharedPreferences.getInstance();
        final c = (sp.getInt('unread') ?? 0) + 1;
        await sp.setInt('unread', c);
        unread.value = c;
        await badge(c);
        final due = '${m.data['tag'] ?? ''}'.startsWith('due');
        await _show(DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000, n.title ?? 'சுப்புலட்சுமி தங்க மாளிகை', n.body ?? '',
            due ? 'stm_due' : 'stm_notice', due ? 'தவணை நினைவூட்டல்' : 'கடை அறிவிப்புகள்', c);
      });
      fm.onTokenRefresh.listen((_) => linkFcm());
      _fcmReady = true;
      await linkFcm();
    } catch (e) {
      debugPrint('fcm: $e');
    }
  }

  /// Register this phone's FCM token with the shop server (push function, same table as the website).
  /// With mobile + mPIN it is linked to the customer, so personal reminders / greetings reach it too.
  static String _m = '', _pin = '';
  static Future<void> linkFcm({String? mobile, String? pin}) async {
    if (mobile != null) _m = mobile;
    if (pin != null) _pin = pin;
    if (!_fcmReady) return;
    try {
      final t = await FirebaseMessaging.instance.getToken();
      if (t == null) return;
      final r = await http.post(Uri.parse('${Api.url}/functions/v1/push'),
          headers: {'apikey': Api.anon, 'Authorization': 'Bearer ${Api.anon}', 'Content-Type': 'application/json'},
          body: jsonEncode({'action': 'fcm_sub', 'token': t, if (_m.isNotEmpty) 'mobile': _m, if (_pin.isNotEmpty) 'pin': _pin}));
      final d = jsonDecode(r.body);
      final sp = await SharedPreferences.getInstance();
      // Server sends personal reminders (1st / 5th) once linked and FCM is configured — then skip the local ones.
      if (d is Map && d['ok'] == true && d['linked'] == true && d['fcm'] == true) await sp.setBool('fcm_linked', true);
    } catch (e) {
      debugPrint('fcm link: $e');
    }
  }

  /// Foreground start: permission (Android 13+), background job, first check.
  static Future<void> start() async {
    try {
      await init();
      await _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        _task,
        _task,
        frequency: const Duration(hours: 3),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
      final sp = await SharedPreferences.getInstance();
      unread.value = sp.getInt('unread') ?? 0;
      await badge(unread.value);
      await scheduleGreetings();
      await check();
    } catch (e) {
      debugPrint('notify start: $e');
    }
    await startFcm();
  }

  static bool _on(SharedPreferences sp, String k) => sp.getBool(k) ?? true;
  static Future<bool> isOn(String k) async => _on(await SharedPreferences.getInstance(), k);
  static Future<void> setOn(String k, bool v) async => (await SharedPreferences.getInstance()).setBool(k, v);

  static DateTime _ist() => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  static String _day(DateTime d) => d.toIso8601String().substring(0, 10);

  /// Called after login / passbook refresh so background reminders know the status.
  static Future<void> saveAccount({required bool paidThisMonth, required bool done, required bool silver, String firstName = ''}) async {
    final sp = await SharedPreferences.getInstance();
    if (firstName.isNotEmpty && sp.getString('fname') != firstName) {
      await sp.setString('fname', firstName);
      await scheduleGreetings();
    }
    await sp.setBool('acct', true);
    await sp.setBool('done', done);
    await sp.setBool('silver', silver);
    if (paidThisMonth) await sp.setString('paid_ym', _day(_ist()).substring(0, 7));
  }

  /// Notices newer than this were not yet opened when the tab was entered (shown as "புதுசு").
  static final readBefore = ValueNotifier<String>('');

  /// Re-read the count written by the background isolate (FCM / WorkManager) and the
  /// notices list, so the bell inside the app shows the same number as the app icon.
  static Future<void> refresh() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.reload();
      var n = sp.getInt('unread') ?? 0;
      final read = sp.getString('read_notice');
      if (read != null) {
        final list = await Api.notices();
        final fresh = list.where((x) => '${x['created_at'] ?? ''}'.compareTo(read) > 0).length;
        if (fresh > n) {
          n = fresh;
          await sp.setInt('unread', n);
          await badge(n);
        }
      }
      unread.value = n;
    } catch (_) {}
  }

  /// Opening the அறிவிப்பு tab clears the count.
  static Future<void> markRead() async {
    final sp = await SharedPreferences.getInstance();
    readBefore.value = sp.getString('read_notice') ?? DateTime.now().toUtc().subtract(const Duration(days: 3)).toIso8601String();
    await sp.setString('read_notice', DateTime.now().toUtc().toIso8601String());
    await sp.setInt('unread', 0);
    unread.value = 0;
    await badge(0);
    try {
      await _p.cancelAll();
      await scheduleGreetings(); // cancelAll also removes scheduled greetings — put them back
    } catch (_) {}
  }

  static Future<void> test() async {
    await init();
    final sp = await SharedPreferences.getInstance();
    final n = (sp.getInt('unread') ?? 0) + 1;
    await sp.setInt('unread', n);
    unread.value = n;
    await badge(n);
    await _show(9, 'சுப்புலட்சுமி தங்க மாளிகை', 'இது ஒரு சோதனை அறிவிப்பு. இப்படித்தான் கடை அறிவிப்புகள் வரும் 🙏', 'stm_notice', 'கடை அறிவிப்புகள்', n);
  }

  /// One pass of all three checks. Safe to call from the app or from the background job.
  static Future<void> check() async {
    final sp = await SharedPreferences.getInstance();
    final now = _ist();
    final today = _day(now);

    // 1) New shop notices
    if (_on(sp, 'n_notice')) {
      try {
        final list = await Api.notices();
        final stamps = list.map((n) => '${n['created_at'] ?? ''}').where((s) => s.isNotEmpty).toList()..sort();
        final seen = sp.getString('seen_notice');
        if (stamps.isNotEmpty) {
          if (seen == null) {
            await sp.setString('seen_notice', stamps.last); // first run: don't flood old notices
          } else {
            final fresh = list.where((n) => '${n['created_at'] ?? ''}'.compareTo(seen) > 0).toList();
            if (fresh.isNotEmpty) {
              final count = (sp.getInt('unread') ?? 0) + fresh.length;
              await sp.setInt('unread', count);
              unread.value = count;
              await badge(count);
              var id = 100;
              for (final n in fresh.take(3)) {
                await _show(id++, '${n['title'] ?? 'புதிய அறிவிப்பு'}', '${n['body'] ?? ''}', 'stm_notice', 'கடை அறிவிப்புகள்', count);
              }
              await sp.setString('seen_notice', stamps.last);
            }
          }
        }
      } catch (_) {}
    }

    // 2) Today's rate — once a day, after the shop updates it
    if (_on(sp, 'n_rate') && now.hour >= 9 && sp.getString('rate_day') != today) {
      try {
        final r = await Api.rate();
        final on = '${r?['updated_on'] ?? ''}';
        if (r != null && on.startsWith(today)) {
          final g = (num.tryParse('${r['rate22'] ?? 0}') ?? 0).round();
          final s = num.tryParse('${r['silver'] ?? 0}') ?? 0;
          if (g > 0) {
            await _show(2, 'இன்றைய தங்க விலை', '22K தங்கம்: ₹${_inr(g)} / கிராம்${s > 0 ? '\nவெள்ளி: ₹${s.toStringAsFixed(s % 1 == 0 ? 0 : 2)} / கிராம்' : ''}', 'stm_rate', 'இன்றைய விலை', sp.getInt('unread') ?? 0);
            await sp.setString('rate_day', today);
          }
        }
      } catch (_) {}
    }

    // 3) Installment reminder — only for someone who has logged in on this phone
    if (_on(sp, 'n_due') && !(sp.getBool('fcm_linked') ?? false) && (sp.getBool('acct') ?? false) && !(sp.getBool('done') ?? false) && now.hour >= 10 && sp.getString('due_day') != today) {
      final silver = sp.getBool('silver') ?? false;
      final paid = sp.getString('paid_ym') == today.substring(0, 7);
      final remindDay = silver ? (now.day == 5 || now.day == 20) : (now.day == 1 || now.day == 4 || now.day == 7);
      if (!paid && remindDay) {
        await _show(
            3,
            'தவணை நினைவூட்டல்',
            silver ? 'இந்த மாதம் வெள்ளி சேமிப்பு இன்னும் செலுத்தல. App-லயே ₹100 முதல் செலுத்தலாம்.' : 'இந்த மாதத் தவணையை 7 ஆம் தேதிக்குள் செலுத்துங்க. App-லயே செலுத்தலாம்.', 'stm_due', 'தவணை நினைவூட்டல்', (sp.getInt('unread') ?? 0) + 1);
        await sp.setString('due_day', today);
      }
    }
  }

  static String _inr(int v) {
    final s = '$v';
    if (s.length <= 3) return s;
    final last = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last';
  }
}

/// Daily greetings — scheduled on the phone itself (like an alarm), so they come
/// at the set time even with mobile data / Wi-Fi off. The next 7 days are kept
/// scheduled; every app open / background run tops it up.
extension Greetings on Notify {
  static const slots = [
    [7, 0, 'காலை வணக்கம்'],
    [13, 0, 'மதிய வணக்கம்'],
    [20, 0, 'இரவு வணக்கம்'],
  ];
  static const texts = [
    [
      'இனிய காலை வணக்கம் 🌅 இன்றைய நாள் இனிதாக அமையட்டும்.',
      'காலை வணக்கம் ☀️ உங்கள் நாள் தங்கம் போல் ஜொலிக்கட்டும்.',
      'இனிய காலை வணக்கம் 🙏 மகிழ்ச்சியும் வளமும் பெருகட்டும்.',
      'காலை வணக்கம் 🌸 நம்பிக்கையுடன் இந்த நாளைத் தொடங்குங்கள்.',
      'இனிய காலை வணக்கம் 🌼 சிறு சேமிப்பு, பெரிய மகிழ்ச்சி!',
      'காலை வணக்கம் ☀️ குடும்பத்துடன் இனிய நாளாக அமையட்டும்.',
      'இனிய காலை வணக்கம் 🙏 இன்று எல்லாம் நல்லதாக நடக்கட்டும்.',
    ],
    [
      'மதிய வணக்கம் 🌤️ சாப்பிட்டீங்களா? கொஞ்சம் ஓய்வும் எடுங்க.',
      'இனிய மதிய வணக்கம் 🙏 உங்கள் நாள் நல்லபடியாகப் போகட்டும்.',
      'மதிய வணக்கம் ☀️ இன்றைய தங்க விலையை app-ல பாருங்க.',
      'மதிய வணக்கம் 🌿 வேலைக்கு நடுவுல கொஞ்சம் தண்ணீர் குடிங்க.',
      'இனிய மதிய வணக்கம் 😊 மீதி நாளும் இனிதாக அமையட்டும்.',
      'மதிய வணக்கம் 🌤️ உங்கள் உழைப்புக்கு நல்ல பலன் கிடைக்கட்டும்.',
      'இனிய மதிய வணக்கம் 🙏 மகிழ்ச்சியான மதியப் பொழுது!',
    ],
    [
      'இனிய இரவு வணக்கம் 🌙 நிம்மதியான உறக்கம் அமையட்டும்.',
      'இரவு வணக்கம் ✨ நாளைய நாள் இன்னும் சிறப்பாக அமையட்டும்.',
      'இனிய இரவு வணக்கம் 🌙 குடும்பத்துடன் இனிய இரவாக அமையட்டும்.',
      'இரவு வணக்கம் 🌟 இன்றைய உழைப்புக்கு நல்ல ஓய்வு எடுங்க.',
      'இனிய இரவு வணக்கம் 🙏 நல்ல கனவுகள் காணுங்கள்.',
      'இரவு வணக்கம் 🌙 அமைதியும் ஆரோக்கியமும் நிறையட்டும்.',
      'இனிய இரவு வணக்கம் ✨ நாளை சந்திப்போம்!',
    ],
  ];
}

const _greetBase = 500; // ids 500..520 (7 days × 3)

Future<void> scheduleGreetings() async {
  try {
    await Notify.init();
    final p = Notify._p;
    for (var id = _greetBase; id < _greetBase + 21; id++) {
      await p.cancel(id);
    }
    final sp = await SharedPreferences.getInstance();
    if (!(sp.getBool('n_greet') ?? true)) return;
    final name = sp.getString('fname') ?? '';
    final now = tz.TZDateTime.now(tz.local);
    for (var d = 0; d < 7; d++) {
      final day = now.add(Duration(days: d));
      final doy = day.difference(tz.TZDateTime(tz.local, day.year)).inDays;
      for (var k = 0; k < 3; k++) {
        final sl = Greetings.slots[k];
        final at = tz.TZDateTime(tz.local, day.year, day.month, day.day, sl[0] as int, sl[1] as int);
        if (!at.isAfter(now)) continue;
        final list = Greetings.texts[k];
        final body = '${list[doy % list.length]}\n— சுப்புலட்சுமி தங்க மாளிகை';
        await p.zonedSchedule(
          _greetBase + d * 3 + k,
          name.isEmpty ? '${sl[2]} 🙏' : '${sl[2]} $name 🙏',
          body,
          at,
          NotificationDetails(
            android: AndroidNotificationDetails('stm_greet', 'தினசரி வணக்கம்',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                icon: Notify._icon,
                color: const Color(0xFF6E1423),
                styleInformation: BigTextStyleInformation(body)),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  } catch (e) {
    debugPrint('greet: $e');
  }
}

/// Background entry point (runs in its own isolate, every ~3 hours when online).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Notify.init();
      await scheduleGreetings();
      await Notify.check();
    } catch (_) {}
    return true;
  });
}

/// FCM message while the app is closed: the system shows it; we only bump the unread count.
@pragma('vm:entry-point')
Future<void> fcmBackground(RemoteMessage m) async {
  try {
    final sp = await SharedPreferences.getInstance();
    final c = (sp.getInt('unread') ?? 0) + 1;
    await sp.setInt('unread', c);
    await Notify.badge(c);
  } catch (_) {}
}
