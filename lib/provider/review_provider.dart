import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/review.dart';
import '../data/repository/review_repository.dart';
import '../core/utils/device_id_util.dart';

final reviewRepositoryProvider = Provider((ref) => ReviewRepository());

// 리뷰 목록 (페이지 0 고정 — 추후 무한스크롤 확장 가능)
final reviewListProvider =
FutureProvider.family<ReviewPage, int>((ref, toiletId) async {
  return ref.watch(reviewRepositoryProvider).getReviews(toiletId);
});

// 내가 이 화장실에 리뷰를 썼는지 여부
final myReviewProvider =
StateProvider.family<bool, int>((ref, toiletId) => false);

class ReviewNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required int toiletId,
    required int rating,
    String? content,
  }) async {
    state = const AsyncLoading();
    final deviceId = await DeviceIdUtil.getDeviceId();
    final result = await AsyncValue.guard(
          () => ref.read(reviewRepositoryProvider).createReview(
        toiletId: toiletId,
        deviceId: deviceId,
        rating: rating,
        content: content,
      ),
    );
    state = const AsyncData(null);

    if (result.hasError) return false;

    // 목록 새로고침
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
