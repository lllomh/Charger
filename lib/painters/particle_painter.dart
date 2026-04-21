import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/particle.dart';

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final String displayText;
  final double glowPulse;
  final double rotation;
  final double breath;

  const ParticlePainter({
    required this.particles,
    required this.displayText,
    required this.glowPulse,
    required this.rotation,
    required this.breath,
  });

  static const double circleRadius = 110.0;

  static Offset circleCenter(Size size) =>
      Offset(size.width / 2, size.height * 0.42);

  @override
  void paint(Canvas canvas, Size size) {
    final center = circleCenter(size);
    _drawParticles(canvas);
    _drawOuterHalos(canvas, center);
    _drawDashedOrbit(canvas, center);
    _drawPulseRing(canvas, center);
    _drawCircleFill(canvas, center);
    _drawSweepArc(canvas, center);
    _drawBorder(canvas, center);
    _drawInnerRim(canvas, center);
    _drawText(canvas, center);
  }

  void _drawParticles(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.opacity);
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  void _drawOuterHalos(Canvas canvas, Offset center) {
    final breathScale = 1.0 + breath * 0.06;
    final layers = [
      (offset: 70.0, blur: 50.0, alpha: 0.06),
      (offset: 45.0, blur: 28.0, alpha: 0.12),
      (offset: 24.0, blur: 16.0, alpha: 0.22),
      (offset: 10.0, blur: 8.0, alpha: 0.35),
    ];
    for (final l in layers) {
      final paint = Paint()
        ..color = Colors.cyanAccent
            .withValues(alpha: l.alpha * (0.75 + breath * 0.25))
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, l.blur);
      canvas.drawCircle(
          center, (circleRadius + l.offset) * breathScale, paint);
    }
  }

  void _drawDashedOrbit(Canvas canvas, Offset center) {
    final orbitRadius = circleRadius + 22 + breath * 4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.cyanAccent.withValues(alpha: 0.45);

    const dashCount = 36;
    const gap = math.pi * 2 / dashCount;
    const dashLen = gap * 0.45;

    for (var i = 0; i < dashCount; i++) {
      final startAngle = -rotation + i * gap;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: orbitRadius),
        startAngle,
        dashLen,
        false,
        paint,
      );
    }

    // Inner counter-rotating orbit
    final orbitRadius2 = circleRadius + 12;
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.cyanAccent.withValues(alpha: 0.25);
    const dashCount2 = 60;
    const gap2 = math.pi * 2 / dashCount2;
    const dashLen2 = gap2 * 0.35;
    for (var i = 0; i < dashCount2; i++) {
      final startAngle = rotation * 1.6 + i * gap2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: orbitRadius2),
        startAngle,
        dashLen2,
        false,
        paint2,
      );
    }
  }

  void _drawPulseRing(Canvas canvas, Offset center) {
    if (glowPulse <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 + glowPulse * 6.0
      ..color = Colors.cyanAccent.withValues(alpha: 0.5 + glowPulse * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 16.0);
    canvas.drawCircle(center, circleRadius + 4 + glowPulse * 14, paint);
  }

  void _drawCircleFill(Canvas canvas, Offset center) {
    final rect = Rect.fromCircle(center: center, radius: circleRadius);
    final fillPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF10253F),
          Color(0xFF061122),
          Color(0xFF020610),
        ],
        stops: [0.0, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, circleRadius, fillPaint);
  }

  void _drawSweepArc(Canvas canvas, Offset center) {
    final rect = Rect.fromCircle(center: center, radius: circleRadius);
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..shader = SweepGradient(
        center: Alignment.center,
        transform: GradientRotation(rotation),
        colors: [
          Colors.transparent,
          Colors.transparent,
          Colors.cyanAccent.withValues(alpha: 0.9),
          Colors.white,
          Colors.cyanAccent.withValues(alpha: 0.9),
          Colors.transparent,
          Colors.transparent,
        ],
        stops: const [0.0, 0.40, 0.47, 0.5, 0.53, 0.60, 1.0],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, circleRadius, sweepPaint);
  }

  void _drawBorder(Canvas canvas, Offset center) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = Colors.cyanAccent.withValues(alpha: 0.75);
    canvas.drawCircle(center, circleRadius, borderPaint);
  }

  void _drawInnerRim(Canvas canvas, Offset center) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.cyanAccent.withValues(alpha: 0.25);
    canvas.drawCircle(center, circleRadius - 8, paint);
  }

  void _drawText(Canvas canvas, Offset center) {
    const fontSize = 22.0;
    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: fontSize,
    );
    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(ui.TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        fontFeatures: const [ui.FontFeature.tabularFigures()],
        shadows: [
          const Shadow(
            color: Colors.cyanAccent,
            blurRadius: 12,
          ),
        ],
      ))
      ..addText(displayText);

    final width = circleRadius * 2 - 16;
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: width));

    canvas.drawParagraph(
      paragraph,
      center.translate(-width / 2, -paragraph.height / 2),
    );
  }

  @override
  bool shouldRepaint(ParticlePainter old) => true;
}
