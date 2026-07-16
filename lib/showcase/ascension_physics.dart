import 'dart:math';
import 'dart:ui';

import 'package:telemetry_of_the_high_wind/models/atmospheric_payload.dart';

enum BalloonState { floating, rupturing, parachuting }

class AscensionBalloon {
  AscensionBalloon({
    required this.payload,
    required this.anchorX,
    required this.seed,
  });

  AtmosphericPayload payload;
  final double anchorX;
  final int seed;

  double worldX = 0;
  double worldY = 0;
  double velX = 0;
  double velY = 0;
  double stretchX = 0;
  double stretchY = 0;
  double windPhase = 0;
  double expansion = 1;
  double cylinderAngle = 0;
  double scratchProgress = 0;
  double parachute = 0;
  BalloonState state = BalloonState.floating;
  bool popped = false;
  double ruptureFlash = 0;

  double get ceilingKm => max(payload.designAltitudeKm, 8);

  double get baseRadius => 12 + (payload.frequencyMhz % 40) * 0.08;
}

class AscensionWorld {
  AscensionWorld({required this.random});

  final Random random;
  final balloons = <AscensionBalloon>[];

  /// Camera altitude in km. Higher = looking further up.
  double viewAltitudeKm = 8;
  double viewVelocity = 0;
  bool physicsFrozen = false;
  String? lockedPayloadId;
  Size size = Size.zero;

  /// Global wind phase for streak animation.
  double windTime = 0;

  /// Visible altitude window around the camera (km).
  static const visibleSpanKm = 28.0;

  void syncPayloads(List<AtmosphericPayload> entries) {
    final ids = entries.map((e) => e.id).toSet();
    balloons.removeWhere((b) => !ids.contains(b.payload.id));

    for (final entry in entries) {
      final match = balloons.where((b) => b.payload.id == entry.id);
      if (match.isEmpty) {
        final seed = entry.id.hashCode;
        final anchor = (0.18 + (seed.abs() % 65) / 100).clamp(0.14, 0.86);
        final balloon = AscensionBalloon(
          payload: entry,
          anchorX: anchor,
          seed: seed,
        );
        balloon.worldX = balloon.anchorX;
        balloon.worldY = _homeAltitude(entry);
        balloon.windPhase = (seed.abs() % 628) / 100;
        balloons.add(balloon);
      } else {
        match.first.payload = entry;
      }
    }
  }

  double _homeAltitude(AtmosphericPayload p) {
    final ceiling = max(p.designAltitudeKm, 6);
    return (ceiling * 0.55 + (p.id.hashCode.abs() % 40) / 10).clamp(4.0, 45.0);
  }

  /// Map world altitude (km) to screen Y (0 = top).
  double altitudeToY(double altitudeKm) {
    final top = viewAltitudeKm + visibleSpanKm * 0.55;
    final bottom = viewAltitudeKm - visibleSpanKm * 0.45;
    final t = ((top - altitudeKm) / (top - bottom)).clamp(0.0, 1.0);
    return t * size.height;
  }

  Offset balloonScreenPos(AscensionBalloon b) {
    final sway = sin(b.windPhase) * 28 * (physicsFrozen ? 0 : 1);
    return Offset(
      b.worldX * size.width + sway + b.stretchX,
      altitudeToY(b.worldY) + b.stretchY,
    );
  }

  Offset payloadScreenPos(AscensionBalloon b) {
    final pos = balloonScreenPos(b);
    return pos + Offset(0, payloadHang(b));
  }

  /// Approximate relative ambient pressure (1 at sea level).
  double ambientPressure(double altitudeKm) =>
      exp(-altitudeKm / 8.5).clamp(0.05, 1.0);

  double jetStrengthAt(double altitudeKm) {
    final d = (altitudeKm - 12.0).abs() / 4.5;
    return exp(-d * d);
  }

  AscensionBalloon? hitTest(Offset screen, {double radius = 64}) {
    AscensionBalloon? best;
    var bestDist = radius;
    for (final b in balloons) {
      final d = (payloadScreenPos(b) - screen).distance;
      final balloonDist = (balloonScreenPos(b) - screen).distance;
      final nearest = min(d, balloonDist);
      if (nearest < bestDist) {
        bestDist = nearest;
        best = b;
      }
    }
    return best;
  }

  AscensionBalloon? nearestToReticle({double lockRadius = 52}) {
    if (size.isEmpty) return null;
    final center = Offset(size.width / 2, size.height / 2);
    AscensionBalloon? best;
    var bestDist = lockRadius;
    for (final b in balloons) {
      if (b.state == BalloonState.rupturing) continue;
      final d = (balloonScreenPos(b) - center).distance;
      if (d < bestDist) {
        bestDist = d;
        best = b;
      }
    }
    return best;
  }

  /// Hang distance from balloon envelope center to payload package.
  double payloadHang(AscensionBalloon b) =>
      26 + b.baseRadius * b.expansion * 0.55;

  /// Place the balloon envelope exactly on the reticle.
  void centerOnReticle(AscensionBalloon b) {
    if (size.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    b.stretchX = 0;
    b.stretchY = 0;
    b.velX = 0;
    b.velY = 0;
    b.worldX = 0.5;

    final top = viewAltitudeKm + visibleSpanKm * 0.55;
    final bottom = viewAltitudeKm - visibleSpanKm * 0.45;
    final t = (center.dy / size.height).clamp(0.0, 1.0);
    b.worldY = (top - t * (top - bottom)).clamp(2.0, 50.0);
  }

  /// Returns true if a balloon just ruptured this frame.
  bool step(double dt, {Offset? dragDelta, AscensionBalloon? dragged}) {
    var didPop = false;
    if (size.isEmpty) return false;

    if (!physicsFrozen) {
      windTime += dt;
      viewVelocity *= pow(0.18, dt).toDouble();
      viewAltitudeKm = (viewAltitudeKm + viewVelocity * dt).clamp(1.5, 52.0);
    } else if (lockedPayloadId != null) {
      final locked = balloons.where((b) => b.payload.id == lockedPayloadId);
      if (locked.isNotEmpty) {
        centerOnReticle(locked.first);
      }
    }

    for (final b in balloons) {
      final pressure = ambientPressure(b.worldY);
      final targetExpansion =
          (1 / pow(pressure, 0.33)).toDouble().clamp(1.0, 2.8);
      b.expansion += (targetExpansion - b.expansion) * min(1.0, dt * 3);

      if (!physicsFrozen && dragged != b) {
        b.windPhase += dt * (1.1 + (b.seed.abs() % 10) / 12);
        final jet = jetStrengthAt(b.worldY);
        // Stronger lateral wind so sway is obvious.
        b.velX += sin(b.windPhase * 0.85) * (22 + jet * 55) * dt;
        b.velX *= pow(0.35, dt).toDouble();
        b.worldX += b.velX * dt / max(size.width, 1);
        b.worldX = b.worldX.clamp(0.1, 0.9);

        // Soft home pull — weak enough that drag feels free.
        final home = _homeAltitude(b.payload);
        b.velY += (home - b.worldY) * 0.12 * dt;
        b.velY *= pow(0.5, dt).toDouble();
        b.worldY += b.velY * dt;
      }

      if (dragged == b && dragDelta != null && !physicsFrozen) {
        // Dragging a spent balloon reinflates it for another ascent.
        if (b.state != BalloonState.floating) {
          _reinflate(b, keepAltitude: true);
        }
        // High gain drag — finger motion maps closely to balloon motion.
        b.stretchX = (b.stretchX + dragDelta.dx * 0.55).clamp(-48, 48);
        b.stretchY = (b.stretchY + dragDelta.dy * 0.25).clamp(-28, 28);
        b.worldX += dragDelta.dx / size.width * 1.35;
        b.worldX = b.worldX.clamp(0.08, 0.92);
        final altDelta = -dragDelta.dy / size.height * visibleSpanKm * 0.85;
        // Stay under this specimen's burst ceiling so drag can't immediately re-pop it.
        final maxSafe = b.ceilingKm * 1.05;
        b.worldY = (b.worldY + altDelta).clamp(2.0, maxSafe);
        b.velX = 0;
        b.velY = 0;
      } else {
        b.stretchX *= pow(0.12, dt).toDouble();
        b.stretchY *= pow(0.12, dt).toDouble();
      }

      if (b.scratchProgress > 0) {
        b.cylinderAngle += dt * (3.5 + b.scratchProgress * 6);
        b.scratchProgress = max(0, b.scratchProgress - dt * 0.28);
      }

      if (b.state == BalloonState.floating &&
          !b.popped &&
          (b.expansion > 2.35 || b.worldY > b.ceilingKm * 1.12)) {
        b.state = BalloonState.rupturing;
        b.popped = true;
        b.ruptureFlash = 1;
        didPop = true;
      }

      if (b.state == BalloonState.rupturing) {
        b.ruptureFlash = max(0, b.ruptureFlash - dt * 2.2);
        b.parachute = min(1, b.parachute + dt * 1.4);
        if (b.parachute > 0.35) b.state = BalloonState.parachuting;
      }

      if (b.state == BalloonState.parachuting && !physicsFrozen) {
        b.worldY = max(1.5, b.worldY - dt * 2.8);
        b.expansion = max(0.2, b.expansion - dt * 1.5);
        // Touchdown — reinflate at home altitude for another flight.
        if (b.worldY <= 1.55) {
          _reinflate(b, keepAltitude: false);
        }
      }
    }
    return didPop;
  }

  /// Swipe up (negative dy) ascends; swipe down (positive dy) descends.
  void adjustAltitude(double swipeDy) {
    if (physicsFrozen) return;
    // Invert so up-swipe = climb.
    final impulse = (-swipeDy).clamp(-900.0, 900.0) / 48;
    viewVelocity += impulse;
    viewAltitudeKm = (viewAltitudeKm + impulse * 0.1).clamp(1.5, 52.0);
  }

  void windMainspring(AscensionBalloon b) {
    b.scratchProgress = 1.0;
    b.cylinderAngle += 0.85;
  }

  void _reinflate(AscensionBalloon b, {required bool keepAltitude}) {
    b.state = BalloonState.floating;
    b.popped = false;
    b.parachute = 0;
    b.ruptureFlash = 0;
    b.velX = 0;
    b.velY = 0;
    b.expansion = 1;
    if (!keepAltitude) {
      b.worldY = _homeAltitude(b.payload);
      b.worldX = b.anchorX;
    } else {
      b.worldY = min(b.worldY, b.ceilingKm * 0.95);
    }
  }

  void lockOn(AscensionBalloon b) {
    lockedPayloadId = b.payload.id;
    physicsFrozen = true;
    viewVelocity = 0;
    centerOnReticle(b);
  }

  void unlock() {
    lockedPayloadId = null;
    physicsFrozen = false;
  }
}
