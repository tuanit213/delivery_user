import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() {
    if (body.contains('ERR_NGROK_3200')) {
      return 'Máy chủ đang ngoại tuyến. Vui lòng khởi động backend và cập nhật API_BASE_URL.';
    }
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        final message = data['message'] ?? data['detail'] ?? data['title'];
        if (message is String && message.trim().isNotEmpty) return message;
      }
    } on FormatException {
      // Use the HTTP status when an error body is HTML or malformed JSON.
    }
    if (statusCode == 401) {
      return 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.';
    }
    if (statusCode == 403) return 'Bạn không có quyền thực hiện thao tác này.';
    return 'Không thể xử lý yêu cầu (HTTP $statusCode). Vui lòng thử lại.';
  }
}

/// A response from an earlier authentication session must not update the UI.
class SessionChangedException extends ApiException {
  const SessionChangedException()
    : super(0, '{"message":"Phiên đã thay đổi. Vui lòng thử lại."}');
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;
  String? get accessToken => _accessToken;
  String? _accessToken;
  int _sessionRevision = 0;
  int get sessionRevision => _sessionRevision;
  Future<void> Function()? onUnauthorized;

  void setAccessToken(String? token) {
    if (_accessToken == token) return;
    _accessToken = token;
    _sessionRevision++;
  }

  Future<Object?> get(String path, {Map<String, String>? query}) =>
      _request('GET', path, query: query);

  Future<Object?> post(String path, {Object? data}) =>
      _request('POST', path, data: data);

  Future<Object?> put(String path, {Object? data}) =>
      _request('PUT', path, data: data);

  Future<Object?> patch(String path, {Object? data}) =>
      _request('PATCH', path, data: data);

  Future<Object?> _request(
    String method,
    String path, {
    Object? data,
    Map<String, String>? query,
  }) async {
    final revision = _sessionRevision;
    final sentToken = _accessToken;
    final request = http.Request(method, _uri(path, query))
      ..headers.addAll(_headers);
    if (data != null) request.body = jsonEncode(data);
    late final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      if (revision != _sessionRevision) throw const SessionChangedException();
      rethrow;
    }
    if (revision != _sessionRevision) throw const SessionChangedException();
    if (response.statusCode == 401 && sentToken != null) {
      await onUnauthorized?.call();
    }
    return _decode(response);
  }

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse(
    '${_baseUrl.replaceAll(RegExp(r"/+$"), "")}$path',
  ).replace(queryParameters: query);

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',

    'ngrok-skip-browser-warning': 'true',
    if (_accessToken != null && _accessToken!.isNotEmpty)
      'Authorization': 'Bearer $_accessToken',
  };

  Object? _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

final apiClient = ApiClient();
