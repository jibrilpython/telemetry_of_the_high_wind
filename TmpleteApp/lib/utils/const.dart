import 'package:flutter/material.dart';
import 'package:shadows_on_the_quarry_wall/enum/my_enums.dart';

const Color kBackground = Color(0xFFF3F1ED);
const Color kPrimaryText = Color(0xFF181614);
const Color kPanelBg = Color(0xFFFFFFFF);
const Color kSecondaryText = Color(0xFF7A7670);
const Color kAccent = Color(0xFF5C4E3A);
const Color kOutline = Color(0xFFE6E2DB);
const Color kAccentAmber = Color(0xFF6B7A5E);
const Color kError = Color(0xFFC0392B);
const Color kAccentLight = Color(0xFF8A765A);
const Color kAccentSurface = Color(0x1F5C4E3A);
const Color kGlassBackground = Color(0xE6FFFFFF);
const Color kSuccess = Color(0xFF6B7A5E);
const Color kWarning = Color(0xFF9B6A32);

const double kSpacingXXS = 4.0;
const double kSpacingXS = 8.0;
const double kSpacingS = 12.0;
const double kSpacingM = 16.0;
const double kSpacingL = 20.0;
const double kSpacingXL = 24.0;
const double kSpacingXXL = 32.0;
const double kSpacingXXXL = 48.0;
const double kRadiusZero = 0.0;
const double kRadiusSmall = 10.0;
const double kRadiusSubtle = 14.0;
const double kRadiusStandard = 18.0;
const double kRadiusMedium = 24.0;
const double kRadiusLarge = 32.0;
const double kRadiusXLarge = 40.0;
const double kRadiusPill = 999.0;

const BoxShadow kShadowSubtle = BoxShadow(
  offset: Offset(0, 8),
  blurRadius: 22,
  spreadRadius: -14,
  color: Color(0x24181614),
);
const BoxShadow kShadowFloat = BoxShadow(
  offset: Offset(0, 16),
  blurRadius: 34,
  spreadRadius: -18,
  color: Color(0x33181614),
);
const double kStrokeWeight = 1.0;
const double kStrokeWeightMedium = 1.5;

Color getImplementationClassColor(ImplementationClass type) {
  switch (type) {
    case ImplementationClass.plugAndFeatherSet:
      return kAccent;
    case ImplementationClass.tracingChisel:
      return const Color(0xFF705D42);
    case ImplementationClass.coreBoringRig:
      return const Color(0xFF3E4650);
    case ImplementationClass.moldingTemplate:
      return const Color(0xFF6B7A5E);
    case ImplementationClass.levelingArc:
      return const Color(0xFF8B6B3E);
    case ImplementationClass.profileGauge:
      return const Color(0xFF59665A);
    case ImplementationClass.other:
      return kSecondaryText;
  }
}

Color getStoneTypeColor(StoneType type) {
  switch (type) {
    case StoneType.granite:
      return const Color(0xFF5F6261);
    case StoneType.limestone:
      return const Color(0xFF9A907F);
    case StoneType.marble:
      return const Color(0xFFB7AEA2);
    case StoneType.sandstone:
      return const Color(0xFFA06B3F);
    case StoneType.slate:
      return const Color(0xFF4E5661);
    case StoneType.basalt:
      return const Color(0xFF262625);
    case StoneType.unknown:
      return kSecondaryText;
  }
}

Color getStructuralSoundnessColor(StructuralSoundness state) {
  switch (state) {
    case StructuralSoundness.operational:
      return kAccent;
    case StructuralSoundness.displayOnly:
      return kAccentAmber;
    case StructuralSoundness.edgeDulling:
      return kWarning;
    case StructuralSoundness.mushrooming:
      return const Color(0xFF8B5A2B);
    case StructuralSoundness.microFracture:
      return kError;
    case StructuralSoundness.unknown:
      return kSecondaryText;
  }
}
