import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../model/paper_request.dart';

class PaperRequestRepository {
  final _dio = DioClient.instance;

  /// 휴지 요청 생성
  Future<PaperRequest> createRequest({
    required int toiletId,
    required String deviceId,
    required String gender,
    required double lat,
    required double lng,
  }) async {
    final res = await _dio.post(
      ApiConstants.paperRequests,
      data: {
        'toiletId': toiletId,
        'deviceId': deviceId,
        'gender': gender,
        'lat': lat,
        'lng': lng,
      },
    );
    return PaperRequest.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// 구조 완료 ("살았습니다.")
  Future<PaperRequest> rescue({
    required int requestId,
    required String deviceId,
  }) async {
    final res = await _dio.post(
      ApiConstants.paperRequestRescue(requestId),
      queryParameters: {'deviceId': deviceId},
    );
    return PaperRequest.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// 내 요청 상태 조회
  Future<PaperRequest> getStatus({
    required int requestId,
    required String deviceId,
  }) async {
    final res = await _dio.get(
      ApiConstants.paperRequestStatus(requestId),
      queryParameters: {'deviceId': deviceId},
    );
    return PaperRequest.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// 지도 마커용 전체 활성 요청 조회
  Future<List<ActiveMarker>> getActiveMarkers() async {
    final res = await _dio.get(ApiConstants.paperRequestActiveMarkers);
    final List data = res.data['data'] as List;
    return data
        .map((e) => ActiveMarker.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// FCM 토큰 등록
  Future<void> registerFcmToken({
    required String deviceId,
    required String fcmToken,
    required double lat,
    required double lng,
  }) async {
    await _dio.post(
      ApiConstants.paperRequestFcmToken,
      queryParameters: {
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'lat': lat,
        'lng': lng,
      },
    );
  }
}
