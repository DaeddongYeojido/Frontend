import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'map/map_screen.dart';
import 'favorites/favorites_screen.dart';
import 'report/report_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _prevIndex = 0;

  // 지도 탭(0)으로 올 때 로딩 오버레이 표시 여부
  bool _showMapOverlay = true;

  static const _screens = [
    MapScreen(),
    FavoritesScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  void _onTabTap(int i) {
    if (i == _index) return;
    final comingToMap = i == 0;
    setState(() {
      _prevIndex = _index;
      _index = i;
      if (comingToMap) _showMapOverlay = true;
    });
  }

  void _onOverlayDone() {
    if (mounted) setState(() => _showMapOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 화면들 (IndexedStack으로 상태 유지)
          IndexedStack(
            index: _index,
            children: _screens,
          ),

          // 지도 탭일 때만 로딩 오버레이 표시
          if (_index == 0 && _showMapOverlay)
            _MapLoadingOverlay(onDone: _onOverlayDone),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _index,
        onTap: _onTabTap,
      ),
    );
  }
}

// ── 지도 로딩 오버레이 ────────────────────────────────────────────────────────

class _MapLoadingOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const _MapLoadingOverlay({required this.onDone});

  @override
  State<_MapLoadingOverlay> createState() => _MapLoadingOverlayState();
}

class _MapLoadingOverlayState extends State<_MapLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeOut;
  bool _fading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeOut = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    // 1초 표시 후 페이드 아웃
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _fading = true);
      _ctrl.forward().then((_) {
        if (mounted) widget.onDone();
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
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeOut),
      child: Container(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: const Offset(0, -24),
                child: Image.asset(
                  'assets/images/logos.png',
                  width: 90,
                  height: 90,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.wc,
                    size: 90,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -16),
                child: Column(
                  children: [
                    const Text(
                      '로딩중',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── BottomNav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.map, label: '지도'),
    (icon: Icons.favorite, label: '즐겨찾기'),
    (icon: Icons.article_outlined, label: '제보 게시판'),
    (icon: Icons.settings, label: '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navBg,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: _items.asMap().entries.map((e) {
              final isSelected = e.key == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(e.key),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(e.value.icon,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            size: 22),
                        const SizedBox(height: 2),
                        Text(e.value.label,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                                fontSize: 9,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
