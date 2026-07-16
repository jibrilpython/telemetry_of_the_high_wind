import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadows_on_the_quarry_wall/common/tool_elevation_painter.dart';
import 'package:shadows_on_the_quarry_wall/enum/my_enums.dart';
import 'package:shadows_on_the_quarry_wall/models/project_model.dart';
import 'package:shadows_on_the_quarry_wall/providers/image_provider.dart';
import 'package:shadows_on_the_quarry_wall/providers/project_provider.dart';
import 'package:shadows_on_the_quarry_wall/showcase/rift_reader_palette.dart';
import 'package:shadows_on_the_quarry_wall/showcase/rift_reader_painter.dart';
import 'package:shadows_on_the_quarry_wall/showcase/rift_reader_physics.dart';
import 'package:shadows_on_the_quarry_wall/utils/layout.dart';

// ─────────────────────────────────────────────────────────────────────────────

class ShowcaseScreen extends ConsumerStatefulWidget {
  final bool isActive;
  const ShowcaseScreen({super.key, this.isActive = true});

  @override
  ConsumerState<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends ConsumerState<ShowcaseScreen>
    with TickerProviderStateMixin {
  late Ticker _ticker;
  final StressFieldEngine _engine = StressFieldEngine();
  final math.Random _rng = math.Random();

  List<RiftNode> _nodes = [];
  ui.Picture? _stoneLayer;
  Size? _stoneLayerSize;
  Size _canvasSize = Size.zero;

  bool _initialized = false;
  int _lastHash = -1;
  double _time = 0;
  int _tickCount = 0;

  RiftNode? _focusTarget;
  RiftNode? _readingNode;
  bool _riftReading = false;
  double _riftSweep = 0;
  double _riftTargetAngle = 0;
  double _splitProgress = 0;
  double _fieldSaturation = 1;
  String? _stressReadout;
  Timer? _readoutTimer;

  int _rapidTapCount = 0;
  DateTime _lastHammerTap = DateTime.fromMillisecondsSinceEpoch(0);

  late AnimationController _splitCtrl;
  late AnimationController _readoutFadeCtrl;
  late AnimationController _riftHintCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.isActive) _ticker.start();

    _splitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() => setState(() => _splitProgress = _splitCtrl.value));

    _readoutFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _riftHintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ShowcaseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _ticker.start();
    } else if (!widget.isActive && oldWidget.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _splitCtrl.dispose();
    _readoutFadeCtrl.dispose();
    _riftHintCtrl.dispose();
    _pulseCtrl.dispose();
    _readoutTimer?.cancel();
    _stoneLayer?.dispose();
    super.dispose();
  }

  void _rebuildStoneLayer(Size size) {
    if (size.isEmpty) return;
    if (_stoneLayerSize == size && _stoneLayer != null) return;
    _stoneLayer?.dispose();
    _stoneLayer = RiftReaderPainter.buildStoneLayer(size);
    _stoneLayerSize = size;
  }

  void _hammerAt(Offset point) {
    HapticFeedback.mediumImpact();
    _engine.addHammerBlow(point, _time);
    setState(() {});
  }

  void _triggerHammerSeries() {
    if (_canvasSize.isEmpty) return;
    HapticFeedback.heavyImpact();
    _engine.addHammerSeries(_canvasSize, _time);
    setState(() {});
    _showReadout(
      '⚒  HAMMER SERIES — SHOCK WAVE TRANSMITTED',
      hold: const Duration(milliseconds: 1200),
    );
  }

  void _handleCanvasTap(Offset point) {
    if (_riftReading) {
      _attemptRiftLock();
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastHammerTap).inMilliseconds > 650) {
      _rapidTapCount = 0;
    }
    _lastHammerTap = now;
    _rapidTapCount++;

    if (_rapidTapCount >= 3) {
      _rapidTapCount = 0;
      _triggerHammerSeries();
      return;
    }

    _hammerAt(point);
  }

  int _hash(List<MasonryToolModel> entries) {
    var h = entries.length;
    for (final e in entries) {
      h ^= Object.hash(
        e.implementationClass,
        e.beddingPlaneIndex,
        e.artisanHallmark,
        e.photoPath,
      );
    }
    return h;
  }

  void _resetRiftOverlay() {
    _focusTarget = null;
    _readingNode = null;
    _riftReading = false;
    _splitProgress = 0;
    _splitCtrl.reset();
    if (_riftHintCtrl.value > 0) {
      _riftHintCtrl.reset();
    }
  }

  void _initNodes(List<MasonryToolModel> entries, Size size) {
    if (size.isEmpty) return;
    if (entries.isEmpty) {
      if (_initialized || _splitProgress > 0 || _focusTarget != null) {
        _resetRiftOverlay();
        _nodes = [];
        _initialized = false;
        _lastHash = -1;
        _engine.clearCracks();
      }
      return;
    }
    final hash = _hash(entries);
    if (_initialized && hash == _lastHash) return;
    _initialized = true;
    _lastHash = hash;

    _resetRiftOverlay();

    final counts = <ImplementationClass, int>{};
    for (final e in entries) {
      counts[e.implementationClass] = (counts[e.implementationClass] ?? 0) + 1;
    }
    final max = counts.values.reduce(math.max);

    _nodes = counts.entries.map((entry) {
      final count = entry.value;
      final factor = (count / max).clamp(0.4, 1.0);
      return RiftNode(
        type: entry.key,
        count: count,
        items: entries.where((e) => e.implementationClass == entry.key).toList(),
        x: size.width * (0.22 + _rng.nextDouble() * 0.56),
        y: size.height * (0.26 + _rng.nextDouble() * 0.40),
        radius: 36 + 28 * factor,
        orientation: _rng.nextDouble() * math.pi,
        appliedForce: 0.45 + factor * 0.35,
      );
    }).toList();

    _rebuildStoneLayer(size);
    _engine.clearCracks();
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !widget.isActive || _canvasSize.isEmpty || _nodes.isEmpty) {
      return;
    }
    _time = elapsed.inMilliseconds / 1000.0;
    _tickCount++;
    _riftSweep += math.pi * 2 / 6 / 60;

    if (_tickCount.isEven) {
      _engine.updateDominantRift(_nodes, _canvasSize, _time);
    }
    _engine.pruneImpulses(_time, RiftPalette.impulseMaxRadius);

    final needsFrame = _riftReading ||
        _engine.impulses.isNotEmpty ||
        _splitProgress > 0 ||
        _tickCount.isEven;
    if (needsFrame) setState(() {});
  }

  double _angleDelta(double a, double b) {
    var d = (a - b).abs() % (2 * math.pi);
    return d > math.pi ? 2 * math.pi - d : d;
  }

  void _beginRiftReading(RiftNode node) {
    final center = Offset(_canvasSize.width / 2, _canvasSize.height / 2);
    setState(() {
      _readingNode = node;
      _riftReading = true;
      _riftTargetAngle = math.atan2(node.y - center.dy, node.x - center.dx);
      _focusTarget = null;
      _splitProgress = 0;
      _splitCtrl.reset();
    });
    _riftHintCtrl.forward();
    HapticFeedback.selectionClick();
  }

  void _attemptRiftLock() {
    if (!_riftReading || _readingNode == null) return;
    final aligned = _angleDelta(_riftSweep, _riftTargetAngle) < 0.35;
    if (!aligned) {
      HapticFeedback.vibrate();
      _showReadout('RIFT MISREAD — ALIGN SWEEP ARM WITH SELECTED TOOL');
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _riftReading = false;
      _focusTarget = _readingNode;
      _readingNode = null;
    });
    _riftHintCtrl.reverse();
    _splitCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 850), () {
      if (mounted) HapticFeedback.lightImpact();
    });
  }

  void _showReadout(String text, {Duration hold = const Duration(seconds: 2)}) {
    _readoutTimer?.cancel();
    setState(() {
      _stressReadout = text;
      _fieldSaturation = 1;
    });
    _readoutFadeCtrl.forward(from: 0);
    _readoutTimer = Timer(hold, () {
      if (mounted) {
        _readoutFadeCtrl.reverse().then((_) {
          if (mounted) setState(() => _stressReadout = null);
        });
      }
    });
  }

  void _longPressNode(RiftNode node) {
    HapticFeedback.lightImpact();
    final text = _engine.stressReadout(node, _nodes, _time);
    setState(() => _fieldSaturation = 1);
    _showReadout(text);
  }

  double _gaugeStress(RiftNode node) {
    final sigma = _engine.stressAt(node.center, _nodes, _time);
    return ((sigma + 0.2) / 1.4).clamp(0.0, 1.0);
  }

  /// Floating nav pill in [MainNavigation]: 24.h margin + 66.h height + gap.
  double get _bottomNavClearance => bottomNavClearance;

  /// Hammer / field strip sits above the nav pill.
  double get _actionBarBottom => _bottomNavClearance;

  double get _actionBarHeight => 48.h;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(projectProvider).entries;
    _canvasSize = MediaQuery.sizeOf(context);
    _initNodes(entries, _canvasSize);
    _rebuildStoneLayer(_canvasSize);

    return Scaffold(
      backgroundColor: RiftPalette.quarryShadow,
      body: entries.isEmpty
          ? _emptyState()
          : Stack(
              fit: StackFit.expand,
              children: [
                // ── Canvas ──────────────────────────────────────────────────
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _handleCanvasTap(d.localPosition),
                  child: CustomPaint(
                    painter: RiftReaderPainter(
                      nodes: _nodes,
                      engine: _engine,
                      stoneLayer: _stoneLayer,
                      time: _time,
                      riftSweepAngle: _riftSweep,
                      riftTargetAngle: _riftReading ? _riftTargetAngle : null,
                      fieldSaturation: _fieldSaturation,
                      showRiftArm: _riftReading,
                      splitProgress:
                          _focusTarget != null ? _splitProgress : 0,
                    ),
                    size: _canvasSize,
                  ),
                ),

                // ── Node plates ─────────────────────────────────────────────
                ..._nodes.map((node) => _RiftNodePlate(
                      node: node,
                      sensorStress: node.kind == RiftNodeKind.gauge
                          ? _gaugeStress(node)
                          : 0.0,
                      riftReading: _riftReading,
                      onRiftTap: _attemptRiftLock,
                      onSelect: _beginRiftReading,
                      onStressRead: _longPressNode,
                      onMoved: () => setState(() {}),
                    )),

                // ── Overlays ─────────────────────────────────────────────────
                // ── Dark top scrim — keeps header text readable over any heatmap brightness.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 170,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            RiftPalette.quarryShadow.withAlpha(210),
                            RiftPalette.quarryShadow.withAlpha(0),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_stressReadout != null) _buildReadoutBanner(),
                _buildHeader(),
                _buildBottomActionBar(),
                if (_focusTarget != null && _splitProgress > 0.55)
                  _buildFocusPanel(_focusTarget!),
                if (_riftReading)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _actionBarBottom + _actionBarHeight + 10.h,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _riftHintCtrl,
                        curve: Curves.easeOutCubic,
                      )),
                      child: _buildRiftHint(),
                    ),
                  ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Positioned(
      top: 52.h,
      left: 18.w,
      right: 18.w,
      child: IgnorePointer(
        child: Column(
          children: [
            Text(
              'Rift Reader',
              style: GoogleFonts.cormorantGaramond(
                color: RiftPalette.splitWhite,
                fontSize: 32.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            // Brass rule.
            Container(
              height: 1,
              width: 120.w,
              color: RiftPalette.trierBrass.withAlpha(160),
              margin: EdgeInsets.symmetric(vertical: 3.h),
            ),
            Text(
              'Griffith Fracture  ·  Kirsch Stress Field',
              style: GoogleFonts.ibmPlexMono(
                color: RiftPalette.trierBrass,
                fontSize: 8.sp,
                letterSpacing: 1.1,
                shadows: const [
                  Shadow(color: Color(0xCC000000), blurRadius: 6),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5.h),
            Text(
              'Tap stone to strike · Hold tool for stress readout · Tap tool to read rift',
              style: GoogleFonts.inter(
                color: RiftPalette.splitWhite.withAlpha(200),
                fontSize: 10.sp,
                height: 1.4,
                shadows: const [
                  Shadow(color: Color(0xCC000000), blurRadius: 8),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM ACTION BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomActionBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: _actionBarBottom,
      child: Container(
        decoration: BoxDecoration(
          color: RiftPalette.quarryShadow.withAlpha(220),
          border: Border(
            top: BorderSide(color: RiftPalette.trierBrass.withAlpha(80), width: 0.8),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        child: Row(
          children: [
            // Hammer series button.
            GestureDetector(
              onTap: _triggerHammerSeries,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: RiftPalette.cleavageBlue.withAlpha(160),
                    width: 0.9,
                  ),
                  color: RiftPalette.cleavageBlue.withAlpha(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gavel_rounded,
                        color: RiftPalette.splitWhite, size: 13.sp),
                    SizedBox(width: 6.w),
                    Text(
                      '⚒  HAMMER SERIES',
                      style: GoogleFonts.ibmPlexMono(
                        color: RiftPalette.splitWhite,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Field saturation toggle.
            GestureDetector(
              onTap: () => setState(() =>
                  _fieldSaturation = _fieldSaturation > 0.5 ? 0.3 : 1.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: RiftPalette.graniteGrey.withAlpha(140),
                    width: 0.9,
                  ),
                  color: _fieldSaturation > 0.5
                      ? RiftPalette.fractureAmber.withAlpha(22)
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _fieldSaturation > 0.5 ? Icons.visibility : Icons.visibility_off,
                      color: _fieldSaturation > 0.5
                          ? RiftPalette.fractureAmber
                          : RiftPalette.graniteGrey,
                      size: 13.sp,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'FIELD',
                      style: GoogleFonts.ibmPlexMono(
                        color: _fieldSaturation > 0.5
                            ? RiftPalette.fractureAmber
                            : RiftPalette.graniteGrey,
                        fontSize: 9.sp,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RIFT HINT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRiftHint() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: RiftPalette.quarryShadow.withAlpha(235),
          border: Border(
            top: BorderSide(color: RiftPalette.fractureAmber.withAlpha(100)),
            bottom: BorderSide(color: RiftPalette.fractureAmber.withAlpha(40)),
          ),
        ),
        child: Row(
          children: [
            // Pulsing amber dot.
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) => Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: RiftPalette.fractureAmber
                      .withAlpha((80 + 175 * _pulseCtrl.value).round()),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Read the rift — watch the heatmap corridors, '
                'tap when the brass sweep arm aligns with the selected tool.',
                style: GoogleFonts.ibmPlexMono(
                  color: RiftPalette.splitWhite.withAlpha(200),
                  fontSize: 9.sp,
                  height: 1.45,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // READOUT BANNER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildReadoutBanner() {
    return Positioned(
      top: 148.h,
      left: 14.w,
      right: 14.w,
      child: FadeTransition(
        opacity: _readoutFadeCtrl,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: RiftPalette.cleavageBlue.withAlpha(180),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: RiftPalette.cleavageBlue.withAlpha(40),
                blurRadius: 16,
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amber accent bar.
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: RiftPalette.fractureAmber,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    child: Text(
                      _stressReadout!,
                      style: GoogleFonts.ibmPlexMono(
                        color: RiftPalette.splitWhite,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FOCUS PANEL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFocusPanel(RiftNode node) {
    final imageProv = ref.watch(imageProvider);
    final item = node.items.first;

    // Slide-up offset based on split progress.
    final slideOffset = (1 - (((_splitProgress - 0.55) / 0.45).clamp(0.0, 1.0)));

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _focusTarget = null;
            _splitProgress = 0;
            _splitCtrl.reset();
          });
        },
        child: Container(
          color: Colors.black.withAlpha(140),
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(0, 120 * slideOffset),
            child: Opacity(
              opacity: (((_splitProgress - 0.55) / 0.45).clamp(0.0, 1.0)),
              child: GestureDetector(
                onTap: () {},
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 300.w,
                    maxHeight: _canvasSize.height * 0.48,
                  ),
                  child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  decoration: BoxDecoration(
                    // Stone-tablet look — dark linear gradient, double border.
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1A1D1C), Color(0xFF121514)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: RiftPalette.splitWhite.withAlpha(22),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(160),
                        blurRadius: 36,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: RiftPalette.fractureAmber.withAlpha(20),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                          // Incised header.
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'SPLIT INTERIOR',
                                  style: GoogleFonts.ibmPlexMono(
                                    color: RiftPalette.trierBrass,
                                    fontSize: 8.sp,
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                node.type.label.toUpperCase(),
                                style: GoogleFonts.ibmPlexMono(
                                  color: RiftPalette.trierBrass.withAlpha(160),
                                  fontSize: 7.sp,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5.h),
                          Container(
                            height: 0.8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  RiftPalette.trierBrass.withAlpha(180),
                                  RiftPalette.trierBrass.withAlpha(0),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          _glassPlatePhoto(imageProv, item),
                          SizedBox(height: 12.h),
                          _incisedField('Material & metallurgy', item.cuttingEdgeMetallurgy),
                          _incisedField('Form & action', item.dimensionalCleavageCapacity),
                          _incisedField('Provenance', item.excavationGroundZero),
                          _incisedField('Stone types worked', item.stoneType.label),
                          _incisedField('Era', item.era),
                          _incisedField('Hallmark', item.artisanHallmark),
                              ],
                            ),
                          ),
                        ),
                        _buildSpecimenStrip(node),
                      ],
                    ),
                  ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Short label for specimen chips so long bedding plane indices don't stretch the panel.
  String _abbreviateBeddingPlaneIndex(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 4) return trimmed;
    return '${trimmed.substring(0, 4)}…';
  }

  Widget _buildSpecimenStrip(RiftNode node) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: RiftPalette.trierBrass.withAlpha(70)),
        ),
        color: const Color(0xFF0E100F),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'OPEN SPECIMEN',
            style: GoogleFonts.ibmPlexMono(
              color: RiftPalette.trierBrass.withAlpha(170),
              fontSize: 7.sp,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 36.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: node.items.length,
              separatorBuilder: (ctx, i) => SizedBox(width: 7.w),
              itemBuilder: (context, index) {
                final sub = node.items[index];
                final fullLabel = sub.beddingPlaneIndex.isNotEmpty
                    ? sub.beddingPlaneIndex.trim()
                    : 'Specimen ${index + 1}';
                final displayLabel = sub.beddingPlaneIndex.isNotEmpty
                    ? _abbreviateBeddingPlaneIndex(fullLabel)
                    : fullLabel;
                return _masonryStampChip(
                  label: displayLabel,
                  tooltip: displayLabel != fullLabel ? fullLabel : null,
                  onTap: () {
                    final globalIndex = ref
                        .read(projectProvider)
                        .entries
                        .indexWhere((e) => e.id == sub.id);
                    if (globalIndex >= 0) {
                      Navigator.pushNamed(
                        context,
                        '/info_screen',
                        arguments: {'index': globalIndex},
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassPlatePhoto(ImageNotifier imageProv, MasonryToolModel item) {
    final path = imageProv.getImagePath(item.photoPath);
    final hasPhoto =
        path != null && item.photoPath.isNotEmpty && File(path).existsSync();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: RiftPalette.splitWhite.withAlpha(55),
          width: 1,
        ),
        // Aged albumen print mount — very subtle warm inner surround.
        boxShadow: [
          BoxShadow(
            color: RiftPalette.trierBrass.withAlpha(18),
            blurRadius: 0,
            spreadRadius: 3,
          ),
        ],
      ),
      child: SizedBox(
        height: 96.h,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: ColorFiltered(
            // Glass-plate negative / sepia filter.
            colorFilter: const ColorFilter.matrix([
              0.45, 0.42, 0.12, 0, 8,
              0.32, 0.38, 0.10, 0, 4,
              0.18, 0.20, 0.08, 0, 2,
              0,    0,    0,    1, 0,
            ]),
            child: hasPhoto
                ? Image.file(File(path), fit: BoxFit.cover)
                : Container(
                    color: RiftPalette.graniteGrey.withAlpha(180),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.architecture_rounded,
                      color: RiftPalette.splitWhite.withAlpha(80),
                      size: 28.sp,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _incisedField(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.ibmPlexMono(
              color: RiftPalette.trierBrass.withAlpha(170),
              fontSize: 7.sp,
              letterSpacing: 1.3,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: GoogleFonts.cormorantGaramond(
              color: RiftPalette.splitWhite,
              fontSize: 14.sp,
              height: 1.2,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            height: 0.4,
            color: RiftPalette.graniteGrey.withAlpha(100),
          ),
        ],
      ),
    );
  }

  /// Victorian masonry-stamp style chip.
  Widget _masonryStampChip({
    required String label,
    String? tooltip,
    required VoidCallback onTap,
  }) {
    final chip = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: RiftPalette.trierBrass.withAlpha(140),
            width: 0.8,
          ),
          color: RiftPalette.trierBrass.withAlpha(14),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.ibmPlexMono(
            color: RiftPalette.trierBrass,
            fontSize: 8.5.sp,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: chip);
    }
    return chip;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.layers_outlined,
            color: RiftPalette.splitWhite.withAlpha(55),
            size: 60.sp,
          ),
          SizedBox(height: 20.h),
          Text(
            'THE QUARRY FACE AWAITS SPECIMENS',
            style: GoogleFonts.ibmPlexMono(
              color: RiftPalette.splitWhite.withAlpha(120),
              fontSize: 11.sp,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: Text(
              'Record tools in the ledger to populate the stress field.',
              style: GoogleFonts.inter(
                color: RiftPalette.splitWhite.withAlpha(80),
                fontSize: 12.sp,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RiftNodePlate — precision-machined disc node widget
// ─────────────────────────────────────────────────────────────────────────────

class _RiftNodePlate extends StatefulWidget {
  final RiftNode node;
  final double sensorStress;
  final bool riftReading;
  final VoidCallback onRiftTap;
  final ValueChanged<RiftNode> onSelect;
  final ValueChanged<RiftNode> onStressRead;
  final VoidCallback onMoved;

  const _RiftNodePlate({
    required this.node,
    required this.sensorStress,
    required this.riftReading,
    required this.onRiftTap,
    required this.onSelect,
    required this.onStressRead,
    required this.onMoved,
  });

  @override
  State<_RiftNodePlate> createState() => _RiftNodePlateState();
}

class _RiftNodePlateState extends State<_RiftNodePlate>
    with SingleTickerProviderStateMixin {
  Timer? _holdTimer;
  bool _dragging = false;
  Offset? _lastGlobal;
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pressCtrl.dispose();
    super.dispose();
  }

  Color _gaugeDiscColor() {
    final t = widget.sensorStress.clamp(0.0, 1.0);
    return Color.lerp(
      RiftPalette.cleavageBlue.withAlpha(120),
      RiftPalette.fractureAmber.withAlpha(120),
      t,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final disc = node.radius * 2.2;

    // Gauge nodes glow with local stress colour.
    final isGauge = node.kind == RiftNodeKind.gauge;
    final discInnerColor = isGauge
        ? _gaugeDiscColor()
        : node.isGrabbed
            ? const Color(0xFF202624)
            : const Color(0xFF161918);

    return Positioned(
      left: node.x - disc / 2,
      top: node.y - disc / 2,
      width: disc,
      height: disc,
      child: RepaintBoundary(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            _dragging = false;
            _lastGlobal = e.position;
            _pressCtrl.forward();
            _holdTimer?.cancel();
            _holdTimer = Timer(const Duration(milliseconds: 480), () {
              if (!_dragging && mounted) {
                widget.onStressRead(node);
              }
            });
          },
          onPointerMove: (e) {
            if (_lastGlobal == null) return;
            final delta = e.position - _lastGlobal!;
            _lastGlobal = e.position;
            if (!_dragging && delta.distance > 6) {
              _dragging = true;
              _holdTimer?.cancel();
              setState(() => node.isGrabbed = true);
            }
            if (_dragging) {
              node.x += delta.dx;
              node.y += delta.dy;
              if (node.kind == RiftNodeKind.wedge) {
                node.orientation = math.atan2(delta.dy, delta.dx);
              }
              widget.onMoved();
            }
          },
          onPointerUp: (_) {
            _holdTimer?.cancel();
            _pressCtrl.reverse();
            if (_dragging) {
              setState(() => node.isGrabbed = false);
            } else if (widget.riftReading) {
              widget.onRiftTap();
            } else {
              widget.onSelect(node);
            }
          },
          onPointerCancel: (_) {
            _holdTimer?.cancel();
            _pressCtrl.reverse();
            setState(() => node.isGrabbed = false);
          },
          child: AnimatedBuilder(
            animation: _pressCtrl,
            builder: (_, child) => Transform.scale(
              scale: 1.0 - _pressCtrl.value * 0.06,
              child: child,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Radial gradient — machined disc face.
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.35),
                  radius: 0.85,
                  colors: [
                    discInnerColor.withAlpha(255),
                    RiftPalette.quarryShadow,
                  ],
                ),
                border: Border.all(
                  color: node.isGrabbed
                      ? RiftPalette.trierBrass
                      : RiftPalette.graniteGrey.withAlpha(170),
                  width: node.isGrabbed ? 1.8 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(140),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                  if (node.isGrabbed)
                    BoxShadow(
                      color: RiftPalette.trierBrass.withAlpha(55),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  if (isGauge)
                    BoxShadow(
                      color: Color.lerp(
                        RiftPalette.cleavageBlue,
                        RiftPalette.fractureAmber,
                        widget.sensorStress,
                      )!.withAlpha(60),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Tool icon — larger, brighter.
                  Padding(
                    padding: EdgeInsets.all(node.radius * 0.24),
                    child: CustomPaint(
                      painter: ToolElevationPainter(
                        toolClass: node.type,
                        color: isGauge
                            ? Color.lerp(
                                RiftPalette.cleavageBlue,
                                RiftPalette.fractureAmber,
                                widget.sensorStress,
                              )!
                            : RiftPalette.splitWhite,
                        operational: true,
                      ),
                    ),
                  ),

                  // Outer engraved ring — gives the machined-disc look.
                  Positioned.fill(
                    child: CustomPaint(painter: _DiscRingPainter(node.isGrabbed)),
                  ),

                  // Count + label badge at bottom.
                  Positioned(
                    bottom: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: RiftPalette.quarryShadow.withAlpha(230),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: node.isGrabbed
                              ? RiftPalette.trierBrass.withAlpha(180)
                              : RiftPalette.graniteGrey.withAlpha(100),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${node.count}',
                        style: GoogleFonts.ibmPlexMono(
                          color: node.isGrabbed
                              ? RiftPalette.trierBrass
                              : RiftPalette.splitWhite,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DiscRingPainter — engraved concentric ring on node disc face
// ─────────────────────────────────────────────────────────────────────────────
class _DiscRingPainter extends CustomPainter {
  final bool grabbed;
  const _DiscRingPainter(this.grabbed);

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    // Outer engraved ring.
    canvas.drawCircle(
      center,
      r * 0.88,
      Paint()
        ..color = (grabbed ? RiftPalette.trierBrass : RiftPalette.graniteGrey)
            .withAlpha(grabbed ? 90 : 55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    // Inner light-catch arc (top-left quadrant) — simulates machined bevel.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.88),
      -2.4,
      1.6,
      false,
      Paint()
        ..color = RiftPalette.splitWhite.withAlpha(grabbed ? 60 : 35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _DiscRingPainter old) => old.grabbed != grabbed;
}
