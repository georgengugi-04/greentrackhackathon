// This used to be Flutter's default generated counter-app test — it
// referenced a `MyApp` class and a tap-to-increment counter that never
// existed in this project, so it failed to even compile.
//
// A note on why this file tests logic, not widgets: most of GreenTrack's
// screens read `sessionProvider`, which calls `FirebaseAuth.instance` the
// moment it's built (see SessionController.build() in session_provider.dart).
// That means pumping almost any real screen in a plain widget test throws,
// because there's no Firebase app initialized in the test environment.
// Testing that properly needs a mocking setup (e.g. the `firebase_auth_mocks`
// and `fake_cloud_firestore` packages) — a reasonable next step, but a
// separate piece of work from "make the test file compile again."
//
// What's tested here instead: the pure business logic that doesn't touch
// Firebase, Flutter widgets, or the network — the crop rotation advisor and
// the offline pest-vision heuristic. Good first tests to extend if you're
// adding features to either of those.
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:greentrack/core/services/crop_planning_advisor.dart';
import 'package:greentrack/core/services/ai_vision_service.dart';
import 'package:greentrack/core/theme/app_theme.dart';
import 'package:greentrack/data/models/models.dart';

void main() {
  group('CropPlanningAdvisor', () {
    test('recommends a nitrogen-fixing legume after a heavy feeder', () {
      final advice = CropPlanningAdvisor.advise(
        previousCropName: 'Tomatoes',
        diagnosis: const VisionDiagnosisResult(
          isHealthy: false,
          label: 'Early blight',
          confidence: 0.8,
          severity: PestSeverity.moderate,
          summary: 'test',
        ),
      );

      expect(advice.avoidFamily, CropFamily.nightshade);
      // Top recommendation after a nightshade should be a legume — that's
      // the whole point of crop rotation for a heavy feeder.
      expect(advice.recommendations.first.crop.family, CropFamily.legume);
    });

    test('never recommends replanting the same family that was diagnosed', () {
      final advice = CropPlanningAdvisor.advise(
        previousCropName: 'Cabbage',
        diagnosis: const VisionDiagnosisResult(
          isHealthy: false,
          label: 'Caterpillar damage',
          confidence: 0.7,
          severity: PestSeverity.moderate,
          summary: 'test',
        ),
      );

      final recommendedFamilies = advice.recommendations.map((r) => r.crop.family);
      expect(recommendedFamilies.contains(CropFamily.brassica), isFalse);
    });

    test('every recommendation includes a non-empty reason', () {
      final advice = CropPlanningAdvisor.advise(
        previousCropName: 'Carrots',
        diagnosis: const VisionDiagnosisResult(
          isHealthy: true,
          label: 'Healthy',
          confidence: 0.9,
          severity: PestSeverity.low,
          summary: 'test',
        ),
      );

      for (final rec in advice.recommendations) {
        expect(rec.reason, isNotEmpty);
        expect(rec.matchScore, inInclusiveRange(0, 100));
      }
    });
  });

  group('HeuristicVisionService', () {
    final service = HeuristicVisionService();

    test('throws a clear error on an empty image instead of guessing', () {
      expect(
        () => service.diagnose(Uint8List(0), cropName: 'Tomatoes'),
        throwsA(isA<AiVisionException>()),
      );
    });

    test('a solid green image reads as healthy', () async {
      // A small solid-green PNG — no discoloration, no edges, should land
      // in the "healthy" branch of the classifier.
      final bytes = _solidColorPng(width: 32, height: 32, r: 40, g: 160, b: 60);
      final result = await service.diagnose(bytes, cropName: 'Cherry Tomatoes');

      expect(result.usedOfflineModel, isTrue);
      expect(result.isHealthy, isTrue);
      expect(result.confidence, inInclusiveRange(0.0, 1.0));
    });
  });

  group('Theme', () {
    test('light and dark themes both build without throwing', () {
      final light = buildAppTheme();
      final dark = buildAppDarkTheme();
      expect(light.brightness.name, 'light');
      expect(dark.brightness.name, 'dark');
    });
  });
}

/// Minimal valid PNG for a single solid color, so tests don't need to
/// bundle a real image asset just to exercise the pixel-analysis path.
/// Uses the same `image` package the app already depends on for its own
/// pest-photo analysis, so there's no extra test-only dependency.
Uint8List _solidColorPng({required int width, required int height,
    required int r, required int g, required int b}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return Uint8List.fromList(img.encodePng(image));
}
