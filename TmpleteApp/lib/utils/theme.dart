import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadows_on_the_quarry_wall/utils/const.dart';

final appTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: kAccent,
  scaffoldBackgroundColor: kBackground,
  colorScheme: const ColorScheme.light(
    primary: kAccent,
    secondary: kAccentAmber,
    surface: kPanelBg,
    onSurface: kPrimaryText,
    onPrimary: kPanelBg,
    error: kError,
    outline: kOutline,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    titleTextStyle: GoogleFonts.cormorantGaramond(
      fontSize: 28.sp,
      fontWeight: FontWeight.w600,
      color: kPrimaryText,
    ),
    iconTheme: const IconThemeData(color: kPrimaryText),
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.cormorantGaramond(fontSize: 46.sp, fontWeight: FontWeight.w600, color: kPrimaryText, height: 0.95),
    displayMedium: GoogleFonts.cormorantGaramond(fontSize: 36.sp, fontWeight: FontWeight.w600, color: kPrimaryText, height: 1.0),
    displaySmall: GoogleFonts.cormorantGaramond(fontSize: 28.sp, fontWeight: FontWeight.w600, color: kPrimaryText),
    headlineLarge: GoogleFonts.cormorantGaramond(fontSize: 26.sp, fontWeight: FontWeight.w600, color: kPrimaryText),
    headlineMedium: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w700, color: kPrimaryText),
    headlineSmall: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: kPrimaryText),
    titleLarge: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: kPrimaryText),
    titleMedium: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: kPrimaryText),
    titleSmall: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: kSecondaryText),
    bodyLarge: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w400, color: kPrimaryText, height: 1.5),
    bodyMedium: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w400, color: kPrimaryText, height: 1.5),
    bodySmall: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w400, color: kSecondaryText),
    labelLarge: GoogleFonts.ibmPlexMono(fontSize: 13.sp, fontWeight: FontWeight.w600, color: kPrimaryText, letterSpacing: 0.2),
    labelMedium: GoogleFonts.ibmPlexMono(fontSize: 12.sp, fontWeight: FontWeight.w500, color: kSecondaryText, letterSpacing: 0.2),
    labelSmall: GoogleFonts.ibmPlexMono(fontSize: 11.sp, fontWeight: FontWeight.w500, color: kSecondaryText, letterSpacing: 0.2),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kPanelBg,
    contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(kRadiusSmall)), borderSide: BorderSide(color: kOutline, width: 1)),
    enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(kRadiusSmall)), borderSide: BorderSide(color: kOutline, width: 1)),
    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(kRadiusSmall)), borderSide: BorderSide(color: kAccent, width: 1.5)),
    hintStyle: GoogleFonts.inter(color: kSecondaryText, fontSize: 14.sp, fontWeight: FontWeight.w400),
    labelStyle: GoogleFonts.inter(color: kSecondaryText, fontSize: 14.sp, fontWeight: FontWeight.w500),
  ),
  cardTheme: const CardThemeData(
    color: kPanelBg,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(kRadiusSmall)), side: BorderSide(color: kOutline, width: 1)),
    margin: EdgeInsets.zero,
  ),
  dividerTheme: const DividerThemeData(color: kOutline, thickness: 1.0, space: 0),
  useMaterial3: true,
);
