import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telemetry_of_the_high_wind/models/atmospheric_payload.dart';
import 'package:telemetry_of_the_high_wind/providers/app_providers.dart';
import 'package:telemetry_of_the_high_wind/showcase/ascension_painter.dart';
import 'package:telemetry_of_the_high_wind/showcase/ascension_palette.dart';
import 'package:telemetry_of_the_high_wind/showcase/ascension_physics.dart';
import 'package:telemetry_of_the_high_wind/theme/app_theme.dart';

class AscensionGridScreen extends ConsumerStatefulWidget {
  const AscensionGridScreen({super.key});

  @override
  ConsumerState<AscensionGridScreen> createState() =>
      _AscensionGridScreenState();
}

class _AscensionGridScreenState extends ConsumerState<AscensionGridScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final AscensionWorld _world;
  Duration _previous = Duration.zero;
  double _pulse = 0;

  AscensionBalloon? _dragged;
  Offset? _lastDrag;
  bool _panningAltitude = false;
  double _panDistance = 0;
  String? _focusedId;
  Timer? _lockPing;
  int _pingCount = 0;

  @override
  void initState() {
    super.initState();
    _world = AscensionWorld(random: Random(42));
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _lockPing?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = _previous == Duration.zero
        ? 1 / 60
        : min((elapsed - _previous).inMicroseconds / 1e6, 0.033);
    _previous = elapsed;
    _pulse = (_pulse + dt * 0.7) % 1;

    final popped = _world.step(
      dt,
      dragDelta: null,
      dragged: _world.physicsFrozen ? null : _dragged,
    );
    if (popped) {
      HapticFeedback.heavyImpact();
    }

    if (!_world.physicsFrozen &&
        _world.viewVelocity.abs() > 2.5 &&
        _world.random.nextDouble() < 0.08) {
      HapticFeedback.selectionClick();
    }

    if (mounted) setState(() {});
  }

  void _windPayload(AscensionBalloon balloon) {
    _world.windMainspring(balloon);
    HapticFeedback.selectionClick();
    Future<void>.delayed(const Duration(milliseconds: 45), () {
      HapticFeedback.selectionClick();
    });
    setState(() {});
  }

  void _tryLock(AscensionBalloon balloon) {
    final candidate = _world.nearestToReticle();
    if (candidate == null || candidate.payload.id != balloon.payload.id) {
      return;
    }
    _world.lockOn(balloon);
    _focusedId = balloon.payload.id;
    _pingCount = 0;
    _lockPing?.cancel();
    _lockPing = Timer.periodic(const Duration(milliseconds: 160), (timer) {
      HapticFeedback.mediumImpact();
      _pingCount++;
      if (_pingCount >= 5) timer.cancel();
    });
    setState(() {});
  }

  void _dismissFocus() {
    _lockPing?.cancel();
    _world.unlock();
    setState(() => _focusedId = null);
  }

  void _clearFocusIfMissing(List<AtmosphericPayload> entries) {
    final id = _focusedId;
    if (id == null) return;
    if (entries.any((e) => e.id == id)) return;
    _lockPing?.cancel();
    _world.unlock();
    _focusedId = null;
  }

  Future<void> _openFocusedDetail() async {
    final id = _focusedId;
    if (id == null) return;
    await Navigator.pushNamed(context, '/detail', arguments: id);
    if (!mounted) return;
    final entries = ref.read(projectProvider).entries;
    if (!entries.any((e) => e.id == id)) {
      _dismissFocus();
    }
  }

  AtmosphericPayload? _liveFocused(List<AtmosphericPayload> entries) {
    final id = _focusedId;
    if (id == null) return null;
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(projectProvider).entries;
    _world.syncPayloads(entries);
    _clearFocusIfMissing(entries);
    final focused = _liveFocused(entries);

    if (entries.isEmpty) {
      return Scaffold(
        backgroundColor: background,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STRATOSPHERIC ASCENSION',
                  style: GoogleFonts.ibmPlexMono(
                    color: radarGreen,
                    fontSize: 10,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Ascension Grid',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'NO PAYLOADS IN THIS ARCHIVE.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexMono(
                        color: secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AscensionPalette.troposphere,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              _world.size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  if (_focusedId != null) return;
                  _panDistance = 0;
                  final hit =
                      _world.hitTest(details.localPosition, radius: 70);
                  if (hit != null) {
                    _dragged = hit;
                    _panningAltitude = false;
                  } else {
                    _dragged = null;
                    _panningAltitude = true;
                  }
                  _lastDrag = details.localPosition;
                },
                onPanUpdate: (details) {
                  if (_focusedId != null) return;
                  final last = _lastDrag;
                  _lastDrag = details.localPosition;
                  if (last == null) return;
                  final delta = details.localPosition - last;
                  _panDistance += delta.distance;

                  if (_dragged != null) {
                    _world.step(
                      1 / 60,
                      dragDelta: delta,
                      dragged: _dragged,
                    );
                    if (delta.distance > 6) {
                      HapticFeedback.selectionClick();
                    }
                  } else if (_panningAltitude) {
                    _world.adjustAltitude(delta.dy);
                    if (delta.dy.abs() > 8) {
                      HapticFeedback.lightImpact();
                    }
                  }
                  setState(() {});
                },
                onPanEnd: (_) {
                  if (_focusedId != null) return;
                  final dragged = _dragged;
                  final wasTap = _panDistance < 12;
                  _dragged = null;
                  _panningAltitude = false;
                  _lastDrag = null;

                  // Short press on a payload = wind the mainspring.
                  // Longer drag = try telemetry lock if in reticle.
                  if (dragged != null) {
                    if (wasTap) {
                      _windPayload(dragged);
                    } else {
                      _tryLock(dragged);
                    }
                  }
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: AscensionPainter(
                    world: _world,
                    locked: _focusedId != null,
                    pulse: _pulse,
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STRATOSPHERIC ASCENSION',
                              style: GoogleFonts.ibmPlexMono(
                                color: AscensionPalette.ink
                                    .withValues(alpha: 0.55),
                                fontSize: 10,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ascension Grid',
                              style: GoogleFonts.spaceGrotesk(
                                color: AscensionPalette.ink,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ViewBadge(altitudeKm: _world.viewAltitudeKm),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Swipe up/down to climb · tap to wind · drag into reticle to lock.',
                    style: GoogleFonts.ibmPlexSans(
                      color: AscensionPalette.muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (focused != null)
            _FocusPanel(
              payload: focused,
              onClose: _dismissFocus,
              onOpenDetail: _openFocusedDetail,
            ),
        ],
      ),
    );
  }
}

class _ViewBadge extends StatelessWidget {
  const _ViewBadge({required this.altitudeKm});
  final double altitudeKm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AscensionPalette.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AscensionPalette.silver),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'VIEW',
            style: GoogleFonts.ibmPlexMono(
              color: AscensionPalette.muted,
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${altitudeKm.toStringAsFixed(1)} km',
            style: GoogleFonts.ibmPlexMono(
              color: AscensionPalette.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusPanel extends StatelessWidget {
  const _FocusPanel({
    required this.payload,
    required this.onClose,
    required this.onOpenDetail,
  });

  final AtmosphericPayload payload;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -1, end: 0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value * 120),
              child: Opacity(opacity: 1 + value, child: child),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Material(
              color: AscensionPalette.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onOpenDetail,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AscensionPalette.silver),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'TELEMETRY LOCK',
                            style: GoogleFonts.ibmPlexMono(
                              color: AscensionPalette.lock,
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: onClose,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close, size: 20),
                            color: AscensionPalette.muted,
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: AscensionPalette.ground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AscensionPalette.silver),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: payload.photoPath.isNotEmpty &&
                                    File(payload.photoPath).existsSync()
                                ? Image.file(
                                    File(payload.photoPath),
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.memory,
                                      color: AscensionPalette.ink
                                          .withValues(alpha: 0.35),
                                      size: 32,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  payload.classification.label,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: AscensionPalette.ink,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  payload.sondeTrackingIndex,
                                  style: GoogleFonts.ibmPlexMono(
                                    color: AscensionPalette.muted,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _row('Manufacturer', payload.artisanHallmark),
                                _row('Temperature', payload.temperatureRange),
                                _row('Era', payload.era),
                                _row(
                                  'Calibrated at',
                                  payload.calibrationSite.isEmpty
                                      ? 'Not recorded'
                                      : payload.calibrationSite,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      'Open specimen record',
                                      style: GoogleFonts.ibmPlexMono(
                                        color: AscensionPalette.lock,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: AscensionPalette.lock,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    final display = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: GoogleFonts.ibmPlexMono(
                color: AscensionPalette.muted,
                fontSize: 9,
              ),
            ),
            TextSpan(
              text: display,
              style: GoogleFonts.ibmPlexSans(
                color: AscensionPalette.ink,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
