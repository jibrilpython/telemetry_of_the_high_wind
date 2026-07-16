import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageNotifier extends ChangeNotifier {
  ImageNotifier() {
    _initializeDocumentsPath();
  }

  String resultImage = '';
  String? _documentsPath;

  String? getImagePath(String storedPath) {
    if (_documentsPath == null || storedPath.isEmpty) return null;
    final fileName = storedPath.split('/').last;
    if (fileName.isEmpty) return null;
    return '$_documentsPath/$fileName';
  }

  Future<void> _initializeDocumentsPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    _documentsPath = appDir.path;
    notifyListeners();
  }

  Future<void> pickImage({required ImageSource source}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      if (_documentsPath == null) {
        await _initializeDocumentsPath();
      }
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fullPath = '${appDir.path}/$fileName';
      await File(pickedFile.path).copy(fullPath);
      resultImage = fullPath;
      notifyListeners();
    }
  }

  void clearImage() {
    resultImage = '';
    notifyListeners();
  }
}

final imageProvider = ChangeNotifierProvider<ImageNotifier>(
  (ref) => ImageNotifier(),
);
