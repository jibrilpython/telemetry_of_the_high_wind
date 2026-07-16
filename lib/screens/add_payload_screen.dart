import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:telemetry_of_the_high_wind/common/temperature_rheostat.dart';
import 'package:telemetry_of_the_high_wind/enum/payload_enums.dart';
import 'package:telemetry_of_the_high_wind/providers/app_providers.dart';
import 'package:telemetry_of_the_high_wind/theme/app_theme.dart';

class AddPayloadScreen extends ConsumerStatefulWidget {
  const AddPayloadScreen({super.key, this.editIndex});
  final int? editIndex;

  @override
  ConsumerState<AddPayloadScreen> createState() => _AddPayloadScreenState();
}

class _AddPayloadScreenState extends ConsumerState<AddPayloadScreen> {
  final pageController = PageController();
  int page = 0;
  bool showHallmarkError = false;
  late final Map<String, TextEditingController> fields;

  @override
  void initState() {
    super.initState();
    final input = ref.read(inputProvider);
    fields = {
      'index': TextEditingController(text: input.sondeTrackingIndex),
      'hallmark': TextEditingController(text: input.artisanHallmark),
      'frequency': TextEditingController(text: input.frequencyMhz.toString()),
      'sensor': TextEditingController(text: input.barometricSensorProfile),
      'battery': TextEditingController(text: input.batteryChemistry),
      'material': TextEditingController(text: input.enclosureMaterial),
      'proportions': TextEditingController(text: input.physicalProportions),
      'preservation': TextEditingController(text: input.preservationNotes),
      'ground': TextEditingController(text: input.groundZero),
      'era': TextEditingController(text: input.era),
      'temperature': TextEditingController(text: input.temperatureRange),
      'calibration': TextEditingController(text: input.calibrationSite),
      'altitude': TextEditingController(
        text: input.designAltitudeKm.toString(),
      ),
      'notes': TextEditingController(text: input.notes),
    };
    fields['hallmark']!.addListener(() {
      if (showHallmarkError && fields['hallmark']!.text.trim().isNotEmpty) {
        setState(() => showHallmarkError = false);
      }
    });
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    pageController.dispose();
    super.dispose();
  }

  bool get _hallmarkValid => fields['hallmark']!.text.trim().isNotEmpty;

  bool _requireHallmark({bool jumpToIdentity = true}) {
    if (_hallmarkValid) {
      if (showHallmarkError) setState(() => showHallmarkError = false);
      return true;
    }
    setState(() => showHallmarkError = true);
    if (jumpToIdentity && page != 0) {
      pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
    return false;
  }

  Future<void> _showPhotoOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Attach photograph',
                style: GoogleFonts.spaceGrotesk(
                  color: primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how to add an apparatus image.',
                style: GoogleFonts.ibmPlexSans(
                  color: secondaryText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library_outlined,
                    color: radarGreen),
                title: Text(
                  'Choose from gallery',
                  style: GoogleFonts.ibmPlexSans(color: primaryText),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.photo_camera_outlined, color: radarGreen),
                title: Text(
                  'Take a photo',
                  style: GoogleFonts.ibmPlexSans(color: primaryText),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    await _pickPhoto(source);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 86,
      maxWidth: 1800,
    );
    if (image == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/thw_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(image.path).copy(path);
    ref.read(inputProvider).photoPath = path;
    ref.read(inputProvider).changed();
  }

  void syncInput() {
    final input = ref.read(inputProvider);
    input.sondeTrackingIndex = fields['index']!.text;
    input.artisanHallmark = fields['hallmark']!.text.trim();
    input.frequencyMhz =
        double.tryParse(fields['frequency']!.text) ?? input.frequencyMhz;
    input.barometricSensorProfile = fields['sensor']!.text;
    input.batteryChemistry = fields['battery']!.text;
    input.enclosureMaterial = fields['material']!.text;
    input.physicalProportions = fields['proportions']!.text;
    input.preservationNotes = fields['preservation']!.text;
    input.groundZero = fields['ground']!.text;
    input.era = fields['era']!.text;
    input.temperatureRange = fields['temperature']!.text;
    input.calibrationSite = fields['calibration']!.text;
    input.designAltitudeKm =
        double.tryParse(fields['altitude']!.text) ?? input.designAltitudeKm;
    input.notes = fields['notes']!.text;
  }

  Future<void> save() async {
    if (!_requireHallmark()) return;
    syncInput();
    await ref
        .read(projectProvider)
        .save(ref.read(inputProvider), index: widget.editIndex);
    ref.read(inputProvider).clear();
    if (mounted) Navigator.pop(context);
  }

  void _continue() {
    if (page == 0 && !_requireHallmark(jumpToIdentity: false)) return;
    pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final input = ref.watch(inputProvider);
    const titles = ['Identity', 'Signal chain', 'Field record'];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editIndex == null ? 'Log payload' : 'Edit payload'),
        actions: [
          TextButton(
            onPressed: save,
            child: Text(
              'SAVE',
              style: GoogleFonts.ibmPlexMono(
                color: radarGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: _StepProgress(page: page, titles: titles),
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (value) => setState(() => page = value),
              children: [
                _buildIdentityPage(input),
                _buildSignalPage(),
                _buildFieldPage(input),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Row(
                children: [
                  if (page > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => pageController.previousPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        ),
                        child: const Text('BACK'),
                      ),
                    ),
                  if (page > 0) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: page == 2 ? save : _continue,
                      child: Text(
                        page == 2 ? 'COMMIT TO ARCHIVE' : 'CONTINUE',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityPage(InputNotifier input) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        _PhotoPicker(path: input.photoPath, onTap: _showPhotoOptions),
        const SizedBox(height: 16),
        _InstrumentPanel(
          eyebrow: 'REGISTRY',
          title: 'Specimen identity',
          accent: radarGreen,
          child: Column(
            children: [
              _Field(
                controller: fields['index']!,
                label: 'Sonde Tracking Index',
                hint: 'Auto-generated when left blank',
                dense: true,
              ),
              const SizedBox(height: 12),
              _ClassificationGrid(
                value: input.classification,
                onChanged: (value) {
                  input.classification = value;
                  input.changed();
                },
              ),
              const SizedBox(height: 12),
              _Field(
                controller: fields['hallmark']!,
                label: 'Artisan hallmark',
                hint: 'Aetheric Sonde Labs',
                requiredMark: true,
                forceError: showHallmarkError,
                errorText: 'Artisan hallmark is required',
                dense: true,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: fields['era']!,
                label: 'Era',
                hint: '1950s',
                eraMode: true,
                dense: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TemperatureRheostat(
          value: fields['temperature']!.text,
          onChanged: (value) => fields['temperature']!.text = value,
        ),
      ],
    );
  }

  Widget _buildSignalPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Text(
          'Carrier & ceiling',
          style: GoogleFonts.spaceGrotesk(
            color: primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Set the two numbers that defined every ground-station lock.',
          style: GoogleFonts.ibmPlexSans(color: secondaryText, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCell(
                icon: Icons.cell_tower_rounded,
                label: 'FREQUENCY',
                unit: 'MHz',
                accent: radarGreen,
                controller: fields['frequency']!,
                hint: '403.0',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCell(
                icon: Icons.height_rounded,
                label: 'CEILING',
                unit: 'km',
                accent: stratosphereBlue,
                controller: fields['altitude']!,
                hint: '30',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InstrumentPanel(
          eyebrow: 'MECHANISM',
          title: 'Sensor & power',
          accent: stratosphereBlue,
          child: Column(
            children: [
              _Field(
                controller: fields['sensor']!,
                label: 'Barometric sensor profile',
                hint: 'Aneroid capsule stack',
                dense: true,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: fields['battery']!,
                label: 'Battery chemistry compound',
                hint: 'Water-activated cuprous chloride cell',
                dense: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InstrumentPanel(
          eyebrow: 'HOUSING',
          title: 'Enclosure & mass',
          accent: radarGreen,
          child: Column(
            children: [
              _Field(
                controller: fields['material']!,
                label: 'Enclosure composition',
                hint: 'Waxed corrugated cardboard',
                dense: true,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: fields['proportions']!,
                label: 'Physical proportions',
                hint: '220 × 140 × 105 mm / 1.8 kg',
                dense: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldPage(InputNotifier input) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        _InstrumentPanel(
          eyebrow: 'LAYER',
          title: 'Atmospheric assignment',
          accent: stratosphereBlue,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AtmosphericLayer.values.map((layer) {
              final selected = input.atmosphericLayer == layer;
              return ChoiceChip(
                label: Text('${layer.label}  ·  ${layer.range}'),
                selected: selected,
                onSelected: (_) {
                  input.atmosphericLayer = layer;
                  input.changed();
                },
                labelStyle: GoogleFonts.ibmPlexMono(
                  color: selected ? primaryText : secondaryText,
                  fontSize: 10,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _InstrumentPanel(
          eyebrow: 'CONDITION',
          title: 'Preservation soundness',
          accent: radarGreen,
          child: Column(
            children: PreservationSoundness.values.map((state) {
              final selected = input.preservationSoundness == state;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    input.preservationSoundness = state;
                    input.changed();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? radarGreen.withValues(alpha: 0.12)
                          : background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? radarGreen : outline,
                        width: selected ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: selected ? radarGreen : secondaryText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.label,
                            style: GoogleFonts.ibmPlexSans(
                              color: primaryText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _InstrumentPanel(
          eyebrow: 'PROVENANCE',
          title: 'Launch & calibration',
          accent: stratosphereBlue,
          child: Column(
            children: [
              _Field(
                controller: fields['ground']!,
                label: 'Stratospheric ground zero',
                hint: 'Historic coastal naval station',
                dense: true,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: fields['calibration']!,
                label: 'Calibration works',
                hint: 'Meridian ceramic kiln no. 4',
                dense: true,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: fields['preservation']!,
                label: 'Preservation notes',
                hint: 'Internal wiring continuity verified',
                dense: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InstrumentPanel(
          eyebrow: 'LOG',
          title: 'Archive notes',
          accent: radarGreen,
          child: _Field(
            controller: fields['notes']!,
            label: 'Notes',
            hint: 'Recovery history, markings, provenance',
            lines: 4,
            dense: true,
          ),
        ),
      ],
    );
  }
}

class _InstrumentPanel extends StatelessWidget {
  const _InstrumentPanel({
    required this.eyebrow,
    required this.title,
    required this.accent,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: outline)),
              color: background.withValues(alpha: 0.55),
            ),
            child: Row(
              children: [
                Container(width: 3, height: 28, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: GoogleFonts.ibmPlexMono(
                          color: accent,
                          fontSize: 9,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                          color: primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.icon,
    required this.label,
    required this.unit,
    required this.accent,
    required this.controller,
    required this.hint,
  });

  final IconData icon;
  final String label;
  final String unit;
  final Color accent;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.ibmPlexMono(
                  color: secondaryText,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.ibmPlexMono(
              color: primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.ibmPlexMono(
                color: secondaryText.withValues(alpha: 0.5),
                fontSize: 22,
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: GoogleFonts.ibmPlexMono(color: accent, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ClassificationGrid extends StatelessWidget {
  const _ClassificationGrid({required this.value, required this.onChanged});

  final PayloadClassification value;
  final ValueChanged<PayloadClassification> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payload classification',
          style: GoogleFonts.ibmPlexSans(
            color: secondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PayloadClassification.values.map((item) {
            final selected = value == item;
            return FilterChip(
              selected: selected,
              label: Text(item.label),
              onSelected: (_) => onChanged(item),
              showCheckmark: false,
              selectedColor: radarGreen.withValues(alpha: 0.18),
              backgroundColor: background,
              side: BorderSide(color: selected ? radarGreen : outline),
              labelStyle: GoogleFonts.ibmPlexSans(
                color: selected ? primaryText : secondaryText,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.page, required this.titles});
  final int page;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final active = index == page;
        final done = index < page;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: done || active ? radarGreen : outline,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: radarGreen.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done || active ? radarGreen : panel,
                        border: Border.all(
                          color: done || active ? radarGreen : outline,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check,
                              size: 11, color: primaryText)
                          : Text(
                              '${index + 1}',
                              style: GoogleFonts.ibmPlexMono(
                                color: active ? primaryText : secondaryText,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        titles[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ibmPlexMono(
                          color: active ? radarGreen : secondaryText,
                          fontSize: 9,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.requiredMark = false,
    this.forceError = false,
    this.errorText,
    this.eraMode = false,
    this.lines = 1,
    this.dense = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool requiredMark;
  final bool forceError;
  final String? errorText;
  final bool eraMode;
  final int lines;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final borderColor = forceError ? critical : outline;
    final focusedColor = forceError ? critical : radarGreen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: lines,
          maxLength: eraMode ? 5 : null,
          keyboardType: TextInputType.text,
          inputFormatters: eraMode
              ? [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9sS]')),
                  LengthLimitingTextInputFormatter(5),
                  _EraTextFormatter(),
                ]
              : null,
          style: GoogleFonts.ibmPlexSans(color: primaryText),
          decoration: InputDecoration(
            labelText: requiredMark ? '$label *' : label,
            hintText: hint,
            counterText: eraMode ? '' : null,
            filled: true,
            fillColor: dense ? background : panel,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: dense ? 12 : 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: borderColor,
                width: forceError ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: focusedColor, width: 1.5),
            ),
          ),
        ),
        if (forceError && errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: GoogleFonts.ibmPlexSans(color: critical, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _EraTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d{0,4}s?$', caseSensitive: false).hasMatch(text)) {
      return oldValue;
    }
    return newValue;
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.path, required this.onTap});
  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 148,
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: outline),
          ),
          child: path.isNotEmpty && File(path).existsSync()
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(path), fit: BoxFit.cover),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: background.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: outline),
                          ),
                          child: Text(
                            'TAP TO REPLACE',
                            style: GoogleFonts.ibmPlexMono(
                              color: radarGreen,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: radarGreen.withValues(alpha: 0.12),
                        border: Border.all(
                          color: radarGreen.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: radarGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ATTACH APPARATUS PHOTOGRAPH',
                      style: GoogleFonts.ibmPlexMono(
                        color: secondaryText,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Camera or gallery',
                      style: GoogleFonts.ibmPlexSans(
                        color: secondaryText.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
        ),
      );
}
