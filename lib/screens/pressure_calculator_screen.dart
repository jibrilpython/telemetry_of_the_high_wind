import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telemetry_of_the_high_wind/theme/app_theme.dart';

class PressureCalculatorScreen extends StatefulWidget {
  const PressureCalculatorScreen({super.key});

  @override
  State<PressureCalculatorScreen> createState() =>
      _PressureCalculatorScreenState();
}

class _PressureCalculatorScreenState extends State<PressureCalculatorScreen> {
  double pressure = 226.3;

  double get altitudeMeters =>
      (44330 * (1 - pow(pressure / 1013.25, 0.1903))).toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
          children: [
            Text(
              'ANEROID CELL UTILITY',
              style: GoogleFonts.ibmPlexMono(
                color: radarGreen,
                fontSize: 10,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Pressure to altitude',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Resolve a theoretical elevation profile from an aneroid capsule pressure reading.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRESSURE INPUT',
                    style: GoogleFonts.ibmPlexMono(
                      color: secondaryText,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pressure.toStringAsFixed(1),
                        style: GoogleFonts.ibmPlexMono(
                          color: primaryText,
                          fontSize: 38,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'mbar',
                          style: GoogleFonts.ibmPlexMono(
                            color: radarGreen,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Slider(
                    min: 1,
                    max: 1050,
                    value: pressure,
                    onChanged: (value) => setState(() => pressure = value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1 mbar',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        'SEA LEVEL 1013.25',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: radarGreen.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: radarGreen.withValues(alpha: .45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THEORETICAL ELEVATION',
                    style: GoogleFonts.ibmPlexMono(
                      color: radarGreen,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${altitudeMeters.toStringAsFixed(0)} m',
                    style: GoogleFonts.ibmPlexMono(
                      color: primaryText,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(altitudeMeters / 1000).toStringAsFixed(2)} km ASL',
                    style: GoogleFonts.ibmPlexMono(
                      color: secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              child: CustomPaint(
                painter: _AtmosphereProfilePainter(
                  pressure: pressure,
                  altitudeRatio: (altitudeMeters / 44330).clamp(0, 1),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ISA BAROMETRIC MODEL',
              style: GoogleFonts.ibmPlexMono(
                color: stratosphereBlue,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Uses the International Standard Atmosphere approximation. Temperature inversions, launch-site elevation, and capsule hysteresis are not compensated; do not use for navigation.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AtmosphereProfilePainter extends CustomPainter {
  const _AtmosphereProfilePainter({
    required this.pressure,
    required this.altitudeRatio,
  });
  final double pressure;
  final double altitudeRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      border,
    );
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()..color = outline.withValues(alpha: .7),
      );
    }
    final point = Offset(
      28 + (size.width - 56) * (1 - pressure / 1050),
      size.height - 22 - (size.height - 44) * altitudeRatio,
    );
    canvas.drawLine(
      Offset(20, size.height - 22),
      point,
      Paint()
        ..color = radarGreen
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      point,
      8,
      Paint()
        ..color = radarGreen.withValues(alpha: .2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(point, 3, Paint()..color = radarGreen);
  }

  @override
  bool shouldRepaint(covariant _AtmosphereProfilePainter oldDelegate) =>
      oldDelegate.pressure != pressure ||
      oldDelegate.altitudeRatio != altitudeRatio;
}
