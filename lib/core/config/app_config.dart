import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  /// Default production hospital backend from live portal (https://hospital.hrpocket.in).
  /// Can also be overridden at build time with --dart-define=API_BASE_URL=...
  /// or changed at runtime from the Server Configuration sheet on Login / Profile.
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hospital.hrpocket.in',
  );

  /// Local Dart CORS bridge port used automatically on Flutter Web (Chrome)
  /// when `dart run tool/run_web.dart` or `dart run tool/cors_proxy.dart` is running.
  static const String localWebCorsProxyUrl = 'http://127.0.0.1:8787';

  /// Tracks whether Flutter Web is routing cross-origin requests via localWebCorsProxyUrl.
  static bool webProxyActive = false;

  static const String storageKeyToken = 'smart_hospital_nurse_jwt';
  static const String storageKeyBaseUrl = 'smart_hospital_base_url';
  static const String storageKeyCachedUser = 'smart_hospital_nurse_profile';

  static String normalizeBaseUrl(String raw) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return defaultBaseUrl;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.endsWith('/api')) {
      trimmed = trimmed.substring(0, trimmed.length - 4);
    }
    return trimmed;
  }

  static bool isLoopbackUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('://localhost') ||
        lower.contains('://127.0.0.1') ||
        lower.contains('://10.0.2.2');
  }

  static String effectiveTransportBaseUrl(String configuredBaseUrl) {
    final normalized = normalizeBaseUrl(configuredBaseUrl);
    if (kIsWeb && webProxyActive && !isLoopbackUrl(normalized)) {
      return localWebCorsProxyUrl;
    }
    return normalized;
  }

  /// Resolves relative upload paths like `/uploads/patient.jpg` against baseUrl.
  static String? resolveMediaUrl(String baseUrl, String? rawPath) {
    if (rawPath == null) return null;
    final clean = rawPath.trim();
    if (clean.isEmpty) return null;
    final transportBase = effectiveTransportBaseUrl(baseUrl);
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      if (kIsWeb && webProxyActive) {
        final parsed = Uri.tryParse(clean);
        if (parsed != null && !isLoopbackUrl(clean)) {
          final q = parsed.hasQuery ? '?${parsed.query}' : '';
          return '$localWebCorsProxyUrl${parsed.path}$q';
        }
      }
      return clean;
    }
    final normalizedPath = clean.startsWith('/') ? clean : '/$clean';
    return '$transportBase$normalizedPath';
  }

  /// Matches backend server.ts security guard:
  /// `/uploads/pathology_report/*` and `/uploads/radiology_report/*` return 401
  /// and MUST be requested through `/api/files/pathology_report/*` or
  /// `/api/files/radiology_report/*` with `Authorization: Bearer <TOKEN>`.
  static String resolveAuthenticatedReportUrl(String baseUrl, String rawPath) {
    final clean = rawPath.trim();
    final transportBase = effectiveTransportBaseUrl(baseUrl);
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      final rewritten = clean
          .replaceFirst(
            '/uploads/pathology_report/',
            '/api/files/pathology_report/',
          )
          .replaceFirst(
            '/uploads/radiology_report/',
            '/api/files/radiology_report/',
          );
      if (kIsWeb && webProxyActive && !isLoopbackUrl(rewritten)) {
        final parsed = Uri.tryParse(rewritten);
        if (parsed != null) {
          final q = parsed.hasQuery ? '?${parsed.query}' : '';
          return '$localWebCorsProxyUrl${parsed.path}$q';
        }
      }
      return rewritten;
    }
    var pathPart = clean.startsWith('/') ? clean : '/$clean';
    if (pathPart.startsWith('/uploads/pathology_report/')) {
      pathPart = pathPart.replaceFirst(
        '/uploads/pathology_report/',
        '/api/files/pathology_report/',
      );
    } else if (pathPart.startsWith('/uploads/radiology_report/')) {
      pathPart = pathPart.replaceFirst(
        '/uploads/radiology_report/',
        '/api/files/radiology_report/',
      );
    }
    return '$transportBase$pathPart';
  }
}
