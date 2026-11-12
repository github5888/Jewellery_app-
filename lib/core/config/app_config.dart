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
  static bool webProxyActive = const bool.fromEnvironment(
    'USE_WEB_PROXY',
    defaultValue: false,
  );

  static const String storageKeyToken = 'smart_hospital_nurse_jwt';
  static const String storageKeyBaseUrl = 'smart_hospital_base_url';
  static const String storageKeyCachedUser = 'smart_hospital_nurse_profile';
  static const String storageKeyPersonalTheme =
      'smart_hospital_personal_theme';

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

  static String? _cleanMediaRaw(String? rawPath) {
    if (rawPath == null) return null;
    var clean = rawPath.trim();
    if (clean.isEmpty) return null;
    final lower = clean.toLowerCase();
    if (lower == 'null' ||
        lower == 'undefined' ||
        lower == 'none' ||
        lower == 'n/a' ||
        lower == 'default.png' ||
        lower == 'avatar.png' ||
        lower == 'no-image.png') {
      return null;
    }
    if (lower.startsWith('data:')) {
      return clean;
    }
    // Detect raw base64 image payloads stored without data URI header
    final compact = clean.replaceAll(RegExp(r'\s+'), '');
    if (compact.length > 100 && !compact.contains('://') && !compact.startsWith('/')) {
      if (compact.startsWith('/9j/')) {
        return 'data:image/jpeg;base64,$compact';
      }
      if (compact.startsWith('iVBOR')) {
        return 'data:image/png;base64,$compact';
      }
      if (compact.startsWith('R0lGOD')) {
        return 'data:image/gif;base64,$compact';
      }
      if (compact.startsWith('UklGR')) {
        return 'data:image/webp;base64,$compact';
      }
    }
    if (clean.startsWith('/9j/') && clean.length > 100) {
      final jpegCompact = clean.replaceAll(RegExp(r'\s+'), '');
      return 'data:image/jpeg;base64,$jpegCompact';
    }
    return clean.replaceAll('\\', '/');
  }

  static String _encodeFullUrl(String url) {
    // Avoid double-encoding already percent-encoded URLs while encoding spaces/parens
    if (url.contains('%')) {
      return url.replaceAll(' ', '%20');
    }
    return Uri.encodeFull(url);
  }

  /// Resolves primary media URL (`data:image/...` or full HTTP URL).
  static String? resolveMediaUrl(String baseUrl, String? rawPath) {
    final candidates = resolveMediaCandidateUrls(baseUrl, rawPath);
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Ordered candidate URLs for profile/patient photos across Express/Multer storage conventions:
  /// handles `/uploads/...`, `uploads/...`, `/public/uploads/...`, `/api/uploads/...`,
  /// `/api/files/...`, `http://` -> `https://` Nginx rewrites, `localhost` rewrites,
  /// `data:...;base64,...`, and bare filenames (`1731320-photo.png`).
  static List<String> resolveMediaCandidateUrls(
    String baseUrl,
    String? rawPath,
  ) {
    final clean = _cleanMediaRaw(rawPath);
    if (clean == null) return const [];
    if (clean.toLowerCase().startsWith('data:')) {
      return <String>[clean];
    }

    final transportBase = effectiveTransportBaseUrl(baseUrl);
    final results = <String>[];
    void addCandidate(String u) {
      final encoded = _encodeFullUrl(u);
      if (!results.contains(encoded)) {
        results.add(encoded);
      }
    }

    void addRelativePathVariants(String relPath) {
      var rel = relPath.trim();
      if (rel.isEmpty) return;
      if (rel.startsWith('public/')) {
        rel = rel.substring('public/'.length);
      } else if (rel.startsWith('/public/')) {
        rel = rel.substring('/public'.length);
      }
      final withSlash = rel.startsWith('/') ? rel : '/$rel';

      if (withSlash.startsWith('/uploads/')) {
        addCandidate('$transportBase$withSlash');
        addCandidate('$transportBase/api$withSlash');
        addCandidate(
          '$transportBase${withSlash.replaceFirst('/uploads/', '/api/files/')}',
        );
      } else if (withSlash.startsWith('/api/')) {
        addCandidate('$transportBase$withSlash');
        if (withSlash.startsWith('/api/uploads/')) {
          addCandidate(
            '$transportBase${withSlash.replaceFirst('/api/uploads/', '/uploads/')}',
          );
        } else if (withSlash.startsWith('/api/files/')) {
          addCandidate(
            '$transportBase${withSlash.replaceFirst('/api/files/', '/uploads/')}',
          );
        }
      } else {
        final noLead = rel.startsWith('/') ? rel.substring(1) : rel;
        addCandidate('$transportBase/uploads/$noLead');
        addCandidate('$transportBase/uploads/profile/$noLead');
        addCandidate('$transportBase/uploads/staff/$noLead');
        addCandidate('$transportBase/uploads/avatars/$noLead');
        addCandidate('$transportBase/uploads/users/$noLead');
        addCandidate('$transportBase/uploads/profile_photo/$noLead');
        addCandidate('$transportBase/uploads/staff_photo/$noLead');
        addCandidate('$transportBase/uploads/images/$noLead');
        addCandidate('$transportBase/api/uploads/$noLead');
        addCandidate('$transportBase/api/files/profile/$noLead');
        addCandidate('$transportBase/api/files/staff/$noLead');
        addCandidate('$transportBase$withSlash');
      }
    }

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      final parsed = Uri.tryParse(_encodeFullUrl(clean));
      if (parsed != null && parsed.path.isNotEmpty && parsed.path != '/') {
        final q = parsed.hasQuery ? '?${parsed.query}' : '';
        final hostLower = parsed.host.toLowerCase();
        final baseUri = Uri.tryParse(normalizeBaseUrl(baseUrl));
        final sameOrInternalHost = hostLower == 'localhost' ||
            hostLower == '127.0.0.1' ||
            hostLower.startsWith('10.') ||
            hostLower.startsWith('192.168.') ||
            (baseUri != null && baseUri.host.toLowerCase() == hostLower);

        if (sameOrInternalHost) {
          addRelativePathVariants('${parsed.path}$q');
        }
        if (kIsWeb && webProxyActive && !isLoopbackUrl(clean)) {
          addCandidate('$localWebCorsProxyUrl${parsed.path}$q');
        }
      }
      // Upgrade cleartext http:// external/hospital URLs to https:// first on mobile
      if (clean.startsWith('http://') && !isLoopbackUrl(clean)) {
        addCandidate('https://${clean.substring('http://'.length)}');
      }
      addCandidate(clean);
      if (parsed != null && parsed.path.isNotEmpty && parsed.path != '/') {
        final q = parsed.hasQuery ? '?${parsed.query}' : '';
        addRelativePathVariants('${parsed.path}$q');
      }
      return results;
    }

    addRelativePathVariants(clean);
    return results;
  }

  /// Matches backend server.ts security guard:
  /// `/uploads/pathology_report/*` and `/uploads/radiology_report/*` return 401
  /// and MUST be requested through `/api/files/pathology_report/*` or
  /// `/api/files/radiology_report/*` with `Authorization: Bearer <TOKEN>`.
  static String resolveAuthenticatedReportUrl(String baseUrl, String rawPath) {
    final clean = rawPath.trim().replaceAll('\\', '/');
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
        final parsed = Uri.tryParse(_encodeFullUrl(rewritten));
        if (parsed != null) {
          final q = parsed.hasQuery ? '?${parsed.query}' : '';
          return '$localWebCorsProxyUrl${parsed.path}$q';
        }
      }
      return _encodeFullUrl(rewritten);
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
    return _encodeFullUrl('$transportBase$pathPart');
  }
}
