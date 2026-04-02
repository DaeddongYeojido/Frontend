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

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  int _prevIndex = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _screens = [
    MapScreen(),
    FavoritesScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.value = 1.0; // 처음엔 바로 보임
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (i == _index) return;
    // ⑤ fade-out → 화면 교체 → fade-in
    _animCtrl.reverse().then((_) {
      setState(() {
        _prevIndex = _index;
        _index = i;
      });
      _animCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _index,
        onTap: _onTap,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.map,             label: '지도'),
    (icon: Icons.favorite,        label: '즐겨찾기'),
    (icon: Icons.article_outlined, label: '제보 게시판'),
    (icon: Icons.settings,        label: '설정'),
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
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 6),
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
