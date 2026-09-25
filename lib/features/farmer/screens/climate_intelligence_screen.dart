import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/models/climate_models.dart';

/// "What should I do today?" — turns the JKUAT/JHUB weather station's
/// aggregated readings into an explainable per-crop risk assessment. See
/// core/services/climate_intelligence_service.dart for where the data
/// comes from (live Firestore, falling back to a bundled historical/demo
/// snapshot) and weather_pipeline/risk_engine.py for how the scores are computed.
class ClimateIntelligenceScreen extends ConsumerStatefulWidget {
  const ClimateIntelligenceScreen({super.key});

  @override
  ConsumerState<ClimateIntelligenceScreen> createState() => _ClimateIntelligenceScreenState();
}

class _ClimateIntelligenceScreenState extends ConsumerState<ClimateIntelligenceScreen> {
  String? _selectedCropKey;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(climateSnapshotProvider);

    return Scaffold(
      backgroundColor: AppColors.farmerSurfaceOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Climate Intelligence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(climateSnapshotProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(climateSnapshotProvider),
        child: snapshotAsync.when(
          loading: () => const _LoadingCard(),
          error: (e, _) => const _ErrorCard(
            message: 'Could not load climate data. Pull to retry.',
          ),
          data: (snapshot) => _SnapshotView(
            snapshot: snapshot,
            selectedCropKey: _selectedCropKey ??
                (snapshot.cropRisks.isNotEmpty ? snapshot.cropRisks.keys.first : null),
            onSelectCrop: (key) => setState(() => _selectedCropKey = key),
          ),
        ),
      ),
    );
  }
}

class _SnapshotView extends StatelessWidget {
  final ClimateSnapshot snapshot;
  final String? selectedCropKey;
  final ValueChanged<String> onSelectCrop;

  const _SnapshotView({
    required this.snapshot,
    required this.selectedCropKey,
    required this.onSelectCrop,
  });

  @override
  Widget build(BuildContext context) {
    final risk = selectedCropKey != null ? snapshot.cropRisks[selectedCropKey] : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DataSourceBanner(snapshot: snapshot),
        const SizedBox(height: 16),
        _FeatureSummaryCard(features: snapshot.features),
        const SizedBox(height: 20),
        Text('Your crop', style: AppTextStyles.h2),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.cropRisks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final key = snapshot.cropRisks.keys.elementAt(i);
              final selected = key == selectedCropKey;
              return ChoiceChip(
                label: Text(_cropLabel(key)),
                selected: selected,
                onSelected: (_) => onSelectCrop(key),
                selectedColor: AppColors.forest.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: selected ? AppColors.forest : null,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (risk != null) _TodaysAdvisoryCard(risk: risk) else const _EmptyState(),
      ],
    );
  }

  String _cropLabel(String key) => key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
}

class _DataSourceBanner extends StatelessWidget {
  final ClimateSnapshot snapshot;
  const _DataSourceBanner({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final isLive = snapshot.source == ClimateDataSource.live;
    final color = isLive ? AppColors.forest : AppColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(isLive ? Icons.sensors : Icons.history, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${snapshot.label} · Quality: ${snapshot.dataQuality.qualityLabel}',
            style: AppTextStyles.bodyMuted.copyWith(fontSize: 12, color: color),
          ),
        ),
      ]),
    );
  }
}

class _FeatureSummaryCard extends StatelessWidget {
  final ClimateFeatures features;
  const _FeatureSummaryCard({required this.features});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('JHUB Weather', style: AppTextStyles.h2.copyWith(color: Colors.white)),
        const SizedBox(height: 12),
        Row(children: [
          _StatTile(label: 'Temp', value: '${features.tempCurrent.toStringAsFixed(1)}°C'),
          _StatTile(label: 'Humidity', value: '${features.humidityCurrent.toStringAsFixed(0)}%'),
          _StatTile(label: 'Rain 24h', value: '${features.rainfallMm24h.toStringAsFixed(1)}mm'),
          _StatTile(label: 'Wind', value: '${features.windCurrent.toStringAsFixed(1)}m/s'),
        ]),
        if (features.wbgtCurrent != null) ...[
          const SizedBox(height: 10),
          _WbgtIndicator(wbgt: features.wbgtCurrent!),
        ],
        if (!features.rainfallModeVerified) ...[
          const SizedBox(height: 6),
          Text(
            'Rainfall totals are unverified (no rain events in the data yet to confirm gauge units).',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10.5),
          ),
        ],
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ]),
    );
  }
}

/// Field-work safety indicator, not medical advice — see the pipeline
/// brief's WBGT guidance.
class _WbgtIndicator extends StatelessWidget {
  final double wbgt;
  const _WbgtIndicator({required this.wbgt});

  (String, String) get _levelAndAdvice {
    if (wbgt >= 28) return ('HIGH', 'Reduce prolonged exposure; schedule demanding work for cooler hours.');
    if (wbgt >= 23) return ('MODERATE', 'Take breaks and stay hydrated during field work.');
    return ('LOW', 'Normal field activity.');
  }

  @override
  Widget build(BuildContext context) {
    final (level, advice) = _levelAndAdvice;
    return Row(children: [
      Icon(Icons.thermostat, size: 14, color: Colors.white.withValues(alpha: 0.8)),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          'Field-work safety: $level — $advice',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
        ),
      ),
    ]);
  }
}

class _TodaysAdvisoryCard extends StatelessWidget {
  final CropRisk risk;
  const _TodaysAdvisoryCard({required this.risk});

  Color get _levelColor => switch (risk.level) {
        'High' => Colors.red,
        'Moderate' => Colors.orange,
        _ => AppColors.forest,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text("Today's Advisory", style: AppTextStyles.body(15).copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _levelColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(risk.level,
                style: TextStyle(color: _levelColor, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(risk.recommendation, style: AppTextStyles.body(14).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(risk.action, style: AppTextStyles.bodyMuted.copyWith(fontSize: 13)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _RiskPill(label: 'Disease', value: risk.disease),
          _RiskPill(label: 'Heat', value: risk.heat),
          _RiskPill(label: 'Water', value: risk.water),
          _RiskPill(label: 'Wind', value: risk.wind),
          _RiskPill(label: 'Rain', value: risk.rain),
        ]),
        const SizedBox(height: 16),
        _InlineStatusRow(
          icon: Icons.water_drop_outlined,
          label: 'Irrigation',
          value: risk.irrigation.need,
          detail: risk.irrigation.reason,
        ),
        const SizedBox(height: 10),
        _InlineStatusRow(
          icon: Icons.air,
          label: 'Spray window',
          value: risk.sprayWindow.status,
          detail: risk.sprayWindow.reason,
        ),
        if (risk.reasons.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Why', style: AppTextStyles.body(13).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...risk.reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('•  '),
                  Expanded(child: Text(r, style: AppTextStyles.bodyMuted.copyWith(fontSize: 12.5))),
                ]),
              )),
        ],
      ]),
    );
  }
}

class _RiskPill extends StatelessWidget {
  final String label;
  final int value;
  const _RiskPill({required this.label, required this.value});

  Color get _color {
    if (value >= 65) return Colors.red;
    if (value >= 35) return Colors.orange;
    return AppColors.forest;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label $value',
          style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _InlineStatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;

  const _InlineStatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: AppColors.forest),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label: $value', style: AppTextStyles.body(13).copyWith(fontWeight: FontWeight.w600)),
          Text(detail, style: AppTextStyles.bodyMuted.copyWith(fontSize: 12)),
        ]),
      ),
    ]);
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(children: [
          const Text('🌦️', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text('No crop risk data available', style: AppTextStyles.body(14)),
        ]),
      );
}
