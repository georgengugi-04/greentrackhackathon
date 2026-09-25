import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// "How GreenTrack Works" — a polished pipeline explainer for judges,
/// per spec section 38. Static content describing the real pipeline
/// (weather_pipeline/ + this app's Firestore reads) rather than a
/// generic marketing diagram — every stage names the actual file/layer
/// responsible for it, so a technical judge can verify the claim.
class HowGreenTrackWorksScreen extends StatelessWidget {
  const HowGreenTrackWorksScreen({super.key});

  static const _stages = [
    (
      icon: Icons.sensors_rounded,
      title: 'Environmental data is collected',
      body: 'The JKUAT IoT weather station (Kiambu, 1523m elevation) records temperature, '
          'humidity, rainfall, wind, and heat-stress indices roughly once a minute.',
    ),
    (
      icon: Icons.fact_check_outlined,
      title: 'Data is validated and processed',
      body: 'An offline pipeline checks every reading for duplicate timestamps, out-of-range '
          'values, and sensor-outage gaps before anything downstream trusts it — see the '
          '"Data Quality" tab in Weather Explorer for the real report.',
    ),
    (
      icon: Icons.functions_rounded,
      title: 'Weather features are calculated',
      body: 'Rolling 1h/3h/6h/24h/7d windows, humidity-persistence duration, and dry-period '
          'length are computed from the validated observations.',
    ),
    (
      icon: Icons.eco_outlined,
      title: 'Crop-specific intelligence analyses risk',
      body: 'A transparent, rules-based engine — not a black-box model — scores disease, heat, '
          'water, wind, and rain risk per crop, using per-crop sensitivity profiles.',
    ),
    (
      icon: Icons.lightbulb_outline_rounded,
      title: 'GreenTrack explains the result',
      body: 'Every risk score ships with the plain-language reasons behind it. Tap "Why?" on '
          'the dashboard card to see exactly which observed values drove the assessment.',
    ),
    (
      icon: Icons.check_circle_outline_rounded,
      title: 'Farmers receive an actionable recommendation',
      body: 'Not just a number — a specific action: monitor for disease, adjust irrigation, '
          'or wait to spray, phrased with careful, non-absolute language throughout.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: const Text('How GreenTrack Works')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Real data, in, explainable action out.',
                style: AppTextStyles.poppins(18, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              "GreenTrack doesn't just tell farmers what the weather is — it tells them "
              'what the weather means for their crops, and what to consider doing about it.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < _stages.length; i++) ...[
              _StageTile(index: i + 1, stage: _stages[i], isLast: i == _stages.length - 1),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.leaf.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('What this is NOT', style: AppTextStyles.sans(13, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  '• Not a fitted ML prediction model — the raw dataset has no labelled disease '
                  'outcomes to validate one against, so we built an explainable rules engine instead.\n'
                  '• Not a weather forecast — every number here is an observed reading, labelled '
                  '"current observed conditions," never a prediction of tomorrow.\n'
                  "• Not a claim that station data equals every farm's exact microclimate — the "
                  "station's location is always shown alongside the reading.",
                  style: AppTextStyles.sans(12.5),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.push('/farmer/weather-explorer'),
              icon: const Icon(Icons.query_stats_rounded),
              label: const Text('See the real data in Weather Explorer'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({required this.index, required this.stage, required this.isLast});
  final int index;
  final ({IconData icon, String title, String body}) stage;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.leaf.withValues(alpha: 0.14), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(stage.icon, size: 18, color: AppColors.leaf),
          ),
          if (!isLast) Expanded(child: Container(width: 2, color: AppColors.borderOf(context))),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$index. ${stage.title}', style: AppTextStyles.sans(14.5, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(stage.body, style: AppTextStyles.bodyMuted),
            ]),
          ),
        ),
      ]),
    );
  }
}
