import '../model/crowd_vote.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class CrowdRepository {
  final _dio = DioClient.instance;

  Future<CrowdVote> vote({
    required int toiletId,
    required String deviceId,
    required String level,
  }) async {
    final res = await _dio.post(
      ApiConstants.crowd(toiletId),
      data: {'deviceId': deviceId, 'level': level},
    );
    return CrowdVote.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
