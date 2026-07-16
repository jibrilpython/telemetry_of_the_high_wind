import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telemetry_of_the_high_wind/theme/app_theme.dart';

class TemperatureRangeCodec {
  static const double floor = -90;
  static const double ceiling = 50;
  static const double defaultLow = -80;
  static const double defaultHigh = 40;

  static (double low, double high) parse(String raw) {
    if (raw.trim().isEmpty) return (defaultLow, defaultHigh);
    final match = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*°?\s*C?\s*(?:to|–|-|—)\s*(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) return (defaultLow, defaultHigh);
    var a = double.tryParse(match.group(1)!) ?? defaultLow;
    var b = double.tryParse(match.group(2)!) ?? defaultHigh;
    if (a > b) {
      final t = a;
      a = b;
      b = t;
    }
    return (a.clamp(floor, ceiling), b.clamp(floor, ceiling));
  }

  static String format(double low, double high) {
    return '${low.round()}°C to ${high.round()}°C';
  }
}

class TemperatureRheostat extends StatefulWidget {
  const TemperatureRheostat({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<TemperatureRheostat> createState() => _TemperatureRheostatState();
}

class _TemperatureRheostatState extends State<TemperatureRheostat> {
  late RangeValues _range;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    final parsed = TemperatureRangeCodec.parse(widget.value);
    _range = RangeValues(parsed.$1, parsed.$2);
    if (widget.value.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(
          TemperatureRangeCodec.format(parsed.$1, parsed.$2),
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant TemperatureRheostat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_dragging) {
      final parsed = TemperatureRangeCodec.parse(widget.value);
      _range = RangeValues(parsed.$1, parsed.$2);
    }
  }

  void _emit(RangeValues next) {
    setState(() => _range = next);
    widget.onChanged(TemperatureRangeCodec.format(next.start, next.end));
  }

  @override
  Widget build(BuildContext context) {
    final span = _range.end - _range.start;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temperature range',
          style: GoogleFonts.ibmPlexSans(
            color: secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _dragging ? radarGreen.withValues(alpha: 0.7) : outline,
              width: _dragging ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _dialReadout(
                    label: 'LOW',
                    value: _range.start.round(),
                    accent: stratosphereBlue,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'OPERATING BAND',
                          style: GoogleFonts.ibmPlexMono(
                            color: secondaryText,
                            fontSize: 9,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${span.round()}° span',
                          style: GoogleFonts.spaceGrotesk(
                            color: radarGreen,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _dialReadout(
                    label: 'HIGH',
                    value: _range.end.round(),
                    accent: radarGreen,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RheostatTrackPainter(
                          low: _range.start,
                          high: _range.end,
                          min: TemperatureRangeCodec.floor,
                          max: TemperatureRangeCodec.ceiling,
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 0,
                        overlayShape: SliderComponentShape.noOverlay,
                        rangeTrackShape:
                            const RoundedRectRangeSliderTrackShape(),
                        rangeThumbShape: _RheostatThumbShape(
                          dragging: _dragging,
                        ),
                        inactiveTrackColor: Colors.transparent,
                        activeTrackColor: Colors.transparent,
                      ),
                      child: RangeSlider(
                        values: _range,
                        min: TemperatureRangeCodec.floor,
                        max: TemperatureRangeCodec.ceiling,
                        divisions: (TemperatureRangeCodec.ceiling -
                                TemperatureRangeCodec.floor)
                            .round(),
                        onChangeStart: (_) {
                          setState(() => _dragging = true);
                          HapticFeedback.selectionClick();
                        },
                        onChanged: (v) {
                          if ((v.start - _range.start).abs() >= 1 ||
                              (v.end - _range.end).abs() >= 1) {
                            HapticFeedback.selectionClick();
                          }
                          _emit(v);
                        },
                        onChangeEnd: (_) {
                          setState(() => _dragging = false);
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _tickLabel('−90°', 'Near space'),
                  _tickLabel('−55°', 'Stratosphere'),
                  _tickLabel('0°', 'Freeze'),
                  _tickLabel('+50°', 'Ground'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          TemperatureRangeCodec.format(_range.start, _range.end),
          style: GoogleFonts.ibmPlexMono(
            color: secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _dialReadout({
    required String label,
    required int value,
    required Color accent,
  }) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              color: secondaryText,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              border: Border.all(
                color: _dragging ? accent : accent.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$value°',
              style: GoogleFonts.ibmPlexMono(
                color: primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tickLabel(String temp, String note) {
    return Column(
      children: [
        Text(
          temp,
          style: GoogleFonts.ibmPlexMono(
            color: secondaryText,
            fontSize: 9,
          ),
        ),
        Text(
          note,
          style: GoogleFonts.ibmPlexSans(
            color: secondaryText.withValues(alpha: 0.7),
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}

class _RheostatThumbShape extends RangeSliderThumbShape {
  const _RheostatThumbShape({required this.dragging});

  final bool dragging;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(28, 28);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool isOnTop = false,
    bool isPressed = false,
    required SliderThemeData sliderTheme,
    TextDirection textDirection = TextDirection.ltr,
    Thumb thumb = Thumb.start,
  }) {
    final canvas = context.canvas;
    final scale = dragging ? 1.08 : 1.0;
    final r = 14.0 * scale;
    final accent =
        thumb == Thumb.start ? stratosphereBlue : radarGreen;

    canvas.drawCircle(
      center,
      r + 4,
      Paint()..color = accent.withValues(alpha: 0.18),
    );
    canvas.drawCircle(center, r, Paint()..color = panel);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final angle = thumb == Thumb.start ? -math.pi / 4 : math.pi / 4;
    final pointerEnd = Offset(
      center.dx + math.cos(angle) * (r - 4),
      center.dy + math.sin(angle) * (r - 4),
    );
    canvas.drawLine(
      center,
      pointerEnd,
      Paint()
        ..color = primaryText
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }
}

class _RheostatTrackPainter extends CustomPainter {
  _RheostatTrackPainter({
    required this.low,
    required this.high,
    required this.min,
    required this.max,
  });

  final double low;
  final double high;
  final double min;
  final double max;

  double _t(double v) => ((v - min) / (max - min)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final trackY = size.height * 0.55;
    const trackH = 10.0;
    const pad = 20.0;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, trackY - trackH / 2, size.width - pad * 2, trackH),
      const Radius.circular(999),
    );

    const colors = [
      Color(0xFF5A8AAA),
      Color(0xFF6B93D6),
      Color(0xFF8FB0A0),
      Color(0xFF2A8A4A),
    ];

    canvas.drawRRect(
      trackRect,
      Paint()
        ..shader = LinearGradient(
          colors: colors.map((c) => c.withValues(alpha: 0.28)).toList(),
        ).createShader(trackRect.outerRect),
    );
    canvas.drawRRect(
      trackRect,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final lowX = pad + _t(low) * (size.width - pad * 2);
    final highX = pad + _t(high) * (size.width - pad * 2);
    final activeRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(lowX, trackY - trackH / 2, highX, trackY + trackH / 2),
      const Radius.circular(999),
    );
    canvas.drawRRect(
      activeRect,
      Paint()
        ..shader = LinearGradient(
          colors: colors.map((c) => c.withValues(alpha: 0.9)).toList(),
        ).createShader(activeRect.outerRect),
    );

    for (final tick in [-90.0, -55.0, 0.0, 50.0]) {
      final x = pad + _t(tick) * (size.width - pad * 2);
      canvas.drawLine(
        Offset(x, trackY - 16),
        Offset(x, trackY + 16),
        Paint()
          ..color = outline
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RheostatTrackPainter old) =>
      old.low != low || old.high != high;
}
