import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final bool showDot;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.label,
    this.showDot = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  ({Color bg, Color fg}) _resolvePalette() {
    final v = label.trim().toLowerCase();
    if (v.contains('critical') ||
        v.contains('urgent') ||
        v.contains('emergency') ||
        v.contains('allerg') ||
        v.contains('missed') ||
        v.contains('refused') ||
        v.contains('out of stock')) {
      return (bg: AppColors.dangerSoft, fg: AppColors.danger);
    }
    if (v.contains('pending') ||
        v.contains('due') ||
        v.contains('wait') ||
        v.contains('held') ||
        v.contains('process')) {
      return (bg: AppColors.warningSoft, fg: AppColors.warning);
    }
    if (v.contains('stable') ||
        v.contains('given') ||
        v.contains('complete') ||
        v.contains('ready') ||
        v.contains('available') ||
        v.contains('online') ||
        v.contains('verified')) {
      return (bg: AppColors.successSoft, fg: AppColors.success);
    }
    return (bg: AppColors.infoSoft, fg: AppColors.info);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _resolvePalette();
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: palette.fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: palette.fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
