import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/review.dart';
import '../data/repository/review_repository.dart';
import '../core/utils/device_id_util.dart';
import '../core/network/dio_client.dart';

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

  /// 성공 시 null, 실패 시 에러 메시지 반환
  Future<String?> submit({
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
    if (result.hasError) {
      return extractErrorMessage(result.error,
          fallback: '리뷰 등록에 실패했습니다.');
    }
    ref.invalidate(reviewListProvider(toiletId));
    return null;
  }

  /// 성공 시 null, 실패 시 에러 메시지 반환
  Future<String?> delete({
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
    if (result.hasError) {
      return extractErrorMessage(result.error,
          fallback: '리뷰 삭제에 실패했습니다.');
    }
    ref.invalidate(reviewListProvider(toiletId));
    return null;
  }
}

final reviewNotifierProvider =
AsyncNotifierProvider<ReviewNotifier, void>(ReviewNotifier.new);
