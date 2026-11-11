import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';

class PatientAvatar extends StatelessWidget {
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

  Uint8List? _tryDecodeDataUri(String uri) {
    try {
      final commaIdx = uri.indexOf(',');
      if (commaIdx == -1) return null;
      return base64Decode(uri.substring(commaIdx + 1).trim());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = AppConfig.resolveMediaUrl(baseUrl, imagePath);
    final initials = AppFormatters.initials(name);
    final bg = backgroundColor ?? AppColors.skySurface;
    final fg = textColor ?? AppColors.primary;

    if (resolvedUrl == null) {
      return _buildInitialsCircle(initials, bg, fg);
    }

    if (resolvedUrl.startsWith('data:image/')) {
      final bytes = _tryDecodeDataUri(resolvedUrl);
      if (bytes == null) {
        return _buildInitialsCircle(initials, bg, fg);
      }
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsText(initials, fg),
        ),
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitialsText(initials, fg),
      ),
    );
  }

  Widget _buildInitialsText(String initials, Color fg) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: fg,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInitialsCircle(String initials, Color bg, Color fg) {
    return Container(
      width: radius * 2,
      height: radius * 2,
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
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
