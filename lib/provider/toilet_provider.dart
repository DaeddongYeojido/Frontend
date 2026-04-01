import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/toilet_summary.dart';
import '../data/model/toilet_detail.dart';
import '../data/repository/toilet_repository.dart';
import 'location_provider.dart';
import 'filter_provider.dart';

final toiletRepositoryProvider = Provider((ref) => ToiletRepository());

final nearbyToiletsProvider = FutureProvider<List<ToiletSummary>>((ref) async {
  final position = await ref.watch(locationProvider.future);
  final filter   = ref.watch(toiletFilterProvider);
  final repo     = ref.watch(toiletRepositoryProvider);
  return repo.getNearby(
    lat: position.latitude,
    lng: position.longitude,
    openStatus: filter.openStatusParam,
    isDisabled: filter.isDisabledParam,
  );
});

final toiletDetailProvider =
FutureProvider.family<ToiletDetail, int>((ref, id) async {
  return ref.watch(toiletRepositoryProvider).getDetail(id);
});

final selectedToiletIdProvider = StateProvider<int?>((ref) => null);
