import 'dart:math' as math;
import 'dart:ui';

import 'package:shadows_on_the_quarry_wall/enum/my_enums.dart';
import 'package:shadows_on_the_quarry_wall/models/project_model.dart';
import 'package:shadows_on_the_quarry_wall/showcase/rift_reader_palette.dart';

enum RiftNodeKind { drill, wedge, gauge, arc, template, other }

RiftNodeKind kindForClass(ImplementationClass type) {
  switch (type) {
    case ImplementationClass.coreBoringRig:
      return RiftNodeKind.drill;
    case ImplementationClass.plugAndFeatherSet:
    case ImplementationClass.tracingChisel:
      return RiftNodeKind.wedge;
    case ImplementationClass.profileGauge:
      return RiftNodeKind.gauge;
    case ImplementationClass.levelingArc:
      return RiftNodeKind.arc;
    case ImplementationClass.moldingTemplate:
      return RiftNodeKind.template;
    case ImplementationClass.other:
      return RiftNodeKind.other;
  }
}

class StressImpulse {
  final Offset origin;
  final double birth;
  final double strength;

  const StressImpulse({
    required this.origin,
    required this.birth,
    this.strength = 1.0,
  });

  double radiusAt(double time) =>
      (time - birth) * RiftPalette.soundSpeedScale;

  bool isExpired(double time, double maxRadius) =>
      radiusAt(time) > maxRadius;
}

class FractureCrack {
  final List<Offset> points;
  bool active;
  double branchChance;

  FractureCrack({
    List<Offset>? points,
    this.active = true,
    this.branchChance = 0.18,
  }) : points = points ?? [];

  FractureCrack clone() => FractureCrack(
        points: List<Offset>.from(points),
        active: active,
        branchChance: branchChance,
      );
}

class RiftNode {
  final ImplementationClass type;
  final RiftNodeKind kind;
  final int count;
  final List<MasonryToolModel> items;

  double x;
  double y;
  double radius;
  double orientation;
  double appliedForce;
  bool isGrabbed;
  bool isRotating;

  RiftNode({
    required this.type,
    required this.count,
    required this.items,
    required this.x,
    required this.y,
    required this.radius,
    double? orientation,
    this.appliedForce = 0.55,
    this.isGrabbed = false,
    this.isRotating = false,
  })  : kind = kindForClass(type),
        orientation = orientation ?? math.Random().nextDouble() * math.pi;

  Offset get center => Offset(x, y);
}

class StressFieldEngine {
  StressFieldEngine({math.Random? random}) : _rng = random ?? math.Random();

  final math.Random _rng;
  final List<StressImpulse> impulses = [];
  final List<FractureCrack> cracks = [];

  double dominantRiftAngle = 0;
  double fieldSaturation = 0;

  void clearCracks() => cracks.clear();

  void addHammerBlow(Offset point, double time, {double strength = 1.0}) {
    impulses.add(StressImpulse(origin: point, birth: time, strength: strength));
  }

  void addHammerSeries(Size size, double time) {
    for (var i = 0; i < 5; i++) {
      addHammerBlow(
        Offset(
          size.width * (0.2 + _rng.nextDouble() * 0.6),
          size.height * (0.25 + _rng.nextDouble() * 0.45),
        ),
        time + i * 0.006,
        strength: 0.85,
      );
    }
  }

  void pruneImpulses(double time, double maxRadius) {
    impulses.removeWhere(
      (i) => i.isExpired(time, maxRadius.clamp(80, RiftPalette.impulseMaxRadius)),
    );
  }

  double kirschTangential({
    required Offset point,
    required Offset holeCenter,
    required double holeRadius,
    double sigmaInf = RiftPalette.sigmaInfinity,
  }) {
    final dx = point.dx - holeCenter.dx;
    final dy = point.dy - holeCenter.dy;
    final r2 = dx * dx + dy * dy;
    if (r2 < holeRadius * holeRadius * 0.85) return -sigmaInf * 0.35;
    final theta = math.atan2(dy, dx);
    final rRatio2 = (holeRadius * holeRadius) / r2;
    final rRatio4 = rRatio2 * rRatio2;
    return (sigmaInf / 2) * (1 + rRatio2) -
        (sigmaInf / 2) * (1 + 3 * rRatio4) * math.cos(2 * theta);
  }

  double westergaardTension({
    required Offset point,
    required Offset tip,
    required double orientation,
    required double kI,
  }) {
    final cosA = math.cos(orientation);
    final sinA = math.sin(orientation);
    final lx = point.dx - tip.dx;
    final ly = point.dy - tip.dy;
    final x = lx * cosA + ly * sinA;
    final y = -lx * sinA + ly * cosA;
    final r = math.sqrt(x * x + y * y);
    if (r < 2.5) return kI * 2.4;
    final theta = math.atan2(y, x);
    final root = 1 / math.sqrt(2 * math.pi * r);
    final term = math.cos(theta / 2) *
        (1 + math.sin(theta / 2) * math.sin(3 * theta / 2));
    return (kI * root * term).clamp(-2.0, 2.4);
  }

  double impulseContribution(Offset point, double time) {
    var sum = 0.0;
    for (final impulse in impulses) {
      final radius = impulse.radiusAt(time);
      if (radius <= 0) continue;
      final dist = (point - impulse.origin).distance;
      final ring = (dist - radius).abs();
      if (ring < 28) {
        sum += impulse.strength * math.exp(-ring / 10) * 0.9;
      }
    }
    return sum;
  }

  double stressAt(Offset point, List<RiftNode> nodes, double time) {
    var sigma = 0.08;
    for (final node in nodes) {
      switch (node.kind) {
        case RiftNodeKind.drill:
          sigma += kirschTangential(
            point: point,
            holeCenter: node.center,
            holeRadius: node.radius * 0.42,
          );
        case RiftNodeKind.wedge:
        case RiftNodeKind.other:
          sigma += westergaardTension(
            point: point,
            tip: node.center,
            orientation: node.orientation,
            kI: node.appliedForce * (node.isGrabbed ? 1.35 : 1.0),
          );
        case RiftNodeKind.gauge:
        case RiftNodeKind.arc:
        case RiftNodeKind.template:
          break;
      }
    }
    sigma += impulseContribution(point, time);
    return sigma;
  }

  Offset stressGradient(Offset point, List<RiftNode> nodes, double time) {
    const h = 6.0;
    final sx = stressAt(point + const Offset(h, 0), nodes, time) -
        stressAt(point - const Offset(h, 0), nodes, time);
    final sy = stressAt(point + const Offset(0, h), nodes, time) -
        stressAt(point - const Offset(0, h), nodes, time);
    return Offset(sx, sy);
  }

  double dominantCorridorAngle(List<RiftNode> nodes, Size size, double time) {
    final center = Offset(size.width / 2, size.height / 2);
    final wedges = nodes.where((n) => n.kind == RiftNodeKind.wedge).toList();
    if (wedges.length >= 2) {
      wedges.sort((a, b) => a.x.compareTo(b.x));
      final a = wedges.first.center;
      final b = wedges.last.center;
      return math.atan2(b.dy - a.dy, b.dx - a.dx);
    }
    final grad = stressGradient(center, nodes, time);
    if (grad.distance < 0.001) return dominantRiftAngle;
    return math.atan2(grad.dy, grad.dx);
  }

  void updateDominantRift(List<RiftNode> nodes, Size size, double time) {
    dominantRiftAngle = dominantCorridorAngle(nodes, size, time);
  }

  void advanceCracks(List<RiftNode> nodes, double time, Size size) {
    final branches = <FractureCrack>[];
    final activeCracks = cracks.where((c) => c.active).toList(growable: false);

    for (final crack in activeCracks) {
      if (crack.points.isEmpty) continue;
      final tip = crack.points.last;
      final grad = stressGradient(tip, nodes, time);
      if (grad.distance < 0.0001) continue;
      final dir = grad / grad.distance;
      final next = tip + dir * (2.8 + _rng.nextDouble());
      crack.points.add(next);

      final stress = stressAt(next, nodes, time);
      if (stress >= RiftPalette.criticalKIc &&
          _rng.nextDouble() < crack.branchChance) {
        branches.add(FractureCrack(
          points: [next],
          branchChance: crack.branchChance * 0.65,
        ));
      }

      if (next.dx < -20 ||
          next.dx > size.width + 20 ||
          next.dy < -20 ||
          next.dy > size.height + 20 ||
          crack.points.length > 280) {
        crack.active = false;
      }
    }

    if (branches.isNotEmpty) {
      cracks.addAll(branches);
    }
    if (cracks.length > 24) {
      cracks.removeRange(0, cracks.length - 24);
    }
  }

  void tryPropagateAt(Offset origin, List<RiftNode> nodes, double time) {
    final stress = stressAt(origin, nodes, time);
    if (stress < RiftPalette.criticalKIc) return;
    final crack = FractureCrack();
    crack.points.add(origin);
    cracks.add(crack);
  }

  void propagateAlongRift(
    Size size,
    double angle, {
    int steps = 48,
    double stepSize = 8,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    final dir = Offset(math.cos(angle), math.sin(angle));
    final crack = FractureCrack(branchChance: 0.05);
    var point = center - dir * (size.shortestSide * 0.55);
    for (var i = 0; i < steps; i++) {
      crack.points.add(point);
      point += dir * stepSize;
    }
    cracks.add(crack);
  }

  void checkAutoSplit(List<RiftNode> nodes, double time, Size size) {
    final wedges = nodes.where((n) => n.kind == RiftNodeKind.wedge).toList();
    if (wedges.length < 2) return;
    for (var i = 0; i < wedges.length; i++) {
      for (var j = i + 1; j < wedges.length; j++) {
        final a = wedges[i];
        final b = wedges[j];
        final delta = b.center - a.center;
        if (delta.distance > 220) continue;
        final alignment = (a.orientation - b.orientation).abs() % math.pi;
        if (alignment > 0.35 && alignment < math.pi - 0.35) continue;
        final mid = Offset((a.x + b.x) / 2, (a.y + b.y) / 2);
        if (stressAt(mid, nodes, time) >= RiftPalette.criticalKIc) {
          tryPropagateAt(mid, nodes, time);
        }
      }
    }
  }

  String stressReadout(RiftNode node, List<RiftNode> nodes, double time) {
    final sigma = stressAt(node.center, nodes, time);
    final tensile = sigma > 0;
    final value = (sigma.abs() * 5.6).toStringAsFixed(1);
    if (sigma >= RiftPalette.criticalKIc * 0.92) {
      return 'STRESS $value MPa TENSILE — PROCEED';
    }
    if (tensile) {
      return 'STRESS $value MPa TENSILE — ALIGN WEDGES';
    }
    return 'STRESS $value MPa COMPRESSIVE — RELOCATE';
  }

  Color colorForStress(double sigma, {double saturation = 1.0}) {
    final t = ((sigma + 0.1) / 1.2).clamp(0.0, 1.0);
    final sat = saturation.clamp(0.0, 1.0);
    if (t < 0.55) {
      return Color.lerp(
        RiftPalette.quarryShadow,
        RiftPalette.cleavageBlue,
        (t / 0.55) * sat,
      )!;
    }
    if (t < 0.88) {
      return Color.lerp(
        RiftPalette.cleavageBlue,
        RiftPalette.splitWhite,
        ((t - 0.55) / 0.33) * sat,
      )!;
    }
    return Color.lerp(
      RiftPalette.splitWhite,
      RiftPalette.fractureAmber,
      ((t - 0.88) / 0.12) * sat * 0.7,
    )!;
  }
}
