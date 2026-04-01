import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_colors.dart';
import 'data/model/favorite_toilet.dart';
import 'data/repository/favorite_repository.dart';
import 'view/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(FavoriteToiletAdapter());
  await FavoriteRepository.init();

  await NaverMapSdk.instance.initialize(clientId: 'a60t7fi5fr');

  runApp(const ProviderScope(child: DaeddongApp()));
}

class DaeddongApp extends StatelessWidget {
  const DaeddongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '대똥여지도',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}
