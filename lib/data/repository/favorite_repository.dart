import 'package:hive_flutter/hive_flutter.dart';
import '../model/favorite_toilet.dart';
import '../model/toilet_summary.dart';

class FavoriteRepository {
  static const _boxName = 'favorites';
  Box<FavoriteToilet> get _box => Hive.box<FavoriteToilet>(_boxName);

  List<FavoriteToilet> getAll() => _box.values.toList();
  bool isFavorite(int id) => _box.values.any((f) => f.id == id);

  Future<void> add(ToiletSummary t) async {
    await _box.put(t.id.toString(), FavoriteToilet(
      id: t.id, name: t.name, address: t.address,
      lat: t.lat, lng: t.lng, openStatus: t.openStatus,
      isDisabled: t.isDisabled, isGenderSep: t.isGenderSep,
    ));
  }

  Future<void> remove(int id) async => await _box.delete(id.toString());

  static Future<void> init() async =>
      await Hive.openBox<FavoriteToilet>(_boxName);

  static Future<Box<FavoriteToilet>> getBox() async =>
      Hive.box<FavoriteToilet>(_boxName);
}
