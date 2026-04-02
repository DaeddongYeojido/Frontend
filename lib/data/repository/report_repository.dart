import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../model/report.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class ReportRepository {
  final _dio = DioClient.instance;

  Future<List<Report>> getReports({int page = 0, int size = 20}) async {
    final res = await _dio.get(
      ApiConstants.reports,
      queryParameters: {'page': page, 'size': size, 'sort': 'createdAt,desc'},
    );
    final pageData = res.data['data'] as Map<String, dynamic>;
    final list = pageData['content'] as List? ?? [];
    return list.map((e) => Report.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Report>> getMyReports({required String deviceId}) async {
    final res = await _dio.get(
      ApiConstants.myReports,
      queryParameters: {'deviceId': deviceId},
    );
    final pageData = res.data['data'] as Map<String, dynamic>;
    final list = pageData['content'] as List? ?? [];
    return list.map((e) => Report.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Report> createReport({
    required String deviceId,
    required String name,
    required String address,
    required double lat,
    required double lng,
    String? openStatus,
    bool? isDisabled,
    bool? isGenderSep,
    String? openHours,
    String? memo,
    File? image,
  }) async {
    final dataMap = <String, dynamic>{
      'deviceId': deviceId,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      if (openStatus != null) 'openStatus': openStatus,
      if (isDisabled != null) 'isDisabled': isDisabled,
      if (isGenderSep != null) 'isGenderSep': isGenderSep,
      if (openHours != null && openHours.isNotEmpty) 'openHours': openHours,
      if (memo != null && memo.isNotEmpty) 'memo': memo,
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
      ApiConstants.reports,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return Report.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
