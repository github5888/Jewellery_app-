class AppConfig {
  AppConfig._();

  /// Default production hospital backend from live portal (https://hospital.hrpocket.in).
  /// Can also be overridden at build time with --dart-define=API_BASE_URL=...
  /// or changed at runtime from the Server Configuration sheet on Login / Profile.
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hospital.hrpocket.in',
  );

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

  /// Resolves relative upload paths like `/uploads/patient.jpg` against baseUrl.
  static String? resolveMediaUrl(String baseUrl, String? rawPath) {
    if (rawPath == null) return null;
    final clean = rawPath.trim();
    if (clean.isEmpty) return null;
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final normalizedBase = normalizeBaseUrl(baseUrl);
    final normalizedPath = clean.startsWith('/') ? clean : '/$clean';
    return '$normalizedBase$normalizedPath';
  }

  /// Matches backend server.ts security guard:
  /// `/uploads/pathology_report/*` and `/uploads/radiology_report/*` return 401
  /// and MUST be requested through `/api/files/pathology_report/*` or
  /// `/api/files/radiology_report/*` with `Authorization: Bearer <TOKEN>`.
  static String resolveAuthenticatedReportUrl(String baseUrl, String rawPath) {
    final clean = rawPath.trim();
    final normalizedBase = normalizeBaseUrl(baseUrl);
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean
          .replaceFirst(
            '/uploads/pathology_report/',
            '/api/files/pathology_report/',
          )
          .replaceFirst(
            '/uploads/radiology_report/',
            '/api/files/radiology_report/',
          );
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
    return '$normalizedBase$pathPart';
  }
}
