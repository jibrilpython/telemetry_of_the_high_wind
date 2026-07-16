import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telemetry_of_the_high_wind/enum/payload_enums.dart';
import 'package:telemetry_of_the_high_wind/models/atmospheric_payload.dart';
import 'package:telemetry_of_the_high_wind/providers/app_providers.dart';
import 'package:telemetry_of_the_high_wind/theme/app_theme.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  AtmosphericLayer? layer;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final archive = ref.watch(projectProvider);
    final entries = archive.entries.where((payload) {
      final search = query.toLowerCase();
      return (layer == null || payload.atmosphericLayer == layer) &&
          (search.isEmpty ||
              payload.sondeTrackingIndex.toLowerCase().contains(search) ||
              payload.artisanHallmark.toLowerCase().contains(search) ||
              payload.classification.label.toLowerCase().contains(search));
    }).toList();

    final matchedCount = entries.length;
    final withPhotos = entries.where((e) => e.photoPath.trim().isNotEmpty).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(inputProvider).clear();
          Navigator.pushNamed(context, '/add');
        },
        backgroundColor: radarGreen,
        foregroundColor: primaryText,
        icon: const Icon(Icons.add),
        label: Text(
          'LOG PAYLOAD',
          style: GoogleFonts.ibmPlexMono(fontSize: 11),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPPER-AIR ARCHIVE',
                      style: GoogleFonts.ibmPlexMono(
                        color: radarGreen,
                        fontSize: 10,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Payload register',
                      style: GoogleFonts.spaceGrotesk(
                        color: primaryText,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 2,
                      color: radarGreen,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _CountChip(
                          value: matchedCount.toString().padLeft(2, '0'),
                          label: 'records',
                        ),
                        const SizedBox(width: 8),
                        _CountChip(
                          value: withPhotos.toString().padLeft(2, '0'),
                          label: 'with photograph',
                          accent: stratosphereBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      onChanged: (value) => setState(() => query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search index, laboratory, classification',
                        prefixIcon: Icon(
                          Icons.radar_rounded,
                          color: radarGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _LayerChip(
                            label: 'ALL LAYERS',
                            selected: layer == null,
                            onTap: () => setState(() => layer = null),
                          ),
                          ...AtmosphericLayer.values.map(
                            (value) => _LayerChip(
                              label: value.label.toUpperCase(),
                              selected: layer == value,
                              onTap: () => setState(() => layer = value),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            if (archive.isLoading)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: radarGreen,
                  backgroundColor: panel,
                ),
              )
            else if (entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'NO PAYLOADS IN THIS ARCHIVE.',
                    style: GoogleFonts.ibmPlexMono(
                      color: secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => PayloadCard(
                    payload: entries[index],
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/detail',
                      arguments: entries[index].id,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.value,
    required this.label,
    this.accent = radarGreen,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              color: secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  const _LayerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}

class PayloadCard extends StatelessWidget {
  const PayloadCard({super.key, required this.payload, required this.onTap});
  final AtmosphericPayload payload;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final recovered =
        payload.preservationSoundness != PreservationSoundness.complete;
    final accent = recovered ? stratosphereBlue : radarGreen;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: panel,
            border: Border.all(color: outline),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Container(
                          width: 66,
                          height: 82,
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: payload.photoPath.isNotEmpty &&
                                  File(payload.photoPath).existsSync()
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.file(
                                    File(payload.photoPath),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : CustomPaint(
                                  painter: PayloadSilhouettePainter(
                                    color: accent,
                                    classification: payload.classification,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                payload.artisanHallmark.isEmpty
                                    ? 'UNATTRIBUTED LABORATORY'
                                    : payload.artisanHallmark.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.ibmPlexMono(
                                  color: secondaryText,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _SpecBadge(
                                    '${payload.frequencyMhz.toStringAsFixed(1)} MHz',
                                  ),
                                  _SpecBadge(
                                    '${payload.designAltitudeKm.toStringAsFixed(0)} km',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                payload.sondeTrackingIndex,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.ibmPlexMono(
                                  color: radarGreen,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: secondaryText,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecBadge extends StatelessWidget {
  const _SpecBadge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: radarGreen.withValues(alpha: .45)),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: GoogleFonts.ibmPlexMono(color: radarGreen, fontSize: 9),
    ),
  );
}

class PayloadSilhouettePainter extends CustomPainter {
  PayloadSilhouettePainter({required this.color, required this.classification});
  final Color color;
  final PayloadClassification classification;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = size.width / 2;
    canvas.drawLine(Offset(center, 8), Offset(center, 25), paint);
    if (classification == PayloadClassification.radarTargetReflector) {
      final path = Path()
        ..moveTo(center, 20)
        ..lineTo(center + 19, 46)
        ..lineTo(center, 68)
        ..lineTo(center - 19, 46)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawLine(Offset(center - 19, 46), Offset(center + 19, 46), paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center, 48), width: 35, height: 45),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.drawCircle(Offset(center, 47), 8, paint);
      canvas.drawLine(Offset(center - 12, 63), Offset(center + 12, 63), paint);
    }
  }

  @override
  bool shouldRepaint(covariant PayloadSilhouettePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.classification != classification;
}
