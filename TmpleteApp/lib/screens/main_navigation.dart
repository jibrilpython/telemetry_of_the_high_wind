import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadows_on_the_quarry_wall/screens/compare_screen.dart';
import 'package:shadows_on_the_quarry_wall/screens/home_screen.dart';
import 'package:shadows_on_the_quarry_wall/screens/showcase_screen.dart';
import 'package:shadows_on_the_quarry_wall/screens/stats_screen.dart';
import 'package:shadows_on_the_quarry_wall/utils/const.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _setIndex(int i) {
    if (i == _currentIndex) return;
    setState(() => _currentIndex = i);
    _animController.forward(from: 0);
  }

  Widget _screenAt(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return ShowcaseScreen(isActive: _currentIndex == 1);
      case 2:
        return const StatsScreen();
      case 3:
        return const CompareScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: List.generate(4, _screenAt),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomNav()),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h, left: 18.w, right: 18.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusPill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 66.h,
            decoration: BoxDecoration(
              color: kPrimaryText.withAlpha(232),
              borderRadius: BorderRadius.circular(kRadiusPill),
              border: Border.all(color: Colors.white.withAlpha(25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.view_agenda_outlined, 'Quarry'),
                _buildNavItem(1, Icons.polyline_outlined, 'Rift Reader'),
                _buildNavItem(2, Icons.analytics_outlined, 'Logbook'),
                _buildNavItem(3, Icons.compare_arrows_rounded, 'Compare'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _setIndex(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 78.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withAlpha(135),
              size: 21.sp,
            ),
            SizedBox(height: 4.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white.withAlpha(135),
                fontSize: 9.5.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label, maxLines: 1),
            ),
            SizedBox(height: 4.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isSelected ? 22.w : 0,
              height: 3.h,
              decoration: BoxDecoration(
                color: kAccentLight,
                borderRadius: BorderRadius.circular(kRadiusPill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
