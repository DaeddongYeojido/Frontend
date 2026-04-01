import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('제보게시판',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: false,
      ),
      body: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.campaign_outlined, size: 56, color: AppColors.textHint),
          SizedBox(height: 12),
          Text('제보게시판 준비 중이에요.',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('화장실 정보를 제보하고 싶다면 곧 이용 가능해요.',
              style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        ]),
      ),
    );
  }
}
