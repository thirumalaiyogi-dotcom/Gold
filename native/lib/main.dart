import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login.dart';
import 'ui.dart';

/// PROTOTYPE: every number below is sample data. Nothing talks to the real backend.
class Demo {
  static const pin = '123456';
  static const gold22 = 13515;
  static const goldChange = -75;
  static const silver = 240.00;
  static const silverChange = 2.0;
  static const rateStamp = 'இன்றைய விலை · 24 அக். 2026 · காலை 9:42';
  static const name = 'பாண்டியன்';
  static const member = 'PAN123';
  static const scheme = 'குபேர லட்சுமி';
  static const months = 12;
  static const monthly = 5000;
  static const payments = [
    ['2', '3 செப். 2026', 5000, 0.370],
    ['1', '4 ஆக. 2026', 5000, 0.370],
  ];
}

/// Very small app state for the prototype.
class AppState extends ChangeNotifier {
  String mobile = '';
  bool loggedIn = false;
  bool haptics = true;
  void login(String m) {
    mobile = m;
    loggedIn = true;
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
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
  runApp(const StmApp());
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
      home: const WelcomeScreen(),
    );
  }
}
