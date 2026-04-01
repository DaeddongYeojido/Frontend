import '../model/toilet_summary.dart';
import '../model/toilet_detail.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class ToiletRepository {
  final _dio = DioClient.instance;

  Future<List<ToiletSummary>> getNearby({
    required double lat,
    required double lng,
    double radius = 1000,
    String? openStatus,
    bool? isDisabled,
  }) async {
    final res = await _dio.get(ApiConstants.nearby, queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      if (openStatus != null) 'openStatus': openStatus,
      if (isDisabled != null) 'isDisabled': isDisabled,
    });
    final List data = res.data['data'] as List;
    return data.map((e) => ToiletSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ToiletSummary> getNearest({
    required double lat,
    required double lng,
  }) async {
    final res = await _dio.get(ApiConstants.nearest,
        queryParameters: {'lat': lat, 'lng': lng});
    return ToiletSummary.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ToiletDetail> getDetail(int id) async {
    final res = await _dio.get(ApiConstants.detail(id));
    return ToiletDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
