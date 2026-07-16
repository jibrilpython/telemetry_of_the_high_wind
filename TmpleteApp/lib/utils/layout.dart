import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Space occupied by the floating nav pill in [MainNavigation]:
/// bottom margin + bar height + breathing room.
double get bottomNavClearance => 24.h + 66.h + 12.h;

/// FAB lift so it sits clearly above the nav pill on all screen heights.
double get fabBottomClearance => bottomNavClearance + 12.h;

/// Scroll/content inset so the last row clears the FAB and nav.
double get homeScrollBottomInset => fabBottomClearance + 56.h;

/// Positions an end-aligned FAB above the overlay bottom nav.
class BottomNavEndFloatFabLocation extends FloatingActionButtonLocation {
  const BottomNavEndFloatFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    const margin = 16.0;
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final size = scaffoldGeometry.scaffoldSize;
    return Offset(
      size.width - fabSize.width - margin,
      size.height - fabSize.height - fabBottomClearance,
    );
  }
}
