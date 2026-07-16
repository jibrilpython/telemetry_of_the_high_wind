import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shadows_on_the_quarry_wall/showcase/rift_reader_palette.dart';
import 'package:shadows_on_the_quarry_wall/showcase/rift_reader_physics.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pre-computed Worley seed set for the stone-texture layer.
// 60 crystal-centre seeds, expressed as fractions of canvas size.
// ─────────────────────────────────────────────────────────────────────────────
const List<Offset> _worleySeeds = [
  Offset(0.04, 0.07), Offset(0.18, 0.03), Offset(0.31, 0.09), Offset(0.47, 0.05),
  Offset(0.62, 0.02), Offset(0.76, 0.08), Offset(0.88, 0.04), Offset(0.96, 0.11),
  Offset(0.10, 0.19), Offset(0.24, 0.16), Offset(0.39, 0.21), Offset(0.54, 0.14),
  Offset(0.67, 0.18), Offset(0.82, 0.22), Offset(0.93, 0.17), Offset(0.03, 0.29),
  Offset(0.15, 0.35), Offset(0.28, 0.31), Offset(0.43, 0.27), Offset(0.58, 0.33),
  Offset(0.71, 0.28), Offset(0.85, 0.36), Offset(0.97, 0.30), Offset(0.08, 0.44),
  Offset(0.21, 0.48), Offset(0.36, 0.41), Offset(0.50, 0.46), Offset(0.64, 0.39),
  Offset(0.79, 0.43), Offset(0.91, 0.49), Offset(0.02, 0.57), Offset(0.14, 0.61),
  Offset(0.27, 0.55), Offset(0.42, 0.59), Offset(0.56, 0.53), Offset(0.70, 0.58),
  Offset(0.83, 0.54), Offset(0.95, 0.62), Offset(0.07, 0.70), Offset(0.19, 0.74),
  Offset(0.33, 0.67), Offset(0.48, 0.72), Offset(0.61, 0.68), Offset(0.75, 0.73),
  Offset(0.89, 0.69), Offset(0.04, 0.82), Offset(0.17, 0.86), Offset(0.30, 0.79),
  Offset(0.44, 0.84), Offset(0.57, 0.80), Offset(0.69, 0.88), Offset(0.82, 0.83),
  Offset(0.94, 0.78), Offset(0.11, 0.93), Offset(0.25, 0.97), Offset(0.40, 0.91),
  Offset(0.53, 0.95), Offset(0.66, 0.92), Offset(0.78, 0.96), Offset(0.90, 0.89),
];

class RiftReaderPainter extends CustomPainter {
  final List<RiftNode> nodes;
  final StressFieldEngine engine;
  final ui.Picture? stoneLayer;
  final double time;
  final double riftSweepAngle;
  final double? riftTargetAngle;
  final double fieldSaturation;
  final bool showRiftArm;
  final double splitProgress;

  RiftReaderPainter({
    required this.nodes,
    required this.engine,
    required this.stoneLayer,
    required this.time,
    this.riftSweepAngle = 0,
    this.riftTargetAngle,
    this.fieldSaturation = 1,
    this.showRiftArm = false,
    this.splitProgress = 0,
  });

  static double _angleDelta(double a, double b) {
    var d = (a - b).abs() % (2 * math.pi);
    return d > math.pi ? 2 * math.pi - d : d;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STONE LAYER — Worley cellular grain + Perlin-style veining + vignette
  // ───────────────────────────────────────────────────────────────────────────
  static ui.Picture buildStoneLayer(Size size) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Offset.zero & size;

    // 1) Base quarry gradient — top-left cool, bottom-right marginally warmer.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1210), Color(0xFF131917), Color(0xFF0A0C0B)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // 2) Worley cellular grain — compute nearest-seed distance per grid cell,
    //    draw polygon-ish cells with a fine hairline edge.
    const step = 12.0;
    final grainPaint = Paint()
      ..color = const Color(0xFF2A3230)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55;

    final cols = (size.width / step).ceil() + 1;
    final rows = (size.height / step).ceil() + 1;

    for (var gy = 0; gy < rows; gy++) {
      for (var gx = 0; gx < cols; gx++) {
        final px = gx * step + step * 0.5;
        final py = gy * step + step * 0.5;

        // Distance to the 3 nearest seeds — Worley F1 for cell border.
        double d1 = double.infinity, d2 = double.infinity, d3 = double.infinity;
        for (final s in _worleySeeds) {
          final sx = s.dx * size.width;
          final sy = s.dy * size.height;
          final dx = px - sx, dy = py - sy;
          final d = dx * dx + dy * dy;
          if (d < d1) {
            d3 = d2;
            d2 = d1;
            d1 = d;
          } else if (d < d2) {
            d3 = d2;
            d2 = d;
          } else if (d < d3) {
            d3 = d;
          }
        }
        // F2 - F1 is the cell-edge proximity — bright edge near 0.
        final edge = (math.sqrt(d2) - math.sqrt(d1)).clamp(0.0, step);
        if (edge < 4.5) {
          final alpha = ((1 - edge / 4.5) * 38).round().clamp(0, 38);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(px, py),
              width: step * 0.88,
              height: step * 0.88,
            ),
            grainPaint..color = Color(0xFF2A3230).withAlpha(alpha),
          );
        }
      }
    }

    // 3) Perlin-style macro veining using nested sin/cos.
    final veinPaint = Paint()
      ..color = const Color(0xFF1E2820)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const veinStep = 3.0;
    for (var y = 0.0; y < size.height; y += veinStep * 8) {
      final path = Path();
      bool first = true;
      for (var x = 0.0; x <= size.width; x += veinStep) {
        final t = x / size.width;
        final yOff = math.sin(t * math.pi * 3.1 + y * 0.008) * 18 +
            math.sin(t * math.pi * 7.3 + y * 0.005) * 7;
        final vy = y + yOff;
        if (first) {
          path.moveTo(x, vy);
          first = false;
        } else {
          path.lineTo(x, vy);
        }
      }
      canvas.drawPath(path, veinPaint..color = const Color(0xFF1E2820).withAlpha(14));
    }

    // 4) Large crystal cluster highlights — lighter irregular blobs.
    const clusters = [
      Offset(0.22, 0.16), Offset(0.68, 0.34), Offset(0.45, 0.67),
      Offset(0.12, 0.78), Offset(0.83, 0.71), Offset(0.38, 0.44),
    ];
    for (final seed in clusters) {
      final c = Offset(seed.dx * size.width, seed.dy * size.height);
      canvas.drawCircle(
        c,
        size.shortestSide * 0.14,
        Paint()
          ..color = const Color(0xFF283228).withAlpha(18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );
    }

    // 5) Radial vignette — edges darker, centre ever so slightly exposed.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Color(0x00000000), Color(0xCC000000)],
        ).createShader(rect),
    );

    return recorder.endRecording();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PAINT
  // ───────────────────────────────────────────────────────────────────────────
  @override
  void paint(Canvas canvas, Size size) {
    // 1) Stone texture base.
    if (stoneLayer != null) {
      canvas.drawPicture(stoneLayer!);
    }

    // 2) Sampled stress heatmap — the single most important visual element.
    _paintHeatmap(canvas, size);

    // 3) Kirsch hot rings around drill nodes.
    _paintDrillHaloRings(canvas);

    // 4) Hammer-blow impulse rings.
    _paintImpulses(canvas);

    // 5) Rift reading sweep arm.
    if (showRiftArm) _paintRiftArm(canvas, size);

    // 6) Stone-split cinematic.
    if (splitProgress > 0) _paintSplit(canvas, size);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEATMAP — sampled grid, colour-mapped σ₁
  // ───────────────────────────────────────────────────────────────────────────
  void _paintHeatmap(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    const step = RiftPalette.heatmapGridStep;
    final cols = (size.width / step).ceil() + 1;
    final rows = (size.height / step).ceil() + 1;
    final cellRect = Rect.fromLTWH(0, 0, step + 1, step + 1);

    for (var gy = 0; gy < rows; gy++) {
      for (var gx = 0; gx < cols; gx++) {
        final px = gx * step;
        final py = gy * step;
        final point = Offset(px + step * 0.5, py + step * 0.5);

        final sigma = engine.stressAt(point, nodes, time);
        // Only paint cells above a threshold — calm zones sink into stone.
        if (sigma < 0.06) continue;

        final col = engine.colorForStress(sigma, saturation: fieldSaturation);
        // Opacity drives the "glowing through dark stone" effect.
        final opacity = ((sigma - 0.06) / 0.94).clamp(0.0, 1.0);
        final alpha = (opacity * 200 * fieldSaturation).round().clamp(0, 200);
        if (alpha < 6) continue;

        canvas.drawRect(
          cellRect.translate(px, py),
          Paint()..color = col.withAlpha(alpha),
        );
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DRILL HALOS — Kirsch hoop stress ring (bright ring at bore boundary)
  // ───────────────────────────────────────────────────────────────────────────
  void _paintDrillHaloRings(Canvas canvas) {
    for (final node in nodes) {
      if (node.kind != RiftNodeKind.drill) continue;
      final c = node.center;
      final r = node.radius * 1.05;
      final rect = Rect.fromCircle(center: c, radius: r * 1.8);

      // Outer glow halo.
      canvas.drawCircle(
        c,
        r * 1.8,
        Paint()
          ..shader = RadialGradient(
            colors: [
              RiftPalette.cleavageBlue.withAlpha(0),
              RiftPalette.fractureAmber.withAlpha((60 * fieldSaturation).round()),
              RiftPalette.splitWhite.withAlpha((80 * fieldSaturation).round()),
              RiftPalette.fractureAmber.withAlpha((40 * fieldSaturation).round()),
              RiftPalette.cleavageBlue.withAlpha(0),
            ],
            stops: const [0.0, 0.52, 0.58, 0.68, 1.0],
          ).createShader(rect),
      );

      // Bright ring edge — stroke.
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = RiftPalette.splitWhite.withAlpha((140 * fieldSaturation).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // IMPULSE RINGS — 3-concentric-ring hammer shock wave
  // ───────────────────────────────────────────────────────────────────────────
  void _paintImpulses(Canvas canvas) {
    for (final impulse in engine.impulses) {
      final radius = impulse.radiusAt(time);
      if (radius <= 2) continue;
      final fade = (1 - radius / RiftPalette.impulseMaxRadius).clamp(0.0, 1.0);

      // Three rings at r, 0.72r, 0.48r with decreasing width and opacity.
      const ringScales = [1.0, 0.72, 0.48];
      const ringWidths = [3.5, 2.2, 1.2];
      const ringAlphas = [0.9, 0.55, 0.30];

      for (var i = 0; i < 3; i++) {
        final r = radius * ringScales[i];
        if (r < 2) continue;
        final alpha =
            (120 * fade * impulse.strength * ringAlphas[i]).round().clamp(0, 160);
        canvas.drawCircle(
          impulse.origin,
          r,
          Paint()
            ..color = RiftPalette.cleavageBlue.withAlpha(alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = ringWidths[i],
        );
        // Amber leading edge on outermost ring.
        if (i == 0) {
          final amberAlpha = (80 * fade * impulse.strength).round().clamp(0, 100);
          canvas.drawCircle(
            impulse.origin,
            r,
            Paint()
              ..color = RiftPalette.fractureAmber.withAlpha(amberAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0,
          );
        }
      }

      // Central impact flash — white dot that fades with radius.
      final flashAlpha = (180 * fade * fade * impulse.strength).round().clamp(0, 180);
      canvas.drawCircle(
        impulse.origin,
        6.0 * fade,
        Paint()..color = RiftPalette.splitWhite.withAlpha(flashAlpha),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RIFT ARM — coloured sweep arm with glow, pivot disc, sweep sector
  // ───────────────────────────────────────────────────────────────────────────
  void _paintRiftArm(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final armLen = size.shortestSide * 0.44;
    final target = riftTargetAngle ?? engine.dominantRiftAngle;

    // Alignment fraction [0..1] — 1 = perfectly aligned, 0 = perpendicular.
    final delta = _angleDelta(riftSweepAngle, target);
    final alignFrac = (1 - delta / math.pi).clamp(0.0, 1.0);
    final aligned = delta < 0.35;

    final armColor = Color.lerp(
      RiftPalette.cleavageBlue,
      RiftPalette.trierBrass,
      alignFrac * alignFrac, // square for snappier colour approach near alignment
    )!;

    // Target corridor dashed guide line.
    if (riftTargetAngle != null) {
      final corridorEnd = center +
          Offset(math.cos(riftTargetAngle!), math.sin(riftTargetAngle!)) * armLen;
      canvas.drawLine(
        center,
        corridorEnd,
        Paint()
          ..color = RiftPalette.fractureAmber.withAlpha(45)
          ..strokeWidth = 1.0,
      );
    }

    // Sweep sector — faint filled arc behind arm.
    const sectorHalf = 0.28; // ±16° fill
    final sweepRect = Rect.fromCircle(center: center, radius: armLen * 0.85);
    canvas.drawArc(
      sweepRect,
      riftSweepAngle - sectorHalf,
      sectorHalf * 2,
      true,
      Paint()
        ..color = armColor.withAlpha((aligned ? 28 : 12))
        ..style = PaintingStyle.fill,
    );

    // Glow pass — wide, blurred.
    canvas.drawLine(
      center,
      center + Offset(math.cos(riftSweepAngle), math.sin(riftSweepAngle)) * armLen,
      Paint()
        ..color = armColor.withAlpha(aligned ? 80 : 35)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Core arm line.
    canvas.drawLine(
      center,
      center + Offset(math.cos(riftSweepAngle), math.sin(riftSweepAngle)) * armLen,
      Paint()
        ..color = armColor.withAlpha(aligned ? 230 : 130)
        ..strokeWidth = aligned ? 2.8 : 1.8
        ..strokeCap = StrokeCap.round,
    );

    // Pivot disc — brass ring + white centre.
    canvas.drawCircle(
      center,
      7.5,
      Paint()
        ..color = RiftPalette.trierBrass.withAlpha(aligned ? 200 : 100),
    );
    canvas.drawCircle(
      center,
      7.5,
      Paint()
        ..color = RiftPalette.trierBrass
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      center,
      3.5,
      Paint()..color = RiftPalette.splitWhite.withAlpha(200),
    );

    // Arrowhead at tip when aligned.
    if (aligned) {
      final tip =
          center + Offset(math.cos(riftSweepAngle), math.sin(riftSweepAngle)) * armLen;
      final perp = Offset(-math.sin(riftSweepAngle), math.cos(riftSweepAngle));
      final arrowPath = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo((tip - Offset(math.cos(riftSweepAngle), math.sin(riftSweepAngle)) * 12 + perp * 5).dx,
            (tip - Offset(math.cos(riftSweepAngle), math.sin(riftSweepAngle)) * 12 + perp * 5).dy)
        ..lineTo((tip - Offset(math.cos(riftSweepAngle), math.sin(riftSweepAngle)) * 12 - perp * 5).dx,
            (tip - Offset(math.cos(riftSweepAngle), math.sin(riftSweepAngle)) * 12 - perp * 5).dy)
        ..close();
      canvas.drawPath(arrowPath, Paint()..color = RiftPalette.trierBrass.withAlpha(220));
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SPLIT — jagged crack + separating stone halves + amber slit glow
  // ───────────────────────────────────────────────────────────────────────────
  void _paintSplit(Canvas canvas, Size size) {
    // Pre-computed zigzag offsets for the crack (12 segments, seeded).
    const zigzagX = [0.0, -6.0, 4.0, -8.0, 5.0, -3.0, 7.0, -5.0, 3.0, -7.0, 4.0, 0.0];
    final cx = size.width / 2;

    // Build jagged crack path.
    final crackPath = Path();
    final segH = size.height / (zigzagX.length - 1);
    crackPath.moveTo(cx + zigzagX[0], 0);
    for (var i = 1; i < zigzagX.length; i++) {
      crackPath.lineTo(cx + zigzagX[i], i * segH);
    }

    // Stone half-separation gap.
    final gap = splitProgress * 22.0;

    // Left half darkening.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cx, size.height),
      Paint()..color = Colors.black.withAlpha((70 * splitProgress).round()),
    );
    // Right half darkening.
    canvas.drawRect(
      Rect.fromLTWH(cx, 0, size.width - cx, size.height),
      Paint()..color = Colors.black.withAlpha((70 * splitProgress).round()),
    );

    // Amber slit glow — the fresh-split interior.
    final slitRect = Rect.fromLTWH(cx - gap - 4, 0, gap * 2 + 8, size.height);
    if (gap > 0.5) {
      canvas.drawRect(
        slitRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              RiftPalette.cleavageBlue.withAlpha(0),
              RiftPalette.fractureAmber.withAlpha((160 * splitProgress).round()),
              RiftPalette.splitWhite.withAlpha((220 * splitProgress).round()),
              RiftPalette.fractureAmber.withAlpha((160 * splitProgress).round()),
              RiftPalette.cleavageBlue.withAlpha(0),
            ],
            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
          ).createShader(slitRect),
      );
    }

    // Diffuse crystal-face spray on each side.
    for (final dx in [-gap - 18, gap + 18]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + dx, size.height * 0.5),
          width: 38,
          height: size.height * 0.7,
        ),
        Paint()
          ..shader = RadialGradient(
            colors: [
              RiftPalette.splitWhite.withAlpha((40 * splitProgress).round()),
              RiftPalette.splitWhite.withAlpha(0),
            ],
          ).createShader(Rect.fromCenter(
            center: Offset(cx + dx, size.height * 0.5),
            width: 38,
            height: size.height * 0.7,
          )),
      );
    }

    // Crack glow pass.
    canvas.save();
    canvas.translate(-gap, 0);
    canvas.drawPath(
      crackPath,
      Paint()
        ..color = RiftPalette.splitWhite.withAlpha((60 * splitProgress).round())
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();

    canvas.save();
    canvas.translate(gap, 0);
    canvas.drawPath(
      crackPath,
      Paint()
        ..color = RiftPalette.splitWhite.withAlpha((60 * splitProgress).round())
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();

    // Hot centreline — left half.
    canvas.save();
    canvas.translate(-gap, 0);
    canvas.drawPath(
      crackPath,
      Paint()
        ..color = RiftPalette.splitWhite.withAlpha((200 * splitProgress).round())
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    // Hot centreline — right half.
    canvas.save();
    canvas.translate(gap, 0);
    canvas.drawPath(
      crackPath,
      Paint()
        ..color = RiftPalette.splitWhite.withAlpha((200 * splitProgress).round())
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RiftReaderPainter oldDelegate) => true;
}
