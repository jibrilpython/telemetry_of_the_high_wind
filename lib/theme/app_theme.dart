import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

const background = Color(0xFF060A08);
const panel = Color(0xFF0C100E);
const panelRaised = Color(0xFF101713);
const primaryText = Color(0xFFE0EDE4);
const secondaryText = Color(0xFF718079);
const radarGreen = Color(0xFF2A8A4A);
const stratosphereBlue = Color(0xFF5A8AAA);
const outline = Color(0xFF1B241F);
const critical = Color(0xFFC0392B);

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: radarGreen,
      secondary: stratosphereBlue,
      surface: panel,
      onSurface: primaryText,
      error: critical,
      outline: outline,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        color: primaryText,
        fontSize: 46,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        color: primaryText,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        color: primaryText,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        color: primaryText,
        fontSize: 21,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        color: primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.ibmPlexSans(
        color: primaryText,
        fontSize: 15,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.ibmPlexSans(
        color: primaryText,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.ibmPlexSans(
        color: secondaryText,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.ibmPlexMono(
        color: primaryText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.ibmPlexMono(color: secondaryText, fontSize: 11),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        color: primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: panel,
      indicatorColor: radarGreen.withValues(alpha: .16),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.ibmPlexMono(fontSize: 10, color: primaryText),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: panel,
      labelStyle: GoogleFonts.ibmPlexSans(color: secondaryText),
      hintStyle: GoogleFonts.ibmPlexSans(color: secondaryText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: radarGreen, width: 1.5),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: panel,
      selectedColor: radarGreen.withValues(alpha: .18),
      side: const BorderSide(color: outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      labelStyle: GoogleFonts.ibmPlexMono(color: primaryText, fontSize: 11),
    ),
    cardTheme: CardThemeData(
      color: panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: outline),
      ),
    ),
    dividerColor: outline,
  );
}
