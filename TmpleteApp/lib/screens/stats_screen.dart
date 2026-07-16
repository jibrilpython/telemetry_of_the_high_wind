import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadows_on_the_quarry_wall/enum/my_enums.dart';
import 'package:shadows_on_the_quarry_wall/models/project_model.dart';
import 'package:shadows_on_the_quarry_wall/providers/project_provider.dart';
import 'package:shadows_on_the_quarry_wall/utils/const.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StructuralSoundness? _selectedSoundness;
  String? _selectedEra;

  @override
  Widget build(BuildContext context) {
    final projectProv = ref.watch(projectProvider);
    final entries = projectProv.entries;

    if (projectProv.isLoading) {
      return Scaffold(
        backgroundColor: kBackground,
        body: Center(
          child: SizedBox(
            width: 120.w,
            child: LinearProgressIndicator(
              color: kAccent,
              backgroundColor: kOutline,
              minHeight: 2.h,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      body: entries.isEmpty
          ? _emptyState()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _surveyHeader(entries.length)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 130.h),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _stoneStrataPanel(entries),
                      SizedBox(height: 14.h),
                      _implementationLedger(entries),
                      SizedBox(height: 14.h),
                      _soundnessSpectrum(entries),
                      SizedBox(height: 14.h),
                      _eraTimeline(entries),
                      SizedBox(height: 14.h),
                      _hallmarkRankings(entries),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _animatedCount(int target, {TextStyle? style}) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: target),
      duration: Duration(milliseconds: 600 + (target * 30).clamp(0, 800)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        '$value',
        style: style,
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.straighten_rounded, color: kOutline, size: 48.sp),
          SizedBox(height: 16.h),
          Text(
            'LOGBOOK AWAITS SPECIMENS',
            style: GoogleFonts.ibmPlexMono(color: kSecondaryText, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _surveyHeader(int count) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 56.h, 16.w, 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIELD SURVEY — LOGBOOK',
                  style: GoogleFonts.ibmPlexMono(
                    color: kSecondaryText,
                    fontSize: 9.sp,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Archive metrics',
                  style: GoogleFonts.cormorantGaramond(
                    color: kPrimaryText,
                    fontSize: 34.sp,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: kPanelBg,
              border: Border.all(color: kOutline),
              borderRadius: BorderRadius.circular(kRadiusSmall),
            ),
            child: Column(
              children: [
                Text(
                  'N',
                  style: GoogleFonts.ibmPlexMono(color: kSecondaryText, fontSize: 8.sp),
                ),
                _animatedCount(
                  count,
                  style: GoogleFonts.ibmPlexMono(
                    color: kAccent,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stoneStrataPanel(List<MasonryToolModel> entries) {
    final counts = <StoneType, int>{};
    for (final e in entries) {
      counts[e.stoneType] = (counts[e.stoneType] ?? 0) + 1;
    }
    final max = counts.values.fold(0, math.max);
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _panel(
      title: 'Stone strata',
      subtitle: 'Primary substrate each tool was engineered to work',
      child: Column(
        children: sorted.map((e) {
          final ratio = max == 0 ? 0.0 : e.value / max;
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key.label,
                        style: GoogleFonts.inter(
                          color: kPrimaryText,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _animatedCount(
                      e.value,
                      style: GoogleFonts.ibmPlexMono(
                        color: kSecondaryText,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(kRadiusPill),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8.h,
                    backgroundColor: kBackground,
                    color: getStoneTypeColor(e.key),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _implementationLedger(List<MasonryToolModel> entries) {
    final counts = <ImplementationClass, int>{};
    for (final e in entries) {
      counts[e.implementationClass] = (counts[e.implementationClass] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _panel(
      title: 'Implementation ledger',
      subtitle: 'Tool classes represented in the quarry archive',
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: sorted.map((e) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: getImplementationClassColor(e.key).withAlpha(22),
              borderRadius: BorderRadius.circular(kRadiusSmall),
              border: Border.all(
                color: getImplementationClassColor(e.key).withAlpha(90),
              ),
            ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.key.label,
                      style: GoogleFonts.inter(
                        color: kPrimaryText,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '×',
                          style: GoogleFonts.ibmPlexMono(
                            color: getImplementationClassColor(e.key),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        _animatedCount(
                          e.value,
                          style: GoogleFonts.ibmPlexMono(
                            color: getImplementationClassColor(e.key),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          );
        }).toList(),
      ),
    );
  }

  Widget _soundnessSpectrum(List<MasonryToolModel> entries) {
    final counts = <StructuralSoundness, int>{};
    for (final e in entries) {
      counts[e.structuralSoundness] = (counts[e.structuralSoundness] ?? 0) + 1;
    }
    final max = counts.values.fold(0, math.max);

    return _panel(
      title: 'Structural soundness spectrum',
      subtitle: 'Condition distribution across catalogued specimens',
      child: Column(
        children: [
          SizedBox(
            height: 160.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: StructuralSoundness.values.map((state) {
                final value = counts[state] ?? 0;
                final heightFactor = max == 0 ? 0.12 : (value / max).clamp(0.12, 1.0);
                final isSelected = _selectedSoundness == state;
                final hasTools = value > 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: hasTools ? () {
                      setState(() {
                        _selectedSoundness =
                            _selectedSoundness == state ? null : state;
                      });
                    } : null,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _animatedCount(
                            value,
                            style: GoogleFonts.ibmPlexMono(
                              color: kSecondaryText,
                              fontSize: 10.sp,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                            height: 100.h * heightFactor,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? getStructuralSoundnessColor(state)
                                  : getStructuralSoundnessColor(state).withAlpha(180),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(6.r),
                              ),
                              border: isSelected
                                  ? Border.all(
                                      color: getStructuralSoundnessColor(state),
                                      width: 2,
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            state.label.split(' ').first,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? getStructuralSoundnessColor(state)
                                  : kSecondaryText,
                              fontSize: 8.sp,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _selectedSoundness != null
                ? _soundnessDetail(entries, _selectedSoundness!)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _soundnessDetail(
      List<MasonryToolModel> entries, StructuralSoundness state) {
    final tools = entries
        .where((e) => e.structuralSoundness == state)
        .toList();
    final color = getStructuralSoundnessColor(state);

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(kRadiusSmall),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility_rounded,
                    size: 14.sp, color: color),
                SizedBox(width: 6.w),
                Text(
                  state.label,
                  style: GoogleFonts.ibmPlexMono(
                    color: color,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${tools.length} specimen${tools.length == 1 ? '' : 's'}',
                  style: GoogleFonts.ibmPlexMono(
                    color: kSecondaryText,
                    fontSize: 9.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            ...tools.map((t) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Row(
                    children: [
                      Container(
                        width: 4.w,
                        height: 4.w,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          t.beddingPlaneIndex,
                          style: GoogleFonts.inter(
                            color: kPrimaryText,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      Text(
                        t.era,
                        style: GoogleFonts.ibmPlexMono(
                          color: kSecondaryText,
                          fontSize: 9.sp,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _eraTimeline(List<MasonryToolModel> entries) {
    final decades = <String, List<MasonryToolModel>>{};
    for (final e in entries) {
      if (e.era.length >= 4) {
        final year = int.tryParse(e.era.substring(0, 4));
        if (year != null) {
          final decade = '${(year ~/ 10) * 10}s';
          decades.putIfAbsent(decade, () => []).add(e);
        }
      }
    }
    if (decades.isEmpty) return const SizedBox.shrink();

    final sorted = decades.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return _panel(
      title: 'Era timeline',
      subtitle: 'Decadal concentration of manufacture dates',
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: sorted.map((e) {
                final isSelected = _selectedEra == e.key;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEra = _selectedEra == e.key ? null : e.key;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 88.w,
                    margin: EdgeInsets.only(right: 10.w),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isSelected ? kAccent.withAlpha(15) : kBackground,
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                      border: Border.all(
                        color: isSelected ? kAccent : kOutline,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: GoogleFonts.ibmPlexMono(
                            color: kAccent,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _animatedCount(
                          e.value.length,
                          style: GoogleFonts.cormorantGaramond(
                            color: kPrimaryText,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'tools',
                          style: GoogleFonts.inter(
                            color: kSecondaryText,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _selectedEra != null
                ? _eraDetail(decades[_selectedEra!]!, _selectedEra!)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _eraDetail(List<MasonryToolModel> tools, String decade) {
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: kAccent.withAlpha(10),
          borderRadius: BorderRadius.circular(kRadiusSmall),
          border: Border.all(color: kAccent.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 14.sp, color: kAccent),
                SizedBox(width: 6.w),
                Text(
                  'Specimens from $decade',
                  style: GoogleFonts.ibmPlexMono(
                    color: kAccent,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            ...tools.map((t) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Row(
                    children: [
                      Container(
                        width: 4.w,
                        height: 4.w,
                        decoration: BoxDecoration(
                          color: kAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          t.beddingPlaneIndex,
                          style: GoogleFonts.inter(
                            color: kPrimaryText,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      Text(
                        t.era,
                        style: GoogleFonts.ibmPlexMono(
                          color: kSecondaryText,
                          fontSize: 9.sp,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _hallmarkRankings(List<MasonryToolModel> entries) {
    final counts = <String, int>{};
    for (final e in entries) {
      final h = e.artisanHallmark.trim();
      if (h.isNotEmpty) counts[h] = (counts[h] ?? 0) + 1;
    }
    if (counts.isEmpty) return const SizedBox.shrink();

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topFive = sorted.take(5).toList();
    final others = sorted.skip(5).toList();
    final othersSpecimens = others.fold<int>(0, (sum, e) => sum + e.value);

    return _panel(
      title: 'Dominant hallmarks',
      subtitle: 'Most represented artisan works in the archive',
      child: Column(
        children: [
          ...topFive.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final e = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: kOutline),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '$rank',
                      style: GoogleFonts.ibmPlexMono(
                        color: kAccent,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      e.key,
                      style: GoogleFonts.inter(
                        color: kPrimaryText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _animatedCount(
                    e.value,
                    style: GoogleFonts.ibmPlexMono(color: kSecondaryText, fontSize: 12.sp),
                  ),
                ],
              ),
            );
          }),
          if (others.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kBackground,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: kOutline),
                    ),
                    child: Text(
                      '…',
                      style: GoogleFonts.ibmPlexMono(
                        color: kSecondaryText,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Others…',
                      style: GoogleFonts.inter(
                        color: kSecondaryText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Text(
                    '${others.length} hallmarks · $othersSpecimens',
                    style: GoogleFonts.ibmPlexMono(
                      color: kSecondaryText,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(color: kOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cormorantGaramond(
              color: kPrimaryText,
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: GoogleFonts.inter(color: kSecondaryText, fontSize: 12.sp),
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }
}
