import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/app_colors.dart';
import 'data/model/favorite_toilet.dart';
import 'data/repository/favorite_repository.dart';
import 'view/main_shell.dart';

// 백그라운드 FCM 핸들러 (top-level 함수여야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // 백그라운드 수신 시 별도 처리 필요하면 여기에 추가
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Firebase 초기화
  await Firebase.initializeApp();

  // 백그라운드 메시지 �핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 포그라운드 알림 표시 설정 (iOS)
  await FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

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
