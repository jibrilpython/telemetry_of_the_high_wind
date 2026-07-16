import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadows_on_the_quarry_wall/providers/user_provider.dart';
import 'package:shadows_on_the_quarry_wall/utils/const.dart';

class InitialScreen extends ConsumerWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProv = ref.watch(userProvider);
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          Positioned(
            top: -80.h,
            right: -60.w,
            child: Container(
              width: 280.w,
              height: 280.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAccent.withAlpha(12),
              ),
            ),
          ),
          Positioned(
            bottom: -120.h,
            left: -80.w,
            child: Container(
              width: 360.w,
              height: 360.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kOutline.withAlpha(60),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 40.h,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SQW.',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 48.sp,
                              color: kPrimaryText,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                              letterSpacing: -2.0,
                            ),
                          ),
                          SizedBox(height: 52.h),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shadows on\nthe Quarry\nWall.',
                                style: GoogleFonts.cormorantGaramond(
                                  color: kPrimaryText,
                                  fontSize: 52.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 0.95,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              Text(
                                'A drawing-office archive for wedges, boring drills, leveling arcs, and templates that shaped monumental stone.',
                                style: GoogleFonts.inter(
                                  color: kSecondaryText,
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 52.h),
                          GestureDetector(
                            onTap: () {
                              userProv.setFirstTimeUser(false);
                              Navigator.pushReplacementNamed(context, '/home');
                            },
                            child: Container(
                              width: double.infinity,
                              height: 60.h,
                              decoration: BoxDecoration(
                                color: kAccent,
                                borderRadius: BorderRadius.circular(kRadiusSmall),
                                boxShadow: [
                                  BoxShadow(
                                    color: kAccent.withAlpha(60),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                    spreadRadius: -4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Open the ledger',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Icon(
                                    Icons.architecture_rounded,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
