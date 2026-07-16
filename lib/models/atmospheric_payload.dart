import 'package:telemetry_of_the_high_wind/enum/payload_enums.dart';

class AtmosphericPayload {
  const AtmosphericPayload({
    required this.id,
    required this.sondeTrackingIndex,
    required this.classification,
    required this.artisanHallmark,
    required this.frequencyMhz,
    required this.barometricSensorProfile,
    required this.batteryChemistry,
    required this.enclosureMaterial,
    required this.physicalProportions,
    required this.preservationSoundness,
    required this.preservationNotes,
    required this.groundZero,
    required this.era,
    required this.temperatureRange,
    required this.calibrationSite,
    required this.atmosphericLayer,
    required this.designAltitudeKm,
    required this.notes,
    required this.photoPath,
    required this.dateAdded,
  });

  final String id;
  final String sondeTrackingIndex;
  final PayloadClassification classification;
  final String artisanHallmark;
  final double frequencyMhz;
  final String barometricSensorProfile;
  final String batteryChemistry;
  final String enclosureMaterial;
  final String physicalProportions;
  final PreservationSoundness preservationSoundness;
  final String preservationNotes;
  final String groundZero;
  final String era;
  final String temperatureRange;
  final String calibrationSite;
  final AtmosphericLayer atmosphericLayer;
  final double designAltitudeKm;
  final String notes;
  final String photoPath;
  final DateTime dateAdded;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sondeTrackingIndex': sondeTrackingIndex,
    'classification': classification.name,
    'artisanHallmark': artisanHallmark,
    'frequencyMhz': frequencyMhz,
    'barometricSensorProfile': barometricSensorProfile,
    'batteryChemistry': batteryChemistry,
    'enclosureMaterial': enclosureMaterial,
    'physicalProportions': physicalProportions,
    'preservationSoundness': preservationSoundness.name,
    'preservationNotes': preservationNotes,
    'groundZero': groundZero,
    'era': era,
    'temperatureRange': temperatureRange,
    'calibrationSite': calibrationSite,
    'atmosphericLayer': atmosphericLayer.name,
    'designAltitudeKm': designAltitudeKm,
    'notes': notes,
    'photoPath': photoPath,
    'dateAdded': dateAdded.toIso8601String(),
  };

  factory AtmosphericPayload.fromJson(Map<String, dynamic> json) {
    T enumValue<T extends Enum>(List<T> values, dynamic name, T fallback) =>
        values.where((value) => value.name == name).firstOrNull ?? fallback;
    return AtmosphericPayload(
      id: json['id'] as String? ?? '',
      sondeTrackingIndex: json['sondeTrackingIndex'] as String? ?? '',
      classification: enumValue(
        PayloadClassification.values,
        json['classification'],
        PayloadClassification.barosonde,
      ),
      artisanHallmark: json['artisanHallmark'] as String? ?? '',
      frequencyMhz: (json['frequencyMhz'] as num?)?.toDouble() ?? 403,
      barometricSensorProfile: json['barometricSensorProfile'] as String? ?? '',
      batteryChemistry: json['batteryChemistry'] as String? ?? '',
      enclosureMaterial: json['enclosureMaterial'] as String? ?? '',
      physicalProportions: json['physicalProportions'] as String? ?? '',
      preservationSoundness: enumValue(
        PreservationSoundness.values,
        json['preservationSoundness'],
        PreservationSoundness.displayOnly,
      ),
      preservationNotes: json['preservationNotes'] as String? ?? '',
      groundZero: json['groundZero'] as String? ?? '',
      era: json['era'] as String? ?? '',
      temperatureRange: json['temperatureRange'] as String? ?? '',
      calibrationSite: json['calibrationSite'] as String? ?? '',
      atmosphericLayer: enumValue(
        AtmosphericLayer.values,
        json['atmosphericLayer'],
        AtmosphericLayer.stratosphere,
      ),
      designAltitudeKm: (json['designAltitudeKm'] as num?)?.toDouble() ?? 30,
      notes: json['notes'] as String? ?? '',
      photoPath: json['photoPath'] as String? ?? '',
      dateAdded:
          DateTime.tryParse(json['dateAdded'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
