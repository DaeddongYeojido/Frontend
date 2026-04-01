import 'package:hive/hive.dart';

part 'favorite_toilet.g.dart';

@HiveType(typeId: 0)
class FavoriteToilet extends HiveObject {
  @HiveField(0) final int id;
  @HiveField(1) final String name;
  @HiveField(2) final String address;
  @HiveField(3) final double lat;
  @HiveField(4) final double lng;
  @HiveField(5) final String openStatus;
  @HiveField(6) final bool isDisabled;
  @HiveField(7) final bool isGenderSep;

  FavoriteToilet({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.openStatus,
    required this.isDisabled,
    required this.isGenderSep,
  });
}
