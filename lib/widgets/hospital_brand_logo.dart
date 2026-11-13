import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Renders the signature Smart Hospital full-blue squircle badge with a
/// centered bold white `+` medical cross (`image-42.png`).
class HospitalBrandLogo extends StatelessWidget {
  final double size;

  const HospitalBrandLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.24;
    final crossSpan = size * 0.54;
    final crossThick = size * 0.184;
    final barRadius = Radius.circular(crossThick * 0.10);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF298BFF),
            Color(0xFF136EF2),
            Color(0xFF004CE6),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33004CE6),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: crossSpan,
        height: crossSpan,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: crossThick,
              height: crossSpan,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(barRadius),
              ),
            ),
            Container(
              width: crossSpan,
              height: crossThick,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(barRadius),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Architectural hospital building illustration with curved royal-blue wave
/// matching the Nurse Care System Splash Screen.
class HospitalFacadeGraphic extends StatelessWidget {
  final double height;

  const HospitalFacadeGraphic({super.key, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _HospitalFacadePainter(),
      ),
    );
  }
}

class _HospitalFacadePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft sky clouds backdrop
    final cloudPaint = Paint()..color = const Color(0x55FFFFFF);
    canvas.drawCircle(Offset(w * 0.2, h * 0.28), 32, cloudPaint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.24), 40, cloudPaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.22), 36, cloudPaint);

    // Side wings
    final wingPaint = Paint()..color = const Color(0xFFD9E8FA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, h * 0.34, w * 0.22, h * 0.50),
        const Radius.circular(8),
      ),
      wingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.68, h * 0.34, w * 0.22, h * 0.50),
        const Radius.circular(8),
      ),
      wingPaint,
    );

    // Central glass hospital tower
    final towerPaint = Paint()..color = const Color(0xFFF3F8FF);
    final towerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.26, h * 0.16, w * 0.48, h * 0.68),
      const Radius.circular(10),
    );
    canvas.drawRRect(towerRect, towerPaint);

    final towerStroke = Paint()
      ..color = const Color(0xFFB5D1F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(towerRect, towerStroke);

    // Blue reflective glass curtain wall
    final glassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D82DE), Color(0xFF0C52A2)],
      ).createShader(Rect.fromLTWH(w * 0.30, h * 0.28, w * 0.40, h * 0.42));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.30, w * 0.40, h * 0.38),
        const Radius.circular(6),
      ),
      glassPaint,
    );

    // Window grid lines
    final gridPaint = Paint()
      ..color = const Color(0x55CFE6FF)
      ..strokeWidth = 1.1;
    for (int i = 1; i <= 3; i++) {
      final gx = w * (0.30 + i * 0.10);
      canvas.drawLine(Offset(gx, h * 0.30), Offset(gx, h * 0.68), gridPaint);
    }
    for (int j = 1; j <= 2; j++) {
      final gy = h * (0.30 + j * 0.125);
      canvas.drawLine(Offset(w * 0.30, gy), Offset(w * 0.70, gy), gridPaint);
    }

    // HOSPITAL header sign bar
    final signPaint = Paint()..color = AppColors.primaryDark;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.33, h * 0.20, w * 0.34, h * 0.07),
        const Radius.circular(5),
      ),
      signPaint,
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: 'HOSPITAL',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((w - tp.width) / 2, h * 0.235 - tp.height / 2),
    );

    // Bottom curved royal blue ribbon wave
    final ribbonPath = Path()
      ..moveTo(0, h * 0.84)
      ..quadraticBezierTo(w * 0.28, h * 0.68, w * 0.56, h * 0.80)
      ..quadraticBezierTo(w * 0.82, h * 0.91, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      ribbonPath,
      Paint()..color = AppColors.primary,
    );

    final whiteSheetPath = Path()
      ..moveTo(0, h * 0.92)
      ..quadraticBezierTo(w * 0.32, h * 0.77, w * 0.65, h * 0.88)
      ..quadraticBezierTo(w * 0.86, h * 0.95, w, h * 0.84)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(whiteSheetPath, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ECG heartbeat footer wave on the Nurse Portal Login Screen.
class EcgWaveFooter extends StatelessWidget {
  final double height;

  const EcgWaveFooter({super.key, this.height = 72});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(painter: _EcgWavePainter()),
    );
  }
}

class _EcgWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final waveBg = Path()
      ..moveTo(0, h * 0.35)
      ..quadraticBezierTo(w * 0.26, h * 0.05, w * 0.54, h * 0.52)
      ..quadraticBezierTo(w * 0.80, h * 0.92, w, h * 0.62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      waveBg,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0E5BB5), Color(0xFF7CB5F4)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Crisp ECG spike line on the right side
    final ecgPaint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final yBase = h * 0.44;
    final ecg = Path()
      ..moveTo(w * 0.58, yBase)
      ..lineTo(w * 0.68, yBase)
      ..lineTo(w * 0.71, yBase - 8)
      ..lineTo(w * 0.74, yBase + 16)
      ..lineTo(w * 0.775, yBase - 26)
      ..lineTo(w * 0.81, yBase + 20)
      ..lineTo(w * 0.84, yBase - 6)
      ..lineTo(w * 0.87, yBase)
      ..lineTo(w * 0.97, yBase);
    canvas.drawPath(ecg, ecgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
