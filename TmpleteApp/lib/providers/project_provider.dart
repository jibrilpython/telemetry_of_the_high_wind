import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:shadows_on_the_quarry_wall/models/project_model.dart';
import 'package:shadows_on_the_quarry_wall/providers/image_provider.dart';
import 'package:shadows_on_the_quarry_wall/providers/input_provider.dart';

class ProjectNotifier extends ChangeNotifier {
  ProjectNotifier() { loadEntries(); }

  List<MasonryToolModel> entries = [];
  bool isLoading = true;
  static const String _storageKey = 'sqw_masonry_tools_v1';
  final _uuid = const Uuid();
  final _rng = Random();

  Future<void> loadEntries() async {
    isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> decodedList = jsonDecode(jsonString);
        entries = decodedList.map((item) => MasonryToolModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading masonry tools: $e');
      entries = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  String _ledgerCode(InputNotifier p) {
    final manual = p.beddingPlaneIndex.trim();
    if (manual.isNotEmpty) return manual;
    final classCode = p.implementationClass.name.replaceAll(RegExp(r'[^A-Z]'), '').padRight(4, 'X').substring(0, 4).toUpperCase();
    final stoneCode = p.stoneType.name.padRight(4, 'x').substring(0, 4).toUpperCase();
    final checksum = 1000 + _rng.nextInt(9000);
    return 'SQW-STONE-$checksum-$stoneCode-$classCode';
  }

  MasonryToolModel _fromInput(WidgetRef ref, {String? id, String? existingPhoto, DateTime? dateAdded}) {
    final p = ref.read(inputProvider);
    final imgProv = ref.read(imageProvider);
    return MasonryToolModel(
      id: id ?? _uuid.v4(),
      beddingPlaneIndex: _ledgerCode(p),
      implementationClass: p.implementationClass,
      stoneType: p.stoneType,
      artisanHallmark: p.artisanHallmark,
      era: p.era,
      temperatureRange: p.temperatureRange,
      calibrationSource: p.calibrationSource,
      dimensionalCleavageCapacity: p.dimensionalCleavageCapacity,
      cuttingEdgeMetallurgy: p.cuttingEdgeMetallurgy,
      templateGeometricPattern: p.templateGeometricPattern,
      chamberDimensionsAndMass: p.chamberDimensionsAndMass,
      structuralSoundness: p.structuralSoundness,
      structuralSoundnessNotes: p.structuralSoundnessNotes,
      excavationGroundZero: p.excavationGroundZero,
      notes: p.notes,
      photoPath: imgProv.resultImage.isNotEmpty ? imgProv.resultImage : (existingPhoto ?? p.photoPath),
      tags: List<String>.from(p.tags),
      dateAdded: dateAdded ?? p.dateAdded,
    );
  }

  void addEntry(WidgetRef ref) {
    entries.add(_fromInput(ref));
    _save();
    notifyListeners();
  }

  void editEntry(WidgetRef ref, int index) {
    final existing = entries[index];
    entries[index] = _fromInput(ref, id: existing.id, existingPhoto: existing.photoPath, dateAdded: existing.dateAdded);
    _save();
    notifyListeners();
  }

  void deleteEntry(int index) {
    entries.removeAt(index);
    _save();
    notifyListeners();
  }

  void fillInput(WidgetRef ref, int index) {
    final p = ref.read(inputProvider);
    final imgProv = ref.read(imageProvider);
    final entry = entries[index];
    p.beddingPlaneIndex = entry.beddingPlaneIndex;
    p.implementationClass = entry.implementationClass;
    p.stoneType = entry.stoneType;
    p.artisanHallmark = entry.artisanHallmark;
    p.era = entry.era;
    p.temperatureRange = entry.temperatureRange;
    p.calibrationSource = entry.calibrationSource;
    p.dimensionalCleavageCapacity = entry.dimensionalCleavageCapacity;
    p.cuttingEdgeMetallurgy = entry.cuttingEdgeMetallurgy;
    p.templateGeometricPattern = entry.templateGeometricPattern;
    p.chamberDimensionsAndMass = entry.chamberDimensionsAndMass;
    p.structuralSoundness = entry.structuralSoundness;
    p.structuralSoundnessNotes = entry.structuralSoundnessNotes;
    p.excavationGroundZero = entry.excavationGroundZero;
    p.notes = entry.notes;
    p.photoPath = entry.photoPath;
    p.tags = List<String>.from(entry.tags);
    p.dateAdded = entry.dateAdded;
    imgProv.resultImage = entry.photoPath;
    notifyListeners();
  }
}

final projectProvider = ChangeNotifierProvider<ProjectNotifier>((ref) => ProjectNotifier());
