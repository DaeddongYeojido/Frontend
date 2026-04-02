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
              icon: Icons.article_outlined,
              label: '이용약관',
              onTap: () => _showPolicy(context, _PolicyType.terms),
            ),
            _Item(
              icon: Icons.privacy_tip_outlined,
              label: '개인정보 처리방침',
              onTap: () => _showPolicy(context, _PolicyType.privacy),
            ),
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

  void _showPolicy(BuildContext context, _PolicyType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PolicyScreen(type: type),
      ),
    );
  }
}

enum _PolicyType { terms, privacy }

class _PolicyScreen extends StatelessWidget {
  final _PolicyType type;
  const _PolicyScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isTerms = type == _PolicyType.terms;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isTerms ? '이용약관' : '개인정보 처리방침',
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: isTerms ? const _TermsContent() : const _PrivacyContent(),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicySection(
          title: '제1조 (목적)',
          body:
              '본 약관은 대똥여지도(이하 "서비스")가 제공하는 공공화장실 정보 제공 서비스의 이용 조건 및 절차, 이용자와 서비스 제공자 간의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.',
        ),
        _PolicySection(
          title: '제2조 (서비스 내용)',
          body:
              '서비스는 사용자의 현재 위치를 기반으로 주변 공공화장실의 위치, 운영 상태, 혼잡도 정보 등을 제공합니다. 화장실 데이터는 공공 데이터 및 사용자 제보를 기반으로 하며, 실제 정보와 다를 수 있습니다.',
        ),
        _PolicySection(
          title: '제3조 (이용자의 의무)',
          body:
              '이용자는 서비스를 이용함에 있어 다음 행위를 해서는 안 됩니다.\n\n• 허위 정보 등록 및 악의적 리뷰 작성\n• 서비스의 정상적인 운영을 방해하는 행위\n• 타인의 개인정보 수집·저장·공개 행위',
        ),
        _PolicySection(
          title: '제4조 (서비스 중단)',
          body:
              '서비스는 시스템 정기점검, 증설 및 교체 작업, 천재지변 등의 사유로 서비스를 일시 중단할 수 있으며, 이 경우 사전에 공지합니다.',
        ),
        _PolicySection(
          title: '제5조 (면책조항)',
          body:
              '서비스는 화장실 위치 정보의 정확성을 보장하지 않으며, 정보 오류로 인한 불편에 대해 법적 책임을 지지 않습니다. 서비스 이용 중 발생하는 손해에 대해 서비스 제공자의 고의 또는 중과실이 없는 한 책임을 지지 않습니다.',
        ),
        _PolicySection(
          title: '부칙',
          body: '본 약관은 2025년 1월 1일부터 시행됩니다.',
        ),
      ],
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicySection(
          title: '1. 수집하는 개인정보 항목',
          body:
              '서비스는 다음과 같은 정보를 수집합니다.\n\n• 위치 정보: 주변 화장실 검색을 위한 현재 위치 (GPS)\n• 기기 식별자: 리뷰 및 혼잡도 투표 중복 방지를 위한 익명 기기 ID\n• 서비스 이용 기록: 앱 오류 로그 및 이용 통계',
        ),
        _PolicySection(
          title: '2. 개인정보 수집 및 이용 목적',
          body:
              '수집된 정보는 아래 목적으로만 사용됩니다.\n\n• 주변 공공화장실 검색 및 정보 제공\n• 혼잡도 투표 및 리뷰 서비스 운영\n• 서비스 품질 향상 및 오류 개선',
        ),
        _PolicySection(
          title: '3. 개인정보 보유 및 이용 기간',
          body:
              '위치 정보는 서비스 이용 시에만 일시적으로 사용되며 서버에 저장되지 않습니다. 기기 식별자는 앱 설치 기간 동안 유지됩니다. 리뷰 데이터는 사용자 삭제 요청 시 즉시 파기됩니다.',
        ),
        _PolicySection(
          title: '4. 제3자 제공',
          body:
              '서비스는 사용자의 개인정보를 원칙적으로 제3자에게 제공하지 않습니다. 단, 법령에 의해 요구되는 경우 예외적으로 제공될 수 있습니다.',
        ),
        _PolicySection(
          title: '5. 이용자의 권리',
          body:
              '이용자는 언제든지 자신의 리뷰 및 데이터 삭제를 요청할 수 있습니다. 위치 정보 수집을 원하지 않는 경우 기기 설정에서 위치 권한을 거부할 수 있으나, 이 경우 일부 서비스 이용이 제한됩니다.',
        ),
        _PolicySection(
          title: '6. 문의',
          body:
              '개인정보 처리에 관한 문의사항은 앱 내 피드백 기능을 통해 접수하실 수 있습니다.\n\n시행일: 2025년 1월 1일',
        ),
      ],
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.7)),
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
      leading:
          Icon(icon, size: 20, color: labelColor ?? AppColors.textSecondary),
      title: Text(label,
          style: TextStyle(
              fontSize: 14, color: labelColor ?? AppColors.textPrimary)),
      trailing: trailing ??
          const Icon(Icons.chevron_right,
              size: 18, color: AppColors.textHint),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
