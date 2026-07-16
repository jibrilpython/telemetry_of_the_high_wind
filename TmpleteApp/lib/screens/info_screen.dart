import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shadows_on_the_quarry_wall/models/project_model.dart';
import 'package:shadows_on_the_quarry_wall/enum/my_enums.dart';
import 'package:shadows_on_the_quarry_wall/providers/image_provider.dart';
import 'package:shadows_on_the_quarry_wall/providers/project_provider.dart';
import 'package:shadows_on_the_quarry_wall/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoScreen extends ConsumerWidget {
  final int index;
  const InfoScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectProv = ref.watch(projectProvider);
    if (index < 0 || index >= projectProv.entries.length) {
      return const Scaffold(body: Center(child: Text('TOOL NOT FOUND')));
    }
    final entry = projectProv.entries[index];
    final imageProv = ref.watch(imageProvider);
    final imagePath = imageProv.getImagePath(entry.photoPath);

    return Scaffold(
      backgroundColor: kBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leadingWidth: 68.w,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 20.w),
            child: _navBtn(
              context,
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          _navBtn(
            context,
            icon: Icons.edit_outlined,
            onTap: () {
              projectProv.fillInput(ref, index);
              Navigator.pushNamed(
                context,
                '/add_screen',
                arguments: {'isEdit': true, 'currentIndex': index},
              );
            },
          ),
          SizedBox(width: 12.w),
          _navBtn(
            context,
            icon: Icons.delete_outline,
            iconColor: kError,
            onTap: () => _showDeleteDialog(context, projectProv, index),
          ),
          SizedBox(width: 20.w),
        ],
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildHeroImage(imagePath, entry)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 80.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildIdentityPanel(entry),
                SizedBox(height: 20.h),
                _buildSpecGrid(entry),
                SizedBox(height: 20.h),
                if (entry.excavationGroundZero.isNotEmpty ||
                    entry.templateGeometricPattern.isNotEmpty ||
                    entry.structuralSoundnessNotes.isNotEmpty ||
                    entry.notes.isNotEmpty)
                  _buildTextPanels(entry),
                if (entry.tags.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _buildTagsPanel(entry),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(String? imagePath, MasonryToolModel entry) {
    return Container(
      width: double.infinity,
      height: 360.h,
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(kRadiusSmall),
          bottomRight: Radius.circular(kRadiusSmall),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child:
          (entry.photoPath.isNotEmpty &&
              imagePath != null &&
              File(imagePath).existsSync())
          ? Image.file(File(imagePath), fit: BoxFit.cover)
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.architecture_rounded,
                    size: 48.sp,
                    color: kSecondaryText.withAlpha(100),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No photograph',
                    style: GoogleFonts.inter(
                      color: kSecondaryText,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildIdentityPanel(MasonryToolModel entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                entry.beddingPlaneIndex.isNotEmpty
                    ? entry.beddingPlaneIndex
                    : 'Unassigned ID',
                style: GoogleFonts.ibmPlexMono(
                  color: kAccent,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.era.isNotEmpty) ...[
              SizedBox(width: 16.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: kAccentAmber.withAlpha(20),
                  borderRadius: BorderRadius.circular(kRadiusPill),
                  border: Border.all(
                    color: kAccentAmber.withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Text(
                  entry.era,
                  style: GoogleFonts.ibmPlexMono(
                    color: kAccentAmber,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          entry.artisanHallmark.isNotEmpty
              ? entry.artisanHallmark
              : 'Unknown Artisan Hallmark',
          style: GoogleFonts.cormorantGaramond(
            color: kPrimaryText,
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: -0.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (entry.calibrationSource.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            entry.calibrationSource,
            style: GoogleFonts.inter(
              color: kSecondaryText,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        SizedBox(height: 14.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _pill(Colors.white, kAccent, entry.implementationClass.label),
            _pill(
              Colors.white,
              getStructuralSoundnessColor(entry.structuralSoundness),
              entry.structuralSoundness.label,
            ),
            if (entry.temperatureRange.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: kBackground,
                  borderRadius: BorderRadius.circular(kRadiusPill),
                  border: Border.all(color: kOutline, width: 1),
                ),
                child: Text(
                  entry.temperatureRange,
                  style: GoogleFonts.ibmPlexMono(
                    color: kSecondaryText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        if (entry.excavationGroundZero.isNotEmpty) ...[
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: kAccentSurface,
              borderRadius: BorderRadius.circular(kRadiusPill),
            ),
            child: Text(
              entry.excavationGroundZero,
              style: GoogleFonts.inter(
                color: kAccent,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _pill(Color textColor, Color bgColor, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(kRadiusPill),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSpecGrid(MasonryToolModel entry) {
    final specs = <String, String>{};
    if (entry.dimensionalCleavageCapacity.isNotEmpty) {
      specs['Tool/gauge configuration'] = entry.dimensionalCleavageCapacity;
    }
    if (entry.stoneType != StoneType.unknown) {
      specs['Stone type'] = entry.stoneType.label;
    }
    if (entry.cuttingEdgeMetallurgy.isNotEmpty) {
      specs['Cutting Edge Metallurgy'] = entry.cuttingEdgeMetallurgy;
    }
    if (entry.chamberDimensionsAndMass.isNotEmpty) {
      specs['Dimensions & weight'] = entry.chamberDimensionsAndMass;
    }
    if (entry.structuralSoundnessNotes.isNotEmpty) {
      specs['Soundness notes'] = entry.structuralSoundnessNotes;
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(color: kOutline, width: 1),
      ),
      child: Column(
        children: specs.entries.map((e) => _specTile(e.key, e.value)).toList(),
      ),
    );
  }

  Widget _specTile(String label, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: kOutline.withAlpha(150), width: 1.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: kSecondaryText,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: kPrimaryText,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPanels(MasonryToolModel entry) {
    return Column(
      children: [
        if (entry.templateGeometricPattern.isNotEmpty)
          _textPanel('Included accessories', entry.templateGeometricPattern),
        if (entry.structuralSoundnessNotes.isNotEmpty)
          _textPanel('Soundness notes', entry.structuralSoundnessNotes),
        if (entry.excavationGroundZero.isNotEmpty)
          _textPanel('Excavation Ground Zero', entry.excavationGroundZero),
        if (entry.notes.isNotEmpty) _textPanel('Notes', entry.notes),
      ],
    );
  }

  Widget _textPanel(String label, String text) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(color: kOutline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.cormorantGaramond(
              color: kPrimaryText,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            text,
            style: GoogleFonts.inter(
              color: kSecondaryText,
              fontSize: 14.sp,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsPanel(MasonryToolModel entry) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: entry.tags
          .map(
            (tag) => Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.circular(kRadiusPill),
                border: Border.all(color: kOutline, width: 1),
              ),
              child: Text(
                '#$tag',
                style: GoogleFonts.inter(
                  color: kSecondaryText,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _navBtn(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = kPrimaryText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.r,
        height: 42.r,
        decoration: BoxDecoration(
          color: kPanelBg.withAlpha(220),
          borderRadius: BorderRadius.circular(kRadiusSmall),
          border: Border.all(color: kOutline, width: 1),
        ),
        child: Icon(icon, color: iconColor, size: 22.sp),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ProjectNotifier projectProv,
    int idx,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: _DeleteDialogUI(
          onConfirm: () {
            projectProv.deleteEntry(idx);
            Navigator.pop(ctx);
            Navigator.pop(context);
          },
          onCancel: () => Navigator.pop(ctx),
        ),
      ),
    );
  }
}

class _DeleteDialogUI extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _DeleteDialogUI({required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(color: kOutline, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: kError.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_outline, color: kError, size: 28.sp),
          ),
          SizedBox(height: 20.h),
          Text(
            'Delete specimen?',
            style: GoogleFonts.cormorantGaramond(
              color: kPrimaryText,
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'This tool record will be permanently removed from the quarry archive.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: kSecondaryText,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 28.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: kBackground,
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                      border: Border.all(color: kOutline, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: kSecondaryText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: kError,
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    child: Center(
                      child: Text(
                        'Delete',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
