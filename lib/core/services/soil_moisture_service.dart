// Sentinel-1 SAR-derived soil moisture for a farm plot.
//
// Sentinel-1 is ESA's radar satellite — it sees through cloud cover and
// works day or night, which makes it useful for something optical
// satellites (and this app's weather API) can't give you: an actual
// measurement of how wet the *soil* is, not just the air.
//
// ── Why this needs a real backscatter → moisture step ────────────────
// Sentinel-1 doesn't hand you "% soil moisture" directly — it gives you
// radar backscatter (VV/VH, in dB). Wetter soil reflects radar more
// strongly, so backscatter correlates with moisture, but the exact curve
// depends on vegetation cover, soil roughness, and incidence angle. Real
// SM-inversion (e.g. a Water Cloud Model) needs calibration per-region.
// [RemoteSoilMoistureService] below uses a simple linear scaling of VV
// backscatter as a *stand-in* — clearly labeled `isApproximate: true` — so
// this ships useful and honest today, and can be swapped for a proper
// inversion model (or a third-party SM product like Copernicus' own Soil
// Water Index) later without touching any UI code.
//
// ── To go live ────────────────────────────────────────────────────────
// 1. Create a free account at https://www.sentinel-hub.com (or via the
//    Copernicus Data Space Ecosystem, dataspace.copernicus.eu — same API).
// 2. Create an OAuth client under Dashboard → User settings → OAuth
//    clients. That gives you a Client ID + Client Secret.
// 3. Run with:
//    --dart-define=SENTINEL_HUB_CLIENT_ID=xxx
//    --dart-define=SENTINEL_HUB_CLIENT_SECRET=xxx
// 4. Nothing else changes — every screen calls through
//    `SoilMoistureService.instance`, same pattern as AiVisionService.
//
// Sentinel-1 revisits the same spot roughly every 6-12 days (not daily),
// so [SoilMoistureReading.observedAt] should always be shown alongside
// the value — never imply this is live.
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class SoilMoistureReading {
  final double moisturePercent; // 0-100, approximate
  final DateTime observedAt; // when Sentinel-1 actually passed over
  final bool isApproximate;

  const SoilMoistureReading({
    required this.moisturePercent,
    required this.observedAt,
    this.isApproximate = true,
  });

  String get label {
    if (moisturePercent < 25) return 'Low';
    if (moisturePercent < 55) return 'Moderate';
    return 'High';
  }

  int get daysSinceObserved => DateTime.now().difference(observedAt).inDays;
}

abstract class SoilMoistureService {
  /// Latest available Sentinel-1 soil moisture estimate for [lat]/[lng].
  /// Returns null if unavailable (no key configured, no recent pass, or
  /// the request failed) — callers should treat that as "hide the tile",
  /// never as an error to surface to the farmer.
  Future<SoilMoistureReading?> fetchFor(double lat, double lng);

  /// Swap this for `RemoteSoilMoistureService(clientId: ..., clientSecret: ...)`
  /// once Sentinel Hub credentials are available; every screen calls
  /// through this single access point.
  static SoilMoistureService instance = _NoopSoilMoistureService();
}

/// Default when no credentials are configured — no satellite tile shown.
class _NoopSoilMoistureService implements SoilMoistureService {
  @override
  Future<SoilMoistureReading?> fetchFor(double lat, double lng) async => null;
}

class RemoteSoilMoistureService implements SoilMoistureService {
  final String clientId;
  final String clientSecret;
  final http.Client _client;

  RemoteSoilMoistureService({
    required this.clientId,
    required this.clientSecret,
    http.Client? client,
  }) : _client = client ?? http.Client();

  String? _accessToken;
  DateTime? _tokenExpiresAt;

  static const _tokenUrl = 'https://services.sentinel-hub.com/oauth/token';
  static const _statsUrl = 'https://services.sentinel-hub.com/api/v1/statistics';

  Future<String?> _getToken() async {
    if (_accessToken != null &&
        _tokenExpiresAt != null &&
        DateTime.now().isBefore(_tokenExpiresAt!)) {
      return _accessToken;
    }
    try {
      final res = await _client.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 300;
      _accessToken = token;
      // Refresh a little early rather than right at expiry.
      _tokenExpiresAt =
          DateTime.now().add(Duration(seconds: math.max(30, expiresIn - 30)));
      return token;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<SoilMoistureReading?> fetchFor(double lat, double lng) async {
    if (clientId.isEmpty || clientSecret.isEmpty) return null;
    final token = await _getToken();
    if (token == null) return null;

    try {
      final now = DateTime.now().toUtc();
      final from = now.subtract(const Duration(days: 12));
      String iso(DateTime d) => d.toIso8601String().split('.').first + 'Z';

      // Small bbox (~150m) centered on the plot — Sentinel-1 GRD is
      // ~10m/px, this keeps the averaged pixel count small and fast.
      const delta = 0.0015;
      final body = {
        'input': {
          'bounds': {
            'bbox': [lng - delta, lat - delta, lng + delta, lat + delta],
            'properties': {
              'crs': 'http://www.opengis.net/def/crs/EPSG/0/4326'
            },
          },
          'data': [
            {
              'type': 'sentinel-1-grd',
              'dataFilter': {
                'timeRange': {'from': iso(from), 'to': iso(now)},
                'acquisitionMode': 'IW',
                'polarization': 'DV',
              },
            },
          ],
        },
        'aggregation': {
          'timeRange': {'from': iso(from), 'to': iso(now)},
          'aggregationInterval': {'of': 'P1D'},
          'evalscript': _evalscript,
          'resx': 20,
          'resy': 20,
        },
      };

      final res = await _client
          .post(
            Uri.parse(_statsUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final intervals = data['data'] as List<dynamic>?;
      if (intervals == null || intervals.isEmpty) return null;

      // Walk backwards for the most recent interval that actually has a
      // valid pixel sample (cloud/pass gaps mean most days are empty).
      for (final interval in intervals.reversed) {
        final outputs = interval['outputs'] as Map<String, dynamic>?;
        final stats = outputs?['data']?['bands']?['B0']?['stats']
            as Map<String, dynamic>?;
        final sampleCount = (stats?['sampleCount'] as num?)?.toInt() ?? 0;
        final noDataCount = (stats?['noDataCount'] as num?)?.toInt() ?? 0;
        if (stats == null || sampleCount == 0 || sampleCount == noDataCount) {
          continue;
        }
        final vvLinearMean = (stats['mean'] as num).toDouble();
        if (vvLinearMean <= 0) continue;

        // Linear power → dB, then a simple linear stand-in mapping
        // (-20dB ≈ dry/0%, -5dB ≈ saturated/100%) — see file header for
        // why this is an approximation, not a calibrated SM-inversion.
        final vvDb = 10 * (math.log(vvLinearMean) / math.ln10);
        final pct = ((vvDb + 20) / 15 * 100).clamp(0, 100).toDouble();

        final intervalTo = interval['interval']?['to'] as String?;
        final observedAt =
            intervalTo != null ? DateTime.tryParse(intervalTo) : null;

        return SoilMoistureReading(
          moisturePercent: pct,
          observedAt: observedAt ?? now,
        );
      }
      return null;
    } catch (e) {
      // Network hiccup, expired/rotated key, or the API contract having
      // drifted since this was written — never let this block the
      // dashboard. Caller just hides the satellite tile.
      return null;
    }
  }

  static const _evalscript = '''
//VERSION=3
function setup() {
  return {
    input: [{ bands: ["VV", "dataMask"] }],
    output: [{ id: "data", bands: 1, sampleType: "FLOAT32" }]
  };
}
function evaluatePixel(sample) {
  return { data: [sample.dataMask === 1 ? sample.VV : NaN] };
}
''';
}
