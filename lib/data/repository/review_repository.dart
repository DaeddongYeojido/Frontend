import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../model/review.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class ReviewRepository {
  final _dio = DioClient.instance;

  /// 태그 목록 조회
  Future<List<TagInfo>> getReviewTags() async {
    final res = await _dio.get(ApiConstants.reviewTags);
    return (res.data['data'] as List)
        .map((e) => TagInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewPage> getReviews(int toiletId, {int page = 0}) async {
    final res = await _dio.get(
      ApiConstants.reviews(toiletId),
      queryParameters: {'page': page, 'size': 10, 'sort': 'createdAt,desc'},
    );
    return ReviewPage.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// multipart/form-data — tags 필드 추가됨
  Future<Review> createReview({
    required int toiletId,
    required String deviceId,
    required int rating,
    String? content,
    File? image,
    List<String> tags = const [],
  }) async {
    final dataMap = <String, dynamic>{
      'deviceId': deviceId,
      'rating': rating,
      if (content != null && content.isNotEmpty) 'content': content,
      if (tags.isNotEmpty) 'tags': tags,
    };

    final formData = FormData.fromMap({
      'data': MultipartFile.fromString(
        jsonEncode(dataMap),
        contentType: DioMediaType('application', 'json'),
      ),
      if (image != null)
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
    });

    final res = await _dio.post(
      ApiConstants.reviews(toiletId),
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
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
