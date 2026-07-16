import 'package:flutter/material.dart';

/// Victorian quarry-face palette for the Rift Reader canvas.
abstract final class RiftPalette {
  static const quarryShadow = Color(0xFF0A0C0B);
  static const cleavageBlue = Color(0xFF1A3A6A);
  static const fractureAmber = Color(0xFFD4680A);
  static const splitWhite = Color(0xFFF0E8D8);
  static const graniteGrey = Color(0xFF3A4240);
  static const trierBrass = Color(0xFFC89A3A);

  static const sigmaInfinity = 1.0;
  static const criticalKIc = 0.82;

  /// Faster expansion — rings feel massive, transmit the shock of metal on stone.
  static const soundSpeedScale = 55.0;

  /// Rings travel far enough to reach distant crack tips.
  static const impulseMaxRadius = 220.0;

  /// Heatmap grid cell size in logical pixels — smaller = crisper, less blocky.
  static const heatmapGridStep = 10.0;
}
