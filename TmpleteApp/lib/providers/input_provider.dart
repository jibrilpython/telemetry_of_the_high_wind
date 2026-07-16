import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadows_on_the_quarry_wall/enum/my_enums.dart';

class InputNotifier extends ChangeNotifier {
  String _beddingPlaneIndex = '';
  ImplementationClass _implementationClass = ImplementationClass.plugAndFeatherSet;
  StoneType _stoneType = StoneType.granite;
  String _artisanHallmark = '';
  String _era = '';
  String _temperatureRange = '';
  String _calibrationSource = '';
  String _dimensionalCleavageCapacity = '';
  String _cuttingEdgeMetallurgy = '';
  String _templateGeometricPattern = '';
  String _chamberDimensionsAndMass = '';
  StructuralSoundness _structuralSoundness = StructuralSoundness.unknown;
  String _structuralSoundnessNotes = '';
  String _excavationGroundZero = '';
  String _notes = '';
  String _photoPath = '';
  List<String> _tags = [];
  DateTime _dateAdded = DateTime.now();

  String get beddingPlaneIndex => _beddingPlaneIndex;
  ImplementationClass get implementationClass => _implementationClass;
  StoneType get stoneType => _stoneType;
  String get artisanHallmark => _artisanHallmark;
  String get era => _era;
  String get temperatureRange => _temperatureRange;
  String get calibrationSource => _calibrationSource;
  String get dimensionalCleavageCapacity => _dimensionalCleavageCapacity;
  String get cuttingEdgeMetallurgy => _cuttingEdgeMetallurgy;
  String get templateGeometricPattern => _templateGeometricPattern;
  String get chamberDimensionsAndMass => _chamberDimensionsAndMass;
  StructuralSoundness get structuralSoundness => _structuralSoundness;
  String get structuralSoundnessNotes => _structuralSoundnessNotes;
  String get excavationGroundZero => _excavationGroundZero;
  String get notes => _notes;
  String get photoPath => _photoPath;
  List<String> get tags => _tags;
  DateTime get dateAdded => _dateAdded;

  set beddingPlaneIndex(String v) { _beddingPlaneIndex = v; notifyListeners(); }
  set implementationClass(ImplementationClass v) { _implementationClass = v; notifyListeners(); }
  set stoneType(StoneType v) { _stoneType = v; notifyListeners(); }
  set artisanHallmark(String v) { _artisanHallmark = v; notifyListeners(); }
  set era(String v) { _era = v; notifyListeners(); }
  set temperatureRange(String v) { _temperatureRange = v; notifyListeners(); }
  set calibrationSource(String v) { _calibrationSource = v; notifyListeners(); }
  set dimensionalCleavageCapacity(String v) { _dimensionalCleavageCapacity = v; notifyListeners(); }
  set cuttingEdgeMetallurgy(String v) { _cuttingEdgeMetallurgy = v; notifyListeners(); }
  set templateGeometricPattern(String v) { _templateGeometricPattern = v; notifyListeners(); }
  set chamberDimensionsAndMass(String v) { _chamberDimensionsAndMass = v; notifyListeners(); }
  set structuralSoundness(StructuralSoundness v) { _structuralSoundness = v; notifyListeners(); }
  set structuralSoundnessNotes(String v) { _structuralSoundnessNotes = v; notifyListeners(); }
  set excavationGroundZero(String v) { _excavationGroundZero = v; notifyListeners(); }
  set notes(String v) { _notes = v; notifyListeners(); }
  set photoPath(String v) { _photoPath = v; notifyListeners(); }
  set tags(List<String> v) { _tags = v; notifyListeners(); }
  set dateAdded(DateTime v) { _dateAdded = v; notifyListeners(); }

  void clearAll() {
    _beddingPlaneIndex = '';
    _implementationClass = ImplementationClass.plugAndFeatherSet;
    _stoneType = StoneType.granite;
    _artisanHallmark = '';
    _era = '';
    _temperatureRange = '';
    _calibrationSource = '';
    _dimensionalCleavageCapacity = '';
    _cuttingEdgeMetallurgy = '';
    _templateGeometricPattern = '';
    _chamberDimensionsAndMass = '';
    _structuralSoundness = StructuralSoundness.unknown;
    _structuralSoundnessNotes = '';
    _excavationGroundZero = '';
    _notes = '';
    _photoPath = '';
    _tags = [];
    _dateAdded = DateTime.now();
    notifyListeners();
  }
}

final inputProvider = ChangeNotifierProvider<InputNotifier>((ref) => InputNotifier());
