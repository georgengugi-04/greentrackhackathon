import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/weather_intelligence_providers.dart';
import '../../../data/models/models.dart';

enum _ExplorerRange { h24, d7, d30 }

extension on _ExplorerRange {
  String get label => switch (this) {
        _ExplorerRange.h24 => '24 Hours',
        _ExplorerRange.d7 => '7 Days',
        _ExplorerRange.d30 => '30 Days',
      };
  bool get useHourly => this == _ExplorerRange.h24;
  int get hours => this == _ExplorerRange.h24 ? 24 : 0;
  int get days => switch (this) {
        _ExplorerRange.h24 => 1,
        _ExplorerRange.d7 => 7,
        _ExplorerRange.d30 => 30,
      };
}

/// Advanced screen for judges, researchers, extension officers and
/// advanced farmers (spec section 21) — the normal farmer dashboard
/// stays simple; all the raw-ish detail lives here instead.
class WeatherExplorerScreen extends ConsumerStatefulWidget {
  const WeatherExplorerScreen({super.key});

  @override
  ConsumerState<WeatherExplorerScreen> createState() => _WeatherExplorerScreenState();
}

class _WeatherExplorerScreenState extends ConsumerState<WeatherExplorerScreen> {
  _ExplorerRange _range = _ExplorerRange.h24;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: AppColors.surfaceOf(context),
        appBar: AppBar(
          title: const Text('Weather Explorer'),
          actions: [
            IconButton(
              tooltip: 'How GreenTrack Works',
              onPressed: () => context.push('/farmer/how-it-works'),
              icon: const Icon(Icons.help_outline_rounded),
            ),
          ],
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Temperature'),
            Tab(text: 'Rainfall'),
            Tab(text: 'Humidity'),
            Tab(text: 'Wind'),
            Tab(text: 'Risk'),
            Tab(text: 'Data Quality'),
          ]),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _ExplorerRange.values
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(r.label),
                            selected: _range == r,
                            onSelected: (_) => setState(() => _range = r),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(children: [
              _OverviewTab(range: _range),
              _TemperatureTab(range: _range),
              _RainfallTab(range: _range),
              _HumidityTab(range: _range),
              _WindTab(range: _range),
              const _RiskTab(),
              const _DataQualityTab(),
            ]),
          ),
        ]),
      ),
    );
  }
}

// Shared: loads either hourly or daily aggregate rows for the selected range.
class _SeriesLoader extends ConsumerWidget {
  const _SeriesLoader({required this.range, required this.builder});
  final _ExplorerRange range;
  final Widget Function(BuildContext, List<Map<String, dynamic>>) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = range.useHourly
        ? ref.watch(hourlyWeatherHistoryProvider(range.hours))
        : ref.watch(dailyWeatherHistoryProvider(range.days));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(
          child: Text("We couldn't load weather history.", style: AppTextStyles.bodyMuted)),
      data: (rows) {
        if (rows.isEmpty) {
          return Center(
              child: Text('No weather history ingested yet for this range.',
                  style: AppTextStyles.bodyMuted));
        }
        return builder(context, rows);
      },
    );
  }
}

double? _numAt(Map<String, dynamic> row, String key) {
  final v = row[key];
  if (v == null) return null;
  return (v as num).toDouble();
}

class _MiniChart extends StatelessWidget {
  const _MiniChart({required this.rows, required this.field, required this.color, this.field2, this.color2});
  final List<Map<String, dynamic>> rows;
  final String field;
  final Color color;
  final String? field2;
  final Color? color2;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    final spots2 = <FlSpot>[];
    for (var i = 0; i < rows.length; i++) {
      final v = _numAt(rows[i], field);
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
      if (field2 != null) {
        final v2 = _numAt(rows[i], field2!);
        if (v2 != null) spots2.add(FlSpot(i.toDouble(), v2));
      }
    }
    return SizedBox(
      height: 200,
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, color: color, barWidth: 2.5, dotData: const FlDotData(show: false)),
          if (field2 != null)
            LineChartBarData(spots: spots2, isCurved: true, color: color2, barWidth: 2.5, dotData: const FlDotData(show: false)),
        ],
      )),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.range});
  final _ExplorerRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuresAsync = ref.watch(currentWeatherFeaturesProvider);
    final stationAsync = ref.watch(weatherStationInfoProvider);
    final qualityAsync = ref.watch(weatherDataQualityProvider);

    return ListView(padding: const EdgeInsets.all(16), children: [
      stationAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, __) => const SizedBox.shrink(),
        data: (s) => s == null
            ? const SizedBox.shrink()
            : _Card(title: 'Station', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: AppTextStyles.sans(14, weight: FontWeight.w700)),
                Text('${s.site} · ${s.elevationM.toStringAsFixed(0)}m elevation', style: AppTextStyles.bodyMuted),
                Text('Lat ${s.latitude}, Lng ${s.longitude}', style: AppTextStyles.bodyMuted),
                const SizedBox(height: 4),
                Text('Attribution: ${s.attribution}', style: AppTextStyles.sans(11, color: AppColors.textSecondaryOf(context))),
                Text('DOI: ${s.doi}', style: AppTextStyles.sans(11, color: AppColors.textSecondaryOf(context))),
              ])),
      ),
      const SizedBox(height: 12),
      featuresAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, __) => const SizedBox.shrink(),
        data: (f) => f == null
            ? const SizedBox.shrink()
            : _Card(title: 'Current Observed Conditions', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _kv('Temperature', '${f.tempCurrent.toStringAsFixed(1)}°C'),
                _kv('Humidity', '${f.humidityCurrent.toStringAsFixed(0)}%'),
                _kv('Rainfall (24h)', '${f.rainfallMm24h.toStringAsFixed(1)}mm'),
                _kv('Wind', '${f.windCurrent.toStringAsFixed(1)} m/s'),
                _kv('Observed at', DateFormat('d MMM yyyy · HH:mm').format(f.observedAt.toLocal())),
              ])),
      ),
      const SizedBox(height: 12),
      qualityAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, __) => const SizedBox.shrink(),
        data: (q) => q == null
            ? const SizedBox.shrink()
            : _Card(title: 'Data Quality', child: Row(children: [
                _QualityBadge(score: q.qualityScore, label: q.qualityLabel),
                const SizedBox(width: 12),
                Expanded(child: Text('${q.validRows}/${q.totalRows} observations valid (${q.coveragePct}% coverage)',
                    style: AppTextStyles.bodyMuted)),
              ])),
      ),
    ]);
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 130, child: Text(k, style: AppTextStyles.bodyMuted)),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}

class _TemperatureTab extends StatelessWidget {
  const _TemperatureTab({required this.range});
  final _ExplorerRange range;

  @override
  Widget build(BuildContext context) => _SeriesLoader(
        range: range,
        builder: (context, rows) {
          final avgKey = 'temp_avg';
          final maxKey = 'temp_max';
          final avgs = rows.map((r) => _numAt(r, avgKey)).whereType<double>().toList();
          final maxs = rows.map((r) => _numAt(r, maxKey)).whereType<double>().toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            _Card(
              title: 'Temperature (avg / max)',
              child: _MiniChart(rows: rows, field: avgKey, color: AppColors.leaf, field2: maxKey, color2: AppColors.premiumWarning),
            ),
            const SizedBox(height: 12),
            _Card(title: 'Stats', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (avgs.isNotEmpty) Text('Average: ${(avgs.reduce((a, b) => a + b) / avgs.length).toStringAsFixed(1)}°C'),
              if (maxs.isNotEmpty) Text('Highest: ${maxs.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}°C'),
            ])),
          ]);
        },
      );
}

class _RainfallTab extends StatelessWidget {
  const _RainfallTab({required this.range});
  final _ExplorerRange range;

  @override
  Widget build(BuildContext context) => _SeriesLoader(
        range: range,
        builder: (context, rows) {
          final rains = rows.map((r) => _numAt(r, 'rainfall_mm')).whereType<double>().toList();
          final total = rains.isEmpty ? 0.0 : rains.reduce((a, b) => a + b);
          return ListView(padding: const EdgeInsets.all(16), children: [
            _Card(title: 'Rainfall', child: _MiniChart(rows: rows, field: 'rainfall_mm', color: AppColors.consumerAccent)),
            const SizedBox(height: 12),
            _Card(title: 'Stats', child: Text('Total over ${range.label.toLowerCase()}: ${total.toStringAsFixed(1)}mm')),
          ]);
        },
      );
}

class _HumidityTab extends StatelessWidget {
  const _HumidityTab({required this.range});
  final _ExplorerRange range;

  @override
  Widget build(BuildContext context) => _SeriesLoader(
        range: range,
        builder: (context, rows) {
          final hums = rows.map((r) => _numAt(r, 'humidity_avg')).whereType<double>().toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            _Card(title: 'Humidity (avg)', child: _MiniChart(rows: rows, field: 'humidity_avg', color: AppColors.premiumEmerald)),
            const SizedBox(height: 12),
            if (hums.isNotEmpty)
              _Card(title: 'Stats',
                  child: Text('Average: ${(hums.reduce((a, b) => a + b) / hums.length).toStringAsFixed(0)}%  ·  '
                      'Peak: ${hums.reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}%')),
            const SizedBox(height: 8),
            Text('Humidity remained elevated for extended periods where the line stays near the top of the chart — '
                'this is the main signal the disease-risk engine watches.',
                style: AppTextStyles.sans(12, color: AppColors.textSecondaryOf(context))),
          ]);
        },
      );
}

class _WindTab extends StatelessWidget {
  const _WindTab({required this.range});
  final _ExplorerRange range;

  @override
  Widget build(BuildContext context) => _SeriesLoader(
        range: range,
        builder: (context, rows) {
          return ListView(padding: const EdgeInsets.all(16), children: [
            _Card(title: 'Wind (avg / max gust)',
                child: _MiniChart(rows: rows, field: 'wind_avg', color: AppColors.slate,
                    field2: 'wind_max_gust', color2: AppColors.red)),
          ]);
        },
      );
}

class _RiskTab extends ConsumerWidget {
  const _RiskTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<CropWeatherRisk>>(
      future: ref.read(weatherStationServiceProvider).getAllCropRisks(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final risks = snap.data!;
        if (risks.isEmpty) {
          return Center(child: Text('No risk data ingested yet.', style: AppTextStyles.bodyMuted));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Risk breakdown across all configured crops — for comparing which crops are '
                'currently most exposed given the same environmental conditions.',
                style: AppTextStyles.bodyMuted),
            const SizedBox(height: 12),
            ...risks.map((r) => _Card(
                  title: kWeatherIntelligenceCrops[r.cropKey] ?? r.cropKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${r.level} · Overall ${r.overall}/100', style: AppTextStyles.sans(13, weight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    _riskBar('Disease', r.disease),
                    _riskBar('Heat', r.heat),
                    _riskBar('Water', r.water),
                    _riskBar('Wind', r.wind),
                    _riskBar('Rain', r.rain),
                  ]),
                )),
          ],
        );
      },
    );
  }

  Widget _riskBar(String label, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 60, child: Text(label, style: AppTextStyles.bodyMuted)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 8,
                backgroundColor: const Color(0xFFE8E4DC),
                color: value >= 65 ? AppColors.red : value >= 35 ? AppColors.premiumWarning : AppColors.premiumEmerald,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$value'),
        ]),
      );
}

class _DataQualityTab extends ConsumerWidget {
  const _DataQualityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qualityAsync = ref.watch(weatherDataQualityProvider);
    return qualityAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(child: Text("We couldn't load the data quality report.", style: AppTextStyles.bodyMuted)),
      data: (q) {
        if (q == null) {
          return Center(child: Text('No data quality report ingested yet.', style: AppTextStyles.bodyMuted));
        }
        return ListView(padding: const EdgeInsets.all(16), children: [
          _Card(
            title: 'WEATHER DATA QUALITY',
            child: Row(children: [
              _QualityBadge(score: q.qualityScore, label: q.qualityLabel),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${q.validRows} / ${q.totalRows} observations valid', style: AppTextStyles.sans(13, weight: FontWeight.w600)),
                  Text('${q.coveragePct}% coverage', style: AppTextStyles.bodyMuted),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _Card(title: 'Details', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Duplicate timestamps: ${q.duplicateTimestamps}'),
            Text('Invalid-value rows: ${q.invalidValueRows}'),
            Text('Timestamp gaps: ${q.gapCount} (largest ${q.largestGapMinutes.toStringAsFixed(0)} min)'),
            if (q.firstObservation != null) Text('First observation: ${DateFormat('d MMM yyyy HH:mm').format(q.firstObservation!.toLocal())}'),
            if (q.lastObservation != null) Text('Last observation: ${DateFormat('d MMM yyyy HH:mm').format(q.lastObservation!.toLocal())}'),
          ])),
          if (q.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(title: 'Flagged Issues', child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: q.issues.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('•  $i', style: AppTextStyles.bodyMuted))).toList())),
          ],
        ]);
      },
    );
  }
}

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.score, required this.label});
  final int score;
  final String label;

  Color get _color => score >= 95 ? AppColors.premiumEmerald : score >= 80 ? AppColors.leaf : score >= 60 ? AppColors.premiumWarning : AppColors.red;

  @override
  Widget build(BuildContext context) => Container(
        width: 64, height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _color.withValues(alpha: 0.14), shape: BoxShape.circle),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$score%', style: TextStyle(fontWeight: FontWeight.w800, color: _color, fontSize: 15)),
          Text(label, style: TextStyle(fontSize: 9, color: _color)),
        ]),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(),
              style: AppTextStyles.sans(11, weight: FontWeight.w700, color: AppColors.textSecondaryOf(context))
                  .copyWith(letterSpacing: 0.6)),
          const SizedBox(height: 8),
          child,
        ]),
      );
}
