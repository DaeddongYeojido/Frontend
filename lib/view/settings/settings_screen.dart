import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../provider/favorite_provider.dart';
import '../../data/repository/favorite_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('설정',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Section(title: '앱 정보', items: [
            _Item(
              icon: Icons.info_outline,
              label: '버전 정보',
              trailing: const Text('v1.0.0',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              onTap: () {},
            ),
            _Item(
                icon: Icons.article_outlined, label: '이용약관', onTap: () {}),
            _Item(
                icon: Icons.privacy_tip_outlined,
                label: '개인정보 처리방침',
                onTap: () {}),
          ]),
          const SizedBox(height: 16),
          _Section(title: '데이터', items: [
            _Item(
              icon: Icons.delete_outline,
              label: '즐겨찾기 전체 삭제',
              labelColor: AppColors.closed,
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('즐겨찾기 삭제'),
                  content: const Text('즐겨찾기를 모두 삭제할까요?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소')),
                    TextButton(
                      onPressed: () async {
                        final box = await FavoriteRepository.getBox();
                        await box.clear();
                        ref.invalidate(favoriteProvider);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('삭제',
                          style: TextStyle(color: AppColors.closed)),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: items.asMap().entries.map((e) => Column(children: [
                e.value,
                if (e.key < items.length - 1)
                  const Divider(
                      height: 1,
                      indent: 48,
                      endIndent: 16,
                      color: AppColors.filterBorder),
              ])).toList(),
        ),
      ),
    ]);
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback onTap;
  const _Item({
    required this.icon,
    required this.label,
    this.labelColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          size: 20, color: labelColor ?? AppColors.textSecondary),
      title: Text(label,
          style: TextStyle(
              fontSize: 14, color: labelColor ?? AppColors.textPrimary)),
      trailing: trailing ??
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
