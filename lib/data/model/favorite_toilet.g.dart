// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'favorite_toilet.dart';

class FavoriteToiletAdapter extends TypeAdapter<FavoriteToilet> {
  @override
  final int typeId = 0;

  @override
  FavoriteToilet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavoriteToilet(
      id: fields[0] as int,
      name: fields[1] as String,
      address: fields[2] as String,
      lat: fields[3] as double,
      lng: fields[4] as double,
      openStatus: fields[5] as String,
      isDisabled: fields[6] as bool,
      isGenderSep: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteToilet obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.address)
      ..writeByte(3)..write(obj.lat)
      ..writeByte(4)..write(obj.lng)
      ..writeByte(5)..write(obj.openStatus)
      ..writeByte(6)..write(obj.isDisabled)
      ..writeByte(7)..write(obj.isGenderSep);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FavoriteToiletAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}
