import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telemetry_of_the_high_wind/providers/app_providers.dart';
import 'package:telemetry_of_the_high_wind/screens/add_payload_screen.dart';
import 'package:telemetry_of_the_high_wind/theme/app_theme.dart';

class PayloadDetailScreen extends ConsumerWidget {
  const PayloadDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archive = ref.watch(projectProvider);
    final index = archive.entries.indexWhere((entry) => entry.id == id);
    if (index < 0) {
      return const Scaffold(body: Center(child: Text('Record unavailable')));
    }
    final payload = archive.entries[index];
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 310,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: BackButton(color: primaryText),
            ),
            actions: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () async {
                  ref.read(inputProvider).fill(payload);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPayloadScreen(editIndex: index),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  tooltip: 'Delete',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: panel,
                        title: Text(
                          'Delete record?',
                          style: GoogleFonts.spaceGrotesk(color: primaryText),
                        ),
                        content: Text(
                          'This removes the specimen from your archive on this device.',
                          style: GoogleFonts.ibmPlexSans(color: secondaryText),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Delete',
                              style: GoogleFonts.ibmPlexSans(color: critical),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await ref.read(projectProvider).delete(index);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline, color: critical),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (payload.photoPath.isNotEmpty &&
                      File(payload.photoPath).existsSync())
                    Image.file(File(payload.photoPath), fit: BoxFit.cover)
                  else
                    const ColoredBox(color: panel),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, background],
                        stops: [.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payload.classification.label,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          payload.sondeTrackingIndex,
                          style: GoogleFonts.ibmPlexMono(
                            color: radarGreen,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'CARRIER',
                        value: '${payload.frequencyMhz.toStringAsFixed(1)} MHz',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Metric(
                        label: 'DESIGN CEILING',
                        value:
                            '${payload.designAltitudeKm.toStringAsFixed(0)} km',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _Section(
                  title: 'INSTRUMENT IDENTITY',
                  rows: {
                    'Laboratory': payload.artisanHallmark,
                    'Era': payload.era,
                    'Atmospheric layer':
                        '${payload.atmosphericLayer.label} / ${payload.atmosphericLayer.range}',
                    'Temperature range': payload.temperatureRange,
                  },
                ),
                _Section(
                  title: 'SIGNAL & MECHANISM',
                  rows: {
                    'Sensor profile': payload.barometricSensorProfile,
                    'Battery compound': payload.batteryChemistry,
                    'Enclosure': payload.enclosureMaterial,
                    'Proportions': payload.physicalProportions,
                  },
                ),
                _Section(
                  title: 'PROVENANCE',
                  rows: {
                    'Ground zero': payload.groundZero,
                    'Calibration works': payload.calibrationSite,
                    'Preservation': payload.preservationSoundness.label,
                    'Condition notes': payload.preservationNotes,
                  },
                ),
                if (payload.notes.isNotEmpty)
                  _Section(
                    title: 'ARCHIVE NOTES',
                    rows: {'Notes': payload.notes},
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: panel,
      border: Border.all(color: outline),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexMono(color: secondaryText, fontSize: 9),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            color: radarGreen,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.ibmPlexMono(
            color: stratosphereBlue,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: outline),
          ),
          child: Column(
            children: rows.entries.map((row) {
              final value = row.value.trim().isEmpty
                  ? 'Not recorded'
                  : row.value;
              return Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 112,
                      child: Text(
                        row.key,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}
