// Data models for GreenTrack Climate Intelligence.
//
// These mirror the JSON documents produced by weather_pipeline/ingest.py and
// written to Firestore by weather_pipeline/upload_to_firestore.py — field names
// match exactly so a doc read straight from Firestore or from the bundled
// demo JSON asset parses the same way. See weather_pipeline/risk_engine.py for
// where the crop risk numbers/reasons actually come from.
library;

/// Where a [ClimateSnapshot] came from. Never mix labels — the UI must
/// always be honest about whether this is live station data or a bundled
/// demo/historical sample.
enum ClimateDataSource { demo, live }

class StationMeta {
  final String stationId;
  final String name;
  final String site;
  final double latitude;
  final double longitude;
  final double elevationM;
  final String attribution;

  const StationMeta({
    required this.stationId,
    required this.name,
    required this.site,
    required this.latitude,
    required this.longitude,
    required this.elevationM,
    required this.attribution,
  });

  factory StationMeta.fromJson(Map<String, dynamic> json) => StationMeta(
        stationId: json['station_id'].toString(),
        name: json['name'] as String? ?? '',
        site: json['site'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        elevationM: (json['elevation_m'] as num?)?.toDouble() ?? 0,
        attribution: json['attribution'] as String? ?? '',
      );
}

class DataQualitySummary {
  final int totalRows;
  final int validRows;
  final int gapCount;
  final double coveragePct;
  final int qualityScore;
  final String qualityLabel;
  final List<String> issues;

  const DataQualitySummary({
    required this.totalRows,
    required this.validRows,
    required this.gapCount,
    required this.coveragePct,
    required this.qualityScore,
    required this.qualityLabel,
    required this.issues,
  });

  factory DataQualitySummary.fromJson(Map<String, dynamic> json) => DataQualitySummary(
        totalRows: (json['total_rows'] as num?)?.toInt() ?? 0,
        validRows: (json['valid_rows'] as num?)?.toInt() ?? 0,
        gapCount: (json['gap_count'] as num?)?.toInt() ?? 0,
        coveragePct: (json['coverage_pct'] as num?)?.toDouble() ?? 0,
        qualityScore: (json['quality_score'] as num?)?.toInt() ?? 0,
        qualityLabel: json['quality_label'] as String? ?? 'Unknown',
        issues: (json['issues'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
}

/// The rolling-window feature set computed "as of" the latest observation
/// — see weather_pipeline/feature_engineering.py:rolling_window_features.
class ClimateFeatures {
  final DateTime observedAt;
  final double tempCurrent;
  final double? tempAvg24h;
  final double? tempMax24h;
  final double? tempMin24h;
  final double humidityCurrent;
  final double? humidityAvg24h;
  final int humidityPersistentHighMinutes24h;
  final double rainfallMm6h;
  final double rainfallMm24h;
  final double rainfallMm7d;
  final double dryPeriodHours;
  final double windCurrent;
  final double? windGustMax24h;
  final double? wbgtCurrent;
  final String rainfallMode; // "increment" | "counter" | "unknown" — see weather_pipeline/feature_engineering.py
  final bool rainfallModeVerified;

  const ClimateFeatures({
    required this.observedAt,
    required this.tempCurrent,
    this.tempAvg24h,
    this.tempMax24h,
    this.tempMin24h,
    required this.humidityCurrent,
    this.humidityAvg24h,
    required this.humidityPersistentHighMinutes24h,
    required this.rainfallMm6h,
    required this.rainfallMm24h,
    required this.rainfallMm7d,
    required this.dryPeriodHours,
    required this.windCurrent,
    this.windGustMax24h,
    this.wbgtCurrent,
    this.rainfallMode = 'unknown',
    this.rainfallModeVerified = false,
  });

  factory ClimateFeatures.fromJson(Map<String, dynamic> json) => ClimateFeatures(
        observedAt: DateTime.parse(json['observed_at'] as String),
        tempCurrent: (json['temp_current'] as num).toDouble(),
        tempAvg24h: (json['temp_avg_24h'] as num?)?.toDouble(),
        tempMax24h: (json['temp_max_24h'] as num?)?.toDouble(),
        tempMin24h: (json['temp_min_24h'] as num?)?.toDouble(),
        humidityCurrent: (json['humidity_current'] as num).toDouble(),
        humidityAvg24h: (json['humidity_avg_24h'] as num?)?.toDouble(),
        humidityPersistentHighMinutes24h:
            (json['humidity_persistent_high_minutes_24h'] as num?)?.toInt() ?? 0,
        rainfallMm6h: (json['rainfall_mm_6h'] as num?)?.toDouble() ?? 0,
        rainfallMm24h: (json['rainfall_mm_24h'] as num?)?.toDouble() ?? 0,
        rainfallMm7d: (json['rainfall_mm_7d'] as num?)?.toDouble() ?? 0,
        dryPeriodHours: (json['dry_period_hours'] as num?)?.toDouble() ?? 0,
        windCurrent: (json['wind_current'] as num?)?.toDouble() ?? 0,
        windGustMax24h: (json['wind_gust_max_24h'] as num?)?.toDouble(),
        wbgtCurrent: (json['wbgt_current'] as num?)?.toDouble(),
        rainfallMode: json['rainfall_mode'] as String? ?? 'unknown',
        rainfallModeVerified: json['rainfall_mode_verified'] as bool? ?? false,
      );
}

class SprayWindowStatus {
  final String status; // "Suitable" | "Caution" | "Not recommended"
  final String reason;
  final String suggestedAction;

  const SprayWindowStatus({
    required this.status,
    required this.reason,
    required this.suggestedAction,
  });

  factory SprayWindowStatus.fromJson(Map<String, dynamic> json) => SprayWindowStatus(
        status: json['status'] as String? ?? 'Suitable',
        reason: json['reason'] as String? ?? '',
        suggestedAction: json['suggested_action'] as String? ?? '',
      );
}

class IrrigationNeedInfo {
  final String need; // "LOW" | "MEDIUM" | "HIGH"
  final String reason;

  const IrrigationNeedInfo({required this.need, required this.reason});

  factory IrrigationNeedInfo.fromJson(Map<String, dynamic> json) => IrrigationNeedInfo(
        need: json['need'] as String? ?? 'LOW',
        reason: json['reason'] as String? ?? '',
      );
}

/// One crop's weather-risk assessment — see weather_pipeline/risk_engine.py for
/// the rules that produce this. `overall`/`level` are a weighted blend of
/// the five sub-scores; a crop can have a high individual score (e.g.
/// disease) while `level` still reads "Low" if the others are all zero,
/// so the UI should surface the dominant sub-score too, not just `level`.
class CropRisk {
  final String cropKey;
  final int overall;
  final int disease;
  final int heat;
  final int water;
  final int wind;
  final int rain;
  final String level; // "Low" | "Moderate" | "High"
  final String recommendation;
  final String action;
  final List<String> reasons;
  final SprayWindowStatus sprayWindow;
  final IrrigationNeedInfo irrigation;

  const CropRisk({
    required this.cropKey,
    required this.overall,
    required this.disease,
    required this.heat,
    required this.water,
    required this.wind,
    required this.rain,
    required this.level,
    required this.recommendation,
    required this.action,
    required this.reasons,
    required this.sprayWindow,
    required this.irrigation,
  });

  factory CropRisk.fromJson(String cropKey, Map<String, dynamic> json) => CropRisk(
        cropKey: cropKey,
        overall: (json['overall'] as num?)?.toInt() ?? 0,
        disease: (json['disease'] as num?)?.toInt() ?? 0,
        heat: (json['heat'] as num?)?.toInt() ?? 0,
        water: (json['water'] as num?)?.toInt() ?? 0,
        wind: (json['wind'] as num?)?.toInt() ?? 0,
        rain: (json['rain'] as num?)?.toInt() ?? 0,
        level: json['level'] as String? ?? 'Low',
        recommendation: json['recommendation'] as String? ?? '',
        action: json['action'] as String? ?? '',
        reasons: (json['reasons'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        sprayWindow: SprayWindowStatus.fromJson(
            (json['spray_window'] as Map<String, dynamic>?) ?? const {}),
        irrigation: IrrigationNeedInfo.fromJson(
            (json['irrigation'] as Map<String, dynamic>?) ?? const {}),
      );

  /// Dominant sub-score — the one driving [recommendation]/[action].
  String get dominantFactor {
    final scores = {'Disease': disease, 'Heat': heat, 'Water': water, 'Wind': wind, 'Rain': rain};
    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

/// Everything the Climate Intelligence screen needs, bundled together with
/// where it came from.
class ClimateSnapshot {
  final ClimateDataSource source;
  final String label;
  final StationMeta station;
  final DataQualitySummary dataQuality;
  final ClimateFeatures features;
  final Map<String, CropRisk> cropRisks;

  const ClimateSnapshot({
    required this.source,
    required this.label,
    required this.station,
    required this.dataQuality,
    required this.features,
    required this.cropRisks,
  });

  factory ClimateSnapshot.fromJson(Map<String, dynamic> json, {required ClimateDataSource source}) {
    final cropRisksJson = (json['crop_risks'] as Map<String, dynamic>? ?? {});
    return ClimateSnapshot(
      source: source,
      label: json['label'] as String? ??
          (source == ClimateDataSource.live
              ? 'JHUB Conduit Weather Station — Live'
              : 'JKUAT Weather Dataset — Historical / Demo'),
      station: StationMeta.fromJson((json['station'] as Map<String, dynamic>?) ?? const {}),
      dataQuality:
          DataQualitySummary.fromJson((json['data_quality'] as Map<String, dynamic>?) ?? const {}),
      features: ClimateFeatures.fromJson((json['features'] as Map<String, dynamic>)),
      cropRisks: {
        for (final entry in cropRisksJson.entries)
          entry.key: CropRisk.fromJson(entry.key, entry.value as Map<String, dynamic>),
      },
    );
  }
}
