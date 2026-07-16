import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadows_on_the_quarry_wall/models/project_model.dart';

class SearchNotifier extends ChangeNotifier {
  String searchQuery = '';

  void setSearchQuery(String query) { searchQuery = query; notifyListeners(); }
  void clearSearchQuery() { searchQuery = ''; notifyListeners(); }

  List<MasonryToolModel> filteredList(List<MasonryToolModel> list) {
    if (searchQuery.isEmpty) return list;
    final query = searchQuery.toLowerCase();
    return list.where((item) =>
      item.beddingPlaneIndex.toLowerCase().contains(query) ||
      item.artisanHallmark.toLowerCase().contains(query) ||
      item.calibrationSource.toLowerCase().contains(query) ||
      item.dimensionalCleavageCapacity.toLowerCase().contains(query) ||
      item.cuttingEdgeMetallurgy.toLowerCase().contains(query) ||
      item.templateGeometricPattern.toLowerCase().contains(query) ||
      item.excavationGroundZero.toLowerCase().contains(query) ||
      item.era.toLowerCase().contains(query) ||
      item.temperatureRange.toLowerCase().contains(query) ||
      item.tags.any((tag) => tag.toLowerCase().contains(query))
    ).toList();
  }
}

final searchProvider = ChangeNotifierProvider((ref) => SearchNotifier());
