import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadows_on_the_quarry_wall/models/project_model.dart';
import 'package:shadows_on_the_quarry_wall/providers/project_provider.dart';
import 'package:shadows_on_the_quarry_wall/utils/const.dart';

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  int? _leftIndex;
  int? _rightIndex;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(projectProvider).entries;

    return Scaffold(
      backgroundColor: kBackground,
      body: entries.length < 2
          ? _notEnoughSpecimens()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header()),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 130.h),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _slotRow(
                        label: 'Specimen A',
                        selectedIndex: _leftIndex,
                        entries: entries,
                        onSelect: (i) => setState(() => _leftIndex = i),
                      ),
                      SizedBox(height: 12.h),
                      _slotRow(
                        label: 'Specimen B',
                        selectedIndex: _rightIndex,
                        entries: entries,
                        onSelect: (i) => setState(() => _rightIndex = i),
                      ),
                      SizedBox(height: 20.h),
                      if (_leftIndex != null &&
                          _rightIndex != null &&
                          _leftIndex != _rightIndex)
                        _comparisonTable(
                          entries[_leftIndex!],
                          entries[_rightIndex!],
                        )
                      else
                        _awaitingPair(),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _notEnoughSpecimens() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows_rounded, color: kOutline, size: 48.sp),
            SizedBox(height: 16.h),
            Text(
              'Two specimens required',
              style: GoogleFonts.cormorantGaramond(
                color: kPrimaryText,
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Catalog at least two masonry tools to open the comparison bench.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: kSecondaryText, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 56.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMPARISON BENCH',
            style: GoogleFonts.ibmPlexMono(
              color: kSecondaryText,
              fontSize: 9.sp,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Side-by-side survey',
            style: GoogleFonts.cormorantGaramond(
              color: kPrimaryText,
              fontSize: 34.sp,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Select two specimens to contrast implementation class, metallurgy, era, and provenance.',
            style: GoogleFonts.inter(color: kSecondaryText, fontSize: 13.sp, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _slotRow({
    required String label,
    required int? selectedIndex,
    required List<MasonryToolModel> entries,
    required ValueChanged<int> onSelect,
  }) {
    final selected = selectedIndex != null ? entries[selectedIndex] : null;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(color: kOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              color: kAccent,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 10.h),
          if (selected != null) ...[
            Text(
              selected.artisanHallmark,
              style: GoogleFonts.cormorantGaramond(
                color: kPrimaryText,
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            Text(
              selected.beddingPlaneIndex,
              style: GoogleFonts.ibmPlexMono(color: kSecondaryText, fontSize: 10.sp),
            ),
          ] else
            Text(
              'No specimen selected',
              style: GoogleFonts.inter(color: kSecondaryText, fontSize: 13.sp),
            ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 38.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (context, index) => SizedBox(width: 8.w),
              itemBuilder: (context, i) {
                final e = entries[i];
                final isSel = selectedIndex == i;
                final blocked = (label == 'Specimen A' && _rightIndex == i) ||
                    (label == 'Specimen B' && _leftIndex == i);
                return GestureDetector(
                  onTap: blocked ? null : () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSel ? kAccent : (blocked ? kBackground : kPanelBg),
                      borderRadius: BorderRadius.circular(kRadiusPill),
                      border: Border.all(
                        color: isSel ? kAccent : kOutline,
                      ),
                    ),
                    child: Text(
                      e.artisanHallmark.isNotEmpty
                          ? e.artisanHallmark
                          : e.beddingPlaneIndex,
                      style: GoogleFonts.inter(
                        color: blocked
                            ? kSecondaryText.withAlpha(120)
                            : (isSel ? Colors.white : kPrimaryText),
                        fontSize: 11.sp,
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
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

  Widget _awaitingPair() {
    return Container(
      padding: EdgeInsets.all(24.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(color: kOutline),
      ),
      child: Text(
        'SELECT TWO DISTINCT SPECIMENS TO BEGIN COMPARISON.',
        textAlign: TextAlign.center,
        style: GoogleFonts.ibmPlexMono(color: kSecondaryText, fontSize: 11.sp),
      ),
    );
  }

  Widget _comparisonTable(MasonryToolModel left, MasonryToolModel right) {
    final rows = <_CompareRow>[
      _CompareRow('Implementation class', left.implementationClass.label, right.implementationClass.label),
      _CompareRow('Stone type', left.stoneType.label, right.stoneType.label),
      _CompareRow('Era', left.era, right.era),
      _CompareRow('Temperature range', left.temperatureRange, right.temperatureRange),
      _CompareRow('Calibration source', left.calibrationSource, right.calibrationSource),
      _CompareRow('Cleavage capacity', left.dimensionalCleavageCapacity, right.dimensionalCleavageCapacity),
      _CompareRow('Metallurgy', left.cuttingEdgeMetallurgy, right.cuttingEdgeMetallurgy),
      _CompareRow('Chamber & mass', left.chamberDimensionsAndMass, right.chamberDimensionsAndMass),
      _CompareRow('Soundness', left.structuralSoundness.label, right.structuralSoundness.label),
      _CompareRow('Ground zero', left.excavationGroundZero, right.excavationGroundZero),
    ];

    return Container(
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(color: kOutline),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: kOutline)),
              color: kBackground,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'FIELD',
                    style: GoogleFonts.ibmPlexMono(
                      color: kSecondaryText,
                      fontSize: 9.sp,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'A',
                    style: GoogleFonts.ibmPlexMono(
                      color: kAccent,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'B',
                    style: GoogleFonts.ibmPlexMono(
                      color: kAccentAmber,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...rows.map((row) {
            final differs = row.valueA.trim().toLowerCase() !=
                    row.valueB.trim().toLowerCase() &&
                row.valueA.isNotEmpty &&
                row.valueB.isNotEmpty;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: kOutline.withAlpha(150))),
                color: differs ? kAccentSurface.withAlpha(40) : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.label,
                      style: GoogleFonts.inter(
                        color: kSecondaryText,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.valueA.isEmpty ? '—' : row.valueA,
                      style: GoogleFonts.inter(
                        color: kPrimaryText,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.valueB.isEmpty ? '—' : row.valueB,
                      style: GoogleFonts.inter(
                        color: kPrimaryText,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CompareRow {
  final String label;
  final String valueA;
  final String valueB;
  const _CompareRow(this.label, this.valueA, this.valueB);
}
