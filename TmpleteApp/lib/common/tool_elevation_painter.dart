import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shadows_on_the_quarry_wall/enum/my_enums.dart';

int bladeCountForImplementationClass(ImplementationClass type) {
  switch (type) {
    case ImplementationClass.plugAndFeatherSet:
      return 3;
    case ImplementationClass.tracingChisel:
      return 2;
    case ImplementationClass.coreBoringRig:
      return 6;
    case ImplementationClass.moldingTemplate:
      return 5;
    case ImplementationClass.levelingArc:
      return 7;
    case ImplementationClass.profileGauge:
      return 8;
    case ImplementationClass.other:
      return 4;
  }
}

/// Side-elevation tool silhouette per ui_rules — architectural drawing convention.
class ToolElevationPainter extends CustomPainter {
  final ImplementationClass toolClass;
  final Color color;
  final bool operational;

  ToolElevationPainter({
    required this.toolClass,
    required this.color,
    this.operational = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color.withAlpha(operational ? 55 : 35)
      ..style = PaintingStyle.fill;

    switch (toolClass) {
      case ImplementationClass.plugAndFeatherSet:
        _drawPlugFeather(canvas, size, paint, fill);
      case ImplementationClass.coreBoringRig:
        _drawCoreDrill(canvas, size, paint, fill);
      case ImplementationClass.moldingTemplate:
      case ImplementationClass.profileGauge:
        _drawProfileGauge(canvas, size, paint, fill);
      case ImplementationClass.levelingArc:
        _drawLevelingArc(canvas, size, paint, fill);
      default:
        _drawChisel(canvas, size, paint, fill);
    }
  }

  void _drawPlugFeather(Canvas c, Size s, Paint p, Paint f) {
    final w = s.width * 0.18;
    final path = Path()
      ..moveTo(s.width * 0.35, s.height * 0.2)
      ..lineTo(s.width * 0.35, s.height * 0.8)
      ..lineTo(s.width * 0.35 + w, s.height * 0.72)
      ..lineTo(s.width * 0.35 + w, s.height * 0.28)
      ..close();
    c.drawPath(path, f);
    c.drawPath(path, p);
    final right = path.shift(Offset(s.width * 0.28, 0));
    c.drawPath(right, f);
    c.drawPath(right, p);
    c.drawLine(
      Offset(s.width * 0.5, s.height * 0.15),
      Offset(s.width * 0.5, s.height * 0.85),
      p,
    );
  }

  void _drawCoreDrill(Canvas c, Size s, Paint p, Paint f) {
    final rect = Rect.fromCenter(
      center: Offset(s.width / 2, s.height / 2),
      width: s.width * 0.55,
      height: s.height * 0.55,
    );
    c.drawOval(rect, f);
    c.drawOval(rect, p);
    c.drawOval(
      Rect.fromCenter(
        center: rect.center,
        width: rect.width * 0.45,
        height: rect.height * 0.45,
      ),
      p,
    );
  }

  void _drawProfileGauge(Canvas c, Size s, Paint p, Paint f) {
    final path = Path()
      ..moveTo(s.width * 0.15, s.height * 0.75)
      ..lineTo(s.width * 0.28, s.height * 0.75)
      ..lineTo(s.width * 0.28, s.height * 0.55)
      ..lineTo(s.width * 0.42, s.height * 0.55)
      ..lineTo(s.width * 0.42, s.height * 0.35)
      ..lineTo(s.width * 0.58, s.height * 0.35)
      ..lineTo(s.width * 0.58, s.height * 0.5)
      ..lineTo(s.width * 0.72, s.height * 0.5)
      ..lineTo(s.width * 0.72, s.height * 0.65)
      ..lineTo(s.width * 0.85, s.height * 0.65);
    c.drawPath(path, p);
  }

  void _drawLevelingArc(Canvas c, Size s, Paint p, Paint f) {
    final rect = Rect.fromLTWH(
      s.width * 0.15,
      s.height * 0.25,
      s.width * 0.7,
      s.height * 0.7,
    );
    c.drawArc(rect, math.pi, math.pi / 2, false, p);
    for (var i = 0; i < 5; i++) {
      final angle = math.pi + (math.pi / 2) * (i / 4);
      final cx = rect.center.dx + math.cos(angle) * rect.width / 2;
      final cy = rect.center.dy + math.sin(angle) * rect.height / 2;
      c.drawLine(Offset(cx, cy), Offset(cx + 6, cy - 6), p);
    }
  }

  void _drawChisel(Canvas c, Size s, Paint p, Paint f) {
    final path = Path()
      ..moveTo(s.width * 0.3, s.height * 0.2)
      ..lineTo(s.width * 0.55, s.height * 0.78)
      ..lineTo(s.width * 0.68, s.height * 0.78)
      ..lineTo(s.width * 0.42, s.height * 0.2)
      ..close();
    c.drawPath(path, f);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant ToolElevationPainter old) =>
      old.toolClass != toolClass || old.color != color || old.operational != operational;
}
