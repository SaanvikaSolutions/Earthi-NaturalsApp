import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

/// Thrown when a request fails — either because the API returned a non-2xx
/// response, or because it could never be reached ([statusCode] == 0).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  /// True when the request never reached the server (offline, wrong host,
  /// server down). Callers can retry these; a 4xx won't fix itself.
  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin HTTP wrapper around the Earthi Naturals backend.
/// Holds an optional bearer token for authenticated routes.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;
  String? _token;

  set token(String? value) => _token = value;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleaned = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('$_baseUrl$path').replace(queryParameters: cleaned);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> body) => _send(() =>
      _client.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> patch(String path, Map<String, dynamic> body) => _send(() =>
      _client.patch(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers));

  /// Runs [request] and turns transport failures into an [ApiException] too, so
  /// callers only ever handle one error type and can show the real reason
  /// instead of a generic "failed".
  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(_timeout);
    } on TimeoutException {
      // An unreachable host looks like this too: packets are dropped rather
      // than refused, so the connect hangs until the timeout instead of
      // failing fast. Word it to cover both.
      throw ApiException(
          0, "Can't reach the server — it didn't respond in time. Check "
              'your connection and try again.');
    } on SocketException {
      throw ApiException(0, _unreachable);
    } on http.ClientException {
      throw ApiException(0, _unreachable);
    }
    return _decode(res);
  }

  static const _timeout = Duration(seconds: 15);
  static const _unreachable =
      "Can't reach the server. Check your internet connection.";

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Request failed';
    throw ApiException(res.statusCode, msg);
  }
}
