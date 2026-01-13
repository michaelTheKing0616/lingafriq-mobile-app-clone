import 'package:flutter/material.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';

class CEFRProgressCard extends StatelessWidget {
  final CEFRInfo cefr;

  const CEFRProgressCard({Key? key, required this.cefr}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Card(
      margin: const EdgeInsets.all(16),
      color: isDark ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Level',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: context.adaptive,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.accentGold],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cefr.level,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Progress: ${cefr.score.toStringAsFixed(1)} / 100',
              style: TextStyle(
                fontSize: 14.sp,
                color: context.adaptive54,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: cefr.score / 100,
                minHeight: 12,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLevelIndicator('A1', cefr.level == 'A1', 0),
                _buildLevelIndicator('A2', cefr.level == 'A2', 20),
                _buildLevelIndicator('B1', cefr.level == 'B1', 40),
                _buildLevelIndicator('B2', cefr.level == 'B2', 55),
                _buildLevelIndicator('C1', cefr.level == 'C1', 70),
                _buildLevelIndicator('C2', cefr.level == 'C2', 85),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelIndicator(String level, bool isCurrent, double threshold) {
    final isReached = cefr.score >= threshold;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent
                ? AppColors.primaryGreen
                : (isReached
                    ? AppColors.accentGold
                    : Colors.grey.withOpacity(0.3)),
            border: Border.all(
              color: isCurrent
                  ? AppColors.primaryGreen
                  : (isReached ? AppColors.accentGold : Colors.grey),
              width: 2,
            ),
          ),
          child: isCurrent
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : (isReached
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null),
        ),
        const SizedBox(height: 4),
        Text(
          level,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent
                ? AppColors.primaryGreen
                : (isReached ? AppColors.accentGold : Colors.grey),
          ),
        ),
      ],
    );
  }
}

