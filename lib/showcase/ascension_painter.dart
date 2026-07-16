import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telemetry_of_the_high_wind/enum/payload_enums.dart';
import 'package:telemetry_of_the_high_wind/showcase/ascension_palette.dart';
import 'package:telemetry_of_the_high_wind/showcase/ascension_physics.dart';

class AscensionPainter extends CustomPainter {
  AscensionPainter({
    required this.world,
    required this.locked,
    required this.pulse,
  });

  final AscensionWorld world;
  final bool locked;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    _paintAtmosphere(canvas, size);
    if (locked) {
      _paintLockGrid(canvas, size);
    } else {
      _paintAltitudeGuides(canvas, size);
      _paintWind(canvas, size);
    }
    for (final balloon in world.balloons) {
      _paintBalloon(canvas, balloon);
    }
    _paintReticle(canvas, size);
  }

  void _paintWind(Canvas canvas, Size size) {
    // Jet-stream band around ~12 km.
    final jetY = world.altitudeToY(12);
    if (jetY > -40 && jetY < size.height + 40) {
      canvas.drawRect(
        Rect.fromLTWH(0, jetY - 28, size.width, 56),
        Paint()..color = AscensionPalette.ink.withValues(alpha: 0.04),
      );
      final label = TextPainter(
        text: TextSpan(
          text: 'JET STREAM',
          style: GoogleFonts.ibmPlexMono(
            color: AscensionPalette.ink.withValues(alpha: 0.28),
            fontSize: 9,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(size.width - label.width - 16, jetY - 36));
    }

    final streak = Paint()
      ..color = AscensionPalette.ink.withValues(alpha: 0.14)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 14; i++) {
      final row = (i * 0.071) % 1.0;
      final y = size.height * (0.18 + row * 0.7);
      final speed = 40 + (i % 5) * 18.0;
      final len = 28.0 + (i % 4) * 10;
      final x =
          ((world.windTime * speed) + i * 73) % (size.width + len) - len * 0.5;
      final wobble = sin(world.windTime * 2.2 + i) * 3;
      canvas.drawLine(
        Offset(x, y + wobble),
        Offset(x + len, y + wobble),
        streak,
      );
    }
  }

  void _paintAtmosphere(Canvas canvas, Size size) {
    // Flat matte layers — no glossy gradients.
    final layers = <(double, Color)>[
      (50, AscensionPalette.stratosphere),
      (35, AscensionPalette.tropopause),
      (18, AscensionPalette.troposphere),
      (8, const Color(0xFFD2DCE8)),
      (0, AscensionPalette.ground),
    ];

    for (var i = 0; i < layers.length; i++) {
      final topAlt = layers[i].$1;
      final bottomAlt = i + 1 < layers.length ? layers[i + 1].$1 : -5.0;
      final y0 = world.altitudeToY(topAlt);
      final y1 = world.altitudeToY(bottomAlt);
      final top = min(y0, y1);
      final bottom = max(y0, y1);
      canvas.drawRect(
        Rect.fromLTRB(0, top, size.width, bottom.clamp(0, size.height)),
        Paint()..color = layers[i].$2,
      );
    }

    // Soft wash toward white near camera focus band.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AscensionPalette.white.withValues(alpha: locked ? 0.55 : 0.08),
    );
  }

  void _paintAltitudeGuides(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AscensionPalette.ink.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var km = 0; km <= 50; km += 5) {
      final y = world.altitudeToY(km.toDouble());
      if (y < -10 || y > size.height + 10) continue;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      final label = TextPainter(
        text: TextSpan(
          text: '$km km',
          style: GoogleFonts.ibmPlexMono(
            color: AscensionPalette.ink.withValues(alpha: 0.28),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(10, y - 12));
    }
  }

  void _paintLockGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AscensionPalette.silver
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AscensionPalette.white.withValues(alpha: 0.72),
    );
  }

  void _paintBalloon(Canvas canvas, AscensionBalloon b) {
    final center = world.balloonScreenPos(b);
    final payload = world.payloadScreenPos(b);
    final r = b.baseRadius * b.expansion;
    final sx = 1 + (b.stretchX.abs() / 80).clamp(0.0, 0.55);
    final sy = 1 - (b.stretchX.abs() / 160).clamp(0.0, 0.25) +
        (b.stretchY.abs() / 200).clamp(0.0, 0.15);

    // Tether
    final tether = Paint()
      ..color = AscensionPalette.ink.withValues(alpha: 0.35)
      ..strokeWidth = 1.1;
    canvas.drawLine(center + Offset(0, r * sy * 0.85), payload, tether);

    if (b.state != BalloonState.floating && b.parachute > 0) {
      _paintParachute(canvas, payload, b.parachute);
    }

    if (b.state == BalloonState.floating || b.expansion > 0.35) {
      // Latex envelope — deformed ellipse under jet stretch.
      final envelope = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: r * 2 * sx,
          height: r * 2.15 * sy,
        ),
        Radius.circular(r),
      );
      canvas.drawRRect(
        envelope,
        Paint()..color = AscensionPalette.white,
      );
      canvas.drawRRect(
        envelope,
        Paint()
          ..color = AscensionPalette.silver
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );

      // Highlight flat panel (matte, not glossy).
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(-r * 0.25 * sx, -r * 0.3 * sy),
          width: r * 0.55 * sx,
          height: r * 0.35 * sy,
        ),
        Paint()..color = AscensionPalette.white,
      );

      if (b.ruptureFlash > 0) {
        canvas.drawCircle(
          center,
          r * (1.4 + (1 - b.ruptureFlash)),
          Paint()
            ..color = AscensionPalette.burst.withValues(alpha: b.ruptureFlash * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    _paintPayload(canvas, payload, b);
  }

  void _paintParachute(Canvas canvas, Offset payload, double t) {
    final top = payload + Offset(0, -28 * t - 10);
    final canopy = Rect.fromCenter(center: top, width: 42 * t, height: 22 * t);
    canvas.drawArc(
      canopy,
      pi,
      pi,
      false,
      Paint()..color = AscensionPalette.white,
    );
    canvas.drawArc(
      canopy,
      pi,
      pi,
      false,
      Paint()
        ..color = AscensionPalette.ink.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final lines = Paint()
      ..color = AscensionPalette.ink.withValues(alpha: 0.35)
      ..strokeWidth = 1.1;
    canvas.drawLine(top + Offset(-16 * t, 4), payload, lines);
    canvas.drawLine(top + Offset(16 * t, 4), payload, lines);
    canvas.drawLine(top, payload, lines);
  }

  void _paintPayload(Canvas canvas, Offset pos, AscensionBalloon b) {
    final type = b.payload.classification;
    final body = Rect.fromCenter(center: pos, width: 22, height: 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      Paint()..color = AscensionPalette.cardboard,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      Paint()
        ..color = AscensionPalette.ink.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Whip antenna
    canvas.drawLine(
      pos + const Offset(0, -14),
      pos + const Offset(0, -28),
      Paint()
        ..color = AscensionPalette.ink
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    if (type == PayloadClassification.radarTargetReflector) {
      final path = Path()
        ..moveTo(pos.dx, pos.dy - 14)
        ..lineTo(pos.dx + 14, pos.dy)
        ..lineTo(pos.dx, pos.dy + 14)
        ..lineTo(pos.dx - 14, pos.dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = AscensionPalette.silver
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    } else {
      // Clockwork cylinder + stylus
      final cyl = Rect.fromCenter(
        center: pos + const Offset(0, 2),
        width: 16,
        height: 16,
      );
      canvas.drawOval(cyl, Paint()..color = AscensionPalette.silver);
      canvas.drawOval(
        cyl,
        Paint()
          ..color = AscensionPalette.ink.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke,
      );
      final angle = b.cylinderAngle;
      canvas.drawLine(
        Offset(pos.dx + cos(angle) * 5, pos.dy + 2 + sin(angle) * 5),
        Offset(pos.dx + cos(angle) * 7, pos.dy + 2 + sin(angle) * 7),
        Paint()
          ..color = AscensionPalette.ink
          ..strokeWidth = 1.2,
      );
      if (b.scratchProgress > 0) {
        final stylus = Path();
        for (var i = 0; i < 12; i++) {
          final a = angle + i * 0.35;
          final p = Offset(
            pos.dx + cos(a) * (3 + i * 0.15),
            pos.dy + 2 + sin(a) * (3 + i * 0.15),
          );
          if (i == 0) {
            stylus.moveTo(p.dx, p.dy);
          } else {
            stylus.lineTo(p.dx, p.dy);
          }
        }
        canvas.drawPath(
          stylus,
          Paint()
            ..color = AscensionPalette.ink.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9,
        );
      }
    }

    // Tiny label
    final label = TextPainter(
      text: TextSpan(
        text: b.payload.classification.label.split(' ').first,
        style: GoogleFonts.ibmPlexMono(
          color: AscensionPalette.ink.withValues(alpha: 0.55),
          fontSize: 7,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 64);
    label.paint(canvas, pos + Offset(-label.width / 2, 22));
  }

  void _paintReticle(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = locked
          ? AscensionPalette.lock
          : AscensionPalette.reticle.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final r = 26 + sin(pulse * pi * 2) * (locked ? 2 : 0);
    canvas.drawCircle(c, r, paint);
    canvas.drawLine(c + Offset(-r - 10, 0), c + Offset(-r + 4, 0), paint);
    canvas.drawLine(c + Offset(r - 4, 0), c + Offset(r + 10, 0), paint);
    canvas.drawLine(c + Offset(0, -r - 10), c + Offset(0, -r + 4), paint);
    canvas.drawLine(c + Offset(0, r - 4), c + Offset(0, r + 10), paint);
    canvas.drawCircle(c, 2.2, Paint()..color = paint.color);
  }

  @override
  bool shouldRepaint(covariant AscensionPainter oldDelegate) => true;
}
