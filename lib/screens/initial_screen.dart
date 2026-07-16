import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telemetry_of_the_high_wind/providers/app_providers.dart';
import 'package:telemetry_of_the_high_wind/theme/app_theme.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});

  @override
  ConsumerState<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends ConsumerState<InitialScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _carrier;
  late final Animation<double> _fade;
  late final Animation<Offset> _rise;
  late final Animation<double> _ladder;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    );
    _carrier = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _rise = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));
    _ladder = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.28, 1, curve: Curves.easeOutCubic),
    );
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _carrier.dispose();
    super.dispose();
  }

  Future<void> _enterArchive() async {
    await ref.read(userProvider).completeOnboarding();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _carrier,
            builder: (context, _) => CustomPaint(
              painter: _AltitudeFieldPainter(pulse: _carrier.value),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _rise,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 44,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StatusLine(pulse: _carrier),
                              const Spacer(flex: 2),
                              Text(
                                'Telemetry\nof the\nHigh Wind',
                                style: GoogleFonts.spaceGrotesk(
                                  color: primaryText,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  height: 0.94,
                                  letterSpacing: -1.8,
                                ),
                              ),
                              const SizedBox(height: 26),
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 2,
                                    color: radarGreen,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Upper-air instrument archive',
                                      style: GoogleFonts.ibmPlexSans(
                                        color: stratosphereBlue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'Catalog early mechanical radiosondes, analog '
                                'trackers, and the transmitters that first returned '
                                'climate data from the stratosphere.',
                                style: GoogleFonts.ibmPlexSans(
                                  color: secondaryText,
                                  fontSize: 16,
                                  height: 1.55,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 40),
                              FadeTransition(
                                opacity: _ladder,
                                child: const _AltitudeLadder(),
                              ),
                              const Spacer(flex: 3),
                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: FilledButton(
                                  onPressed: _enterArchive,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: radarGreen,
                                    foregroundColor: primaryText,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Enter the archive',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  'For personal collecting',
                                  style: GoogleFonts.ibmPlexMono(
                                    color: secondaryText.withValues(alpha: 0.75),
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final glow = 0.35 + pulse.value * 0.4;
        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: radarGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: radarGreen.withValues(alpha: glow),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'INSTRUMENT REGISTER',
              style: GoogleFonts.ibmPlexMono(
                color: primaryText.withValues(alpha: 0.9),
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Quiet vertical climb through atmospheric layers — not a feature card row.
class _AltitudeLadder extends StatelessWidget {
  const _AltitudeLadder();

  static const _rungs = [
    ('NEAR SPACE', '50 km+'),
    ('STRATOSPHERE', '12–50 km'),
    ('TROPOPAUSE', '8–18 km'),
    ('TROPOSPHERE', '0–12 km'),
  ];

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: radarGreen.withValues(alpha: 0.55),
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: radarGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _rungs.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _rungs[i].$1,
                          style: GoogleFonts.ibmPlexMono(
                            color: i == 0
                                ? stratosphereBlue
                                : secondaryText,
                            fontSize: 11,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      Text(
                        _rungs[i].$2,
                        style: GoogleFonts.ibmPlexMono(
                          color: primaryText.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiet altitude-band field — geometric, not decorative weather art.
class _AltitudeFieldPainter extends CustomPainter {
  const _AltitudeFieldPainter({required this.pulse});

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final bandPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 5; i++) {
      final top = size.height * (0.06 + i * 0.065);
      bandPaint.color = stratosphereBlue.withValues(alpha: 0.014 + i * 0.007);
      canvas.drawRect(
        Rect.fromLTWH(0, top, size.width, size.height * 0.05),
        bandPaint,
      );
    }

    final grid = Paint()
      ..color = outline.withValues(alpha: 0.5)
      ..strokeWidth = 0.6;
    for (var x = 24.0; x < size.width; x += 52) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.38), grid);
    }

    final antennaX = size.width - 48;
    final antenna = Paint()
      ..color = radarGreen.withValues(alpha: 0.2 + pulse * 0.08)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(antennaX, size.height * 0.1),
      Offset(antennaX, size.height * 0.34),
      antenna,
    );
    canvas.drawCircle(
      Offset(antennaX, size.height * 0.1),
      3.2,
      Paint()..color = radarGreen.withValues(alpha: 0.4 + pulse * 0.2),
    );

    final arc = Paint()
      ..color = radarGreen.withValues(alpha: 0.08 + pulse * 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(antennaX, size.height * 0.1),
          radius: (16.0 + pulse * 2) * i,
        ),
        math.pi * 0.15,
        math.pi * 0.7,
        false,
        arc,
      );
    }

    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          background.withValues(alpha: 0.12),
          background,
          background,
        ],
        stops: const [0.0, 0.46, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);
  }

  @override
  bool shouldRepaint(covariant _AltitudeFieldPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}
