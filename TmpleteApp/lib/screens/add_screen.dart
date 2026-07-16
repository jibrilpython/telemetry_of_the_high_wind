import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadows_on_the_quarry_wall/common/photo_bottom_sheet.dart';
import 'package:shadows_on_the_quarry_wall/common/temperature_rheostat.dart';
import 'package:shadows_on_the_quarry_wall/enum/my_enums.dart';
import 'package:shadows_on_the_quarry_wall/providers/image_provider.dart';
import 'package:shadows_on_the_quarry_wall/providers/input_provider.dart';
import 'package:shadows_on_the_quarry_wall/providers/project_provider.dart';
import 'package:shadows_on_the_quarry_wall/utils/const.dart';

class AddScreen extends ConsumerStatefulWidget {
  final bool isEdit;
  final int currentIndex;
  const AddScreen({super.key, this.isEdit = false, this.currentIndex = 0});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _hallmarkError = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  late TextEditingController _idCtrl;
  late TextEditingController _manCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _toolCtrl;
  late TextEditingController _matCtrl;
  late TextEditingController _dimCtrl;
  late TextEditingController _accCtrl;
  late TextEditingController _markCtrl;
  late TextEditingController _provCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _tagsCtrl;

  static const _steps = [
    ('01', 'Identity', 'Registry & class'),
    ('02', 'Geometry', 'Stone & cleavage'),
    ('03', 'Metallurgy', 'Steel & soundness'),
    ('04', 'Ground', 'Provenance & notes'),
  ];

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    final p = ref.read(inputProvider);
    _idCtrl = TextEditingController(text: p.beddingPlaneIndex);
    _manCtrl = TextEditingController(text: p.artisanHallmark);
    _countryCtrl = TextEditingController(text: p.calibrationSource);
    _yearCtrl = TextEditingController(
      text: p.era.replaceAll(RegExp(r'[^0-9]'), '').substring(
        0,
        p.era.replaceAll(RegExp(r'[^0-9]'), '').length.clamp(0, 4),
      ),
    );
    _toolCtrl = TextEditingController(text: p.dimensionalCleavageCapacity);
    _matCtrl = TextEditingController(text: p.cuttingEdgeMetallurgy);
    _dimCtrl = TextEditingController(text: p.chamberDimensionsAndMass);
    _accCtrl = TextEditingController(text: p.templateGeometricPattern);
    _markCtrl = TextEditingController(text: p.structuralSoundnessNotes);
    _provCtrl = TextEditingController(text: p.excavationGroundZero);
    _notesCtrl = TextEditingController(text: p.notes);
    _tagsCtrl = TextEditingController(text: p.tags.join(', '));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _shakeCtrl.dispose();
    for (final c in [
      _idCtrl, _manCtrl, _countryCtrl, _yearCtrl, _toolCtrl,
      _matCtrl, _dimCtrl, _accCtrl, _markCtrl, _provCtrl, _notesCtrl, _tagsCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _steps.length) return;
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _save() async {
    final p = ref.read(inputProvider);
    if (p.artisanHallmark.trim().isEmpty) {
      setState(() {
        _hallmarkError = true;
        _currentPage = 0;
      });
      _goToPage(0);
      _shakeCtrl.forward(from: 0);
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() => _hallmarkError = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SavingDialog(),
    );
    await Future.delayed(const Duration(milliseconds: 1100));
    if (widget.isEdit) {
      ref.read(projectProvider).editEntry(ref, widget.currentIndex);
    } else {
      ref.read(projectProvider).addEntry(ref);
    }
    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
      ref.read(inputProvider).clearAll();
      ref.read(imageProvider).clearImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentPage + 1) / _steps.length;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressRail(progress),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPage1Identity(),
                  _buildPage2Geometry(),
                  _buildPage3Metallurgy(),
                  _buildPage4Ground(),
                ],
              ),
            ),
            if (_hallmarkError) _buildHallmarkBanner(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: kPrimaryText, size: 22.sp),
            style: IconButton.styleFrom(
              backgroundColor: kPanelBg,
              side: const BorderSide(color: kOutline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusSmall),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.isEdit ? 'Revise specimen' : 'New quarry record',
                  style: GoogleFonts.cormorantGaramond(
                    color: kPrimaryText,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Step ${_currentPage + 1} of ${_steps.length}',
                  style: GoogleFonts.ibmPlexMono(
                    color: kSecondaryText,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }

  Widget _buildProgressRail(double progress) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(kRadiusPill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 4.h,
                backgroundColor: kOutline,
                color: kAccent,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: List.generate(_steps.length, (i) {
              final step = _steps[i];
              final active = i == _currentPage;
              final done = i < _currentPage;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _goToPage(i),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 30.w,
                        height: 30.w,
                        decoration: BoxDecoration(
                          color: active || done ? kAccent : kPanelBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active || done ? kAccent : kOutline,
                            width: active ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          step.$1,
                          style: GoogleFonts.ibmPlexMono(
                            color: active || done ? Colors.white : kSecondaryText,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        step.$2,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: active ? kAccent : kSecondaryText,
                          fontSize: 9.sp,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHallmarkBanner() {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      offset: Offset.zero,
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: kError.withAlpha(18),
          borderRadius: BorderRadius.circular(kRadiusSmall),
          border: Border.all(color: kError.withAlpha(90)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: kError, size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Artisan hallmark required',
                    style: GoogleFonts.inter(
                      color: kError,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Every specimen must identify its maker before entering the ledger.',
                    style: GoogleFonts.inter(
                      color: kPrimaryText,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _hallmarkError = false);
                _goToPage(0);
              },
              child: Text(
                'Fix',
                style: GoogleFonts.inter(
                  color: kError,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentPage == _steps.length - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h),
      decoration: BoxDecoration(
        color: kPanelBg.withAlpha(245),
        border: Border(top: BorderSide(color: kOutline)),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goToPage(_currentPage - 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kSecondaryText,
                  side: const BorderSide(color: kOutline),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadiusSmall),
                  ),
                ),
                child: Text('Back', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
          if (_currentPage > 0) SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: isLast ? _save : () => _goToPage(_currentPage + 1),
              style: FilledButton.styleFrom(
                backgroundColor: kAccent,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusSmall),
                ),
              ),
              child: Text(
                isLast
                    ? (widget.isEdit ? 'Commit revision' : 'Enter ledger')
                    : 'Continue',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1Identity() {
    final p = ref.watch(inputProvider);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhotoSection(),
          SizedBox(height: 24.h),
          _sectionTitle(_steps[0].$3),
          SizedBox(height: 14.h),
          _field(
            label: 'Bedding plane index',
            ctrl: _idCtrl,
            hint: 'Auto-generated, e.g. SQW-STONE-1149-MARB-G',
            mono: true,
            onChanged: (v) {
              p.beddingPlaneIndex = v;
              setState(() => _hallmarkError = false);
            },
          ),
          SizedBox(height: 16.h),
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(_hallmarkError ? _shakeAnim.value : 0, 0),
              child: child,
            ),
            child: _field(
              label: 'Artisan hallmark',
              ctrl: _manCtrl,
              hint: 'e.g. Bedford Iron & Wedge Co.',
              hasError: _hallmarkError,
              onChanged: (v) {
                p.artisanHallmark = v;
                if (v.trim().isNotEmpty && _hallmarkError) {
                  setState(() => _hallmarkError = false);
                }
              },
            ),
          ),
          SizedBox(height: 16.h),
          _field(
            label: 'Calibration mill / foundry',
            ctrl: _countryCtrl,
            hint: 'e.g. Keystone Foundry No. 4',
            onChanged: (v) => p.calibrationSource = v,
          ),
          SizedBox(height: 16.h),
          _field(
            label: 'Era',
            ctrl: _yearCtrl,
            hint: 'e.g. 1870',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onChanged: (v) => p.era = v,
          ),
          SizedBox(height: 20.h),
          Text(
            'Implementation class',
            style: GoogleFonts.inter(
              color: kSecondaryText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: ImplementationClass.values.map((t) {
              final sel = p.implementationClass == t;
              return GestureDetector(
                onTap: () => p.implementationClass = t,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: sel ? kAccent : kPanelBg,
                    borderRadius: BorderRadius.circular(kRadiusPill),
                    border: Border.all(color: sel ? kAccent : kOutline),
                  ),
                  child: Text(
                    t.label,
                    style: GoogleFonts.inter(
                      color: sel ? Colors.white : kPrimaryText,
                      fontSize: 12.sp,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2Geometry() {
    final p = ref.watch(inputProvider);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(_steps[1].$3),
          SizedBox(height: 14.h),
          _field(
            label: 'Dimensional cleavage capacity',
            ctrl: _toolCtrl,
            hint: 'e.g. 18-inch bore depth, 4-inch wedge clearance',
            maxLines: 2,
            onChanged: (v) => p.dimensionalCleavageCapacity = v,
          ),
          SizedBox(height: 16.h),
          TemperatureRheostat(
            value: p.temperatureRange,
            onChanged: (v) => p.temperatureRange = v,
          ),
          SizedBox(height: 20.h),
          Text(
            'Stone type',
            style: GoogleFonts.inter(
              color: kSecondaryText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          ...StoneType.values.map((stone) {
            final sel = p.stoneType == stone;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Material(
                color: sel ? kAccentSurface : kPanelBg,
                borderRadius: BorderRadius.circular(kRadiusSmall),
                child: InkWell(
                  onTap: () => p.stoneType = stone,
                  borderRadius: BorderRadius.circular(kRadiusSmall),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                      border: Border.all(
                        color: sel ? kAccent : kOutline,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            color: getStoneTypeColor(stone),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            stone.label,
                            style: GoogleFonts.inter(
                              color: sel ? kPrimaryText : kSecondaryText,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (sel)
                          Icon(Icons.check_rounded, color: kAccent, size: 18.sp),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPage3Metallurgy() {
    final p = ref.watch(inputProvider);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(_steps[2].$3),
          SizedBox(height: 14.h),
          _field(
            label: 'Cutting edge metallurgy',
            ctrl: _matCtrl,
            hint: 'e.g. fire-tempered high-carbon steel',
            maxLines: 2,
            onChanged: (v) => p.cuttingEdgeMetallurgy = v,
          ),
          SizedBox(height: 16.h),
          _field(
            label: 'Chamber dimensions & mass',
            ctrl: _dimCtrl,
            hint: 'e.g. 760 mm boring shaft, 18.4 kg dry mass',
            maxLines: 2,
            mono: true,
            onChanged: (v) => p.chamberDimensionsAndMass = v,
          ),
          SizedBox(height: 20.h),
          Text(
            'Structural soundness',
            style: GoogleFonts.inter(
              color: kSecondaryText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          ...StructuralSoundness.values.map((state) {
            final sel = p.structuralSoundness == state;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: GestureDetector(
                onTap: () => p.structuralSoundness = state,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: sel ? getStructuralSoundnessColor(state).withAlpha(24) : kPanelBg,
                    borderRadius: BorderRadius.circular(kRadiusSmall),
                    border: Border.all(
                      color: sel ? getStructuralSoundnessColor(state) : kOutline,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: getStructuralSoundnessColor(state),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          state.label,
                          style: GoogleFonts.inter(
                            color: kPrimaryText,
                            fontSize: 13.sp,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPage4Ground() {
    final p = ref.watch(inputProvider);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(_steps[3].$3),
          SizedBox(height: 14.h),
          _field(
            label: 'Template geometric pattern',
            ctrl: _accCtrl,
            hint: 'e.g. Ogee arch profile, Roman Doric fluting',
            maxLines: 2,
            onChanged: (v) => p.templateGeometricPattern = v,
          ),
          SizedBox(height: 16.h),
          _field(
            label: 'Soundness notes',
            ctrl: _markCtrl,
            hint: 'e.g. edge dulling 18%, head mushrooming light',
            maxLines: 2,
            onChanged: (v) => p.structuralSoundnessNotes = v,
          ),
          SizedBox(height: 16.h),
          _field(
            label: 'Excavation ground zero',
            ctrl: _provCtrl,
            hint: 'e.g. Forgotten Vermont marble pit',
            maxLines: 3,
            onChanged: (v) => p.excavationGroundZero = v,
          ),
          SizedBox(height: 16.h),
          _field(
            label: 'Notes',
            ctrl: _notesCtrl,
            hint: 'Additional quarry or lodge observations…',
            maxLines: 3,
            onChanged: (v) => p.notes = v,
          ),
          SizedBox(height: 16.h),
          _field(
            label: 'Tags',
            ctrl: _tagsCtrl,
            hint: 'granite, cathedral, plug wedge…',
            onChanged: (v) => p.tags = v
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    final imageProv = ref.watch(imageProvider);
    final displayPath = imageProv.getImagePath(imageProv.resultImage);
    final hasImage = displayPath != null && File(displayPath).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SPECIMEN PLATE',
              style: GoogleFonts.ibmPlexMono(
                color: kAccent,
                fontSize: 9.sp,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            if (hasImage)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: kSuccess.withAlpha(24),
                  borderRadius: BorderRadius.circular(kRadiusPill),
                  border: Border.all(color: kSuccess.withAlpha(80)),
                ),
                child: Text(
                  'LOADED',
                  style: GoogleFonts.ibmPlexMono(
                    color: kSuccess,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              FocusScope.of(context).unfocus();
              photoBottomSheet(context, ref.read(imageProvider), 0, ref);
            },
            borderRadius: BorderRadius.circular(kRadiusSubtle),
            child: Ink(
              decoration: BoxDecoration(
                color: kPanelBg,
                borderRadius: BorderRadius.circular(kRadiusSubtle),
                border: Border.all(
                  color: hasImage ? kAccent.withAlpha(100) : kOutline,
                  width: hasImage ? 1.5 : 1,
                ),
                boxShadow: hasImage ? const [kShadowSubtle] : null,
              ),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(kRadiusSubtle - 1),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage)
                        Image.file(File(displayPath), fit: BoxFit.cover)
                      else
                        ColoredBox(
                          color: kBackground,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56.w,
                                height: 56.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kAccentSurface,
                                  border: Border.all(color: kAccent.withAlpha(60)),
                                ),
                                child: Icon(
                                  Icons.add_a_photo_rounded,
                                  color: kAccent,
                                  size: 24.sp,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'Load specimen photograph',
                                style: GoogleFonts.inter(
                                  color: kPrimaryText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Tap to open capture deck',
                                style: GoogleFonts.inter(
                                  color: kSecondaryText,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Positioned(
                        left: 10.w,
                        top: 10.h,
                        child: _photoCornerMark(),
                      ),
                      Positioned(
                        right: 10.w,
                        top: 10.h,
                        child: Transform.flip(
                          flipX: true,
                          child: _photoCornerMark(),
                        ),
                      ),
                      Positioned(
                        left: 10.w,
                        bottom: 10.h,
                        child: Transform.flip(
                          flipY: true,
                          child: _photoCornerMark(),
                        ),
                      ),
                      Positioned(
                        right: 10.w,
                        bottom: 10.h,
                        child: Transform.flip(
                          flipX: true,
                          flipY: true,
                          child: _photoCornerMark(),
                        ),
                      ),
                      Positioned(
                        right: 12.w,
                        bottom: 12.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(235),
                            borderRadius: BorderRadius.circular(kRadiusPill),
                            border: Border.all(color: kOutline),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasImage ? Icons.swap_horiz_rounded : Icons.touch_app_rounded,
                                size: 14.sp,
                                color: kAccent,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                hasImage ? 'Change plate' : 'Open deck',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoCornerMark() {
    return SizedBox(
      width: 16.w,
      height: 16.w,
      child: CustomPaint(
        painter: _PhotoCornerPainter(color: kAccent.withAlpha(160)),
      ),
    );
  }

  Widget _sectionTitle(String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle.toUpperCase(),
          style: GoogleFonts.ibmPlexMono(
            color: kAccent,
            fontSize: 9.sp,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required ValueChanged<String> onChanged,
    String? hint,
    int maxLines = 1,
    bool mono = false,
    bool hasError = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: hasError ? kError : kSecondaryText,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: ctrl,
          onChanged: onChanged,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: (mono ? GoogleFonts.ibmPlexMono : GoogleFonts.inter)(
            color: kPrimaryText,
            fontSize: 14.sp,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: hasError ? kError.withAlpha(10) : kPanelBg,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadiusSmall),
              borderSide: BorderSide(color: hasError ? kError : kOutline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadiusSmall),
              borderSide: BorderSide(
                color: hasError ? kError : kAccent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoCornerPainter extends CustomPainter {
  final Color color;

  _PhotoCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SavingDialog extends StatelessWidget {
  const _SavingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: kPanelBg,
          borderRadius: BorderRadius.circular(kRadiusSmall),
          border: Border.all(color: kOutline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36.w,
              height: 36.w,
              child: CircularProgressIndicator(
                color: kAccent,
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'Indexing specimen…',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
