import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationProvider = FutureProvider<Position>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) throw Exception('위치 서비스가 꺼져 있어요. 설정에서 켜주세요.');

  LocationPermission perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) throw Exception('위치 권한이 거부되었어요.');
  }
  if (perm == LocationPermission.deniedForever) {
    throw Exception('위치 권한이 영구 거부되었어요. 설정에서 허용해주세요.');
  }

  return await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
});
