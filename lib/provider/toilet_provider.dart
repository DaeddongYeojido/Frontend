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

// ── 키워드 검색 ──────────────────────────────────────────────────────────────

class ToiletSearchState {
  final String keyword;
  final List<ToiletSearchResult> results;
  final bool isLoading;
  final String? error;

  const ToiletSearchState({
    this.keyword = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  ToiletSearchState copyWith({
    String? keyword,
    List<ToiletSearchResult>? results,
    bool? isLoading,
    String? error,
  }) =>
      ToiletSearchState(
        keyword: keyword ?? this.keyword,
        results: results ?? this.results,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  /// 2자 이상 입력했는데 결과가 없고 로딩도 아닌 상태
  bool get showEmpty =>
      keyword.trim().length >= 2 && results.isEmpty && !isLoading && error == null;
}

class ToiletSearchNotifier extends Notifier<ToiletSearchState> {
  @override
  ToiletSearchState build() => const ToiletSearchState();

  Future<void> search(String keyword, {double? lat, double? lng}) async {
    if (keyword.trim().length < 2) {
      state = state.copyWith(keyword: keyword, results: [], isLoading: false, error: null);
      return;
    }
    state = state.copyWith(keyword: keyword, isLoading: true, error: null);
    try {
      final results = await ref.read(toiletRepositoryProvider).searchToilets(
        keyword: keyword.trim(),
        lat: lat,
        lng: lng,
      );
      state = state.copyWith(results: results, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: '검색 중 오류가 발생했습니다',
        results: [],
      );
    }
  }

  void clear() => state = const ToiletSearchState();
}

final toiletSearchProvider =
NotifierProvider<ToiletSearchNotifier, ToiletSearchState>(
    ToiletSearchNotifier.new);
