import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_colors.dart';
import 'data/model/favorite_toilet.dart';
import 'data/repository/favorite_repository.dart';
import 'view/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 스타일
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  await Hive.initFlutter();
  Hive.registerAdapter(FavoriteToiletAdapter());
  await FavoriteRepository.init();

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
      home: const _SplashGate(),
    );
  }
}

// ── 스플래시 → 메인 전환 ─────────────────────────────────────────────────────

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  bool _showMain = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    // 1.2초 후 페이드 아웃 → 메인으로 전환
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _ctrl.forward().then((_) {
        if (mounted) setState(() => _showMain = true);
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showMain) return const MainShell();

    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fade),
      child: const _SplashScreen(),
    );
  }
}

// ── 스플래시 화면 UI ──────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ddong.png 로고 (가운데 살짝 위)
            Transform.translate(
              offset: const Offset(0, -20),
              child: Image.asset(
                'assets/images/ddong.png',
                width: 140,
                height: 140,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.wc,
                  size: 140,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
