import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
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
    AppConfig.webProxyActive = false;
  }

  void updateToken(String? token) {
    _authToken =
        (token != null && token.trim().isNotEmpty) ? token.trim() : null;
  }

  Map<String, String> _headers({
    bool includeAuth = true,
    bool jsonContent = true,
    bool viaWebBridge = false,
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
    if (viaWebBridge && !AppConfig.isLoopbackUrl(_baseUrl)) {
      map['X-Hospital-Target'] = _baseUrl;
    }
    return map;
  }

  Uri _buildUri(
    String pathOrFullUrl, {
    Map<String, String>? queryParameters,
    String? overrideBaseUrl,
  }) {
    final effectiveBase =
        overrideBaseUrl ?? AppConfig.effectiveTransportBaseUrl(_baseUrl);
    Uri uri;
    if (pathOrFullUrl.startsWith('http://') ||
        pathOrFullUrl.startsWith('https://')) {
      final parsed = Uri.parse(pathOrFullUrl);
      if (overrideBaseUrl != null ||
          (kIsWeb &&
              AppConfig.webProxyActive &&
              !AppConfig.isLoopbackUrl(pathOrFullUrl))) {
        final proxyParsed = Uri.parse(effectiveBase);
        uri = parsed.replace(
          scheme: proxyParsed.scheme,
          host: proxyParsed.host,
          port: proxyParsed.hasPort ? proxyParsed.port : null,
        );
      } else {
        uri = parsed;
      }
    } else {
      final cleanPath =
          pathOrFullUrl.startsWith('/') ? pathOrFullUrl : '/$pathOrFullUrl';
      uri = Uri.parse('$effectiveBase$cleanPath');
    }

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    final filtered = <String, String>{...uri.queryParameters};
    queryParameters.forEach((key, val) {
      if (val.trim().isNotEmpty) {
        filtered[key] = val.trim();
      }
    });
    return filtered.isEmpty ? uri : uri.replace(queryParameters: filtered);
  }

  bool get _canFallbackToWebBridge =>
      kIsWeb && !AppConfig.webProxyActive && !AppConfig.isLoopbackUrl(_baseUrl);

  ApiException _formatNetworkError(Object e) {
    final raw = e.toString();
    if (kIsWeb &&
        (raw.contains('Failed to fetch') || raw.contains('XMLHttpRequest'))) {
      return ApiException(
        message:
            'Chrome browser CORS blocked direct request to $_baseUrl.\n'
            'To run in Chrome, start with: dart run tool/run_web.dart (or double-click run_chrome.bat).\n'
            'On Android APK / Emulator, direct connection works automatically.',
      );
    }
    return ApiException(
      message: 'Unable to connect to hospital server ($_baseUrl). $raw',
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool includeAuth = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final usingBridge = kIsWeb && AppConfig.webProxyActive;
      final uri = _buildUri(path, queryParameters: queryParameters);
      final response = await _http
          .get(
            uri,
            headers: _headers(
              includeAuth: includeAuth,
              jsonContent: false,
              viaWebBridge: usingBridge,
            ),
          )
          .timeout(timeout);
      return _decodeResponse(response, triggerAuthCallback: includeAuth);
    } on TimeoutException {
      throw const ApiException(
        message: 'Hospital server request timed out. Please check connectivity.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      if (_canFallbackToWebBridge) {
        try {
          final bridgeUri = _buildUri(
            path,
            queryParameters: queryParameters,
            overrideBaseUrl: AppConfig.localWebCorsProxyUrl,
          );
          final bridgeRes = await _http
              .get(
                bridgeUri,
                headers: _headers(
                  includeAuth: includeAuth,
                  jsonContent: false,
                  viaWebBridge: true,
                ),
              )
              .timeout(timeout);
          AppConfig.webProxyActive = true;
          return _decodeResponse(bridgeRes, triggerAuthCallback: includeAuth);
        } on ApiException {
          AppConfig.webProxyActive = true;
          rethrow;
        } catch (_) {}
      }
      throw _formatNetworkError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final encodedBody = jsonEncode(body ?? const <String, dynamic>{});
    try {
      final usingBridge = kIsWeb && AppConfig.webProxyActive;
      final uri = _buildUri(path);
      final response = await _http
          .post(
            uri,
            headers: _headers(
              includeAuth: includeAuth,
              jsonContent: true,
              viaWebBridge: usingBridge,
            ),
            body: encodedBody,
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
      if (_canFallbackToWebBridge) {
        try {
          final bridgeUri = _buildUri(
            path,
            overrideBaseUrl: AppConfig.localWebCorsProxyUrl,
          );
          final bridgeRes = await _http
              .post(
                bridgeUri,
                headers: _headers(
                  includeAuth: includeAuth,
                  jsonContent: true,
                  viaWebBridge: true,
                ),
                body: encodedBody,
              )
              .timeout(timeout);
          AppConfig.webProxyActive = true;
          return _decodeResponse(bridgeRes, triggerAuthCallback: includeAuth);
        } on ApiException {
          AppConfig.webProxyActive = true;
          rethrow;
        } catch (_) {}
      }
      throw _formatNetworkError(e);
    }
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final encodedBody = jsonEncode(body ?? const <String, dynamic>{});
    try {
      final usingBridge = kIsWeb && AppConfig.webProxyActive;
      final uri = _buildUri(path);
      final response = await _http
          .put(
            uri,
            headers: _headers(
              includeAuth: includeAuth,
              jsonContent: true,
              viaWebBridge: usingBridge,
            ),
            body: encodedBody,
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
      if (_canFallbackToWebBridge) {
        try {
          final bridgeUri = _buildUri(
            path,
            overrideBaseUrl: AppConfig.localWebCorsProxyUrl,
          );
          final bridgeRes = await _http
              .put(
                bridgeUri,
                headers: _headers(
                  includeAuth: includeAuth,
                  jsonContent: true,
                  viaWebBridge: true,
                ),
                body: encodedBody,
              )
              .timeout(timeout);
          AppConfig.webProxyActive = true;
          return _decodeResponse(bridgeRes, triggerAuthCallback: includeAuth);
        } on ApiException {
          AppConfig.webProxyActive = true;
          rethrow;
        } catch (_) {}
      }
      throw _formatNetworkError(e);
    }
  }

  Future<dynamic> delete(
    String path, {
    bool includeAuth = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final usingBridge = kIsWeb && AppConfig.webProxyActive;
      final uri = _buildUri(path);
      final response = await _http
          .delete(
            uri,
            headers: _headers(
              includeAuth: includeAuth,
              jsonContent: false,
              viaWebBridge: usingBridge,
            ),
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
      if (_canFallbackToWebBridge) {
        try {
          final bridgeUri = _buildUri(
            path,
            overrideBaseUrl: AppConfig.localWebCorsProxyUrl,
          );
          final bridgeRes = await _http
              .delete(
                bridgeUri,
                headers: _headers(
                  includeAuth: includeAuth,
                  jsonContent: false,
                  viaWebBridge: true,
                ),
              )
              .timeout(timeout);
          AppConfig.webProxyActive = true;
          return _decodeResponse(bridgeRes, triggerAuthCallback: includeAuth);
        } on ApiException {
          AppConfig.webProxyActive = true;
          rethrow;
        } catch (_) {}
      }
      throw _formatNetworkError(e);
    }
  }

  /// Downloads authenticated clinical reports (`/api/files/pathology_report/*`
  /// and `/api/files/radiology_report/*`) with `Authorization: Bearer <TOKEN>`.
  Future<({Uint8List bytes, String contentType})> downloadAuthenticatedBytes(
    String rawReportPath, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final fullUrl =
        AppConfig.resolveAuthenticatedReportUrl(_baseUrl, rawReportPath);
    final uri = _buildUri(fullUrl);
    try {
      final response = await _http
          .get(
            uri,
            headers: <String, String>{
              if (hasToken) 'Authorization': 'Bearer $_authToken',
              if (kIsWeb &&
                  AppConfig.webProxyActive &&
                  !AppConfig.isLoopbackUrl(_baseUrl))
                'X-Hospital-Target': _baseUrl,
            },
          )
          .timeout(timeout);
      if (response.statusCode == 401) {
        onUnauthorized?.call();
        throw const ApiException(
          message:
              'Session expired. Please log in again to view clinical reports.',
          statusCode: 401,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String errMsg =
            'Failed to fetch clinical report (${response.statusCode})';
        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map && parsed['message'] != null) {
            errMsg = parsed['message'].toString();
          }
        } catch (_) {}
        throw ApiException(message: errMsg, statusCode: response.statusCode);
      }
      final contentType =
          response.headers['content-type'] ?? 'application/octet-stream';
      return (bytes: response.bodyBytes, contentType: contentType);
    } on TimeoutException {
      throw const ApiException(message: 'Report download timed out.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _formatNetworkError(e);
    }
  }

  /// Uploads a clinical attachment (e.g. wound/rash photo on Nurse Progress Notes)
  /// to `POST https://hospital.hrpocket.in/api/uploads`.
  Future<String> uploadMultipartBytes({
    required String urlOrPath,
    required Uint8List bytes,
    required String filename,
    String fieldName = 'file',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = _buildUri(urlOrPath);
    final request = http.MultipartRequest('POST', uri);
    if (hasToken) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }
    if (kIsWeb &&
        AppConfig.webProxyActive &&
        !AppConfig.isLoopbackUrl(_baseUrl)) {
      request.headers['X-Hospital-Target'] = _baseUrl;
    }
    request.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
    );
    try {
      final streamed = await _http.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      final decoded = _decodeResponse(response, triggerAuthCallback: true);
      if (decoded is Map) {
        final data = decoded['data'];
        final candidate = decoded['url'] ??
            decoded['path'] ??
            decoded['file'] ??
            (data is Map ? (data['url'] ?? data['path'] ?? data['file']) : data);
        if (candidate != null && candidate.toString().trim().isNotEmpty) {
          return candidate.toString().trim();
        }
      }
      throw const ApiException(
        message: 'Upload completed without returning an attachment path.',
      );
    } on TimeoutException {
      throw const ApiException(message: 'Attachment upload timed out.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _formatNetworkError(e);
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
        message: _extractErrorMessage(decoded) ??
            'Invalid credentials or session expired.',
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
          message: _extractErrorMessage(decoded) ??
              'Operation rejected by server.',
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
