import 'dart:convert';

import 'package:http/http.dart' as http;

/// Live Supabase access — the SAME public (anon) key the website uses.
/// Everything sensitive goes through the same RPCs as the website (mobile + mPIN checked in the database).
/// No service key, no direct table access to customers / payments.
class Api {
  static const url = 'https://efvcsxgzxkfcqjhgvniz.supabase.co';
  static const anon =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVmdmNzeGd6eGtmY3FqaGd2bml6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkwMTM3NTQsImV4cCI6MjA5NDU4OTc1NH0.b_y6Hm61BVbDJmERAF_CEGcPIEZi51xL2SgAqZJlqI4';
  static const site = 'https://gold.thirumalaiyogi.workers.dev';
  static final _h = {'apikey': anon, 'Authorization': 'Bearer $anon', 'Content-Type': 'application/json'};
  static const _t = Duration(seconds: 15);

  static Future<dynamic> _get(String path) async {
    final r = await http.get(Uri.parse('$url/rest/v1/$path'), headers: _h).timeout(_t);
    if (r.statusCode >= 300) throw ApiError(r.statusCode, r.body);
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  static Future<dynamic> rpc(String fn, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$url/rest/v1/rpc/$fn'), headers: _h, body: jsonEncode(body)).timeout(_t);
    if (r.statusCode >= 300) throw ApiError(r.statusCode, r.body);
    final s = utf8.decode(r.bodyBytes);
    return s.isEmpty ? null : jsonDecode(s);
  }

  static Future<Map<String, dynamic>?> rate() async {
    final d = await _get('gold_rate?select=*&id=eq.1&limit=1');
    return (d is List && d.isNotEmpty) ? Map<String, dynamic>.from(d.first) : null;
  }

  static Future<List<Map<String, dynamic>>> history(int days) async {
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String().substring(0, 10);
    final d = await _get('gold_rate_history?select=day,rate22,silver&day=gte.$since&order=day.asc');
    return (d as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> notices() async {
    final d = await _get('gold_notices?select=*&order=created_at.desc&limit=30');
    return (d as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> extraSchemes() async {
    final d = await _get('gold_schemes?select=*&active=eq.true&order=created_at.asc');
    return (d as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Same call as the website's Passbook login (5 wrong tries → OTP lock, enforced in the database).
  static Future<Map<String, dynamic>?> login(String mobile, String pin) async {
    final d = await rpc('gold_login', {'p_mobile': mobile, 'p_pin': pin});
    return d is Map ? Map<String, dynamic>.from(d) : null;
  }

  static Future<bool?> mobileOk(String mobile) async {
    final d = await rpc('gold_mobile_ok', {'p_mobile': mobile});
    return d is bool ? d : null;
  }

  static Future<Map<String, dynamic>?> activate(String mobile, String code, String pin) async {
    final d = await rpc('gold_activate', {'p_mobile': mobile, 'p_code': code, 'p_pin': pin});
    return d is Map ? Map<String, dynamic>.from(d) : null;
  }

  /// Join request — anon may only INSERT into gold_requests (RLS), same as the website form.
  static Future<void> enrol(Map<String, dynamic> row) async {
    final r = await http
        .post(Uri.parse('$url/rest/v1/gold_requests'), headers: {..._h, 'Prefer': 'return=minimal'}, body: jsonEncode(row))
        .timeout(_t);
    if (r.statusCode >= 300) throw ApiError(r.statusCode, r.body);
  }
}

class ApiError implements Exception {
  ApiError(this.status, this.body);
  final int status;
  final String body;
  bool get duplicate => status == 409 || body.contains('23505');
  @override
  String toString() => 'ApiError($status)';
}

/// Same Cashfree edge function the website uses (cf-pay). The function itself
/// re-checks mobile + mPIN, scheme rules, one-per-month etc. — the app adds no new rules.
class PayApi {
  static Future<Map<String, dynamic>> call(Map<String, dynamic> body) async {
    try {
      final r = await http
          .post(Uri.parse('${Api.url}/functions/v1/cf-pay'),
              headers: {'apikey': Api.anon, 'Authorization': 'Bearer ${Api.anon}', 'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 25));
      try {
        return Map<String, dynamic>.from(jsonDecode(utf8.decode(r.bodyBytes)));
      } catch (_) {
        return {'ok': false, 'err': 'http${r.statusCode}'};
      }
    } catch (_) {
      return {'ok': false, 'err': 'net'};
    }
  }
}
