import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/model/report.dart';
import '../../provider/report_provider.dart';
import 'report_write_screen.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(reportTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '제보게시판',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportWriteScreen()),
              ),
              icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
              label: const Text(
                '제보하기',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 탭
          _TabBar(currentTab: tab, onTab: (i) {
            ref.read(reportTabProvider.notifier).state = i;
          }),
          const SizedBox(height: 4),
          Expanded(
            child: tab == 0
                ? const _AllReportList()
                : const _MyReportList(),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTab;
  const _TabBar({required this.currentTab, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          _TabItem(label: '전체 제보', index: 0, current: currentTab, onTap: onTab),
          _TabItem(label: '내 제보', index: 1, current: currentTab, onTap: onTab),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  const _TabItem(
      {required this.label,
      required this.index,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ── 전체 제보 목록 ──────────────────────────────────────────────────────

class _AllReportList extends ConsumerWidget {
  const _AllReportList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportListProvider);
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(reportListProvider)),
      data: (list) => list.isEmpty
          ? const _EmptyView(message: '아직 등록된 제보가 없어요.')
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(reportListProvider),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: list.length,
                itemBuilder: (_, i) => _ReportCard(report: list[i], showStatus: false),
              ),
            ),
    );
  }
}

// ── 내 제보 목록 ────────────────────────────────────────────────────────

class _MyReportList extends ConsumerWidget {
  const _MyReportList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myReportListProvider);
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(myReportListProvider)),
      data: (list) => list.isEmpty
          ? const _EmptyView(message: '아직 제보를 작성하지 않았어요.')
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(myReportListProvider),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    _ReportCard(report: list[i], showStatus: true),
              ),
            ),
    );
  }
}

// ── 카드 ────────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final Report report;
  final bool showStatus;
  const _ReportCard({required this.report, required this.showStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: report.imageUrl != null
                  ? Image.network(
                      report.imageUrl!,
                      width: 62, height: 62,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PlaceholderIcon(),
                    )
                  : _PlaceholderIcon(),
            ),
            const SizedBox(width: 12),
            // 본문
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        report.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showStatus) ...[
                      const SizedBox(width: 8),
                      _StatusBadge(status: report.status),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        report.address,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  if (report.memo != null && report.memo!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      report.memo!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    if (report.isDisabled == true)
                      _Chip(icon: Icons.accessible, label: '장애인'),
                    if (report.isGenderSep == true)
                      _Chip(icon: Icons.wc, label: '남녀구분'),
                    const Spacer(),
                    Text(
                      _formatDate(report.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}

class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 62, height: 62,
        color: AppColors.background,
        child: const Icon(Icons.wc, color: AppColors.textHint, size: 28),
      );
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 10, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _StatusBadge extends StatelessWidget {
  final ReportStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (status) {
      case ReportStatus.approved:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case ReportStatus.rejected:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        break;
      default:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 11, color: fg, fontWeight: FontWeight.bold)),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.campaign_outlined,
              size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('화장실 정보를 제보해주시면 큰 도움이 돼요!',
              style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        ]),
      );
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text('불러오지 못했어요.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('다시 시도'),
          ),
        ]),
      );
}
