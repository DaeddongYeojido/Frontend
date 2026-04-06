import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../provider/paper_request_provider.dart';
import '../../provider/location_provider.dart';

/// 휴지 요청 바텀시트
/// 흐름: 성별 선택 → 긴급 확인 다이얼로그 → 요청 전송
class PaperRequestSheet extends ConsumerStatefulWidget {
  final int toiletId;
  final String toiletName;

  const PaperRequestSheet({
    super.key,
    required this.toiletId,
    required this.toiletName,
  });

  @override
  ConsumerState<PaperRequestSheet> createState() => _PaperRequestSheetState();
}

class _PaperRequestSheetState extends ConsumerState<PaperRequestSheet> {
  String? _selectedGender;
  bool _isLoading = false;

  Future<void> _onConfirm() async {
    // 중복 탭 방지
    if (_selectedGender == null || _isLoading) return;

    // 1) 긴급 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '🧻 정말 긴급한 상황인가요?!?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          '휴지 요청 기능은 하루에 한 번만 사용할 수 있습니다.\n정말 긴급한 상황일 때만 사용해주세요!',
          style: TextStyle(
              fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('확인, 요청할게요!'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // 2) 위치 확인
    final pos = ref.read(locationProvider).value;
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 정보를 가져올 수 없어요.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    // 3) 요청 전송 — try/finally로 항상 _isLoading 해제 보장
    try {
      await ref.read(paperRequestProvider.notifier).createRequest(
        toiletId: widget.toiletId,
        gender: _selectedGender!,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      if (!mounted) return;

      // 성공: 시트 닫기
      final result = ref.read(paperRequestProvider);
      if (result.value != null && result.value!.isActive) {
        Navigator.pop(context, true);
      } else if (result.hasError) {
        _showError(result.error);
      }
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Dio 에러에서 서버 메시지 추출 후 스낵바 표시
  // 수정
  void _showError(Object? e) {
    if (!mounted) return;

    String msg = '요청에 실패했어요. 다시 시도해주세요.';
    bool shouldPop = false;

    if (e is DioException) {
      final serverMsg = e.response?.data?['message'] as String?;
      if (serverMsg != null) {
        if (serverMsg.contains('한 번')) {
          msg = '오늘은 이미 휴지 요청을 사용했어요. 내일 다시 시도해주세요.';
          shouldPop = true; // 시트 닫기
        } else if (serverMsg.contains('500m')) {
          msg = '화장실로부터 500m 이내에서만 요청할 수 있어요.';
          // 시트 유지
        } else {
          msg = serverMsg;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );

    if (shouldPop) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 20),

          const Text('🧻', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),

          const Text(
            '긴급 휴지 요청',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.toiletName,
            style:
            const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // 성별 선택
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '화장실 성별을 선택해주세요',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _GenderButton(
                  label: '🚹 남자',
                  isSelected: _selectedGender == 'MALE',
                  onTap: _isLoading
                      ? null
                      : () => setState(() => _selectedGender = 'MALE'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderButton(
                  label: '🚺 여자',
                  isSelected: _selectedGender == 'FEMALE',
                  onTap: _isLoading
                      ? null
                      : () => setState(() => _selectedGender = 'FEMALE'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
              (_selectedGender != null && !_isLoading) ? _onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.filterBorder,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : const Text(
                '휴지 요청하기',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;  // 로딩 중 비활성화 위해 nullable로 변경

  const _GenderButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.filterBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.filterBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
