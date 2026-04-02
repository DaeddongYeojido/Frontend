import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../provider/toilet_provider.dart';
import '../../provider/favorite_provider.dart';
import '../../data/model/toilet_detail.dart';
import '../../data/model/toilet_summary.dart';
import '../widget/open_status_badge.dart';
import '../widget/crowded_button.dart';
import '../widget/review_popup.dart';

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

  // 드래그 관련
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
            onVerticalDragStart: (_) {
              setState(() => _isDragging = true);
            },
            onVerticalDragUpdate: (d) {
              setState(() {
                _dragOffset += d.delta.dy;
              });
            },
            onVerticalDragEnd: (d) {
              final velocity = d.primaryVelocity ?? 0;
              // 100px 이상 내렸거나, 빠르게 아래로 스와이프하면 닫기
              if (_dragOffset > 100 || velocity > 400) {
                _dismiss();
              } else {
                // 원위치 복귀
                setState(() {
                  _dragOffset = 0;
                  _isDragging = false;
                });
              }
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  child:
                      Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (e, _) => SizedBox(
                  height: 180,
                  child: Center(
                    child: Text('불러오지 못했어요.\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                data: (detail) => _Content(detail: detail, onDismiss: _dismiss),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  final ToiletDetail detail;
  final VoidCallback? onDismiss;
  const _Content({required this.detail, this.onDismiss});

  void _openReview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewPopup(toiletId: detail.id, toiletName: detail.name),
    );
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
            // 핸들 (드래그 가능 표시)
            Center(
                child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            )),
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

                        // OPEN + 영업시간 + 별점 + 즐겨찾기
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
                                            color: AppColors.textSecondary)),
                                  ]),
                            ),
                            GestureDetector(
                              onTap: () => ref
                                  .read(favoriteProvider.notifier)
                                  .toggle(summary),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
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
