import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/models.dart';

/// Result of a nutrition lookup, distinguishing "we got a real analysed
/// value" from "we fell back to the static per-100g table" so the UI can
/// be honest with the chef about which one they're looking at.
class NutritionLookupResult {
  final MealNutritionSnapshot nutrition;
  final bool fromApi;
  final String? error;
  const NutritionLookupResult(
      {required this.nutrition, required this.fromApi, this.error});
}

/// Nutrient IDs used by USDA FoodData Central for the values we care about.
/// (See https://fdc.nal.usda.gov/api-guide.html — these are stable across
/// their datasets.)
class _UsdaNutrientIds {
  static const calories = 1008; // Energy (kcal)
  static const protein = 1003; // Protein (g)
  static const carbs = 1005; // Carbohydrate, by difference (g)
  static const fat = 1004; // Total lipid / fat (g)
  static const fiber = 1079; // Fiber, total dietary (g)
}

/// Sources real nutrition data from USDA's FoodData Central — a free,
/// government-run food database with no paid tier, no card, and no
/// request quota you can accidentally get billed for. Unlike Edamam's
/// single "give me a whole recipe" call, USDA only searches one
/// ingredient at a time, so this looks each ingredient up individually
/// and sums the results, scaled to the grams used in the meal.
///
/// Falls back to the static per-100g reference table automatically if
/// the API is unreachable or a lookup comes back empty — a meal should
/// never be left with no nutrition info just because a network call
/// failed.
///
/// Setup (optional): USDA's shared `DEMO_KEY` works out of the box with
/// no signup, but is rate-limited (30 requests/hour, 50/day) across
/// everyone using it. For a real project, get your own free key (no
/// cost, ever, 1,000 requests/hour) at https://api.data.gov/signup and
/// run with:
///   flutter run --dart-define=USDA_API_KEY=your_key_here
class NutritionApiService {
  static const _apiKey =
      String.fromEnvironment('USDA_API_KEY', defaultValue: 'DEMO_KEY');
  static const _searchEndpoint =
      'https://api.nal.usda.gov/fdc/v1/foods/search';

  bool get isConfigured => true; // DEMO_KEY always works, just rate-limited

  Future<NutritionLookupResult> analyze({
    required String mealName,
    required List<MealIngredient> ingredients,
  }) async {
    final fallback = MealNutritionSnapshot.calculate(
        ingredients, MockData.nutritionReference);

    if (ingredients.isEmpty) {
      return NutritionLookupResult(nutrition: fallback, fromApi: false);
    }

    try {
      double calories = 0, protein = 0, carbs = 0, fat = 0, fiber = 0;
      var matchedAny = false;

      for (final ingredient in ingredients) {
        final per100g = await _lookupPer100g(ingredient.cropName);
        if (per100g == null) continue; // this one ingredient just isn't found
        matchedAny = true;
        final factor = ingredient.quantityGrams / 100.0;
        calories += per100g.calories * factor;
        protein += per100g.protein * factor;
        carbs += per100g.carbs * factor;
        fat += per100g.fat * factor;
        fiber += per100g.fiber * factor;
      }

      if (!matchedAny) {
        return NutritionLookupResult(
          nutrition: fallback,
          fromApi: false,
          error: 'No ingredients matched in USDA FoodData Central',
        );
      }

      return NutritionLookupResult(
        nutrition: MealNutritionSnapshot(
          calories: calories,
          proteinG: protein,
          carbsG: carbs,
          fatG: fat,
          fiberG: fiber,
        ),
        fromApi: true,
      );
    } catch (e) {
      // Offline, timed out, rate-limited, malformed response — any of
      // these should quietly fall back rather than block saving a meal.
      return NutritionLookupResult(
          nutrition: fallback, fromApi: false, error: e.toString());
    }
  }

  Future<_Per100g?> _lookupPer100g(String cropName) async {
    final uri = Uri.parse(_searchEndpoint).replace(queryParameters: {
      'query': cropName,
      'api_key': _apiKey,
      'pageSize': '5',
      // Prefer whole-food datasets (raw produce) over branded/processed
      // entries, which is what a crop batch actually is.
      'dataType': 'Foundation,SR Legacy',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final foods = data['foods'] as List<dynamic>? ?? [];
    if (foods.isEmpty) return null;

    final nutrients =
        (foods.first as Map<String, dynamic>)['foodNutrients'] as List<dynamic>? ??
            [];

    double byId(int id) {
      for (final n in nutrients) {
        final nMap = n as Map<String, dynamic>;
        if (nMap['nutrientId'] == id) {
          return (nMap['value'] as num?)?.toDouble() ?? 0;
        }
      }
      return 0;
    }

    // USDA values here are already per-100g, matching our reference table.
    return _Per100g(
      calories: byId(_UsdaNutrientIds.calories),
      protein: byId(_UsdaNutrientIds.protein),
      carbs: byId(_UsdaNutrientIds.carbs),
      fat: byId(_UsdaNutrientIds.fat),
      fiber: byId(_UsdaNutrientIds.fiber),
    );
  }
}

class _Per100g {
  final double calories, protein, carbs, fat, fiber;
  const _Per100g({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });
}
