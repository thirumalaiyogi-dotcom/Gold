import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui.dart';

/// Fingerprint login (owner approved 2026-11-09). Since 2026-11-21 also the phone's own screen lock
/// (pattern / PIN / password) like GPay — biometricOnly: false.
/// The mPIN is kept only on this phone, encrypted with the Android Keystore, and the app
/// hands it to the normal login RPC only after a successful fingerprint check.
/// Cleared on logout, when the mPIN is set again, or when the stored mPIN stops working.
class Bio {
  static final _auth = LocalAuthentication();
  static const _st = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  static const _kM = 'bio_mobile', _kP = 'bio_pin';

  /// Phone has a screen lock (fingerprint / face / pattern / PIN / password).
  static Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enabledFor(String mobile) async {
    try {
      return (await _st.read(key: _kM)) == mobile && ((await _st.read(key: _kP)) ?? '').length == 6;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> check(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }

  /// Turn on after a fresh fingerprint check.
  static Future<bool> enable(String mobile, String pin) async {
    if (pin.length != 6 || !await check('கைரேகை / phone lock உள்நுழைவை இயக்க உறுதிப்படுத்தவும்')) return false;
    try {
      await _st.write(key: _kM, value: mobile);
      await _st.write(key: _kP, value: pin);
      await setWanted(mobile, true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The customer's choice survives logout: logout wipes the stored mPIN (security),
  /// but the next mPIN login on this phone turns phone-lock login back on with one confirmation.
  static Future<void> setWanted(String mobile, bool v) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('bio_wanted_$mobile', v);
    } catch (_) {}
  }

  static Future<void> disable() async {
    try {
      await _st.delete(key: _kM);
      await _st.delete(key: _kP);
    } catch (_) {}
  }

  /// Fingerprint → stored mPIN (null if cancelled / not set up).
  static Future<String?> unlock(String mobile) async {
    if (!await enabledFor(mobile)) return null;
    if (!await check('Passbook திறக்க கைரேகை / phone lock-ஐ பயன்படுத்தவும்')) return null;
    try {
      return await _st.read(key: _kP);
    } catch (_) {
      return null;
    }
  }

  /// After a normal mPIN login: offer fingerprint once per mobile number.
  static Future<void> offer(BuildContext context, String mobile, String pin) async {
    try {
      if (await enabledFor(mobile) || !await available()) return;
      final sp = await SharedPreferences.getInstance();
      if (sp.getBool('bio_wanted_$mobile') == true) {
        await enable(mobile, pin);
        return;
      }
      final k = 'bio_asked_$mobile';
      if (sp.getBool(k) == true) return;
      await sp.setBool(k, true);
      if (!context.mounted) return;
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: C.paper,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.lock_person_outlined, size: 48, color: C.navy),
          title: Text('கைரேகை மூலம் உள்நுழையலாமா?', textAlign: TextAlign.center, style: serif(20, color: C.head)),
          content: Text('அடுத்த முறை mPIN இல்லாமல், உங்கள் phone-ன் கைரேகை / pattern / PIN மூலம் பாதுகாப்பாக உள்நுழையலாம். கணக்கு → அமைப்புகளில் எப்போது வேண்டுமானாலும் மாற்றலாம்.',
              textAlign: TextAlign.center, style: sans(14, color: C.mute, height: 1.6)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(children: [
              Expanded(child: OutlineBtn('இப்போது வேண்டாம்', onTap: () => Navigator.pop(c, false))),
              const SizedBox(width: 10),
              Expanded(child: PrimaryButton('இயக்கு', onTap: () => Navigator.pop(c, true))),
            ]),
          ],
        ),
      );
      if (yes == true) await enable(mobile, pin);
    } catch (_) {}
  }
}
