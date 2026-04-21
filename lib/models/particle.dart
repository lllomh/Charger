import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart' show HSVColor;

class Particle {
  Offset position;
  Offset velocity;
  double radius;
  double opacity;
  double speed;
  Color color;

  Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.opacity,
    required this.speed,
    required this.color,
  });

  factory Particle.spawn(Size screenSize, Random rng) {
    final x = rng.nextDouble() * screenSize.width;
    final y = screenSize.height + rng.nextDouble() * 40;
    final speed = 100.0 + rng.nextDouble() * 80.0;
    final vx = (rng.nextDouble() - 0.5) * speed * 0.3;
    final vy = -speed;

    return Particle(
      position: Offset(x, y),
      velocity: Offset(vx, vy),
      radius: 2.0 + rng.nextDouble() * 4.0,
      opacity: 0.5 + rng.nextDouble() * 0.5,
      speed: speed,
      color: HSVColor.fromAHSV(
        1.0,
        190 + rng.nextDouble() * 60,
        0.7 + rng.nextDouble() * 0.3,
        1.0,
      ).toColor(),
    );
  }
}
