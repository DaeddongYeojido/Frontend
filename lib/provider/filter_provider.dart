import 'package:flutter_riverpod/flutter_riverpod.dart';

class ToiletFilter {
  final bool showOnlyOpen;
  final bool showOnlyDisabled;

  const ToiletFilter({this.showOnlyOpen = false, this.showOnlyDisabled = false});

  ToiletFilter copyWith({bool? showOnlyOpen, bool? showOnlyDisabled}) =>
      ToiletFilter(
        showOnlyOpen: showOnlyOpen ?? this.showOnlyOpen,
        showOnlyDisabled: showOnlyDisabled ?? this.showOnlyDisabled,
      );

  String? get openStatusParam => showOnlyOpen ? 'OPEN' : null;
  bool?   get isDisabledParam => showOnlyDisabled ? true : null;
}

final toiletFilterProvider =
StateProvider<ToiletFilter>((ref) => const ToiletFilter());
