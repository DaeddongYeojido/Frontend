import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/device_id_util.dart';
import '../../data/model/review.dart';
import '../../provider/review_provider.dart';
import '../../provider/toilet_provider.dart';

class ReviewPopup extends ConsumerStatefulWidget {
  final int toiletId;
  final String toiletName;

  const ReviewPopup({
    super.key,
    required this.toiletId,
    required this.toiletName,
  });

  @override
  ConsumerState<ReviewPopup> createState() => _ReviewPopupState();
}

class _ReviewPopupState extends ConsumerState<ReviewPopup> {
  int _myRating = 0;
  final _controller = TextEditingController();
  // ✅ 기기 ID를 한 번만 로드해서 보관
  String? _myDeviceId;

  @override
  void initState() {
    super.initState();
    DeviceIdUtil.getDeviceId().then((id) {
      if (mounted) setState(() => _myDeviceId = id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_myRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점을 선택해주세요.')),
      );
      return;
    }
    final ok = await ref.read(reviewNotifierProvider.notifier).submit(
          toiletId: widget.toiletId,
          rating: _myRating,
          content: _controller.text.trim().isEmpty
              ? null
              : _controller.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      ref.invalidate(toiletDetailProvider(widget.toiletId));
      setState(() => _myRating = 0);
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰가 등록되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미 리뷰를 작성하셨거나 오류가 발생했어요.'),
          backgroundColor: AppColors.closed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewAsync = ref.watch(reviewListProvider(widget.toiletId));
    final submitState = ref.watch(reviewNotifierProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            child: Row(children: [
              const Icon(Icons.rate_review_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.toiletName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 별점 선택
                  const Text('별점을 선택하세요',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () => setState(() => _myRating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            _myRating > i ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFC107),
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // 리뷰 입력
                  const Text('리뷰 작성',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: '이 화장실에 대한 리뷰를 남겨주세요. (선택)',
                      hintStyle: const TextStyle(
                          color: AppColors.textHint, fontSize: 13),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.filterBorder)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.primary)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitState.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: submitState.isLoading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('등록하기',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 리뷰 목록
                  reviewAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                    error: (e, _) => const Text('리뷰를 불러오지 못했어요.',
                        style: TextStyle(color: AppColors.textSecondary)),
                    data: (page) => _ReviewList(
                      reviews: page.content,
                      totalCount: page.totalElements,
                      toiletId: widget.toiletId,
                      myDeviceId: _myDeviceId,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewList extends ConsumerWidget {
  final List<Review> reviews;
  final int totalCount;
  final int toiletId;
  final String? myDeviceId;

  const _ReviewList({
    required this.reviews,
    required this.totalCount,
    required this.toiletId,
    required this.myDeviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('다른 사람들의 리뷰',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 6),
          Text('($totalCount)',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('아직 리뷰가 없어요. 첫 리뷰를 남겨보세요!',
                  style: TextStyle(color: AppColors.textHint, fontSize: 13)),
            ),
          )
        else
          ...reviews.map((r) => _ReviewCard(
                review: r,
                toiletId: toiletId,
                isMyReview: myDeviceId != null && myDeviceId == r.deviceId,
              )),
      ],
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final Review review;
  final int toiletId;
  final bool isMyReview;

  const _ReviewCard({
    required this.review,
    required this.toiletId,
    required this.isMyReview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Row(
              children: List.generate(
                  5,
                  (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFC107),
                        size: 14,
                      )),
            ),
            const SizedBox(width: 8),
            Text(
              isMyReview ? '나' : '익명',
              style: TextStyle(
                  fontSize: 12,
                  color: isMyReview
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              _formatDate(review.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            if (isMyReview) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () async {
                  final ok = await ref
                      .read(reviewNotifierProvider.notifier)
                      .delete(toiletId: toiletId, reviewId: review.id);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('리뷰가 삭제되었습니다.')),
                    );
                  }
                },
                child: const Icon(Icons.delete_outline,
                    size: 16, color: AppColors.closed),
              ),
            ],
          ]),
          if (review.content != null && review.content!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.content!,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4)),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}
