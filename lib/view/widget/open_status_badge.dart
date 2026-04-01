import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class OpenStatusBadge extends StatelessWidget {
  final String status;
  const OpenStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'OPEN'  => ('OPEN', AppColors.open),
      'NIGHT' => ('NIGHT', AppColors.night),
      _       => ('CLOSED', AppColors.closed),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
