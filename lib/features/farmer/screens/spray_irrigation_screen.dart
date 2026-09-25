import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/weather_intelligence_providers.dart';
import '../../../data/models/models.dart';

/// "Best Time to Spray" + "Watering Recommendation" (spec sections 16-17).
/// Both read straight off the same CropWeatherRisk the dashboard card
/// already computes — no separate calculation path to keep in sync.
class SprayAndIrrigationScreen extends ConsumerWidget {
  const SprayAndIrrigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCrop = ref.watch(selectedIntelligenceCropProvider);
    final riskAsync = ref.watch(cropWeatherRiskProvider(selectedCrop));
    final featuresAsync = ref.watch(currentWeatherFeaturesProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: const Text('Spraying & Watering')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 36,
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
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            riskAsync.when(
              loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator())),
              error: (e, __) => Text("We couldn't load this recommendation.", style: AppTextStyles.bodyMuted),
              data: (risk) {
                if (risk == null) {
                  return Text('No weather intelligence data yet for this crop.', style: AppTextStyles.bodyMuted);
                }
                final features = featuresAsync.value;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('BEST TIME TO SPRAY',
                      style: AppTextStyles.sans(12, weight: FontWeight.w700, color: AppColors.textSecondaryOf(context))
                          .copyWith(letterSpacing: 0.6)),
                  const SizedBox(height: 10),
                  _SprayCard(sprayWindow: risk.sprayWindow, features: features),
                  const SizedBox(height: 24),
                  Text('WATERING RECOMMENDATION',
                      style: AppTextStyles.sans(12, weight: FontWeight.w700, color: AppColors.textSecondaryOf(context))
                          .copyWith(letterSpacing: 0.6)),
                  const SizedBox(height: 10),
                  _IrrigationCard(cropLabel: kWeatherIntelligenceCrops[selectedCrop] ?? selectedCrop,
                      irrigation: risk.irrigation),
                  const SizedBox(height: 16),
                  Text(
                    'This is an environmental recommendation based on recent rainfall and temperature — '
                    'not a direct measurement of soil moisture.',
                    style: AppTextStyles.sans(11.5, color: AppColors.textSecondaryOf(context)),
                  ),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SprayCard extends StatelessWidget {
  const _SprayCard({required this.sprayWindow, required this.features});
  final SprayWindow sprayWindow;
  final WeatherFeatures? features;

  Color get _color => switch (sprayWindow.status) {
        SprayStatus.suitable => AppColors.premiumEmerald,
        SprayStatus.caution => AppColors.premiumWarning,
        SprayStatus.notRecommended => AppColors.red,
      };

  IconData get _icon => switch (sprayWindow.status) {
        SprayStatus.suitable => Icons.check_circle_rounded,
        SprayStatus.caution => Icons.warning_rounded,
        SprayStatus.notRecommended => Icons.cancel_rounded,
      };

  Widget _mini(BuildContext context, String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.sans(10.5, color: AppColors.textSecondaryOf(context))),
        Text(value, style: AppTextStyles.sans(13, weight: FontWeight.w700)),
      ]);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(_icon, color: _color, size: 22),
          const SizedBox(width: 8),
          Text(sprayWindow.status.label.toUpperCase(),
              style: AppTextStyles.poppins(16, weight: FontWeight.w800, color: _color)),
        ]),
        const SizedBox(height: 8),
        Text(sprayWindow.reason, style: AppTextStyles.sans(13.5)),
        const SizedBox(height: 4),
        Text('Suggested action: ${sprayWindow.suggestedAction}',
            style: AppTextStyles.sans(13, weight: FontWeight.w600)),
        if (features != null) ...[
          const Divider(height: 24),
          Text('CURRENT OBSERVED CONDITIONS',
              style: AppTextStyles.sans(10.5, weight: FontWeight.w700, color: AppColors.textSecondaryOf(context))
                  .copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 16, runSpacing: 6, children: [
            _mini(context, 'Wind', '${features!.windCurrent.toStringAsFixed(1)} m/s'),
            if (features!.windGustMax24h != null)
              _mini(context, 'Max gust (24h)', '${features!.windGustMax24h!.toStringAsFixed(1)} m/s'),
            _mini(context, 'Rainfall (6h)', '${features!.rainfallMm6h.toStringAsFixed(1)} mm'),
            _mini(context, 'Temp', '${features!.tempCurrent.toStringAsFixed(0)}°C'),
            _mini(context, 'Humidity', '${features!.humidityCurrent.toStringAsFixed(0)}%'),
          ]),
          const SizedBox(height: 4),
          Text('These are observed conditions, not a forecast.',
              style: AppTextStyles.sans(10.5, color: AppColors.textSecondaryOf(context))),
        ],
      ]),
    );
  }
}

class _IrrigationCard extends StatelessWidget {
  const _IrrigationCard({required this.cropLabel, required this.irrigation});
  final String cropLabel;
  final IrrigationNeed irrigation;

  Color get _color => switch (irrigation.need) {
        IrrigationNeedLevel.low => AppColors.premiumEmerald,
        IrrigationNeedLevel.medium => AppColors.premiumWarning,
        IrrigationNeedLevel.high => AppColors.red,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(cropLabel.toUpperCase(),
            style: AppTextStyles.sans(12, weight: FontWeight.w700, color: AppColors.textSecondaryOf(context))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: _color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
          child: Text('Watering need: ${irrigation.need.name.toUpperCase()}',
              style: AppTextStyles.sans(12.5, weight: FontWeight.w700, color: _color)),
        ),
        const SizedBox(height: 10),
        Text(irrigation.reason, style: AppTextStyles.sans(13.5)),
      ]),
    );
  }
}
