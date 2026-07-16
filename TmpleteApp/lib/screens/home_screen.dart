import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadows_on_the_quarry_wall/common/tool_elevation_painter.dart';
import 'package:shadows_on_the_quarry_wall/enum/my_enums.dart';
import 'package:shadows_on_the_quarry_wall/models/project_model.dart';
import 'package:shadows_on_the_quarry_wall/providers/image_provider.dart';
import 'package:shadows_on_the_quarry_wall/providers/input_provider.dart';
import 'package:shadows_on_the_quarry_wall/providers/project_provider.dart';
import 'package:shadows_on_the_quarry_wall/providers/search_provider.dart';
import 'package:shadows_on_the_quarry_wall/utils/const.dart';
import 'package:shadows_on_the_quarry_wall/utils/layout.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  StoneType? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectProv = ref.watch(projectProvider);
    final allEntries = projectProv.entries;
    final filteredByStone = _selectedFilter == null
        ? allEntries
        : allEntries.where((e) => e.stoneType == _selectedFilter).toList();
    final entries = ref.watch(searchProvider).filteredList(filteredByStone);

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildLedgerHeader(allEntries.length)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
              child: Column(
                children: [
                  _buildSearchField(),
                  SizedBox(height: 12.h),
                  _buildStoneFilters(),
                ],
              ),
            ),
          ),
          if (entries.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, homeScrollBottomInset),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                childCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final mainIndex = ref.read(projectProvider).entries.indexOf(entry);
                  return _MasonryToolCard(
                    entry: entry,
                    index: mainIndex,
                    tall: index % 3 == 0,
                    wideAccent: index % 5 == 0,
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: _buildRecordFab(),
      floatingActionButtonLocation: const BottomNavEndFloatFabLocation(),
    );
  }

  Widget _buildLedgerHeader(int count) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 52.h, 16.w, 8.h),
      padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 18.h),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(color: kOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 3.w,
                height: 52.h,
                color: kAccent,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DRAWING OFFICE — LEDGER SHEET',
                      style: GoogleFonts.ibmPlexMono(
                        color: kSecondaryText,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Shadows on the Quarry Wall',
                      style: GoogleFonts.cormorantGaramond(
                        color: kPrimaryText,
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SPECIMENS',
                    style: GoogleFonts.ibmPlexMono(
                      color: kSecondaryText,
                      fontSize: 8.sp,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    count.toString().padLeft(3, '0'),
                    style: GoogleFonts.ibmPlexMono(
                      color: kAccent,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(height: 1, color: kOutline),
          // SizedBox(height: 10.h),
          // Row(
          //   children: [
          //     _headerMeta('SHEET', 'SQW-ARCHIVE'),
          //     SizedBox(width: 20.w),
          //     _headerMeta('SCALE', '1:1 FIELD'),
          //     const Spacer(),
          //     Text(
          //       'QUARRY INDEX',
          //       style: GoogleFonts.ibmPlexMono(
          //         color: kAccentAmber,
          //         fontSize: 9.sp,
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  // Widget _headerMeta(String label, String value) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: GoogleFonts.ibmPlexMono(
  //           color: kSecondaryText,
  //           fontSize: 8.sp,
  //           letterSpacing: 0.8,
  //         ),
  //       ),
  //       Text(
  //         value,
  //         style: GoogleFonts.ibmPlexMono(
  //           color: kPrimaryText,
  //           fontSize: 10.sp,
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSearchField() {
    final focused = _searchFocusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      // padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      padding: EdgeInsets.only(left: 14.w, right: 8.w, top: 8.h, bottom: 8.h),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(
          color: focused ? kAccent : kOutline,
          width: focused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18.sp, color: focused ? kAccent : kSecondaryText),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: ref.read(searchProvider.notifier).setSearchQuery,
              style: GoogleFonts.inter(fontSize: 14.sp, color: kPrimaryText),
              decoration: InputDecoration(
                hintText: 'Hallmark, ledger code, quarry site…',
                hintStyle: GoogleFonts.inter(color: kSecondaryText, fontSize: 13.sp),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.fromLTRB(6.w, 10.h, 0, 10.h),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                ref.read(searchProvider.notifier).clearSearchQuery();
              },
              child: Icon(Icons.close, size: 16.sp, color: kSecondaryText),
            ),
        ],
      ),
    );
  }

  Widget _buildStoneFilters() {
    return SizedBox(
      height: 36.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _stoneChip('All stone', null),
          ...StoneType.values
              .where((s) => s != StoneType.unknown)
              .map((s) => _stoneChip(s.label, s)),
        ],
      ),
    );
  }

  Widget _stoneChip(String label, StoneType? type) {
    final selected = _selectedFilter == type;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: selected ? kAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(kRadiusPill),
            border: Border.all(color: selected ? kAccent : kOutline),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : kSecondaryText,
              fontSize: 11.sp,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordFab() {
    return FloatingActionButton.extended(
      onPressed: () {
        ref.read(inputProvider).clearAll();
        ref.read(imageProvider).clearImage();
        Navigator.pushNamed(context, '/add_screen');
      },
      backgroundColor: kAccent,
      elevation: 0,
      icon: Icon(Icons.add, color: Colors.white, size: 20.sp),
      label: Text(
        'Record tool',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13.sp,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80.w,
            height: 80.w,
            child: CustomPaint(
              size: Size(80.w, 80.w),
              painter: _EmptyStateIconPainter(color: kOutline),
            ),
          ),
          SizedBox(height: 28.h),
          Text(
            'NO TOOLS IN THIS QUARRY YET.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexMono(
              color: kSecondaryText,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateIconPainter extends CustomPainter {
  final Color color;

  _EmptyStateIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    canvas.drawCircle(
      Offset(cx, cy), w / 2 - 0.5, Paint()..color = color.withAlpha(10));
    canvas.drawCircle(
      Offset(cx, cy), w / 2 - 0.5, Paint()
        ..color = color.withAlpha(25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0);

    _drawTool(canvas, w, h);
  }

  void _drawTool(Canvas canvas, double w, double h) {
    final cx = w / 2;
    final gap = w * 0.048;
    final topW = w * 0.13;
    final botW = w * 0.20;
    final yT = h * 0.22;
    final yB = h * 0.75;

    // Left wedge
    final lx1 = cx - gap / 2 - topW;
    final lx2 = cx - gap / 2;
    final lx3 = cx - gap / 2 + (botW - topW) * 0.35;
    final lx4 = cx - gap / 2 - botW;

    _drawWedge(canvas, [
      Offset(lx1, yT), Offset(lx2, yT), Offset(lx3, yB), Offset(lx4, yB),
    ]);

    // Right wedge
    final rx1 = cx + gap / 2;
    final rx2 = cx + gap / 2 + topW;
    final rx3 = cx + gap / 2 + botW;
    final rx4 = cx + gap / 2 - (botW - topW) * 0.35;

    _drawWedge(canvas, [
      Offset(rx1, yT), Offset(rx2, yT), Offset(rx3, yB), Offset(rx4, yB),
    ]);

    // Feather line
    canvas.drawLine(
      Offset(cx, yT - h * 0.05),
      Offset(cx, yB + h * 0.05),
      Paint()
        ..color = color
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(cx + 1.5, yT - h * 0.04),
      Offset(cx + 1.5, yB + h * 0.04),
      Paint()
        ..color = Colors.white.withAlpha(55)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );


  }

  void _drawWedge(Canvas canvas, List<Offset> pts) {
    final path = Path()..addPolygon(pts, true);

    // Front face
    canvas.drawPath(path, Paint()..color = color);

    // Bold outline
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round);

    // Top striking surface (shows 3D thickness)
    final topPath = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[1].dx - 2.5, pts[1].dy - 4)
      ..lineTo(pts[0].dx + 2.5, pts[0].dy - 4)
      ..close();
    canvas.drawPath(topPath, Paint()..color = color.withAlpha(150));
    canvas.drawPath(topPath, Paint()
      ..color = color.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);

    // Highlight on outer edge
    final isLeft = pts[0].dx < pts[1].dx;
    canvas.drawLine(
      Offset(pts[0].dx + (isLeft ? 1.5 : 0), pts[0].dy + 3),
      Offset(pts[3].dx + (isLeft ? 1.5 : 0), pts[3].dy - 3),
      Paint()
        ..color = Colors.white.withAlpha(65)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _EmptyStateIconPainter old) => old.color != color;
}

class _MasonryToolCard extends ConsumerWidget {
  final MasonryToolModel entry;
  final int index;
  final bool tall;
  final bool wideAccent;

  const _MasonryToolCard({
    required this.entry,
    required this.index,
    required this.tall,
    required this.wideAccent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageProv = ref.watch(imageProvider);
    final imagePath = imageProv.getImagePath(entry.photoPath);
    final hasPhoto = entry.photoPath.isNotEmpty &&
        imagePath != null &&
        File(imagePath).existsSync();
    final operational =
        entry.structuralSoundness == StructuralSoundness.operational;
    final silhouetteColor = operational ? kAccent : kAccentAmber;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/info_screen',
        arguments: {'index': index},
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        decoration: BoxDecoration(
          color: kPanelBg,
          borderRadius: BorderRadius.circular(kRadiusSmall),
          border: Border.all(color: kOutline),
          boxShadow: wideAccent ? const [kShadowSubtle] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: tall ? 130.h : (hasPhoto ? 100.h : 72.h),
                decoration: BoxDecoration(
                  color: kBackground,
                  border: Border(bottom: BorderSide(color: kOutline.withAlpha(180))),
                ),
                child: hasPhoto
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(imagePath), fit: BoxFit.cover),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 3.w, color: silhouetteColor),
                          ),
                        ],
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size(48.w, 48.w),
                            painter: ToolElevationPainter(
                              toolClass: entry.implementationClass,
                              color: silhouetteColor,
                              operational: operational,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 3.w, color: silhouetteColor),
                          ),
                        ],
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.beddingPlaneIndex.isNotEmpty
                          ? entry.beddingPlaneIndex
                          : 'UNASSIGNED',
                      style: GoogleFonts.ibmPlexMono(
                        color: kAccent,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      entry.artisanHallmark.isNotEmpty
                          ? entry.artisanHallmark
                          : 'Unknown hallmark',
                      style: GoogleFonts.cormorantGaramond(
                        color: kPrimaryText,
                        fontSize: tall ? 18.sp : 16.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.05,
                      ),
                      maxLines: tall ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      entry.implementationClass.label,
                      style: GoogleFonts.inter(
                        color: kSecondaryText,
                        fontSize: 10.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.dimensionalCleavageCapacity.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: kOutline),
                          borderRadius: BorderRadius.circular(kRadiusPill),
                        ),
                        child: Text(
                          entry.dimensionalCleavageCapacity,
                          style: GoogleFonts.ibmPlexMono(
                            color: kPrimaryText,
                            fontSize: 9.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (entry.excavationGroundZero.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: kAccentSurface,
                          borderRadius: BorderRadius.circular(kRadiusPill),
                        ),
                        child: Text(
                          entry.excavationGroundZero,
                          style: GoogleFonts.inter(
                            color: kAccent,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
