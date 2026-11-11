import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _http;
  String _baseUrl;
  String? _authToken;
  void Function()? onUnauthorized;

  ApiClient({
    required String baseUrl,
    String? authToken,
    http.Client? httpClient,
    this.onUnauthorized,
  })  : _baseUrl = AppConfig.normalizeBaseUrl(baseUrl),
        _authToken = authToken,
        _http = httpClient ?? http.Client();

  String get baseUrl => _baseUrl;
  String? get authToken => _authToken;
  bool get hasToken => _authToken != null && _authToken!.trim().isNotEmpty;

  void updateBaseUrl(String newUrl) {
    _baseUrl = AppConfig.normalizeBaseUrl(newUrl);
  }

  void updateToken(String? token) {
    _authToken = (token != null && token.trim().isNotEmpty) ? token.trim() : null;
  }

  Map<String, String> _headers({
    bool includeAuth = true,
    bool jsonContent = true,
  }) {
    final map = <String, String>{
      'Accept': 'application/json',
    };
    if (jsonContent) {
      map['Content-Type'] = 'application/json';
    }
    if (includeAuth && hasToken) {
      map['Authorization'] = 'Bearer $_authToken';
    }
    return map;
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$cleanPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    final filtered = <String, String>{};
    queryParameters.forEach((key, val) {
      if (val.trim().isNotEmpty) {
        filtered[key] = val.trim();
      }
    });
    return filtered.isEmpty ? uri : uri.replace(queryParameters: filtered);
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool includeAuth = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = _buildUri(path, queryParameters);
    try {
      final response = await _http
          .get(uri, headers: _headers(includeAuth: includeAuth, jsonContent: false))
          .timeout(timeout);
      return _decodeResponse(response, triggerAuthCallback: includeAuth);
    } on TimeoutException {
      throw const ApiException(
        message: 'Hospital server request timed out. Please check connectivity.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unable to reach hospital server ($_baseUrl). $e',
      );
    }
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = _buildUri(path);
    try {
      final response = await _http
          .post(
            uri,
            headers: _headers(includeAuth: includeAuth, jsonContent: true),
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(timeout);
      return _decodeResponse(response, triggerAuthCallback: includeAuth);
    } on TimeoutException {
      throw const ApiException(
        message: 'Server took too long to respond. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unable to connect to hospital server ($_baseUrl). $e',
      );
    }
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = _buildUri(path);
    try {
      final response = await _http
          .put(
            uri,
            headers: _headers(includeAuth: includeAuth, jsonContent: true),
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(timeout);
      return _decodeResponse(response, triggerAuthCallback: includeAuth);
    } on TimeoutException {
      throw const ApiException(
        message: 'Server took too long to respond. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unable to connect to hospital server ($_baseUrl). $e',
      );
    }
  }

  /// Downloads authenticated clinical reports (`/api/files/pathology_report/*`
  /// and `/api/files/radiology_report/*`) with `Authorization: Bearer <TOKEN>`.
  Future<({Uint8List bytes, String contentType})> downloadAuthenticatedBytes(
    String rawReportPath, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final fullUrl = AppConfig.resolveAuthenticatedReportUrl(_baseUrl, rawReportPath);
    final uri = Uri.parse(fullUrl);
    try {
      final response = await _http
          .get(
            uri,
            headers: <String, String>{
              if (hasToken) 'Authorization': 'Bearer $_authToken',
            },
          )
          .timeout(timeout);
      if (response.statusCode == 401) {
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Session expired. Please log in again to view clinical reports.',
          statusCode: 401,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String errMsg = 'Failed to fetch clinical report (${response.statusCode})';
        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map && parsed['message'] != null) {
            errMsg = parsed['message'].toString();
          }
        } catch (_) {}
        throw ApiException(message: errMsg, statusCode: response.statusCode);
      }
      final contentType = response.headers['content-type'] ?? 'application/octet-stream';
      return (bytes: response.bodyBytes, contentType: contentType);
    } on TimeoutException {
      throw const ApiException(message: 'Report download timed out.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Could not download report: $e');
    }
  }

  dynamic _decodeResponse(
    http.Response response, {
    required bool triggerAuthCallback,
  }) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }
    }

    if (response.statusCode == 401) {
      if (triggerAuthCallback) {
        onUnauthorized?.call();
      }
      throw ApiException(
        message: _extractErrorMessage(decoded) ?? 'Invalid credentials or session expired.',
        statusCode: 401,
        rawBody: decoded,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: _extractErrorMessage(decoded) ??
            'Request failed with status ${response.statusCode}',
        statusCode: response.statusCode,
        rawBody: decoded,
      );
    }

    if (decoded is Map && decoded.containsKey('status')) {
      final st = decoded['status'];
      if (st == 0 || st == false || st == '0' || st == 'error') {
        throw ApiException(
          message: _extractErrorMessage(decoded) ?? 'Operation rejected by server.',
          statusCode: response.statusCode,
          rawBody: decoded,
        );
      }
    }

    return decoded;
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map) {
      for (final key in const ['message', 'error', 'msg', 'detail']) {
        final v = decoded[key];
        if (v is String && v.trim().isNotEmpty) {
          return v.trim();
        }
      }
    }
    return null;
  }
}
