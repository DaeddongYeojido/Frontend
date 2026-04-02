import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/model/toilet_summary.dart';
import '../data/model/toilet_detail.dart';
import '../data/repository/toilet_repository.dart';
import 'location_provider.dart';
import 'filter_provider.dart';

final toiletRepositoryProvider = Provider((ref) => ToiletRepository());

// 지도 이동 검색 위치 (null이면 GPS 위치 사용)
final searchLocationProvider = StateProvider<LatLng?>((ref) => null);

final nearbyToiletsProvider = FutureProvider<List<ToiletSummary>>((ref) async {
  final position = await ref.watch(locationProvider.future);
  final filter = ref.watch(toiletFilterProvider);
  final searchLocation = ref.watch(searchLocationProvider);
  final repo = ref.watch(toiletRepositoryProvider);

  // 지도 이동 검색 위치가 있으면 그걸 사용, 없으면 GPS
  final lat = searchLocation?.latitude ?? position.latitude;
  final lng = searchLocation?.longitude ?? position.longitude;

  return repo.getNearby(
    lat: lat,
    lng: lng,
    openStatus: filter.openStatusParam,
    isDisabled: filter.isDisabledParam,
  );
});

final toiletDetailProvider =
    FutureProvider.family<ToiletDetail, int>((ref, id) async {
  return ref.watch(toiletRepositoryProvider).getDetail(id);
});

final selectedToiletIdProvider = StateProvider<int?>((ref) => null);
