import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../provider/toilet_provider.dart';
import '../../provider/favorite_provider.dart';
import '../../provider/location_provider.dart';
import '../../provider/paper_request_provider.dart';
import '../../data/model/toilet_detail.dart';
import '../../data/model/toilet_summary.dart';
import '../widget/open_status_badge.dart';
import '../widget/crowded_button.dart';
import '../widget/review_popup.dart';
import '../widget/paper_request_sheet.dart';

class ToiletBottomSheet extends ConsumerStatefulWidget {
  final int toiletId;
  final VoidCallback? onDismiss;
  const ToiletBottomSheet({super.key, required this.toiletId, this.onDismiss});

  @override
  ConsumerState<ToiletBottomSheet> createState() => _ToiletBottomSheetState();
}

class _ToiletBottomSheetState extends ConsumerState<ToiletBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _animCtrl.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(toiletDetailProvider(widget.toiletId));

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Transform.translate(
          offset: Offset(0, _dragOffset.clamp(0, double.infinity)),
          child: GestureDetector(
            onVerticalDragStart: (_) => setState(() => _isDragging = true),
            onVerticalDragUpdate: (d) =>
                setState(() => _dragOffset += d.delta.dy),
            onVerticalDragEnd: (d) {
              final velocity = d.primaryVelocity ?? 0;
              if (_dragOffset > 100 || velocity > 400) {
                _dismiss();
              } else {
                setState(() {
                  _dragOffset = 0;
                  _isDragging = false;
                });
              }
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2))
                ],
              ),
              child: detailAsync.when(
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)),
                ),
                error: (e, _) => SizedBox(
                  height: 180,
                  child: Center(
                    child: Text('불러오지 못했어요.\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                  ),
                ),
                data: (detail) =>
                    _Content(detail: detail, onDismiss: _dismiss),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Content extends ConsumerWidget {
  final ToiletDetail detail;
  final VoidCallback? onDismiss;
  const _Content({required this.detail, this.onDismiss});

  void _openReview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ReviewPopup(toiletId: detail.id, toiletName: detail.name),
    );
  }

  /// 휴지 요청 버튼 탭
  Future<void> _onPaperRequest(BuildContext context, WidgetRef ref) async {
    // 이미 내가 요청 중인지 확인
    final myRequest = ref.read(paperRequestProvider).value;
    if (myRequest != null && myRequest.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미 휴지 요청 중이에요!'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    // 현재 위치 vs 화장실 500m 사전 검증
    final pos = ref.read(locationProvider).value;
    if (pos != null) {
      final dist = _haversineDistance(
          pos.latitude, pos.longitude, detail.lat, detail.lng);
      if (dist > 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '화장실로부터 ${dist.toInt()}m 떨어져 있어요.\n500m 이내에서만 요청할 수 있어요.'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }
    }

    // 핵심 수정: showModalBottomSheet의 결과를 기다려서
    // 요청 성공(true) 시 화장실 바텀시트도 닫기
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaperRequestSheet(
        toiletId: detail.id,
        toiletName: detail.name,
      ),
    );

    if (result == true) {
      onDismiss?.call();
    }
  }

  double _haversineDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProvider);
    final isFav = favorites.any((f) => f.id == detail.id);

    final summary = ToiletSummary(
      id: detail.id,
      name: detail.name,
      address: detail.address,
      lat: detail.lat,
      lng: detail.lng,
      openStatus: detail.openStatus,
      isDisabled: detail.isDisabled,
      isGenderSep: detail.isGenderSep,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 3),

            // 이름 + 붐벼요
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(detail.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1.2)),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            OpenStatusBadge(status: detail.openStatus),
                            if (detail.openHours != null)
                              Text(detail.openHours!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            GestureDetector(
                              onTap: () => _openReview(context),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star,
                                        color: Color(0xFFFFC107), size: 16),
                                    const SizedBox(width: 2),
                                    Text(detail.ratingDisplay,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary)),
                                    const SizedBox(width: 2),
                                    Text('(${detail.reviewCount})',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color:
                                            AppColors.textSecondary)),
                                  ]),
                            ),
                            GestureDetector(
                              onTap: () => ref
                                  .read(favoriteProvider.notifier)
                                  .toggle(summary),
                              child: Icon(
                                isFav
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                isFav ? Colors.red : AppColors.textHint,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(detail.address,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4)),
                        const SizedBox(height: 10),
                        if (detail.isDisabled || detail.isGenderSep)
                          Row(children: [
                            if (detail.isDisabled) ...[
                              _TagChip(
                                  icon: Icons.accessible,
                                  label: '장애인 화장실'),
                              const SizedBox(width: 8),
                            ],
                            if (detail.isGenderSep)
                              _TagChip(icon: Icons.wc, label: '남녀 구분'),
                          ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Align(
                    alignment: Alignment.topCenter,
                    child: CrowdedButton(
                      toiletId: detail.id,
                      crowdedCount: detail.crowdSummary['CROWDED'] ?? 0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 🧻 휴지 요청 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _onPaperRequest(context, ref),
                icon: const Text('🧻', style: TextStyle(fontSize: 16)),
                label: const Text(
                  '긴급 휴지 요청',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side:
                  const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 상세 길찾기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${detail.name} 길찾기'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('상세 길찾기',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TagChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.filterBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
