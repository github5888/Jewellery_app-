import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../state/nurse_portal_controller.dart';

/// Resilient Clinical Profile & Patient Avatar:
/// - Supports `data:image/...;base64,...` (including multiline/whitespace base64) and raw base64
/// - Probes all candidate Express/Multer media URLs (`/uploads/...`, `/uploads/profile/...`,
///   `/uploads/staff/...`, `/api/uploads/...`, `/api/files/...`)
/// - Sends `Authorization: Bearer <JWT>` when available (with unauthenticated fallback)
/// - Guards against Express SPA catch-all `index.html` responses (`text/html`)
/// - Caches decoded `Uint8List` bytes in memory for instant zero-flicker rendering across screens.
class PatientAvatar extends StatefulWidget {
  final String name;
  final String? imagePath;
  final String baseUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const PatientAvatar({
    super.key,
    required this.name,
    required this.baseUrl,
    this.imagePath,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
  });

  static final Map<String, Uint8List> _memoryCache = <String, Uint8List>{};
  static final Map<String, Future<Uint8List?>> _inFlight =
      <String, Future<Uint8List?>>{};
  static int _cacheGeneration = 0;

  static void clearCache() {
    _memoryCache.clear();
    _inFlight.clear();
    _cacheGeneration++;
  }

  static void primeCache(String baseUrl, String rawPath, Uint8List bytes) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty || bytes.isEmpty) return;
    _memoryCache['$baseUrl|$trimmed'] = bytes;
    _cacheGeneration++;
  }

  @override
  State<PatientAvatar> createState() => _PatientAvatarState();
}

class _PatientAvatarState extends State<PatientAvatar> {
  Uint8List? _resolvedBytes;
  String? _activeKey;
  String? _lastAuthToken;
  int _seenGeneration = PatientAvatar._cacheGeneration;

  @override
  void initState() {
    super.initState();
    _syncImage(allowSetState: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncImage(allowSetState: false);
  }

  @override
  void didUpdateWidget(covariant PatientAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentToken = _readAuthToken();
    final tokenArrived = (_lastAuthToken == null || _lastAuthToken!.isEmpty) &&
        (currentToken != null && currentToken.isNotEmpty);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.baseUrl != widget.baseUrl ||
        _seenGeneration != PatientAvatar._cacheGeneration ||
        (tokenArrived && _resolvedBytes == null)) {
      _syncImage(allowSetState: true);
    }
  }

  String? _readAuthToken() {
    final element =
        context.getElementForInheritedWidgetOfExactType<NursePortalScope>();
    if (element == null) return null;
    final scope = element.widget as NursePortalScope;
    return scope.notifier?.authToken;
  }

  Uint8List? _tryDecodeDataUri(String uri) {
    try {
      final commaIdx = uri.indexOf(',');
      if (commaIdx == -1) return null;
      final cleanB64 = uri
          .substring(commaIdx + 1)
          .replaceAll(RegExp(r'\s+'), '');
      if (cleanB64.isEmpty) return null;
      return base64Decode(cleanB64);
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeRealImageBytes(Uint8List bytes, String? contentType) {
    if (bytes.length < 16) return false;
    final ct = (contentType ?? '').toLowerCase();
    if (ct.contains('text/html') ||
        ct.contains('application/json') ||
        ct.contains('text/plain')) {
      return false;
    }
    final head = String.fromCharCodes(bytes.take(32)).trimLeft().toLowerCase();
    if (head.startsWith('<!doctype') ||
        head.startsWith('<html') ||
        head.startsWith('<head') ||
        head.startsWith('<svg') ||
        head.startsWith('{') ||
        head.startsWith('[')) {
      return false;
    }
    // Check magic headers: JPEG, PNG, GIF, WEBP, BMP, AVIF/HEIF (`ftyp`), ICO, TIFF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return true;
    }
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return true;
    if (bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70) {
      return true;
    }
    if (ct.startsWith('image/') || ct.contains('octet-stream')) return true;
    return false;
  }

  Future<Uint8List?> _fetchCandidateBytes(
    List<String> candidates,
    String? token,
  ) async {
    for (final url in candidates) {
      final uri = Uri.tryParse(url);
      if (uri == null) continue;

      final headerAttempts = <Map<String, String>>[
        if (token != null && token.trim().isNotEmpty)
          <String, String>{
            'Authorization': 'Bearer ${token.trim()}',
            'Accept': 'image/*,*/*;q=0.8',
          },
        const <String, String>{
          'Accept': 'image/*,*/*;q=0.8',
        },
      ];

      for (final headers in headerAttempts) {
        try {
          final res = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 10));
          if (res.statusCode >= 200 &&
              res.statusCode < 300 &&
              _looksLikeRealImageBytes(
                res.bodyBytes,
                res.headers['content-type'],
              )) {
            return res.bodyBytes;
          }
          // If 404, no need to retry same URL without auth header
          if (res.statusCode == 404) break;
        } catch (_) {}
      }
    }
    if (kDebugMode && candidates.isNotEmpty) {
      debugPrint(
        '[PatientAvatar] Could not load image for "${widget.name}" from ${candidates.first}',
      );
    }
    return null;
  }

  void _applyBytes(Uint8List? bytes, {required bool allowSetState}) {
    if (allowSetState && mounted) {
      setState(() => _resolvedBytes = bytes);
    } else {
      _resolvedBytes = bytes;
    }
  }

  void _syncImage({required bool allowSetState}) {
    final raw = widget.imagePath?.trim() ?? '';
    if (raw.isEmpty) {
      if (_resolvedBytes != null || _activeKey != null) {
        _activeKey = null;
        _applyBytes(null, allowSetState: allowSetState);
      }
      return;
    }

    final cacheKey = '${widget.baseUrl}|$raw';
    final genChanged = _seenGeneration != PatientAvatar._cacheGeneration;
    _seenGeneration = PatientAvatar._cacheGeneration;

    final cached = PatientAvatar._memoryCache[cacheKey];
    if (cached != null) {
      _activeKey = cacheKey;
      if (_resolvedBytes != cached) {
        _applyBytes(cached, allowSetState: allowSetState);
      }
      return;
    }

    if (!genChanged && _activeKey == cacheKey && _resolvedBytes != null) {
      return;
    }
    _activeKey = cacheKey;

    final candidates = AppConfig.resolveMediaCandidateUrls(
      widget.baseUrl,
      raw,
    );
    if (candidates.isEmpty) {
      _applyBytes(null, allowSetState: allowSetState);
      return;
    }

    if (candidates.first.toLowerCase().startsWith('data:')) {
      final decoded = _tryDecodeDataUri(candidates.first);
      if (decoded != null) {
        PatientAvatar._memoryCache[cacheKey] = decoded;
      }
      _applyBytes(decoded, allowSetState: allowSetState);
      return;
    }

    final token = _readAuthToken();
    _lastAuthToken = token;
    final future = PatientAvatar._inFlight.putIfAbsent(
      cacheKey,
      () => _fetchCandidateBytes(candidates, token),
    );

    future.then((bytes) {
      PatientAvatar._inFlight.remove(cacheKey);
      if (bytes != null) {
        PatientAvatar._memoryCache[cacheKey] = bytes;
      }
      if (mounted && _activeKey == cacheKey) {
        setState(() => _resolvedBytes = bytes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final initials = AppFormatters.initials(widget.name);
    final bg = widget.backgroundColor ?? AppColors.skySurface;
    final fg = widget.textColor ?? AppColors.primary;
    final diameter = widget.radius * 2;

    if (_resolvedBytes != null) {
      return Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          _resolvedBytes!,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _buildInitialsText(initials, fg),
        ),
      );
    }

    return _buildInitialsCircle(initials, bg, fg, diameter);
  }

  Widget _buildInitialsText(String initials, Color fg) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: fg,
          fontSize: widget.radius * 0.72,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInitialsCircle(
    String initials,
    Color bg,
    Color fg,
    double diameter,
  ) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: fg,
          fontSize: widget.radius * 0.72,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
