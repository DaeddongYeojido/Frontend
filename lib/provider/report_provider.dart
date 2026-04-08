import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/report.dart';
import '../data/repository/report_repository.dart';
import '../core/utils/device_id_util.dart';
import '../core/network/dio_client.dart';

final reportRepositoryProvider = Provider((ref) => ReportRepository());

final reportListProvider = FutureProvider<List<Report>>((ref) async {
  return ref.watch(reportRepositoryProvider).getReports();
});

final myReportListProvider = FutureProvider<List<Report>>((ref) async {
  final deviceId = await DeviceIdUtil.getDeviceId();
  return ref.watch(reportRepositoryProvider).getMyReports(deviceId: deviceId);
});

final reportTabProvider = StateProvider<int>((ref) => 0);

class ReportNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// 성공 시 null, 실패 시 에러 메시지 반환
  Future<String?> submit({
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
    state = const AsyncLoading();
    final deviceId = await DeviceIdUtil.getDeviceId();
    final result = await AsyncValue.guard(
          () => ref.read(reportRepositoryProvider).createReport(
        deviceId: deviceId,
        name: name,
        address: address,
        lat: lat,
        lng: lng,
        openStatus: openStatus,
        isDisabled: isDisabled,
        isGenderSep: isGenderSep,
        openHours: openHours,
        memo: memo,
        image: image,
      ),
    );
    state = const AsyncData(null);
    if (result.hasError) {
      return extractErrorMessage(result.error,
          fallback: '제보 등록에 실패했습니다.');
    }
    ref.invalidate(reportListProvider);
    ref.invalidate(myReportListProvider);
    return null;
  }
}

final reportNotifierProvider =
AsyncNotifierProvider<ReportNotifier, void>(ReportNotifier.new);
