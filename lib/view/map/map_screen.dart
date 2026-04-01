import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../provider/location_provider.dart';
import '../../provider/toilet_provider.dart';
import '../../provider/filter_provider.dart';
import '../../data/model/toilet_summary.dart';
import '../toilet/toilet_bottom_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  NaverMapController? _ctrl;
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationProvider);
    final filter        = ref.watch(toiletFilterProvider);

    ref.listen(nearbyToiletsProvider, (_, next) {
      next.whenData((toilets) => _updateMarkers(toilets));
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 지도
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
                      style: const TextStyle(color: AppColors.textSecondary)),
                ]),
              ),
            ),
            data: (pos) => NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(pos.latitude, pos.longitude),
                  zoom: 15,
                ),
                locationButtonEnable: false,
                consumeSymbolTapEvents: false,
              ),
              onMapReady: (controller) async {
                _ctrl = controller;
                controller.setLocationTrackingMode(
                    NLocationTrackingMode.follow);
                // 지도 준비 완료 후 현재 toilets 데이터로 마커 즉시 그리기
                final toilets = ref.read(nearbyToiletsProvider).value;
                if (toilets != null) _updateMarkers(toilets);
              },
              onMapTapped: (_, __) {
                if (_selectedId != null) {
                  setState(() => _selectedId = null);
                }
              },
            ),
          ),

          // 상단 앱바 + 필터
          _TopBar(
            filter: filter,
            onFilterChanged: (f) =>
                ref.read(toiletFilterProvider.notifier).state = f,
          ),

          // 바텀시트
          if (_selectedId != null)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: ToiletBottomSheet(toiletId: _selectedId!),
            ),
        ],
      ),
    );
  }

  Future<void> _updateMarkers(List<ToiletSummary> toilets) async {
    if (_ctrl == null) return;
    await _ctrl!.clearOverlays();
    for (final t in toilets) {
      final color = switch (t.openStatus) {
        'OPEN'  => AppColors.open,
        'NIGHT' => AppColors.night,
        _       => AppColors.closed,
      };
      final marker = NMarker(
        id: t.id.toString(),
        position: NLatLng(t.lat, t.lng),
        caption: NOverlayCaption(text: t.name, textSize: 10),
        iconTintColor: color,
      );
      marker.setOnTapListener((_) => setState(() => _selectedId = t.id));
      await _ctrl!.addOverlay(marker);
    }
  }
}

class _TopBar extends StatelessWidget {
  final ToiletFilter filter;
  final ValueChanged<ToiletFilter> onFilterChanged;
  const _TopBar({required this.filter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Image.asset('assets/images/logo.png', height: 32,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.wc, color: AppColors.primary, size: 32)),
              const SizedBox(width: 8),
              Image.asset('assets/images/textlogo.png', height: 22,
                  errorBuilder: (_, __, ___) =>
                      const Text('대똥여지도',
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
                  label: 'SHOW ONLY OPEN',
                  isActive: filter.showOnlyOpen,
                  onTap: () => onFilterChanged(
                      filter.copyWith(showOnlyOpen: !filter.showOnlyOpen)),
                ),
                const SizedBox(height: 6),
                _FilterChip(
                  icon: Icons.accessible,
                  label: 'HANDICAPPED ACCESSIBLE',
                  isActive: filter.showOnlyDisabled,
                  onTap: () => onFilterChanged(filter.copyWith(
                      showOnlyDisabled: !filter.showOnlyDisabled)),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  color: isActive ? Colors.white : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
