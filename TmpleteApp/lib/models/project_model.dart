import 'package:shadows_on_the_quarry_wall/enum/my_enums.dart';

class MasonryToolModel {
  String id;
  String beddingPlaneIndex;
  ImplementationClass implementationClass;
  StoneType stoneType;
  String artisanHallmark;
  String era;
  String temperatureRange;
  String calibrationSource;
  String dimensionalCleavageCapacity;
  String cuttingEdgeMetallurgy;
  String templateGeometricPattern;
  String chamberDimensionsAndMass;
  StructuralSoundness structuralSoundness;
  String structuralSoundnessNotes;
  String excavationGroundZero;
  String notes;
  String photoPath;
  List<String> tags;
  DateTime dateAdded;

  MasonryToolModel({
    required this.id,
    required this.beddingPlaneIndex,
    required this.implementationClass,
    required this.stoneType,
    required this.artisanHallmark,
    required this.era,
    required this.temperatureRange,
    required this.calibrationSource,
    required this.dimensionalCleavageCapacity,
    required this.cuttingEdgeMetallurgy,
    required this.templateGeometricPattern,
    required this.chamberDimensionsAndMass,
    required this.structuralSoundness,
    required this.structuralSoundnessNotes,
    required this.excavationGroundZero,
    required this.notes,
    required this.photoPath,
    required this.tags,
    required this.dateAdded,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'beddingPlaneIndex': beddingPlaneIndex,
        'implementationClass': implementationClass.name,
        'stoneType': stoneType.name,
        'artisanHallmark': artisanHallmark,
        'era': era,
        'temperatureRange': temperatureRange,
        'calibrationSource': calibrationSource,
        'dimensionalCleavageCapacity': dimensionalCleavageCapacity,
        'cuttingEdgeMetallurgy': cuttingEdgeMetallurgy,
        'templateGeometricPattern': templateGeometricPattern,
        'chamberDimensionsAndMass': chamberDimensionsAndMass,
        'structuralSoundness': structuralSoundness.name,
        'structuralSoundnessNotes': structuralSoundnessNotes,
        'excavationGroundZero': excavationGroundZero,
        'notes': notes,
        'photoPath': photoPath,
        'tags': tags,
        'dateAdded': dateAdded.toIso8601String(),
      };

  factory MasonryToolModel.fromJson(Map<String, dynamic> json) => MasonryToolModel(
        id: json['id'] ?? '',
        beddingPlaneIndex: json['beddingPlaneIndex'] ?? json['atmosphericIdentifier'] ?? '',
        implementationClass: ImplementationClass.values.asNameMap()[json['implementationClass'] ?? json['instrumentType']] ?? ImplementationClass.plugAndFeatherSet,
        stoneType: StoneType.values.asNameMap()[json['stoneType'] ?? json['movementType']] ?? StoneType.unknown,
        artisanHallmark: json['artisanHallmark'] ?? json['manufacturer'] ?? '',
        era: json['era'] ?? json['yearOfManufacture'] ?? '',
        temperatureRange: json['temperatureRange'] ?? json['measurementRange'] ?? '',
        calibrationSource: json['calibrationSource'] ?? json['countryOfManufacture'] ?? '',
        dimensionalCleavageCapacity: json['dimensionalCleavageCapacity'] ?? json['vaneConfiguration'] ?? '',
        cuttingEdgeMetallurgy: json['cuttingEdgeMetallurgy'] ?? json['materials'] ?? '',
        templateGeometricPattern: json['templateGeometricPattern'] ?? json['includedAccessories'] ?? '',
        chamberDimensionsAndMass: json['chamberDimensionsAndMass'] ?? json['dimensionsAndWeight'] ?? '',
        structuralSoundness: StructuralSoundness.values.asNameMap()[json['structuralSoundness'] ?? json['conditionState']] ?? StructuralSoundness.unknown,
        structuralSoundnessNotes: json['structuralSoundnessNotes'] ?? json['markingsAndStamps'] ?? '',
        excavationGroundZero: json['excavationGroundZero'] ?? json['provenance'] ?? '',
        notes: json['notes'] ?? '',
        photoPath: json['photoPath'] ?? '',
        tags: List<String>.from(json['tags'] ?? []),
        dateAdded: DateTime.tryParse(json['dateAdded'] ?? '') ?? DateTime.now(),
      );
}
