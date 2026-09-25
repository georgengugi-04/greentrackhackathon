import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_vision_service.dart';
import '../../../core/services/crop_planning_advisor.dart';

/// Shown after a pest/disease diagnosis — recommends the most favorable
/// next crop for the plot based on what was just diagnosed.
class CropRecommendationScreen extends StatelessWidget {
  final String previousCropName;
  final VisionDiagnosisResult diagnosis;
  final DateTime? phiClearDate;

  const CropRecommendationScreen({
    required this.previousCropName,
    required this.diagnosis,
    this.phiClearDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final advice = CropPlanningAdvisor.advise(
      previousCropName: previousCropName,
      diagnosis: diagnosis,
      phiClearDate: phiClearDate,
    );

    return Scaffold(
      backgroundColor: AppColors.farmerSurfaceOf(context),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Plan Next Crop')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(advice.headline,
                    style: AppTextStyles.h2.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  'Based on the ${diagnosis.label.toLowerCase()} found in your last '
                  '$previousCropName batch.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
                if (advice.earliestPlantingDate != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [
                    const Icon(Icons.event_available, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Plot free to replant from '
                      '${DateFormat.yMMMd().format(advice.earliestPlantingDate!)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Recommended crops for this plot', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          ...advice.recommendations.map((r) => _RecommendationCard(recommendation: r)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.paleGreen,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppColors.farmerAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recommendations follow standard crop-rotation practice: avoid replanting '
                  'the same plant family right after a pest or disease outbreak, and follow '
                  'heavy feeders with a nitrogen-fixing legume.',
                  style: AppTextStyles.bodyMuted,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final CropRecommendation recommendation;
  const _RecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final crop = recommendation.crop;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.paleGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(crop.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(crop.name, style: AppTextStyles.h2.copyWith(fontSize: 15))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.amberPale,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${recommendation.matchScore}% match',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.harvest)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(recommendation.reason, style: AppTextStyles.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
