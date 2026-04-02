import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/review.dart';
import '../data/repository/review_repository.dart';
import '../core/utils/device_id_util.dart';

final reviewRepositoryProvider = Provider((ref) => ReviewRepository());

final reviewListProvider =
    FutureProvider.family<ReviewPage, int>((ref, toiletId) async {
  return ref.watch(reviewRepositoryProvider).getReviews(toiletId);
});

final myReviewProvider =
    StateProvider.family<bool, int>((ref, toiletId) => false);

class ReviewNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required int toiletId,
    required int rating,
    String? content,
    File? image,
  }) async {
    state = const AsyncLoading();
    final deviceId = await DeviceIdUtil.getDeviceId();
    final result = await AsyncValue.guard(
      () => ref.read(reviewRepositoryProvider).createReview(
            toiletId: toiletId,
            deviceId: deviceId,
            rating: rating,
            content: content,
            image: image,
          ),
    );
    state = const AsyncData(null);
    if (result.hasError) return false;
    ref.invalidate(reviewListProvider(toiletId));
    return true;
  }

  Future<bool> delete({
    required int toiletId,
    required int reviewId,
  }) async {
    state = const AsyncLoading();
    final deviceId = await DeviceIdUtil.getDeviceId();
    final result = await AsyncValue.guard(
      () => ref.read(reviewRepositoryProvider).deleteReview(
            toiletId: toiletId,
            reviewId: reviewId,
            deviceId: deviceId,
          ),
    );
    state = const AsyncData(null);
    if (result.hasError) return false;
    ref.invalidate(reviewListProvider(toiletId));
    return true;
  }
}

final reviewNotifierProvider =
    AsyncNotifierProvider<ReviewNotifier, void>(ReviewNotifier.new);
