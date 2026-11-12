import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/ipd_models.dart';

/// Bedside Vitals Trend Graph (`GET /api/ipd/:id` -> `vitals` history array).
class VitalsTrendChart extends StatelessWidget {
  final List<VitalSignRecord> vitals;

  const VitalsTrendChart({super.key, required this.vitals});

  @override
  Widget build(BuildContext context) {
    final chronological = List<VitalSignRecord>.from(vitals)
      ..sort((a, b) {
        final da = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });

    final recent = chronological.length > 10
        ? chronological.sublist(chronological.length - 10)
        : chronological;

    final pulsePoints = <double>[];
    final spo2Points = <double>[];
    final systolicPoints = <double>[];
    final labels = <String>[];

    for (final v in recent) {
      pulsePoints.add(v.pulseNumeric ?? 0);
      spo2Points.add(v.spo2Numeric ?? 0);
      systolicPoints.add(v.systolicNumeric ?? 0);
      labels.add(v.date != null ? AppFormatters.formatTime12h(v.date) : '');
    }

    final hasPlotData = pulsePoints.any((n) => n > 0) ||
        spo2Points.any((n) => n > 0) ||
        systolicPoints.any((n) => n > 0);

    if (!hasPlotData) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Record bedside vitals to view trend graph',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: const [
            _LegendDot(color: AppColors.danger, label: 'Heart Rate (bpm)'),
            _LegendDot(color: AppColors.primary, label: 'Systolic BP (mmHg)'),
            _LegendDot(color: AppColors.teal, label: 'SpO2 (%)'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 165,
          width: double.infinity,
          child: CustomPaint(
            painter: _VitalsGraphPainter(
              pulse: pulsePoints,
              systolic: systolicPoints,
              spo2: spo2Points,
              labels: labels,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VitalsGraphPainter extends CustomPainter {
  final List<double> pulse;
  final List<double> systolic;
  final List<double> spo2;
  final List<String> labels;

  const _VitalsGraphPainter({
    required this.pulse,
    required this.systolic,
    required this.spo2,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const rightPad = 12.0;
    const topPad = 10.0;
    const bottomPad = 24.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;
    if (chartW <= 0 || chartH <= 0) return;

    final allVals = <double>[
      ...pulse.where((v) => v > 0),
      ...systolic.where((v) => v > 0),
      ...spo2.where((v) => v > 0),
    ];
    if (allVals.isEmpty) return;

    final minVal = math.max(40.0, allVals.reduce(math.min) - 10);
    final maxVal = math.max(minVal + 20.0, allVals.reduce(math.max) + 10);

    final gridPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = topPad + (chartH * i / 3);
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + chartW, y), gridPaint);
      final axisValue = (maxVal - ((maxVal - minVal) * i / 3)).round();
      final tp = TextPainter(
        text: TextSpan(
          text: '$axisValue',
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    void drawSeries(List<double> values, Color color) {
      final pts = <Offset>[];
      final count = values.length;
      for (int i = 0; i < count; i++) {
        final v = values[i];
        if (v <= 0) continue;
        final x = count == 1
            ? leftPad + chartW / 2
            : leftPad + (chartW * i / (count - 1));
        final norm = ((v - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
        final y = topPad + chartH * (1.0 - norm);
        pts.add(Offset(x, y));
      }
      if (pts.isEmpty) return;

      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (pts.length >= 2) {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (int i = 1; i < pts.length; i++) {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
        canvas.drawPath(path, linePaint);
      }

      for (final p in pts) {
        canvas.drawCircle(p, 4.0, Paint()..color = Colors.white);
        canvas.drawCircle(p, 3.0, Paint()..color = color);
      }
    }

    drawSeries(systolic, AppColors.primary);
    drawSeries(pulse, AppColors.danger);
    drawSeries(spo2, AppColors.teal);

    // Draw first and last time labels
    if (labels.isNotEmpty) {
      final firstTp = TextPainter(
        text: TextSpan(
          text: labels.first,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      firstTp.paint(canvas, Offset(leftPad, topPad + chartH + 6));

      if (labels.length > 1) {
        final lastTp = TextPainter(
          text: TextSpan(
            text: labels.last,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        lastTp.paint(
          canvas,
          Offset(leftPad + chartW - lastTp.width, topPad + chartH + 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VitalsGraphPainter oldDelegate) => true;
}
