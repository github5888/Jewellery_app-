import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../screens/profile/nurse_profile_screen.dart';
import '../state/nurse_portal_controller.dart';
import 'global_search_sheet.dart';
import 'patient_avatar.dart';

/// Studio-lit ambient top wash background so every screen feels spacious,
/// layered, and executive — without any clunky top AppBar.
class PremiumScreenBackground extends StatelessWidget {
  final Widget child;
  final Color? accentColor;

  const PremiumScreenBackground({
    super.key,
    required this.child,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final primary = accentColor ?? controller.personalTheme.primaryColor;

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: controller.personalTheme.scaffoldColor),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 290,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primary.withAlpha(22),
                    primary.withAlpha(8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -70,
          right: -50,
          width: 220,
          height: 220,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withAlpha(24),
                    primary.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Executive Floating Card with subtle dual-layer ambient shadow and crisp hairline border.
class SoftSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final BorderRadius? borderRadius;

  const SoftSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(22);
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.cardSurface,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
    return card;
  }
}

/// Sculpted Two-Tone Gradient Squircle Icon Badge used across KPIs, Bento & Headers.
class GradientIconBadge extends StatelessWidget {
  final IconData icon;
  final List<Color> colors;
  final double size;
  final double iconSize;
  final double radius;

  const GradientIconBadge({
    super.key,
    required this.icon,
    required this.colors,
    this.size = 40,
    this.iconSize = 20,
    this.radius = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colors.last.withAlpha(55),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

/// Elevated Pill Search Input with Tinted Icon Squircle & Crisp Clear Button.
class PremiumSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Color? accentColor;

  const PremiumSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary =
        accentColor ?? NursePortalScope.of(context).personalTheme.primaryColor;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: primary.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.search_rounded, size: 18, color: primary),
            ),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.cancel_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () {
                    controller.clear();
                    if (onClear != null) {
                      onClear!();
                    } else if (onChanged != null) {
                      onChanged!('');
                    }
                  },
                )
              : null,
        ),
      ),
    );
  }
}

/// Executive Native Mobile Screen Header for Embedded Shell Tabs
class MobileScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? countBadge;
  final Widget? trailingAction;
  final bool showSearchButton;

  const MobileScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.countBadge,
    this.trailingAction,
    this.showSearchButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final user = controller.currentUser;
    final primary = controller.personalTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CLINICAL WORKSPACE',
                      style: TextStyle(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                          height: 1.12,
                        ),
                      ),
                    ),
                    if (countBadge != null && countBadge!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primary.withAlpha(35)),
                        ),
                        child: Text(
                          countBadge!,
                          style: TextStyle(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFeatures: AppTheme.tabularNums,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (trailingAction != null) ...[
            trailingAction!,
            const SizedBox(width: 8),
          ] else if (showSearchButton) ...[
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => showGlobalHospitalSearchSheet(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NurseProfileScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, primary.withAlpha(140)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: PatientAvatar(
                  name: user?.fullName ?? 'Nurse',
                  imagePath: user?.image,
                  baseUrl: controller.baseUrl,
                  radius: 17.5,
                  backgroundColor: primary.withAlpha(22),
                  textColor: primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClinicalLoadingState extends StatelessWidget {
  final String message;

  const ClinicalLoadingState({
    super.key,
    this.message = 'Syncing live hospital workspace...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClinicalEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ClinicalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final primary = NursePortalScope.of(context).personalTheme.primaryColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary.withAlpha(28), primary.withAlpha(10)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 28, color: primary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ClinicalErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ClinicalErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.danger,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to Sync Hospital Data',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(150, 44),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Retry Sync'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Precision Radial Gauge with Subtle Calibration Ticks & Glowing Arc
class WardOccupancyRing extends StatelessWidget {
  final double ratio;
  final double size;
  final Color? trackColor;
  final Color? progressColor;
  final Widget? centerChild;

  const WardOccupancyRing({
    super.key,
    required this.ratio,
    this.size = 76,
    this.trackColor,
    this.progressColor,
    this.centerChild,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _OccupancyRingPainter(
              ratio: ratio.clamp(0.0, 1.0),
              trackColor: trackColor ?? const Color(0x2EFFFFFF),
              progressColor: progressColor ?? const Color(0xFF34D399),
            ),
          ),
          if (centerChild != null) centerChild!,
        ],
      ),
    );
  }
}

class _OccupancyRingPainter extends CustomPainter {
  final double ratio;
  final Color trackColor;
  final Color progressColor;

  const _OccupancyRingPainter({
    required this.ratio,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    // Subtle inner glass fill
    final fillPaint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, fillPaint);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (ratio > 0) {
      final active = ratio > 0.88 ? const Color(0xFFFB7185) : progressColor;
      final glowPaint = Paint()
        ..color = active.withAlpha(70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * ratio,
        false,
        glowPaint,
      );

      final progressPaint = Paint()
        ..color = active
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * ratio,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OccupancyRingPainter oldDelegate) =>
      oldDelegate.ratio != ratio ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
