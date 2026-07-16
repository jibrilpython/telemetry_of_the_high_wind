import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadows_on_the_quarry_wall/providers/image_provider.dart';
import 'package:shadows_on_the_quarry_wall/utils/const.dart';

void photoBottomSheet(
  BuildContext context,
  ImageNotifier imageProv,
  int index,
  WidgetRef ref,
) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: kPanelBg,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXLarge)),
    ),
    builder: (sheetContext) {
      return ListenableBuilder(
        listenable: imageProv,
        builder: (context, _) {
          return _SpecimenCaptureSheet(
            imageProv: imageProv,
            onClose: () => Navigator.pop(sheetContext),
          );
        },
      );
    },
  );
}

class _SpecimenCaptureSheet extends StatelessWidget {
  final ImageNotifier imageProv;
  final VoidCallback onClose;

  const _SpecimenCaptureSheet({
    required this.imageProv,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final displayPath = imageProv.getImagePath(imageProv.resultImage);
    final hasImage = displayPath != null && File(displayPath).existsSync();
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(kRadiusSmall),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Specimen plate',
                          style: GoogleFonts.cormorantGaramond(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cutting edge or profile outline forward',
                          style: GoogleFonts.inter(
                            color: Colors.white.withAlpha(210),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(30),
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _PreviewFrame(hasImage: hasImage, imagePath: displayPath),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CaptureTile(
                    icon: Icons.camera_alt_rounded,
                    title: 'Camera',
                    subtitle: 'Live capture',
                    accent: kAccent,
                    onTap: () => _pick(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CaptureTile(
                    icon: Icons.photo_library_rounded,
                    title: 'Gallery',
                    subtitle: 'Import plate',
                    accent: kAccentAmber,
                    onTap: () => _pick(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (hasImage) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  imageProv.clearImage();
                },
                icon: const Icon(Icons.delete_outline_rounded, color: kError, size: 18),
                label: Text(
                  'Remove photograph',
                  style: GoogleFonts.inter(
                    color: kError,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: kError.withAlpha(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadiusSmall),
                    side: BorderSide(color: kError.withAlpha(50)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: Text(
                'SQW · DRAWING OFFICE ',
                style: GoogleFonts.ibmPlexMono(
                  color: kSecondaryText.withAlpha(160),
                  fontSize: 9,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    await imageProv.pickImage(source: source);
  }
}

class _PreviewFrame extends StatelessWidget {
  final bool hasImage;
  final String? imagePath;

  const _PreviewFrame({required this.hasImage, this.imagePath});

  @override
  Widget build(BuildContext context) {
    final frameWidth = MediaQuery.sizeOf(context).width - 40;
    final frameHeight = (frameWidth * 0.5).clamp(120.0, 168.0);

    return SizedBox(
      width: frameWidth,
      height: frameHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(kRadiusSubtle),
          border: Border.all(color: kOutline),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusSubtle),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage && imagePath != null)
                Image.file(File(imagePath!), fit: BoxFit.cover)
              else
                CustomPaint(
                  painter: _PlateGridPainter(),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_center_focus_rounded,
                          color: kAccent.withAlpha(140),
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No plate loaded',
                          style: GoogleFonts.inter(
                            color: kSecondaryText,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ..._cornerBrackets(),
              if (hasImage)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(kRadiusPill),
                    ),
                    child: Text(
                      'PREVIEW',
                      style: GoogleFonts.ibmPlexMono(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _cornerBrackets() {
    const inset = 10.0;
    const len = 18.0;
    const stroke = 2.0;
    final color = kAccent.withAlpha(180);

    Widget bracket(Alignment align) {
      return Positioned.fill(
        child: Align(
          alignment: align,
          child: SizedBox(
            width: len + inset,
            height: len + inset,
            child: CustomPaint(
              painter: _CornerBracketPainter(
                align: align,
                color: color,
                length: len,
                stroke: stroke,
                inset: inset,
              ),
            ),
          ),
        ),
      );
    }

    return [
      bracket(Alignment.topLeft),
      bracket(Alignment.topRight),
      bracket(Alignment.bottomLeft),
      bracket(Alignment.bottomRight),
    ];
  }
}

class _CornerBracketPainter extends CustomPainter {
  final Alignment align;
  final Color color;
  final double length;
  final double stroke;
  final double inset;

  _CornerBracketPainter({
    required this.align,
    required this.color,
    required this.length,
    required this.stroke,
    required this.inset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final x = align.x < 0 ? inset : size.width - inset;
    final y = align.y < 0 ? inset : size.height - inset;
    final hx = align.x < 0 ? 1.0 : -1.0;
    final hy = align.y < 0 ? 1.0 : -1.0;

    canvas.drawLine(Offset(x, y), Offset(x + hx * length, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + hy * length), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlateGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kOutline.withAlpha(120)
      ..strokeWidth = 0.5;

    const step = 24.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CaptureTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _CaptureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_CaptureTile> createState() => _CaptureTileState();
}

class _CaptureTileState extends State<_CaptureTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: _pressed ? widget.accent.withAlpha(24) : kBackground,
            borderRadius: BorderRadius.circular(kRadiusSubtle),
            border: Border.all(
              color: _pressed ? widget.accent : kOutline,
              width: _pressed ? 1.5 : 1,
            ),
            boxShadow: _pressed ? const [kShadowSubtle] : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.accent.withAlpha(22),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.accent.withAlpha(80)),
                ),
                child: Icon(widget.icon, color: widget.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        color: kPrimaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        color: kSecondaryText,
                        fontSize: 10,
                      ),
                    ),
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
