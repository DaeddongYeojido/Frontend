import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _ctrl;
  int? _selectedId;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  BitmapDescriptor? _markerIcon;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcon();
  }

  Future<void> _loadMarkerIcon() async {
    try {
      _markerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(90, 90)),
        'assets/images/marker.png',
      );
    } catch (_) {
    }
    final toilets = ref.read(nearbyToiletsProvider).value;
    if (toilets != null && mounted) _updateMarkers(toilets);
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationProvider);
    final filter        = ref.watch(toiletFilterProvider);

    ref.listen(nearbyToiletsProvider, (_, next) {
      next.whenData((toilets) => _updateMarkers(toilets));
    });

    ref.listen(locationProvider, (_, next) {
      next.whenData((pos) => _updateLocationCircle(pos.latitude, pos.longitude));
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          locationAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_off, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ]),
              ),
            ),
            data: (pos) => GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(pos.latitude, pos.longitude),
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
              circles: _circles,
              onMapCreated: (controller) {
                _ctrl = controller;
                final toilets = ref.read(nearbyToiletsProvider).value;
                if (toilets != null) _updateMarkers(toilets);
                _updateLocationCircle(pos.latitude, pos.longitude);
              },
              onTap: (_) {
                if (_selectedId != null) setState(() => _selectedId = null);
              },
            ),
          ),

          _TopBar(
            filter: filter,
            onFilterChanged: (f) =>
                ref.read(toiletFilterProvider.notifier).state = f,
          ),

          Positioned(
            right: 16,
            bottom: _selectedId != null ? 320 : 100,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: () async {
                final pos = ref.read(locationProvider).value;
                if (pos != null && _ctrl != null) {
                  _ctrl!.animateCamera(CameraUpdate.newLatLng(
                    LatLng(pos.latitude, pos.longitude),
                  ));
                }
              },
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

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
          radius: 20,
          fillColor: const Color(0xFF5C3D2E).withOpacity(0.15),
          strokeColor: Colors.transparent,
          strokeWidth: 0,
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

// ── TopBar ────────────────────────────────────────────────

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
          padding: EdgeInsets.fromLTRB(16, topPadding + 4, 16, 10),
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
          Icon(icon, size: 14,
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
