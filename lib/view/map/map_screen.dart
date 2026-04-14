import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../provider/location_provider.dart';
import '../../provider/toilet_provider.dart';
import '../../provider/filter_provider.dart';
import '../../provider/paper_request_provider.dart';
import '../../data/model/toilet_summary.dart';
import '../../data/model/paper_request.dart';
import '../toilet/toilet_bottom_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _ctrl;
  int? _selectedId;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  BitmapDescriptor? _markerIcon;
  BitmapDescriptor? _myLocationIcon;

  LatLng? _mapCenter;
  bool _showSearchHereButton = false;

  // 휴지 분수 애니메이션 컨트롤러 제거 (새 방식에서는 _PaperOverlay 내부에서 관리)


  @override
  void initState() {
    super.initState();
    _loadMarkerIcon();
    _buildMyLocationCircleMarker();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadMarkerIcon() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/marker.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 70,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ByteData? byteData =
      await fi.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        _markerIcon =
            BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      }
    } catch (_) {}
    final toilets = ref.read(nearbyToiletsProvider).value;
    if (toilets != null && mounted) _updateMarkers(toilets);
  }

  Future<void> _buildMyLocationCircleMarker() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 36.0;
    final outerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, outerPaint);
    final innerPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawCircle(
        const Offset(size / 2, size / 2), size / 2 - 3, innerPaint);
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bytes != null && mounted) {
      setState(() {
        _myLocationIcon =
            BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationProvider);
    final filter = ref.watch(toiletFilterProvider);
    final activeMarkersAsync = ref.watch(activeMarkersProvider);

    // ── 핵심 수정: AsyncLoading 중에도 이전 value 유지되도록 직접 꺼냄
    final myRequest = ref.watch(paperRequestProvider).value;
    final isBannerVisible = myRequest != null && myRequest.isActive;

    // 활성 마커 동기화는 _PaperOverlay 내부에서 처리

    ref.listen(nearbyToiletsProvider, (_, next) {
      next.whenData(_updateMarkers);
    });
    ref.listen(locationProvider, (_, next) {
      next.whenData(
              (pos) => _updateLocationCircle(pos.latitude, pos.longitude));
    });

    final bottomSheetVisible = _selectedId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── 지도 ────────────────────────────────────────────────────────
          locationAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_off,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(e.toString(),
                      textAlign: TextAlign.center,
                      style:
                      const TextStyle(color: AppColors.textSecondary)),
                ]),
              ),
            ),
            data: (pos) => GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(pos.latitude, pos.longitude),
                zoom: 15,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                ..._markers,
                if (_myLocationIcon != null)
                  Marker(
                    markerId: const MarkerId('my_location'),
                    position: LatLng(pos.latitude, pos.longitude),
                    icon: _myLocationIcon!,
                    anchor: const Offset(0.5, 0.5),
                    zIndex: 999,
                  ),
              },
              circles: _circles,
              onMapCreated: (controller) {
                _ctrl = controller;
                final toilets = ref.read(nearbyToiletsProvider).value;
                if (toilets != null) _updateMarkers(toilets);
                _updateLocationCircle(pos.latitude, pos.longitude);
              },
              onCameraMove: (position) => _mapCenter = position.target,
              onCameraIdle: () {
                if (_mapCenter != null) {
                  setState(() => _showSearchHereButton = true);
                }
                setState(() {});
              },
              onTap: (_) {
                if (_selectedId != null) setState(() => _selectedId = null);
              },
            ),
          ),

          // ── 🧻 휴지 분수 / *구조* 오버레이 ──────────────────────────────
          if (activeMarkersAsync.value != null &&
              activeMarkersAsync.value!.isNotEmpty &&
              _ctrl != null)
            _PaperOverlay(
              activeMarkers: activeMarkersAsync.value!,
              mapController: _ctrl!,
            ),

          // ── TopBar ───────────────────────────────────────────────────────
          _TopBar(
            filter: filter,
            onFilterChanged: (f) =>
            ref.read(toiletFilterProvider.notifier).state = f,
          ),

          // ── 이 지역 검색 버튼 ─────────────────────────────────────────────
          if (_showSearchHereButton)
            Positioned(
              top: 130,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_mapCenter == null) return;
                    setState(() => _showSearchHereButton = false);
                    ref.read(searchLocationProvider.notifier).state =
                        _mapCenter;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search,
                            size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text('이 지역 검색',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── 🧻 휴지요청중 배너 (바텀시트가 없을 때만 표시) ────────────────────
          if (isBannerVisible && !bottomSheetVisible)
            _PaperRequestBanner(
              request: myRequest,
              toiletName: myRequest.toiletName,
            ),

          // ── 현위치 버튼 ───────────────────────────────────────────────────
          Positioned(
            right: 18,
            bottom: bottomSheetVisible
                ? 310 + MediaQuery.of(context).padding.bottom
                : isBannerVisible
                ? 130 + MediaQuery.of(context).padding.bottom
                : 16 + MediaQuery.of(context).padding.bottom + 20,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: () async {
                final pos = ref.read(locationProvider).value;
                if (pos != null && _ctrl != null) {
                  _ctrl!.animateCamera(CameraUpdate.newLatLng(
                      LatLng(pos.latitude, pos.longitude)));
                  ref.read(searchLocationProvider.notifier).state = null;
                  setState(() => _showSearchHereButton = false);
                }
              },
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // ── 화장실 바텀시트 ───────────────────────────────────────────────
          if (_selectedId != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ToiletBottomSheet(
                toiletId: _selectedId!,
                onDismiss: () => setState(() => _selectedId = null),
              ),
            ),
        ],
      ),
    );
  }

  void _updateLocationCircle(double lat, double lng) {
    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('user_halo'),
          center: LatLng(lat, lng),
          radius: 18,
          fillColor: const Color(0xFF4285F4).withOpacity(0.15),
          strokeColor: const Color(0xFF4285F4).withOpacity(0.3),
          strokeWidth: 1,
        ),
      };
    });
  }

  void _updateMarkers(List<ToiletSummary> toilets) {
    final icon = _markerIcon ?? BitmapDescriptor.defaultMarker;
    final markers = toilets.map((t) {
      return Marker(
        markerId: MarkerId(t.id.toString()),
        position: LatLng(t.lat, t.lng),
        icon: icon,
        onTap: () => setState(() => _selectedId = t.id),
      );
    }).toSet();
    setState(() => _markers = markers);
  }
}

// ── 휴지 분수 / *구조* 오버레이 ────────────────────────────────────────────────
// getScreenCoordinate 대신 구글맵 마커 + 커스텀 비트맵으로 구현

class _PaperOverlay extends StatefulWidget {
  final List<ActiveMarker> activeMarkers;

  final GoogleMapController mapController;

  const _PaperOverlay({
    super.key,
    required this.activeMarkers,
    required this.mapController,
  });

  @override
  State<_PaperOverlay> createState() => _PaperOverlayState();
}

class _PaperOverlayState extends State<_PaperOverlay> {
  // 각 마커별 애니메이션 프레임 인덱스 (0~5)
  final Map<int, int> _frameIndex = {};
  final Map<int, Timer?> _timers = {};

  // 미리 구워둔 비트맵 (프레임별)
  static List<BitmapDescriptor>? _paperFrames;
  static BitmapDescriptor? _rescuedIcon;
  bool _iconsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t?.cancel();
    }
    super.dispose();
  }

  Future<void> _loadIcons() async {
    if (_paperFrames != null && _rescuedIcon != null) {
      if (mounted) setState(() => _iconsLoaded = true);
      return;
    }

    // 휴지 PNG를 6가지 오프셋(분수 효과)으로 미리 렌더링
    final frames = <BitmapDescriptor>[];
    final ByteData paperData =
    await rootBundle.load('assets/images/toilet_paper.png');
    final ui.Codec codec = await ui.instantiateImageCodec(
      paperData.buffer.asUint8List(),
      targetWidth: 60,
      targetHeight: 60,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image paperImg = fi.image;

    for (int i = 0; i < 6; i++) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 80, 120));

      // 분수 궤적 계산
      final double t = i / 6.0;
      final double angle = (i * 60.0 - 90) * pi / 180;
      final double dist = t * 50;
      final double x = 40 + sin(angle) * dist - 30;
      final double y = 80 - (dist * 0.8) - t * t * 30;

      canvas.drawImageRect(
        paperImg,
        Rect.fromLTWH(0, 0, paperImg.width.toDouble(), paperImg.height.toDouble()),
        Rect.fromLTWH(x, y, 60, 60),
        Paint()..color = Colors.white.withOpacity((1.0 - t).clamp(0.3, 1.0)),
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(80, 120);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        frames.add(BitmapDescriptor.fromBytes(bytes.buffer.asUint8List()));
      }
    }
    _paperFrames = frames;

    // *구조* 아이콘 생성
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 120, 40));
    final paint = Paint()..color = Colors.green.shade700;
    final rrect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 120, 40), const Radius.circular(20));
    canvas.drawRRect(rrect, paint);

    const textStyle = TextStyle(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);
    final textSpan = TextSpan(text: '*구조*', style: textStyle);
    final textPainter = TextPainter(
        text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(
        canvas, Offset((120 - textPainter.width) / 2, (40 - textPainter.height) / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(120, 40);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bytes != null) {
      _rescuedIcon = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
    }

    if (mounted) setState(() => _iconsLoaded = true);
    _startAnimations();
  }

  void _startAnimations() {
    for (final m in widget.activeMarkers) {
      if (m.isPaperFlying && !_timers.containsKey(m.toiletId)) {
        _frameIndex[m.toiletId] = 0;
        _timers[m.toiletId] = Timer.periodic(
          const Duration(milliseconds: 200),
              (_) {
            if (mounted) {
              setState(() {
                _frameIndex[m.toiletId] =
                    ((_frameIndex[m.toiletId] ?? 0) + 1) % 6;
              });
            }
          },
        );
      }
    }
  }

  @override
  void didUpdateWidget(_PaperOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 새 마커 타이머 시작
    for (final m in widget.activeMarkers) {
      if (m.isPaperFlying && !_timers.containsKey(m.toiletId)) {
        _frameIndex[m.toiletId] = 0;
        _timers[m.toiletId] = Timer.periodic(
          const Duration(milliseconds: 200),
              (_) {
            if (mounted) {
              setState(() {
                _frameIndex[m.toiletId] =
                    ((_frameIndex[m.toiletId] ?? 0) + 1) % 6;
              });
            }
          },
        );
      }
    }
    // 사라진 마커 타이머 제거
    final currentIds = widget.activeMarkers.map((m) => m.toiletId).toSet();
    final toRemove =
    _timers.keys.where((id) => !currentIds.contains(id)).toList();
    for (final id in toRemove) {
      _timers[id]?.cancel();
      _timers.remove(id);
      _frameIndex.remove(id);
    }
  }

  /// 마커 위 살짝 위에 표시하기 위해 위도를 오프셋
  LatLng _offsetLatLng(double lat, double lng, double meterNorth) {
    const double metersPerDegree = 111320.0;
    return LatLng(lat + meterNorth / metersPerDegree, lng);
  }

  @override
  Widget build(BuildContext context) {
    if (!_iconsLoaded || widget.activeMarkers.isEmpty) {
      return const SizedBox.shrink();
    }

    // 마커 Set을 부모에 올리는 대신 Positioned.fill + IgnorePointer로 감싸서
    // GoogleMap 위에 오버레이되는 별도 마커 레이어처럼 동작하게 함
    // → 실제로는 GoogleMap의 markers에 추가해야 하므로, 이 위젯은 신호만 보내고
    //   부모(_MapScreenState)가 마커를 관리하는 구조로 리팩토링 필요
    //
    // 여기서는 간단히 Stack 오버레이 방식 유지하되 좌표 변환 문제를 피하기 위해
    // CustomPainter로 직접 그림

    return Positioned.fill(
      child: IgnorePointer(
        child: _PaperOverlayPainter(
          activeMarkers: widget.activeMarkers,
          frameIndex: _frameIndex,
          paperFrames: _paperFrames,
          rescuedIcon: _rescuedIcon,
          mapController: widget.mapController,
        ),
      ),
    );
  }
}

class _PaperOverlayPainter extends StatefulWidget {
  final List<ActiveMarker> activeMarkers;
  final Map<int, int> frameIndex;
  final List<BitmapDescriptor>? paperFrames;
  final BitmapDescriptor? rescuedIcon;
  final GoogleMapController mapController;

  const _PaperOverlayPainter({
    required this.activeMarkers,
    required this.frameIndex,
    required this.paperFrames,
    required this.rescuedIcon,
    required this.mapController,
  });

  @override
  State<_PaperOverlayPainter> createState() => _PaperOverlayPainterState();
}

class _PaperOverlayPainterState extends State<_PaperOverlayPainter> {
  final Map<int, Offset> _positions = {};

  @override
  void initState() {
    super.initState();
    _updatePositions();
  }

  @override
  void didUpdateWidget(_PaperOverlayPainter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePositions();
  }

  Future<void> _updatePositions() async {
    if (!mounted) return;
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final Map<int, Offset> result = {};
    for (final m in widget.activeMarkers) {
      try {
        final sp = await widget.mapController.getScreenCoordinate(
          LatLng(m.toiletLat, m.toiletLng),
        );
        result[m.toiletId] = Offset(sp.x / dpr, sp.y / dpr);
      } catch (_) {}
    }
    if (mounted) setState(() => _positions
      ..clear()
      ..addAll(result));
  }

  // 외부에서 갱신 트리거용
  void refresh() => _updatePositions();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: widget.activeMarkers.map((marker) {
        final pos = _positions[marker.toiletId];
        if (pos == null) return const SizedBox.shrink();

        if (marker.isRescued) {
          return Positioned(
            left: pos.dx - 33,
            top: pos.dy - 70,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Text(
                '*구조*',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        }

        // 휴지 분수: 현재 프레임 기준 6개 파티클
        final frame = widget.frameIndex[marker.toiletId] ?? 0;
        return Positioned(
          left: pos.dx - 45,
          top: pos.dy - 110,
          child: _ToiletPaperFountain(frame: frame),
        );
      }).toList(),
    );
  }
}

class _ToiletPaperFountain extends StatelessWidget {
  final int frame;
  const _ToiletPaperFountain({required this.frame});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 110,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(6, (i) {
          final t = ((i + frame) % 6) / 6.0;
          final angle = (i * 60.0 - 90) * pi / 180;
          final dist = t * 55;
          final x = sin(angle) * dist;
          final y = cos(angle) * dist * 0.6 - t * t * 25;
          final opacity = (1.0 - t * 0.8).clamp(0.2, 1.0);
          final size = (1.0 - t * 0.4).clamp(0.5, 1.0) * 42;

          return Positioned(
            bottom: 8 + y,
            left: 45 + x - size / 2,
            child: Opacity(
              opacity: opacity,
              child: Image.asset(
                'assets/images/toilet_paper.png',
                width: size,
                height: size,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── 휴지요청중 배너 ───────────────────────────────────────────────────────────

class _PaperRequestBanner extends ConsumerStatefulWidget {
  final PaperRequest request;
  final String toiletName;
  const _PaperRequestBanner({required this.request, required this.toiletName});

  @override
  ConsumerState<_PaperRequestBanner> createState() =>
      _PaperRequestBannerState();
}

class _PaperRequestBannerState extends ConsumerState<_PaperRequestBanner> {
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.request.remainingSeconds;
    _startCountdown();
  }

  @override
  void didUpdateWidget(_PaperRequestBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.request.remainingSeconds != oldWidget.request.remainingSeconds) {
      _remaining = widget.request.remainingSeconds;
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _remaining = (_remaining - 1).clamp(0, 999999));
      return _remaining > 0 && widget.request.isActive;
    });
  }

  String get _timeStr {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _onSurvived() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '누군가 구조해주셨나요? 🙏',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        content: const Text(
          '확인을 누르면 휴지 요청이 종료되고\n지도에 *구조* 표시가 3분간 나타납니다 🎉',
          style: TextStyle(
              fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('아직이요',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('살았어요! 🎉'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(paperRequestProvider.notifier).rescue();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16 + MediaQuery.of(context).padding.bottom,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('🧻', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '휴지요청중..',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.toiletName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _timeStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSurvived,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text(
                  '🙏 살았습니다.',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TopBar (기존 코드 그대로) ─────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final ToiletFilter filter;
  final ValueChanged<ToiletFilter> onFilterChanged;
  const _TopBar({required this.filter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: AppColors.background,
          padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 10),
          child: Row(children: [
            Image.asset('assets/images/logo.png',
                height: 32,
                errorBuilder: (_, __, ___) => const Icon(Icons.wc,
                    color: AppColors.primary, size: 32)),
            const SizedBox(width: 8),
            Image.asset('assets/images/textlogo.png',
                height: 22,
                errorBuilder: (_, __, ___) => const Text('대똥여지도',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 14, top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterChip(
                icon: Icons.access_time,
                label: '운영중만 보기',
                isActive: filter.showOnlyOpen,
                onTap: () => onFilterChanged(
                    filter.copyWith(showOnlyOpen: !filter.showOnlyOpen)),
              ),
              const SizedBox(height: 6),
              _FilterChip(
                icon: Icons.accessible,
                label: '장애인 화장실',
                isActive: filter.showOnlyDisabled,
                onTap: () => onFilterChanged(filter.copyWith(
                    showOnlyDisabled: !filter.showOnlyDisabled)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.filterBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive ? AppColors.primary : AppColors.filterBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 14,
              color: isActive ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color:
                  isActive ? Colors.white : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
