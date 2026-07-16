import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telemetry_of_the_high_wind/enum/payload_enums.dart';
import 'package:telemetry_of_the_high_wind/providers/app_providers.dart';
import 'package:telemetry_of_the_high_wind/theme/app_theme.dart';

class LogbookScreen extends ConsumerWidget {
  const LogbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(projectProvider).entries;

    if (entries.isEmpty) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COLLECTION ANALYTICS',
                  style: GoogleFonts.ibmPlexMono(
                    color: radarGreen,
                    fontSize: 10,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Signal logbook',
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

    final complete = entries
        .where((e) => e.preservationSoundness == PreservationSoundness.complete)
        .length;
    final recovered = entries.length - complete;
    final averageAltitude = _avg(entries.map((e) => e.designAltitudeKm));
    final averageFrequency = _avg(entries.map((e) => e.frequencyMhz));
    final maxAltitude =
        entries.map((e) => e.designAltitudeKm).reduce(max);
    final minAltitude =
        entries.map((e) => e.designAltitudeKm).reduce(min);

    final layerCounts = {
      for (final layer in AtmosphericLayer.values)
        layer: entries.where((e) => e.atmosphericLayer == layer).length,
    };
    final classCounts = {
      for (final c in PayloadClassification.values)
        c: entries.where((e) => e.classification == c).length,
    };
    final soundnessCounts = {
      for (final s in PreservationSoundness.values)
        s: entries.where((e) => e.preservationSoundness == s).length,
    };

    final eras = <String, int>{};
    for (final e in entries) {
      final era = e.era.trim().isEmpty ? 'Unspecified' : e.era.trim();
      eras[era] = (eras[era] ?? 0) + 1;
    }
    final topEras = eras.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final withPhoto =
        entries.where((e) => e.photoPath.trim().isNotEmpty).length;
    final withCalibration =
        entries.where((e) => e.calibrationSite.trim().isNotEmpty).length;
    final withGround =
        entries.where((e) => e.groundZero.trim().isNotEmpty).length;

    final maxLayer = max(1, layerCounts.values.fold(0, max));
    final maxClass = max(1, classCounts.values.fold(0, max));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
          children: [
            Text(
              'COLLECTION ANALYTICS',
              style: GoogleFonts.ibmPlexMono(
                color: radarGreen,
                fontSize: 10,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Signal logbook',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${entries.length} specimen${entries.length == 1 ? '' : 's'} in your on-device register.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 22),
            Container(
              height: 210,
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: outline),
              ),
              child: CustomPaint(
                painter: _RingPainter(
                  archiveRatio: min(entries.length / 20, 1),
                  intactRatio:
                      entries.isEmpty ? 0 : complete / entries.length,
                  altitudeRatio: min(averageAltitude / 50, 1),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entries.length.toString().padLeft(2, '0'),
                        style: GoogleFonts.spaceGrotesk(
                          color: primaryText,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'IN ARCHIVE',
                        style: GoogleFonts.ibmPlexMono(
                          color: secondaryText,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'INTACT',
                    value: '$complete',
                    accent: radarGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: 'FIELD WORN',
                    value: '$recovered',
                    accent: stratosphereBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: 'WITH PHOTO',
                    value: '$withPhoto',
                    accent: primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SectionTitle('ALTITUDE & SIGNAL'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _NumberCard(
                    label: 'MEAN CEILING',
                    value: '${averageAltitude.toStringAsFixed(1)} km',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberCard(
                    label: 'MEAN FREQUENCY',
                    value: '${averageFrequency.toStringAsFixed(1)} MHz',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _NumberCard(
                    label: 'HIGHEST DESIGN',
                    value: '${maxAltitude.toStringAsFixed(0)} km',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberCard(
                    label: 'LOWEST DESIGN',
                    value: '${minAltitude.toStringAsFixed(0)} km',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SectionTitle('ATMOSPHERIC LAYERS'),
            const SizedBox(height: 10),
            _Panel(
              child: Column(
                children: layerCounts.entries.map((item) {
                  return _BarRow(
                    label: item.key.label,
                    count: item.value,
                    max: maxLayer,
                    color: item.key == AtmosphericLayer.stratosphere
                        ? radarGreen
                        : stratosphereBlue,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),
            _SectionTitle('PAYLOAD CLASSIFICATION'),
            const SizedBox(height: 10),
            _Panel(
              child: Column(
                children: classCounts.entries
                    .where((e) => entries.isEmpty || e.value > 0)
                    .map(
                      (item) => _BarRow(
                        label: item.key.label,
                        count: item.value,
                        max: maxClass,
                        color: radarGreen,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 22),
            _SectionTitle('PRESERVATION SPECTRUM'),
            const SizedBox(height: 10),
            _Panel(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: soundnessCounts.entries.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.value}',
                          style: GoogleFonts.ibmPlexMono(
                            color: radarGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 120,
                          child: Text(
                            item.key.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.ibmPlexSans(
                              color: secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),
            _SectionTitle('ERA BANDS'),
            const SizedBox(height: 10),
            _Panel(
              child: topEras.isEmpty
                  ? _EmptyHint('No eras recorded yet.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: topEras.take(8).map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: radarGreen.withValues(alpha: 0.4),
                            ),
                            color: radarGreen.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            '${item.key}  ·  ${item.value}',
                            style: GoogleFonts.ibmPlexMono(
                              color: radarGreen,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 22),
            _SectionTitle('RECORD COMPLETENESS'),
            const SizedBox(height: 10),
            _Panel(
              child: Column(
                children: [
                  _CompletenessRow(
                    label: 'Photographs attached',
                    value: withPhoto,
                    total: entries.length,
                  ),
                  _CompletenessRow(
                    label: 'Calibration works noted',
                    value: withCalibration,
                    total: entries.length,
                  ),
                  _CompletenessRow(
                    label: 'Launch sites noted',
                    value: withGround,
                    total: entries.length,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _avg(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.ibmPlexMono(
          color: stratosphereBlue,
          fontSize: 10,
          letterSpacing: 1.2,
        ),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: outline),
        ),
        child: child,
      );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.ibmPlexMono(color: secondaryText, fontSize: 11),
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.accent,
  });
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.ibmPlexMono(
                color: accent,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.ibmPlexMono(
                color: secondaryText,
                fontSize: 8,
              ),
            ),
          ],
        ),
      );
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  GoogleFonts.ibmPlexMono(color: secondaryText, fontSize: 9),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.ibmPlexMono(
                color: radarGreen,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.count,
    required this.max,
    required this.color,
  });
  final String label;
  final int count;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 108,
              child: Text(
                label.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.ibmPlexMono(
                  color: secondaryText,
                  fontSize: 8,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: max == 0 ? 0 : count / max,
                  minHeight: 8,
                  color: color,
                  backgroundColor: background,
                ),
              ),
            ),
            SizedBox(
              width: 28,
              child: Text(
                '$count',
                textAlign: TextAlign.end,
                style: GoogleFonts.ibmPlexMono(
                  color: primaryText,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      );
}

class _CompletenessRow extends StatelessWidget {
  const _CompletenessRow({
    required this.label,
    required this.value,
    required this.total,
  });
  final String label;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.ibmPlexSans(
                    color: primaryText,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                total == 0 ? '—' : '${(ratio * 100).round()}%',
                style: GoogleFonts.ibmPlexMono(
                  color: radarGreen,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              color: radarGreen,
              backgroundColor: background,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.archiveRatio,
    required this.intactRatio,
    required this.altitudeRatio,
  });
  final double archiveRatio;
  final double intactRatio;
  final double altitudeRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final radius = 84.0 - i * 17;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        -pi / 2,
        pi * 2,
        false,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7,
      );
      final ratios = [archiveRatio, intactRatio, altitudeRatio];
      final colors = [radarGreen, stratosphereBlue, primaryText];
      canvas.drawArc(
        rect,
        -pi / 2,
        pi * 2 * ratios[i],
        false,
        Paint()
          ..color = colors[i]
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.archiveRatio != archiveRatio ||
      oldDelegate.intactRatio != intactRatio ||
      oldDelegate.altitudeRatio != altitudeRatio;
}
