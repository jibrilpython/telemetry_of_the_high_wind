import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:telemetry_of_the_high_wind/enum/payload_enums.dart';
import 'package:telemetry_of_the_high_wind/models/atmospheric_payload.dart';

class InputNotifier extends ChangeNotifier {
  String sondeTrackingIndex = '';
  PayloadClassification classification = PayloadClassification.barosonde;
  String artisanHallmark = '';
  double frequencyMhz = 403;
  String barometricSensorProfile = '';
  String batteryChemistry = '';
  String enclosureMaterial = '';
  String physicalProportions = '';
  PreservationSoundness preservationSoundness = PreservationSoundness.complete;
  String preservationNotes = '';
  String groundZero = '';
  String era = '';
  String temperatureRange = '';
  String calibrationSite = '';
  AtmosphericLayer atmosphericLayer = AtmosphericLayer.stratosphere;
  double designAltitudeKm = 30;
  String notes = '';
  String photoPath = '';

  void changed() => notifyListeners();

  void clear() {
    sondeTrackingIndex = '';
    classification = PayloadClassification.barosonde;
    artisanHallmark = '';
    frequencyMhz = 403;
    barometricSensorProfile = '';
    batteryChemistry = '';
    enclosureMaterial = '';
    physicalProportions = '';
    preservationSoundness = PreservationSoundness.complete;
    preservationNotes = '';
    groundZero = '';
    era = '';
    temperatureRange = '';
    calibrationSite = '';
    atmosphericLayer = AtmosphericLayer.stratosphere;
    designAltitudeKm = 30;
    notes = '';
    photoPath = '';
    notifyListeners();
  }

  void fill(AtmosphericPayload payload) {
    sondeTrackingIndex = payload.sondeTrackingIndex;
    classification = payload.classification;
    artisanHallmark = payload.artisanHallmark;
    frequencyMhz = payload.frequencyMhz;
    barometricSensorProfile = payload.barometricSensorProfile;
    batteryChemistry = payload.batteryChemistry;
    enclosureMaterial = payload.enclosureMaterial;
    physicalProportions = payload.physicalProportions;
    preservationSoundness = payload.preservationSoundness;
    preservationNotes = payload.preservationNotes;
    groundZero = payload.groundZero;
    era = payload.era;
    temperatureRange = payload.temperatureRange;
    calibrationSite = payload.calibrationSite;
    atmosphericLayer = payload.atmosphericLayer;
    designAltitudeKm = payload.designAltitudeKm;
    notes = payload.notes;
    photoPath = payload.photoPath;
    notifyListeners();
  }
}

final inputProvider = ChangeNotifierProvider<InputNotifier>(
  (ref) => InputNotifier(),
);

class ProjectNotifier extends ChangeNotifier {
  ProjectNotifier() {
    load();
  }

  static const _storageKey = 'thw_atmospheric_payloads_v1';
  final _uuid = const Uuid();
  final _random = Random();
  List<AtmosphericPayload> entries = [];
  bool isLoading = true;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null) {
        entries = (jsonDecode(data) as List)
            .map(
              (value) => AtmosphericPayload.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList();
      }
    } catch (error) {
      debugPrint('Payload archive load failed: $error');
      entries = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _generatedIndex(InputNotifier input) {
    if (input.sondeTrackingIndex.trim().isNotEmpty) {
      return input.sondeTrackingIndex.trim().toUpperCase();
    }
    final code = input.classification.name
        .replaceAll(RegExp('[^A-Z]'), '')
        .padRight(3, 'X')
        .substring(0, 3)
        .toUpperCase();
    return 'THW-SONDE-${1100 + _random.nextInt(8900)}-MET-$code';
  }

  AtmosphericPayload _fromInput(
    InputNotifier input, {
    String? id,
    DateTime? dateAdded,
  }) => AtmosphericPayload(
    id: id ?? _uuid.v4(),
    sondeTrackingIndex: _generatedIndex(input),
    classification: input.classification,
    artisanHallmark: input.artisanHallmark.trim(),
    frequencyMhz: input.frequencyMhz,
    barometricSensorProfile: input.barometricSensorProfile.trim(),
    batteryChemistry: input.batteryChemistry.trim(),
    enclosureMaterial: input.enclosureMaterial.trim(),
    physicalProportions: input.physicalProportions.trim(),
    preservationSoundness: input.preservationSoundness,
    preservationNotes: input.preservationNotes.trim(),
    groundZero: input.groundZero.trim(),
    era: input.era.trim(),
    temperatureRange: input.temperatureRange.trim(),
    calibrationSite: input.calibrationSite.trim(),
    atmosphericLayer: input.atmosphericLayer,
    designAltitudeKm: input.designAltitudeKm,
    notes: input.notes.trim(),
    photoPath: input.photoPath,
    dateAdded: dateAdded ?? DateTime.now(),
  );

  Future<void> save(InputNotifier input, {int? index}) async {
    if (index == null) {
      entries.insert(0, _fromInput(input));
    } else {
      final old = entries[index];
      entries[index] = _fromInput(input, id: old.id, dateAdded: old.dateAdded);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> delete(int index) async {
    entries.removeAt(index);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}

final projectProvider = ChangeNotifierProvider<ProjectNotifier>(
  (ref) => ProjectNotifier(),
);

class UserNotifier extends ChangeNotifier {
  UserNotifier() {
    load();
  }

  static const _key = 'thw_onboarding_complete';
  bool firstTimeUser = true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    firstTimeUser = !(prefs.getBool(_key) ?? false);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    firstTimeUser = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    notifyListeners();
  }
}

final userProvider = ChangeNotifierProvider<UserNotifier>(
  (ref) => UserNotifier(),
);
