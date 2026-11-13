import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// Defaults to the hosted backend on Render.
/// Override with --dart-define=API_BASE_URL=https://api.example.com
/// (local API: http://127.0.0.1:5080, Android emulator: http://10.0.2.2:5080).
class ApiClient {
  static const configuredUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dooja-app.onrender.com',
  );

  /// The free Render instance sleeps when idle and needs up to ~50s to wake.
  static const requestTimeout = Duration(seconds: 60);
  final String baseUrl;
  final http.Client client;
  final FlutterSecureStorage storage;
  String? token;
  ApiClient({
    this.baseUrl = configuredUrl,
    http.Client? client,
    this.storage = const FlutterSecureStorage(),
  }) : client = client ?? http.Client();
  Future<void> restore() async {
    token = await storage.read(key: 'dooja.jwt');
  }

  Future<void> saveToken(String value) async {
    await storage.write(key: 'dooja.jwt', value: value);
    token = value;
  }

  Future<void> clearToken() async {
    token = null;
    await storage.delete(key: 'dooja.jwt');
  }

  Future<dynamic> request(
    String method,
    String path, [
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  ]) async {
    if (baseUrl.isEmpty)
      throw const ApiException('حدد عنوان API_BASE_URL قبل تشغيل التطبيق');
    final url = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/api/$path',
    );
    final req = http.Request(method, url)
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      });
    if (body != null) req.body = jsonEncode(body);
    http.Response res;
    try {
      res = await client
          .send(req)
          .then(http.Response.fromStream)
          .timeout(requestTimeout);
    } catch (_) {
      throw const ApiException(
        'تعذر الاتصال بالخادم. تحقق من الإنترنت وعنوان API',
      );
    }
    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      data = null;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (res.statusCode == 401) await clearToken();
      throw ApiException(
        data is Map
            ? (data['error'] ??
                      data['title'] ??
                      'فشل الطلب (${res.statusCode})')
                  .toString()
            : res.statusCode == 401
            ? 'انتهت الجلسة، سجّل دخول من جديد'
            : 'فشل الطلب (${res.statusCode})',
        res.statusCode,
      );
    }
    return data;
  }

  /// Wakes a sleeping server early so the first real request is fast.
  Future<void> warmUp() async {
    if (baseUrl.isEmpty) return;
    try {
      await client
          .get(Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/health'))
          .timeout(requestTimeout);
    } catch (_) {}
  }

  Future<dynamic> get(String path) => request('GET', path);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      request('POST', path, body);
  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      request('PUT', path, body);
  Future<dynamic> delete(String path) => request('DELETE', path);
}
