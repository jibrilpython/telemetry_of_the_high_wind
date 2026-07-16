import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadows_on_the_quarry_wall/utils/const.dart';

class TemperatureRangeCodec {
  static const double floor = -40;
  static const double ceiling = 400;
  static const double defaultLow = -10;
  static const double defaultHigh = 220;

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
    return (
      a.clamp(floor, ceiling),
      b.clamp(floor, ceiling),
    );
  }

  static String format(double low, double high) {
    final lo = low.round();
    final hi = high.round();
    return '$lo°C to $hi°C foundry calibration';
  }
}

class TemperatureRheostat extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const TemperatureRheostat({
    super.key,
    required this.value,
    required this.onChanged,
  });

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
        widget.onChanged(TemperatureRangeCodec.format(parsed.$1, parsed.$2));
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
          style: GoogleFonts.inter(
            color: kSecondaryText,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 14.h),
          decoration: BoxDecoration(
            color: kPanelBg,
            borderRadius: BorderRadius.circular(kRadiusSmall),
            border: Border.all(
              color: _dragging ? kAccent.withAlpha(140) : kOutline,
              width: _dragging ? 1.5 : 1,
            ),
            boxShadow: _dragging ? [kShadowSubtle] : null,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _dialReadout(
                    label: 'LOW',
                    value: _range.start.round(),
                    accent: const Color(0xFF5A6B7A),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'OPERATING BAND',
                          style: GoogleFonts.ibmPlexMono(
                            color: kSecondaryText,
                            fontSize: 8.sp,
                            letterSpacing: 1.4,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${span.round()}° span',
                          style: GoogleFonts.cormorantGaramond(
                            color: kAccent,
                            fontSize: 22.sp,
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
                    accent: kWarning,
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              SizedBox(
                height: 88.h,
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
                        rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
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
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _tickLabel('−40°', 'Quarry frost'),
                  _tickLabel('0°', 'Freeze'),
                  _tickLabel('220°', 'Forge'),
                  _tickLabel('400°', 'Anneal'),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          TemperatureRangeCodec.format(_range.start, _range.end),
          style: GoogleFonts.ibmPlexMono(
            color: kSecondaryText,
            fontSize: 10.sp,
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
      width: 72.w,
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              color: kSecondaryText,
              fontSize: 8.sp,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 6.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withAlpha(18),
              border: Border.all(
                color: _dragging ? accent : accent.withAlpha(100),
                width: 1.5,
              ),
              boxShadow: _dragging
                  ? [
                      BoxShadow(
                        color: accent.withAlpha(40),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$value°',
              style: GoogleFonts.ibmPlexMono(
                color: kPrimaryText,
                fontSize: 13.sp,
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
            color: kSecondaryText,
            fontSize: 9.sp,
          ),
        ),
        Text(
          note,
          style: GoogleFonts.inter(
            color: kSecondaryText.withAlpha(180),
            fontSize: 8.sp,
          ),
        ),
      ],
    );
  }
}

class _RheostatThumbShape extends RangeSliderThumbShape {
  final bool dragging;

  const _RheostatThumbShape({required this.dragging});

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

    canvas.drawCircle(
      center,
      r + 4,
      Paint()..color = kAccent.withAlpha(30),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()..color = kPanelBg,
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = thumb == Thumb.start ? const Color(0xFF5A6B7A) : kWarning
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
        ..color = kPrimaryText
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }
}

class _RheostatTrackPainter extends CustomPainter {
  final double low;
  final double high;
  final double min;
  final double max;

  _RheostatTrackPainter({
    required this.low,
    required this.high,
    required this.min,
    required this.max,
  });

  double _t(double v) => ((v - min) / (max - min)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final trackY = size.height * 0.55;
    final trackH = 10.0;
    final pad = 20.0;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, trackY - trackH / 2, size.width - pad * 2, trackH),
      const Radius.circular(999),
    );

    final gradient = LinearGradient(
      colors: const [
        Color(0xFF5A6B7A),
        Color(0xFF9A907F),
        Color(0xFFC49A5C),
        Color(0xFFB85C38),
      ],
    );
    final mutedGradient = LinearGradient(
      colors: gradient.colors.map((c) => c.withAlpha(90)).toList(),
    );
    canvas.drawRRect(
      trackRect,
      Paint()
        ..shader = mutedGradient.createShader(trackRect.outerRect),
    );
    canvas.drawRRect(
      trackRect,
      Paint()
        ..color = kOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final lowX = pad + _t(low) * (size.width - pad * 2);
    final highX = pad + _t(high) * (size.width - pad * 2);
    final activeRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(lowX, trackY - trackH / 2, highX, trackY + trackH / 2),
      const Radius.circular(999),
    );
    final vividGradient = LinearGradient(
      colors: gradient.colors.map((c) => c.withAlpha(220)).toList(),
    );
    canvas.drawRRect(
      activeRect,
      Paint()
        ..shader = vividGradient.createShader(activeRect.outerRect),
    );

    for (final tick in [-40.0, 0.0, 100.0, 220.0, 400.0]) {
      final x = pad + _t(tick) * (size.width - pad * 2);
      canvas.drawLine(
        Offset(x, trackY - 16),
        Offset(x, trackY + 16),
        Paint()
          ..color = kOutline
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RheostatTrackPainter old) =>
      old.low != low || old.high != high;
}
