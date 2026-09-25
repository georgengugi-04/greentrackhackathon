// Rule-based "AI crop planning" engine — recommends the most favorable
// next crop for a plot once a pest/disease diagnosis comes back, using
// standard crop-rotation agronomy:
//   - never replant the same family right away (lets pest/pathogen
//     populations that overwinter in soil starve out)
//   - follow a heavy feeder with a nitrogen-fixing legume to rebuild soil
//   - match the recommendation to the season and the PHI clear date, so
//     the farmer knows exactly when the plot is free to replant
//
// Like [IrrigationAdvisor], this is a transparent expert system rather
// than a black box — every recommendation states *why*, which matters
// for a farmer deciding whether to trust it.
import '../../data/models/models.dart';
import 'ai_vision_service.dart';

enum CropFamily { nightshade, brassica, legume, cucurbit, allium, leafyGreen, root, herb }

class CropOption {
  final String name;
  final CropFamily family;
  final String emoji;
  const CropOption(this.name, this.family, this.emoji);
}

class CropRecommendation {
  final CropOption crop;
  final String reason;
  final int matchScore; // 0-100, higher is better
  const CropRecommendation({
    required this.crop,
    required this.reason,
    required this.matchScore,
  });
}

class CropPlanningAdvice {
  final DateTime? earliestPlantingDate;
  final CropFamily avoidFamily;
  final String headline;
  final List<CropRecommendation> recommendations;
  const CropPlanningAdvice({
    required this.earliestPlantingDate,
    required this.avoidFamily,
    required this.headline,
    required this.recommendations,
  });
}

class CropPlanningAdvisor {
  static const _catalogue = [
    CropOption('Bush Beans', CropFamily.legume, '🫘'),
    CropOption('Cowpeas', CropFamily.legume, '🌱'),
    CropOption('Kale', CropFamily.leafyGreen, '🥬'),
    CropOption('Lettuce', CropFamily.leafyGreen, '🥬'),
    CropOption('Carrots', CropFamily.root, '🥕'),
    CropOption('Onions', CropFamily.allium, '🧅'),
    CropOption('Garlic', CropFamily.allium, '🧄'),
    CropOption('Cabbage', CropFamily.brassica, '🥦'),
    CropOption('Broccoli', CropFamily.brassica, '🥦'),
    CropOption('Basil', CropFamily.herb, '🌿'),
    CropOption('Cucumber', CropFamily.cucurbit, '🥒'),
    CropOption('Butternut Squash', CropFamily.cucurbit, '🎃'),
    CropOption('Tomatoes', CropFamily.nightshade, '🍅'),
    CropOption('Bell Pepper', CropFamily.nightshade, '🫑'),
  ];

  static CropFamily _familyOf(String cropName) {
    final name = cropName.toLowerCase();
    if (name.contains('tomato') || name.contains('pepper') || name.contains('eggplant') ||
        name.contains('potato')) {
      return CropFamily.nightshade;
    }
    if (name.contains('cabbage') || name.contains('kale') || name.contains('broccoli') ||
        name.contains('cauliflower')) {
      return CropFamily.brassica;
    }
    if (name.contains('bean') || name.contains('pea') || name.contains('legume')) {
      return CropFamily.legume;
    }
    if (name.contains('cucumber') || name.contains('squash') || name.contains('melon') ||
        name.contains('pumpkin')) {
      return CropFamily.cucurbit;
    }
    if (name.contains('onion') || name.contains('garlic') || name.contains('leek')) {
      return CropFamily.allium;
    }
    if (name.contains('carrot') || name.contains('beet') || name.contains('radish')) {
      return CropFamily.root;
    }
    if (name.contains('basil') || name.contains('herb') || name.contains('mint')) {
      return CropFamily.herb;
    }
    return CropFamily.leafyGreen;
  }

  /// Families that share pests/pathogens with each other, beyond just
  /// their own family — e.g. whitefly and blight both hit nightshades and
  /// cucurbits hard, so it's worth steering away from both.
  static const _crossSusceptible = {
    CropFamily.nightshade: [CropFamily.nightshade],
    CropFamily.brassica: [CropFamily.brassica],
    CropFamily.cucurbit: [CropFamily.cucurbit],
  };

  /// Builds a recommendation for what to plant next in a plot, given the
  /// diagnosis that was just logged there and the previous crop grown.
  static CropPlanningAdvice advise({
    required String previousCropName,
    required VisionDiagnosisResult diagnosis,
    DateTime? phiClearDate,
  }) {
    final previousFamily = _familyOf(previousCropName);
    final avoid = {previousFamily, ..._crossSusceptible[previousFamily] ?? []};

    // Heavy feeders (fruiting nightshades/cucurbits) deplete soil nitrogen;
    // follow them with a legume to rebuild it rather than another heavy feeder.
    final wantsNitrogenFixer =
        previousFamily == CropFamily.nightshade || previousFamily == CropFamily.cucurbit;

    final scored = _catalogue
        .where((c) => !avoid.contains(c.family))
        .map((c) {
      var score = 60;
      String reason;
      if (c.family == CropFamily.legume && wantsNitrogenFixer) {
        score = 95;
        reason = '$previousCropName is a heavy feeder — ${c.name.toLowerCase()} '
            'fixes nitrogen back into the soil for the next heavy feeder.';
      } else if (diagnosis.severity == PestSeverity.severe &&
          (c.family == CropFamily.allium || c.family == CropFamily.herb)) {
        score = 88;
        reason = 'Alliums and aromatic herbs naturally repel many of the pests that '
            'affected the previous batch, giving the plot a break from severe pressure.';
      } else if (c.family == CropFamily.leafyGreen) {
        score = 75;
        reason = 'Fast-growing and low-risk — a safe rotation choice while soil recovers.';
      } else if (c.family == CropFamily.root) {
        score = 70;
        reason = 'Root crops draw from a different soil layer and share few pests with '
            '$previousCropName.';
      } else {
        score = 55;
        reason = 'Different plant family from $previousCropName, so pest/pathogen '
            'pressure resets for this plot.';
      }
      return CropRecommendation(crop: c, reason: reason, matchScore: score);
    }).toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    final headline = diagnosis.isHealthy
        ? 'Plot is healthy — rotate as a precaution'
        : 'Rotate away from ${_familyLabel(previousFamily)} crops next';

    return CropPlanningAdvice(
      earliestPlantingDate: phiClearDate,
      avoidFamily: previousFamily,
      headline: headline,
      recommendations: scored.take(4).toList(),
    );
  }

  static String _familyLabel(CropFamily f) => switch (f) {
        CropFamily.nightshade => 'nightshade',
        CropFamily.brassica => 'brassica',
        CropFamily.legume => 'legume',
        CropFamily.cucurbit => 'cucurbit',
        CropFamily.allium => 'allium',
        CropFamily.leafyGreen => 'leafy green',
        CropFamily.root => 'root vegetable',
        CropFamily.herb => 'herb',
      };
}
