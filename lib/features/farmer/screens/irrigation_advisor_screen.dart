import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/irrigation_advisor.dart';
import '../../shared/widgets/animated_emoji.dart';

/// AI irrigation recommendations for every active batch, driven by live
/// weather at the farm's location plus each batch's growth stage and
/// irrigation history. See core/services/irrigation_advisor.dart for the
/// recommendation logic.
class IrrigationAdvisorScreen extends ConsumerWidget {
  const IrrigationAdvisorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final adviceAsync = ref.watch(irrigationAdviceProvider);

    return Scaffold(
      backgroundColor: AppColors.farmerSurfaceOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Irrigation Advisor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(weatherProvider);
              ref.invalidate(irrigationAdviceProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weatherProvider);
          ref.invalidate(irrigationAdviceProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            weatherAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(
                  message: 'Could not load live weather. Pull to retry.'),
              data: (w) => Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(children: [
                  Text(w.emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${w.tempC.toStringAsFixed(0)}°C · ${w.condition}',
                            style: AppTextStyles.h2.copyWith(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          'Rain last 24h: ${w.rainfallLast24hMm.toStringAsFixed(1)}mm · '
                          'Forecast next 24h: ${w.rainForecastNext24hMm.toStringAsFixed(1)}mm',
                          style: AppTextStyles.bodyMuted.copyWith(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Text('Recommendations by batch', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              'Based on current weather, crop stage, and irrigation history.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 12),
            adviceAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const _EmptyState();
                }
                return Column(
                  children: list
                      .map((a) => _AdviceCard(advice: a))
                      .toList(growable: false),
                );
              },
              error: (e, _) => _ErrorCard(message: 'Could not build recommendations.'),
              loading: () => const _LoadingCard(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final IrrigationAdvice advice;
  const _AdviceCard({required this.advice});

  Color get _tint => switch (advice.urgency) {
        IrrigationUrgency.high => Colors.red,
        IrrigationUrgency.medium => Colors.orange,
        IrrigationUrgency.low => AppColors.amber,
        IrrigationUrgency.skip => AppColors.forest,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _tint.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Text(advice.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(advice.batch.cropName,
                      style: AppTextStyles.body(14)
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text(advice.batch.plotName ?? 'Unnamed plot',
                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(advice.headline,
              style: AppTextStyles.body(14).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(advice.reason, style: AppTextStyles.bodyMuted.copyWith(fontSize: 13)),
          if (advice.recommendedLiters > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.water_drop_outlined, size: 16),
                label: const Text('Log this watering'),
                onPressed: () => context.push('/farmer/batches/irrigation'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(children: [
          AnimatedEmoji('🌱', size: 40),
          const SizedBox(height: 10),
          Text('No active batches yet', style: AppTextStyles.body(14)),
          Text('Add a crop batch to get irrigation recommendations.',
              style: AppTextStyles.bodyMuted),
        ]),
      );
}
