// GreenTrack Climate Intelligence — data access.
//
// Reads the aggregated weather-intelligence documents that
// weather_pipeline/upload_to_firestore.py writes (see that file for the exact
// Firestore layout). If Firestore has no data yet for this station — no
// JHUB Conduit live credentials wired up, or the pipeline hasn't been run
// against the full dataset yet — this falls back to the bundled demo JSON
// asset built from a real (but historical/sample) JKUAT export.
//
// The two modes are never mixed or mislabeled: `ClimateSnapshot.source`
// and `.label` always say plainly which one the UI is looking at.
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/climate_models.dart';

const _demoAssetPath = 'assets/data/climate_demo.json';
const _defaultStationId = '61'; // Kenya Kiambu JKUAT IoT AWS — see weather_pipeline/ingest.py STATION_META

class ClimateIntelligenceService {
  final FirebaseFirestore? _firestore;

  /// Pass a [FirebaseFirestore] instance in tests; defaults to the app's
  /// configured instance otherwise.
  ClimateIntelligenceService({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<ClimateSnapshot> getSnapshot({String stationId = _defaultStationId}) async {
    try {
      final live = await _tryLive(stationId);
      if (live != null) return live;
    } catch (_) {
      // Firestore unreachable, not configured, or the station has no
      // documents yet — fall through to the bundled demo snapshot rather
      // than surfacing an error for what is an expected "no live data
      // yet" state during the hackathon.
    }
    return _loadDemo();
  }

  Future<ClimateSnapshot?> _tryLive(String stationId) async {
    final stationRef = _db.collection('weather_stations').doc(stationId);

    final featuresDoc = await stationRef.collection('features').doc('current').get();
    if (!featuresDoc.exists) return null; // no live pipeline output yet

    final qualityDoc = await stationRef.collection('quality').doc('latest').get();
    final cropRisksSnap = await stationRef.collection('crop_risks').get();
    final stationDoc = await stationRef.get();

    return ClimateSnapshot.fromJson(
      {
        'label': 'JHUB Conduit Weather Station — Live',
        'station': stationDoc.data() ?? {},
        'data_quality': qualityDoc.data() ?? {},
        'features': featuresDoc.data() ?? {},
        'crop_risks': {for (final d in cropRisksSnap.docs) d.id: d.data()},
      },
      source: ClimateDataSource.live,
    );
  }

  Future<ClimateSnapshot> _loadDemo() async {
    final raw = await rootBundle.loadString(_demoAssetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ClimateSnapshot.fromJson(json, source: ClimateDataSource.demo);
  }
}
