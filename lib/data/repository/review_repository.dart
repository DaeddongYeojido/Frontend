import '../model/review.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class ReviewRepository {
  final _dio = DioClient.instance;

  Future<ReviewPage> getReviews(int toiletId, {int page = 0}) async {
    final res = await _dio.get(
      ApiConstants.reviews(toiletId),
      queryParameters: {'page': page, 'size': 10, 'sort': 'createdAt,desc'},
    );
    return ReviewPage.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Review> createReview({
    required int toiletId,
    required String deviceId,
    required int rating,
    String? content,
  }) async {
    final res = await _dio.post(
      ApiConstants.reviews(toiletId),
      data: {
        'deviceId': deviceId,
        'rating': rating,
        if (content != null && content.isNotEmpty) 'content': content,
      },
    );
    return Review.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteReview({
    required int toiletId,
    required int reviewId,
    required String deviceId,
  }) async {
    await _dio.delete(
      ApiConstants.deleteReview(toiletId, reviewId),
      queryParameters: {'deviceId': deviceId},
    );
  }
}
