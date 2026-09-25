// Rule-based "AI irrigation recommendation" engine.
//
// This is a transparent expert-system rather than a black-box ML model —
// appropriate for an on-device recommendation with no backend, and easy to
// explain to a farmer ("why is it telling me this?"). It combines:
//   - how much rain has actually fallen vs. how much is forecast
//   - the crop's growth stage (young plants need more frequent, lighter
//     watering; fruiting/ready-to-harvest crops are more drought-tolerant
//     but yield-sensitive to stress)
//   - sun exposure (full sun dries soil faster)
//   - days since the batch was last irrigated
import 'weather_service.dart';
import '../../data/models/models.dart';

enum IrrigationUrgency { skip, low, medium, high }

class IrrigationAdvice {
  final CropBatch batch;
  final IrrigationUrgency urgency;
  final String headline;
  final String reason;
  final double recommendedLiters;

  const IrrigationAdvice({
    required this.batch,
    required this.urgency,
    required this.headline,
    required this.reason,
    required this.recommendedLiters,
  });

  String get emoji => switch (urgency) {
        IrrigationUrgency.skip => '✅',
        IrrigationUrgency.low => '🟢',
        IrrigationUrgency.medium => '🟡',
        IrrigationUrgency.high => '🔴',
      };
}

class IrrigationAdvisor {
  /// Base litres/day a mature plant of this crop roughly needs in full sun,
  /// before adjusting for weather. Rough horticultural rules of thumb —
  /// intended as a helpful starting point, not a precise agronomic model.
  static double _baseLitersPerPlant(String cropName) {
    final name = cropName.toLowerCase();
    if (name.contains('tomato')) return 2.0;
    if (name.contains('lettuce')) return 0.5;
    if (name.contains('carrot')) return 0.8;
    if (name.contains('avocado')) return 15.0;
    if (name.contains('pepper') || name.contains('chili')) return 1.2;
    if (name.contains('basil') || name.contains('herb')) return 0.4;
    return 1.0;
  }

  static double _stageMultiplier(CropStage stage) => switch (stage) {
        CropStage.planned => 0,
        CropStage.planted => 1.3, // establishing roots, needs frequent water
        CropStage.sprouting => 1.4,
        CropStage.vegetative => 1.1,
        CropStage.flowering => 1.2, // stress here hurts fruit set
        CropStage.fruiting => 1.0,
        CropStage.readyToHarvest => 0.6, // avoid splitting/diluting flavor
        CropStage.harvested => 0,
        CropStage.concern => 0.9,
        CropStage.failed => 0,
      };

  static double _sunMultiplier(SunExposure sun) => switch (sun) {
        SunExposure.fullSun => 1.2,
        SunExposure.partialSun => 1.0,
        SunExposure.shade => 0.75,
      };

  /// Builds a recommendation for one batch given the latest weather snapshot.
  static IrrigationAdvice advise(CropBatch batch, WeatherSnapshot weather) {
    if (batch.stage == CropStage.harvested ||
        batch.stage == CropStage.failed ||
        batch.stage == CropStage.planned) {
      return IrrigationAdvice(
        batch: batch,
        urgency: IrrigationUrgency.skip,
        headline: 'No action needed',
        reason: 'This batch is not currently in active growth.',
        recommendedLiters: 0,
      );
    }

    final daysSinceIrrigation = batch.irrigationLogs.isEmpty
        ? null
        : DateTime.now()
            .difference(batch.irrigationLogs.last.timestamp)
            .inDays;

    final plantCount = batch.quantityPlanted ?? 20;
    final base = _baseLitersPerPlant(batch.cropName) *
        _stageMultiplier(batch.stage) *
        _sunMultiplier(batch.sunExposure) *
        plantCount;

    // Heavy recent rain covers most of the need; heavy forecast rain means
    // hold off to avoid waterlogging/root rot and wasted effort.
    final rainCoverage = weather.rainfallLast24hMm; // mm in the last day
    final rainComing = weather.rainForecastNext24hMm;

    double recommended = base;
    IrrigationUrgency urgency;
    String reason;
    String headline;

    if (rainComing >= 10) {
      urgency = IrrigationUrgency.skip;
      headline = 'Hold off — rain expected';
      reason = '${rainComing.toStringAsFixed(1)}mm of rain is forecast in '
          'the next 24h, more than enough for ${batch.cropName}.';
      recommended = 0;
    } else if (rainCoverage >= 15) {
      urgency = IrrigationUrgency.skip;
      headline = 'Skip today — well watered by rain';
      reason = '${rainCoverage.toStringAsFixed(1)}mm fell in the last 24h, '
          'soil should still be moist.';
      recommended = 0;
    } else if (rainCoverage >= 5) {
      urgency = IrrigationUrgency.low;
      headline = 'Light top-up recommended';
      reason = 'Some rain fell (${rainCoverage.toStringAsFixed(1)}mm) but '
          'may not be enough for ${batch.stage.label.toLowerCase()} '
          '${batch.cropName.toLowerCase()} in ${weather.tempC.toStringAsFixed(0)}°C.';
      recommended = base * 0.4;
    } else if (weather.tempC >= 28 && weather.humidityPct <= 50) {
      urgency = IrrigationUrgency.high;
      headline = 'Water today — hot & dry';
      reason = '${weather.tempC.toStringAsFixed(0)}°C with '
          '${weather.humidityPct.toStringAsFixed(0)}% humidity means fast '
          'evaporation. No meaningful rain in the forecast.';
      recommended = base * 1.3;
    } else if (daysSinceIrrigation != null && daysSinceIrrigation >= 3) {
      urgency = IrrigationUrgency.medium;
      headline = 'Due for watering';
      reason = 'It has been $daysSinceIrrigation days since the last '
          'irrigation log, with no significant rain since.';
    } else if (daysSinceIrrigation == null) {
      urgency = IrrigationUrgency.medium;
      headline = 'No irrigation logged yet';
      reason = 'Start a regular watering schedule for this batch.';
    } else {
      urgency = IrrigationUrgency.low;
      headline = 'Conditions are fine';
      reason = 'Recently watered and no heat stress expected today.';
      recommended = base * 0.5;
    }

    return IrrigationAdvice(
      batch: batch,
      urgency: urgency,
      headline: headline,
      reason: reason,
      recommendedLiters: recommended < 0 ? 0 : recommended,
    );
  }

  static List<IrrigationAdvice> adviseAll(
    List<CropBatch> batches,
    WeatherSnapshot weather,
  ) =>
      batches.map((b) => advise(b, weather)).toList()
        ..sort((a, b) => b.urgency.index.compareTo(a.urgency.index));
}
