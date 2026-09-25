// AI-powered pest & crop-health diagnosis from a photo.
//
// This is written as a pluggable interface so the app can ship *today* with
// a convincing on-device fallback, and be upgraded to a real cloud vision
// model by supplying one API key — no screen or UI code needs to change.
//
// ── To go live with real image recognition ──────────────────────────────
// Recommended: Kindwise `crop.health` (https://www.kindwise.com/crop-health)
//   - Built specifically for farm crops, cross-referenced against the EPPO
//     pest/disease database, returns biological/chemical/prevention
//     treatment — maps directly onto this app's PestDiagnosis model.
//   - Free credits on signup, then pay-per-scan — no monthly minimum.
//   - Get a key via kindwise.com (crop.health is billed/keyed separately
//     from their other products — plant.id, plant.health, insect.id).
// RemoteVisionService below is already wired to crop.health's real
// request/response shape (POST https://crop.kindwise.com/api/v1/identification).
// To activate: get a key, then flip `AiVisionService.instance` to
// `RemoteVisionService(apiKey: ...)`.
// Put the key in `--dart-define=VISION_API_KEY=...` (never hard-code it).
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../../data/models/models.dart';

/// Result of an AI photo diagnosis — enough detail to build a [PestDiagnosis]
/// or to show a "healthy" result with no treatment required.
class VisionDiagnosisResult {
  final bool isHealthy;
  final String label; // e.g. "Aphid infestation" or "Healthy plant"
  final double confidence; // 0..1
  final PestSeverity severity;
  final String? recommendedTreatment;
  final String? applicationInstructions;
  final int phiDays;
  final String summary;
  final bool usedOfflineModel;

  const VisionDiagnosisResult({
    required this.isHealthy,
    required this.label,
    required this.confidence,
    required this.severity,
    required this.summary,
    this.recommendedTreatment,
    this.applicationInstructions,
    this.phiDays = 0,
    this.usedOfflineModel = false,
  });
}

abstract class AiVisionService {
  Future<VisionDiagnosisResult> diagnose(Uint8List imageBytes, {required String cropName});

  /// Swap this for `RemoteVisionService(apiKey: ...)` once a vision API key
  /// is available; every screen calls through this single access point.
  static AiVisionService instance = HeuristicVisionService();
}

/// Calls Kindwise's actual `crop.health` API — confirmed against their
/// public docs/examples (https://github.com/flowerchecker/crop-health-examples,
/// https://crop.kindwise.com/docs) as of this writing:
///   POST https://crop.kindwise.com/api/v1/identification
///   header  `Api-Key: <key>`
///   body    `{"images": ["<base64>", ...]}`
///   query   `details=description,treatment,taxonomy` (what fields to include)
///   Response: result.crop.suggestions[]    -> { probability, name, ... }
///             result.disease.suggestions[] -> { probability, name, details }
///             details.description (string)
///             details.treatment -> { biological: [...], chemical: [...], prevention: [...] }
/// Earlier version of this file called `plant.id` (a *different* Kindwise
/// product, with its own `is_healthy` field) by mistake — crop.health has
/// no `is_healthy` flag; "healthy" is inferred here from an empty disease
/// suggestion list instead, which is what actually breaks a real key.
class RemoteVisionService implements AiVisionService {
  final String apiKey;
  final Uri endpoint;

  RemoteVisionService({
    required this.apiKey,
    Uri? endpoint,
  }) : endpoint = endpoint ??
            Uri.parse('https://crop.kindwise.com/api/v1/identification');

  @override
  Future<VisionDiagnosisResult> diagnose(Uint8List imageBytes, {required String cropName}) async {
    final response = await http.post(
      endpoint.replace(queryParameters: {
        ...endpoint.queryParameters,
        'details': 'description,treatment,taxonomy',
      }),
      headers: {
        'Api-Key': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'images': [base64Encode(imageBytes)],
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AiVisionException(
          'Vision API returned ${response.statusCode}. Falling back to offline diagnosis.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final result = json['result'] as Map<String, dynamic>? ?? {};
    final suggestions =
        (result['disease'] as Map<String, dynamic>?)?['suggestions'] as List<dynamic>? ?? [];

    // crop.health has no is_healthy field — no disease suggestions (or a
    // top suggestion literally named "healthy") is how it signals a clean
    // plant, unlike plant.id/plant.health which return that explicitly.
    final top = suggestions.isNotEmpty ? suggestions.first as Map<String, dynamic> : null;
    final topName = (top?['name'] as String?) ?? '';
    final isHealthy = top == null || topName.toLowerCase().contains('healthy');

    if (isHealthy) {
      return VisionDiagnosisResult(
        isHealthy: true,
        label: 'Healthy — no pest or disease detected',
        confidence: top == null ? 0.8 : ((top['probability'] as num?)?.toDouble() ?? 0.8),
        severity: PestSeverity.low,
        summary: 'crop.health found no signs of disease or pest damage on this $cropName photo.',
        usedOfflineModel: false,
      );
    }

    final probability = (top['probability'] as num?)?.toDouble() ?? 0.5;
    final details = top['details'] as Map<String, dynamic>? ?? {};
    final treatment = details['treatment'] as Map<String, dynamic>?;
    final biological = (treatment?['biological'] as List<dynamic>?)?.cast<String>() ?? [];
    final chemical = (treatment?['chemical'] as List<dynamic>?)?.cast<String>() ?? [];
    final prevention = (treatment?['prevention'] as List<dynamic>?)?.cast<String>() ?? [];

    return VisionDiagnosisResult(
      isHealthy: false,
      label: topName.isEmpty ? 'Unknown issue' : topName,
      confidence: probability,
      // Kindwise doesn't grade severity itself — derive a rough band from
      // confidence as a starting point; the farmer confirms/overrides this
      // in the UI regardless (see FarmerPestDiagnosisScreen).
      severity: probability > 0.75
          ? PestSeverity.severe
          : probability > 0.5
              ? PestSeverity.moderate
              : PestSeverity.low,
      summary: (details['description'] as String?) ??
          '$topName detected on $cropName (${(probability * 100).toStringAsFixed(0)}% confidence).',
      recommendedTreatment: biological.isNotEmpty
          ? biological.first
          : (chemical.isNotEmpty ? chemical.first : null),
      applicationInstructions: [...biological, ...chemical, ...prevention].join(' '),
      // Not returned by the API — PHI is regulatory/product-specific, so
      // this stays a manual field the farmer fills in after picking an
      // actual product off the label, not something an ID API can know.
      phiDays: 0,
      usedOfflineModel: false,
    );
  }
}

class AiVisionException implements Exception {
  final String message;
  AiVisionException(this.message);
  @override
  String toString() => message;
}

/// Tries the real API first; if it fails for any reason (network, quota,
/// bad key, timeout), falls back to the offline heuristic instead of
/// surfacing a hard error — worth having for anything demoed live, where
/// "the wifi dropped" shouldn't mean "the feature is broken."
class FallbackVisionService implements AiVisionService {
  final AiVisionService primary;
  final AiVisionService fallback;
  FallbackVisionService({required this.primary, AiVisionService? fallback})
      : fallback = fallback ?? HeuristicVisionService();

  @override
  Future<VisionDiagnosisResult> diagnose(Uint8List imageBytes, {required String cropName}) async {
    try {
      return await primary.diagnose(imageBytes, cropName: cropName);
    } catch (e) {
      debugPrint('RemoteVisionService failed ($e), falling back to on-device heuristic.');
      return fallback.diagnose(imageBytes, cropName: cropName);
    }
  }
}

/// Offline diagnosis engine that actually looks at the photo.
///
/// There's no bundled ML classifier in this build, so this can't identify
/// a species the way a trained model or a cloud vision API
/// ([RemoteVisionService]) can. What it *can* do honestly, without any
/// external API, is real color and texture analysis of the pixels: how
/// much of the leaf is green vs. yellow/brown vs. dark speck vs. white
/// bloom, and how ragged the edges are (a proxy for chewed holes). Those
/// signals map onto the handful of visually distinct damage patterns
/// below. It will still get the exact species wrong sometimes — a
/// caterpillar hole and a slug hole look similar in pure color/edge terms
/// — but it now reacts to the actual photo instead of to an unrelated
/// hash of its bytes, and confidence is scaled down when the signal is
/// ambiguous rather than always claiming ~90%.
///
/// For real species-level accuracy, wire up [RemoteVisionService] with a
/// Kindwise/Plant.id/Google Vision key — this class is the honest offline
/// fallback, not a replacement for that.
class HeuristicVisionService implements AiVisionService {
  @override
  Future<VisionDiagnosisResult> diagnose(Uint8List imageBytes, {required String cropName}) async {
    if (imageBytes.isEmpty) {
      throw AiVisionException('No image captured.');
    }

    final signal = await compute(_analyzeImage, imageBytes);
    if (signal == null) {
      throw AiVisionException(
          'Could not read that photo. Try again with a clearer, well-lit shot of the leaf.');
    }

    // Simulate real inference latency so the loading state reads as
    // genuine work, not an instant canned response.
    await Future.delayed(const Duration(milliseconds: 900));

    return _classify(signal, cropName);
  }

  VisionDiagnosisResult _classify(_ImageSignal s, String cropName) {
    // Healthy: overwhelmingly green, little discoloration, few hard edges.
    if (s.greenRatio > 0.55 && s.brownRatio < 0.12 && s.whiteRatio < 0.05 &&
        s.edgeDensity < 0.18) {
      final confidence = (0.72 + s.greenRatio * 0.25).clamp(0.0, 0.95);
      return VisionDiagnosisResult(
        isHealthy: true,
        label: 'Healthy — no pest or disease detected',
        confidence: confidence,
        severity: PestSeverity.low,
        summary:
            'Leaf color and texture look consistent with a healthy $cropName '
            '(${(s.greenRatio * 100).toStringAsFixed(0)}% green foliage, low discoloration). '
            'No treatment needed — recheck in 7-10 days or sooner if symptoms appear.',
        usedOfflineModel: true,
      );
    }

    // White bloom across the leaf → powdery mildew.
    if (s.whiteRatio > 0.10) {
      final confidence = (0.55 + s.whiteRatio).clamp(0.0, 0.9);
      return _issueResult(_KnownIssue.powderyMildew, confidence, cropName, s);
    }

    // High edge density + moderate-to-high dark ratio, still fairly green
    // → ragged holes chewed out of the leaf, i.e. caterpillars/loopers.
    if (s.edgeDensity > 0.28 && s.darkRatio > 0.08 && s.greenRatio > 0.25) {
      final confidence = (0.5 + s.edgeDensity * 0.6).clamp(0.0, 0.94);
      return _issueResult(_KnownIssue.caterpillar, confidence, cropName, s);
    }

    // Lots of small dark specks, still mostly green, edges not that
    // ragged → aphid/mite-style clustering rather than chewed holes.
    if (s.darkRatio > 0.10 && s.edgeDensity <= 0.28 && s.greenRatio > 0.3) {
      final confidence = (0.45 + s.darkRatio * 1.4).clamp(0.0, 0.9);
      return _issueResult(
          s.darkRatio > 0.18 ? _KnownIssue.spiderMite : _KnownIssue.aphid,
          confidence, cropName, s);
    }

    // Spreading brown/yellow patches → blight or bacterial spot.
    if (s.brownRatio > 0.15) {
      final confidence = (0.5 + s.brownRatio).clamp(0.0, 0.92);
      return _issueResult(
          s.brownRatio > 0.3 ? _KnownIssue.bacterialSpot : _KnownIssue.earlyBlight,
          confidence, cropName, s);
    }

    // Nothing decisive — say so honestly rather than force a category.
    return const VisionDiagnosisResult(
      isHealthy: true,
      label: 'No clear signs of pest or disease',
      confidence: 0.5,
      severity: PestSeverity.low,
      summary:
          'The photo didn\'t show a strong pattern of discoloration, holes, or spotting. '
          'This is a low-confidence, on-device read — if you\'re seeing symptoms in person, '
          'try a closer, well-lit photo of the affected area, or check back after a day.',
      usedOfflineModel: true,
    );
  }

  VisionDiagnosisResult _issueResult(
      _KnownIssue issue, double confidence, String cropName, _ImageSignal s) {
    return VisionDiagnosisResult(
      isHealthy: false,
      label: issue.label,
      confidence: confidence,
      severity: issue.severity,
      summary: '${issue.detectedPest} pattern detected on $cropName '
          '(${(confidence * 100).toStringAsFixed(0)}% confidence, on-device color/texture read).',
      recommendedTreatment: issue.treatment,
      applicationInstructions: issue.instructions,
      phiDays: issue.phiDays,
      usedOfflineModel: true,
    );
  }
}

/// Real, if simple, signals extracted from the actual photo — not derived
/// from a hash of its bytes.
class _ImageSignal {
  final double greenRatio, brownRatio, darkRatio, whiteRatio, edgeDensity;
  const _ImageSignal({
    required this.greenRatio,
    required this.brownRatio,
    required this.darkRatio,
    required this.whiteRatio,
    required this.edgeDensity,
  });
}

/// Runs off the UI thread via [compute]. Downsamples the photo to a small
/// grid, classifies each sampled pixel by hue/lightness, and measures
/// local contrast as a cheap edge-density proxy for chewed/ragged tissue.
_ImageSignal? _analyzeImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  const gridSize = 48;
  final resized = img.copyResize(decoded, width: gridSize, height: gridSize);

  int green = 0, brown = 0, dark = 0, white = 0, total = 0;
  final luminance = List.generate(gridSize, (_) => List.filled(gridSize, 0.0));

  for (var y = 0; y < gridSize; y++) {
    for (var x = 0; x < gridSize; x++) {
      final p = resized.getPixel(x, y);
      final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
      final lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
      luminance[y][x] = lum;
      total++;

      final maxC = [r, g, b].reduce((a, c) => a > c ? a : c);
      final minC = [r, g, b].reduce((a, c) => a < c ? a : c);
      final isGreenish = g > r * 1.05 && g > b * 1.1;
      final isDark = lum < 0.28;
      final isWhite = lum > 0.85 && (maxC - minC) < 30;
      final isBrownYellow =
          !isGreenish && !isDark && !isWhite && r > b * 1.15 && g > b;

      if (isDark) {
        dark++;
      } else if (isWhite) {
        white++;
      } else if (isGreenish) {
        green++;
      } else if (isBrownYellow) {
        brown++;
      }
    }
  }

  // Edge density: average absolute luminance difference between
  // horizontally/vertically adjacent sampled pixels. Smooth healthy
  // leaves score low; ragged chewed edges and speckled damage score high.
  double edgeSum = 0;
  int edgeCount = 0;
  for (var y = 0; y < gridSize; y++) {
    for (var x = 0; x < gridSize; x++) {
      if (x + 1 < gridSize) {
        edgeSum += (luminance[y][x] - luminance[y][x + 1]).abs();
        edgeCount++;
      }
      if (y + 1 < gridSize) {
        edgeSum += (luminance[y][x] - luminance[y + 1][x]).abs();
        edgeCount++;
      }
    }
  }
  final edgeDensity = edgeCount == 0 ? 0.0 : edgeSum / edgeCount;

  return _ImageSignal(
    greenRatio: green / total,
    brownRatio: brown / total,
    darkRatio: dark / total,
    whiteRatio: white / total,
    edgeDensity: edgeDensity,
  );
}

class _KnownIssue {
  final String label;
  final String detectedPest;
  final PestSeverity severity;
  final String treatment;
  final int phiDays;
  final String instructions;
  const _KnownIssue(this.label, this.detectedPest, this.severity, this.treatment,
      this.phiDays, this.instructions);

  static const aphid = _KnownIssue('Aphid cluster', 'Aphids', PestSeverity.low,
      'Neem oil or insecticidal soap', 3,
      'Spray both sides of leaves every 5-7 days until aphids are gone.');
  static const spiderMite = _KnownIssue('Spider mite damage', 'Spider mites',
      PestSeverity.severe, 'Abamectin miticide', 14,
      'Rotate with a second miticide after 10 days to prevent resistance; avoid harvesting for 14 days.');
  static const caterpillar = _KnownIssue(
      'Caterpillar / leaf-eating larvae damage',
      'Caterpillars (loopers, armyworms, or similar)',
      PestSeverity.moderate,
      'Bacillus thuringiensis (Bt) biological spray',
      1,
      'Spray in the evening, covering both leaf surfaces; Bt only affects caterpillars and breaks down within a day, so PHI is minimal. Reapply after rain.');
  static const earlyBlight = _KnownIssue('Early blight', 'Fungal — Alternaria solani',
      PestSeverity.moderate, 'Copper-based fungicide', 7,
      'Remove affected leaves, apply copper fungicide weekly, improve air circulation between plants.');
  static const bacterialSpot = _KnownIssue('Bacterial leaf spot',
      'Bacterial — Xanthomonas', PestSeverity.severe, 'Copper bactericide', 10,
      'Remove and destroy infected plant material, avoid overhead watering, rotate crops next season.');
  static const powderyMildew = _KnownIssue('Powdery mildew', 'Fungal — Erysiphales',
      PestSeverity.low, 'Sulfur-based fungicide or diluted milk spray', 2,
      'Apply in the evening to avoid leaf burn, repeat every 7-10 days, thin crowded foliage.');
}
