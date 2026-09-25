import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/models.dart';

/// Reads the JKUAT station's aggregated weather intelligence data —
/// written by weather_pipeline/upload_to_firestore.py, never computed
/// on-device from raw rows (the app only ever sees the compact
/// aggregates the offline pipeline already produced).
class WeatherStationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Single station for now (JKUAT). The doc path already keys off
  // stationId so adding more stations later is additive, not a rewrite —
  // see spec section 20's "future architecture should allow multiple
  // weather stations."
  static const defaultStationId = '61';

  DocumentReference<Map<String, dynamic>> _station(String stationId) =>
      _db.collection('weather_stations').doc(stationId);

  Future<WeatherStationInfo?> getStationInfo({String stationId = defaultStationId}) async {
    final doc = await _station(stationId).get();
    if (!doc.exists) return null;
    return WeatherStationInfo.fromJson(doc.data()!);
  }

  Stream<WeatherStationInfo?> watchStationInfo({String stationId = defaultStationId}) =>
      _station(stationId).snapshots().map((d) => d.exists ? WeatherStationInfo.fromJson(d.data()!) : null);

  Future<WeatherDataQuality?> getDataQuality({String stationId = defaultStationId}) async {
    final doc = await _station(stationId).collection('quality').doc('latest').get();
    if (!doc.exists) return null;
    return WeatherDataQuality.fromJson(doc.data()!);
  }

  Stream<WeatherFeatures?> watchCurrentFeatures({String stationId = defaultStationId}) =>
      _station(stationId)
          .collection('features')
          .doc('current')
          .snapshots()
          .map((d) => d.exists ? WeatherFeatures.fromJson(d.data()!) : null);

  Stream<CropWeatherRisk?> watchCropRisk(String cropKey, {String stationId = defaultStationId}) =>
      _station(stationId)
          .collection('crop_risks')
          .doc(cropKey)
          .snapshots()
          .map((d) => d.exists ? CropWeatherRisk.fromJson(cropKey, d.data()!) : null);

  Future<List<CropWeatherRisk>> getAllCropRisks({String stationId = defaultStationId}) async {
    final snap = await _station(stationId).collection('crop_risks').get();
    return snap.docs.map((d) => CropWeatherRisk.fromJson(d.id, d.data())).toList();
  }

  /// Hourly aggregates for the timeline chart. `hours` caps how far back
  /// to look — never pulls the full history into the app at once.
  Future<List<Map<String, dynamic>>> getHourlyHistory({
    String stationId = defaultStationId,
    int hours = 24,
  }) async {
    final since = DateTime.now().toUtc().subtract(Duration(hours: hours));
    final snap = await _station(stationId)
        .collection('hourly')
        .where('Time', isGreaterThanOrEqualTo: since.toIso8601String())
        .orderBy('Time')
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getDailyHistory({
    String stationId = defaultStationId,
    int days = 7,
  }) async {
    final since = DateTime.now().toUtc().subtract(Duration(days: days));
    final snap = await _station(stationId)
        .collection('daily')
        .where('Time', isGreaterThanOrEqualTo: since.toIso8601String())
        .orderBy('Time')
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }
}
