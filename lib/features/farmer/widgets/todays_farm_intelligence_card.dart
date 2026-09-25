import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/weather_intelligence_providers.dart';
import '../../../data/models/models.dart';

/// "Today's Farm Intelligence" — Hack The Weather 2026's hero feature.
/// Deliberately separate from _WeatherCard (Open-Meteo, the farmer's own
/// location) — this reads the real JKUAT station feed, always labelled
/// as such, and turns it into a crop-specific, explainable risk read
/// rather than raw numbers (spec: "don't just tell farmers what the
/// weather is, tell them what it means for their crops").
class TodaysFarmIntelligenceCard extends ConsumerWidget {
  const TodaysFarmIntelligenceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCrop = ref.watch(selectedIntelligenceCropProvider);
    final riskAsync = ref.watch(cropWeatherRiskProvider(selectedCrop));
    final featuresAsync = ref.watch(currentWeatherFeaturesProvider);
    final stationAsync = ref.watch(weatherStationInfoProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.insights_rounded, color: AppColors.leaf, size: 20),
          const SizedBox(width: 8),
          Text("Today's Farm Intelligence",
              style: AppTextStyles.poppins(15, weight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),

        // Crop selector
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: kWeatherIntelligenceCrops.entries
                .map((e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: selectedCrop == e.key,
                        onSelected: (_) =>
                            ref.read(selectedIntelligenceCropProvider.notifier).state = e.key,
                        selectedColor: AppColors.leaf.withValues(alpha: 0.18),
                        labelStyle: AppTextStyles.sans(12.5,
                            weight: FontWeight.w600,
                            color: selectedCrop == e.key
                                ? AppColors.leaf
                                : AppColors.textSecondaryOf(context)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),

        riskAsync.when(
          loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator())),
          error: (e, __) => _unavailableNotice(context,
              "Weather intelligence temporarily unavailable. Showing your last available assessment."),
          data: (risk) {
            if (risk == null) {
              return _unavailableNotice(context,
                  'No weather intelligence data yet for this station. Run the ingestion pipeline to populate it.');
            }
           final features = featuresAsync.value;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Risk badge
              Row(children: [
                _RiskBadge(level: risk.level, score: risk.overall),
                const Spacer(),
                if (features != null)
                  Text(_freshnessLabel(features.observedAt),
                      style: AppTextStyles.sans(11, color: AppColors.textSecondaryOf(context))),
              ]),
              const SizedBox(height: 14),

              if (features != null) _StatRow(features: features),
              const SizedBox(height: 14),

              // Recommendation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.leaf.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(risk.recommendation, style: AppTextStyles.sans(13, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Action: ${risk.action}', style: AppTextStyles.bodyMuted),
                ]),
              ),
              const SizedBox(height: 10),

              // Why? — expandable explanation, never a bare score
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Why?',
                    style: AppTextStyles.sans(13, weight: FontWeight.w700, color: AppColors.leaf)),
                children: risk.reasons
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('•  '),
                            Expanded(child: Text(r, style: AppTextStyles.bodyMuted)),
                          ]),
                        ))
                    .toList(),
              ),

              const Divider(height: 20),
              stationAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, __) => const SizedBox.shrink(),
                data: (station) => station == null
                    ? const SizedBox.shrink()
                    : Text(
                        'Source: ${station.name} · ${station.site} · ${station.elevationM.toStringAsFixed(0)}m elevation',
                        style: AppTextStyles.sans(10.5, color: AppColors.textSecondaryOf(context)),
                      ),
              ),
              Row(children: [
                TextButton.icon(
                  onPressed: () => context.push('/farmer/weather-explorer'),
                  icon: const Icon(Icons.query_stats_rounded, size: 16),
                  label: const Text('Weather Explorer'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => context.push('/farmer/spray-irrigation'),
                  icon: const Icon(Icons.water_drop_outlined, size: 16),
                  label: const Text('Spray & Watering'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                ),
              ]),
            ]);
          },
        ),
      ]),
    );
  }

  Widget _unavailableNotice(BuildContext context, String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.textSecondaryOf(context)),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: AppTextStyles.bodyMuted)),
        ]),
      );

  String _freshnessLabel(DateTime observedAt) {
    final diff = DateTime.now().toUtc().difference(observedAt.toUtc());
    if (diff.inMinutes < 1) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.level, required this.score});
  final String level;
  final int score;

  Color get _color => switch (level) {
        'Low' => AppColors.premiumEmerald,
        'Moderate' => AppColors.premiumWarning,
        _ => AppColors.red,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: _color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$level Weather Risk · $score/100',
              style: AppTextStyles.sans(12, weight: FontWeight.w700, color: _color)),
        ]),
      );
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.features});
  final WeatherFeatures features;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: _Stat(icon: '🌡', label: '${features.tempCurrent.toStringAsFixed(0)}°C', caption: 'Temp')),
        Expanded(child: _Stat(icon: '💧', label: '${features.humidityCurrent.toStringAsFixed(0)}%', caption: 'Humidity')),
        Expanded(child: _Stat(icon: '🌧', label: '${features.rainfallMm24h.toStringAsFixed(1)}mm', caption: '24h rain')),
        Expanded(child: _Stat(icon: '💨', label: '${features.windCurrent.toStringAsFixed(1)}m/s', caption: 'Wind')),
      ]);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.caption});
  final String icon, label, caption;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.sans(13, weight: FontWeight.w700)),
        Text(caption, style: AppTextStyles.sans(10, color: AppColors.textSecondaryOf(context))),
      ]);
}
