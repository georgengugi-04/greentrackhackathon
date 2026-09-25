import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/unsplash_service.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';

class ChefMealBuilderScreen extends ConsumerStatefulWidget {
  const ChefMealBuilderScreen({super.key});

  @override
  ConsumerState<ChefMealBuilderScreen> createState() =>
      _ChefMealBuilderScreenState();
}

class _ChefMealBuilderScreenState
    extends ConsumerState<ChefMealBuilderScreen> {
  int _step = 0;
  bool _loading = false;
  final List<String> _steps = ['Details', 'Ingredients', 'Allergens', 'Review'];

  String _mealName = '';
  String _description = '';

  // Auto-fetched dish photo — no manual upload, same pattern as the
  // farmer's crop batch photo. Debounced on meal-name changes.
  UnsplashPhoto? _autoPhoto;
  bool _photoLoading = false;
  Timer? _photoDebounce;
  String _lastQueriedMealName = '';
  final Map<String, double> _selectedIngredients = {};
  final Map<AllergenType, _AllergenState> _allergens = {
    for (final a in AllergenType.values)
      if (a != AllergenType.none) a: _AllergenState.none,
    AllergenType.none: _AllergenState.none,
  };
  String _otherAllergen = '';

  MealNutritionSnapshot? _nutrition;
  bool _nutritionFromApi = false;
  bool _fetchingNutrition = false;
  Timer? _nutritionDebounce;

  List<MealIngredient> get _currentIngredients => _selectedIngredients.entries
      .map((e) => MealIngredient(
          cropBatchId: 'batch_001', cropName: e.key, quantityGrams: e.value))
      .toList();

  // Ingredients change on every quantity tap — debounce so we're not
  // firing a lookup per tap, then source real nutrition instead
  // of only ever using the static per-100g table.
  void _scheduleNutritionRefresh() {
    _nutritionDebounce?.cancel();
    if (_selectedIngredients.isEmpty) {
      setState(() {
        _nutrition = null;
        _nutritionFromApi = false;
      });
      return;
    }
    _nutritionDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _fetchingNutrition = true);
      final result = await ref.read(nutritionApiServiceProvider).analyze(
            mealName: _mealName.trim().isEmpty ? 'Meal' : _mealName.trim(),
            ingredients: _currentIngredients,
          );
      if (!mounted) return;
      setState(() {
        _nutrition = result.nutrition;
        _nutritionFromApi = result.fromApi;
        _fetchingNutrition = false;
      });
    });
  }

  @override
  void dispose() {
    _nutritionDebounce?.cancel();
    _photoDebounce?.cancel();
    super.dispose();
  }

  void _onMealNameChanged(String v) {
    setState(() => _mealName = v);
    _photoDebounce?.cancel();
    final query = v.trim();
    if (query.isEmpty || query == _lastQueriedMealName) return;
    _photoDebounce =
        Timer(const Duration(milliseconds: 700), () => _fetchMealPhoto(query));
  }

  Future<void> _fetchMealPhoto(String query) async {
    if (!mounted) return;
    setState(() => _photoLoading = true);
    final photo = await UnsplashService.instance.photoFor('$query dish plated food');
    _lastQueriedMealName = query;
    if (!mounted) return;
    setState(() {
      _autoPhoto = photo;
      _photoLoading = false;
    });
  }

  Future<void> _save() async {
    if (_mealName.trim().isEmpty) {
      setState(() => _step = 0);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Give the meal a name before saving.')));
      return;
    }
    if (_selectedIngredients.isEmpty) {
      setState(() => _step = 1);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add at least one ingredient before saving.')));
      return;
    }
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You need to be signed in with a real account to '
              'save a meal — the "Quick access" dev buttons don\'t create one.')));
      return;
    }
    final user = ref.read(sessionProvider);
    final restaurantName = user?.restaurantName ?? user?.name ?? 'Kitchen';

    final ingredients = _currentIngredients;
    final allergens = _allergens.entries
        .where((e) => e.key != AllergenType.none && e.value != _AllergenState.none)
        .map((e) => MealAllergen(
              mealId: '',
              allergenId: e.key,
              contains: e.value == _AllergenState.contains,
              mayContain: e.value == _AllergenState.mayContain,
            ))
        .toList();

    // If a debounced/in-flight lookup hasn't resolved yet, do one final
    // direct fetch rather than saving with stale or missing nutrition.
    if (_nutrition == null || _fetchingNutrition) {
      _nutritionDebounce?.cancel();
      final result = await ref.read(nutritionApiServiceProvider).analyze(
            mealName: _mealName.trim(),
            ingredients: ingredients,
          );
      _nutrition = result.nutrition;
      _nutritionFromApi = result.fromApi;
    }
    final nutrition = _nutrition!;

    setState(() => _loading = true);
    try {
      final meal = await ref.read(mealServiceProvider).createMeal(
            chefId: uid,
            restaurantName: restaurantName,
            name: _mealName.trim(),
            description: _description.trim().isEmpty ? null : _description.trim(),
            ingredients: ingredients,
            nutrition: nutrition,
            allergens: allergens,
            otherAllergenNote:
                _otherAllergen.trim().isEmpty ? null : _otherAllergen.trim(),
            autoPhotoUrl: _autoPhoto?.url,
          );
      // Confirm actual use of the photo, per Unsplash API guidelines —
      // best-effort, never blocks the save flow if it fails.
      if (_autoPhoto != null) {
        unawaited(UnsplashService.instance.trackDownload(_autoPhoto!));
      }
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('🍽️ ${meal.name} is on the menu!')));
        // Guaranteed navigation home regardless of how this screen was
        // reached — a plain Navigator.pop(context) can silently no-op if
        // there's nothing on this navigator to pop to, which looks
        // exactly like a stuck save even though it already succeeded.
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/chef');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mirrors the same fix as the farmer's "Plant" screen: block navigating
    // away while the save is actually in flight, so it can't look "stuck
    // with no message" when it was really just abandoned mid-save.
    return PopScope(
      canPop: !_loading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _loading) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Still saving your meal — one moment…')));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Build Meal'),
          leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _loading ? null : () => Navigator.pop(context)),
        ),
        body: Stack(children: [
          Column(
            children: [
              _StepHeader(step: _step, steps: _steps),
              Expanded(
                child: IndexedStack(
                  index: _step,
                  children: [
                    _DetailsStep(
                      mealName: _mealName,
                      description: _description,
                      autoPhoto: _autoPhoto,
                      photoLoading: _photoLoading,
                      onNameChanged: _onMealNameChanged,
                      onDescriptionChanged: (v) =>
                          setState(() => _description = v),
                      onRerollPhoto: _mealName.trim().isEmpty
                          ? null
                          : () {
                              _lastQueriedMealName = ''; // force a re-fetch
                              _fetchMealPhoto(_mealName.trim());
                            },
                    ),
                    _IngredientsStep(
                      selected: _selectedIngredients,
                      nutrition: _nutrition,
                      fetching: _fetchingNutrition,
                      fromApi: _nutritionFromApi,
                      onAdd: (crop, qty) {
                        setState(() => _selectedIngredients[crop] = qty);
                        _scheduleNutritionRefresh();
                      },
                      onRemove: (crop) {
                        setState(() => _selectedIngredients.remove(crop));
                        _scheduleNutritionRefresh();
                      },
                    ),
                    _AllergensStep(
                      allergens: _allergens,
                      other: _otherAllergen,
                      onAllergenChanged: (type, state) =>
                          setState(() => _allergens[type] = state),
                      onOtherChanged: (v) => setState(() => _otherAllergen = v),
                    ),
                    _ReviewStep(
                      mealName: _mealName,
                      description: _description,
                      autoPhoto: _autoPhoto,
                      ingredients: _selectedIngredients,
                      nutrition: _nutrition,
                      nutritionFromApi: _nutritionFromApi,
                      allergens: _allergens,
                      other: _otherAllergen,
                    ),
                  ],
                ),
              ),
              _NavBar(
                step: _step,
                total: _steps.length,
                loading: _loading,
                onBack: () => setState(() => _step--),
                onNext: () {
                  if (_step == _steps.length - 1) {
                    _save();
                  } else {
                    setState(() => _step++);
                  }
                },
              ),
            ],
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: AppColors.cardOf(context),
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const CircularProgressIndicator(color: AppColors.chefAccent),
                      const SizedBox(height: 14),
                      Text('Saving your meal…', style: AppTextStyles.body(14)),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

enum _AllergenState { none, contains, mayContain }

// ── Step header ───────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final int step;
  final List<String> steps;
  const _StepHeader({required this.step, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardOf(context),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final active = e.key == step;
          final done = e.key < step;
          return Expanded(
            child: Row(children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: done
                    ? AppColors.chefAccent
                    : active
                        ? AppColors.forest
                        : AppColors.borderOf(context),
                child: done
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : Text('${e.key + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(e.value,
                    style: AppTextStyles.label.copyWith(
                        color: active
                            ? AppColors.forest
                            : AppColors.textSecondaryOf(context)),
                    overflow: TextOverflow.ellipsis),
              ),
              if (e.key < steps.length - 1)
                Expanded(
                    child: Container(height: 1, color: AppColors.borderOf(context))),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int step, total;
  final bool loading;
  final VoidCallback onBack, onNext;
  const _NavBar(
      {required this.step,
      required this.total,
      required this.onBack,
      required this.onNext,
      this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardOf(context),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(children: [
        if (step > 0) ...[
          Expanded(child: OutlinedButton(
              onPressed: loading ? null : onBack, child: const Text('Back'))),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.chefAccent),
            onPressed: loading ? null : onNext,
            child: Text(step == total - 1 ? 'Save Meal' : 'Next'),
          ),
        ),
      ]),
    );
  }
}

// ── Details ───────────────────────────────────────────────────────────────────

class _DetailsStep extends StatelessWidget {
  final String mealName;
  final String description;
  final UnsplashPhoto? autoPhoto;
  final bool photoLoading;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback? onRerollPhoto;
  const _DetailsStep({
    required this.mealName,
    required this.description,
    required this.autoPhoto,
    required this.photoLoading,
    required this.onNameChanged,
    required this.onDescriptionChanged,
    required this.onRerollPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
      Text('Meal Details', style: AppTextStyles.h2),
      const SizedBox(height: AppSpacing.md),
      // Dish photo — auto-fetched from Unsplash as soon as a meal name is
      // typed, same pattern as the farmer's crop batch photo. No manual
      // upload needed.
      Container(
        height: 160,
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: photoLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.chefAccent, strokeWidth: 2.4))
            : autoPhoto == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_search_outlined,
                          size: 34, color: AppColors.chefAccent),
                      const SizedBox(height: 8),
                      Text(
                          mealName.trim().isEmpty
                              ? 'Type a meal name to auto-fetch a photo'
                              : "Couldn't find a match — try a simpler name",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.sans(13,
                              weight: FontWeight.w600,
                              color: AppColors.textPrimaryOf(context))),
                      Text('Photos are pulled automatically from Unsplash',
                          style: AppTextStyles.sans(11,
                              color: AppColors.textSecondaryOf(context))),
                    ],
                  )
                : Stack(fit: StackFit.expand, children: [
                    Image.network(autoPhoto!.thumbUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.chefAccent)),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                            'Photo: ${autoPhoto!.photographerName} / Unsplash',
                            style:
                                AppTextStyles.sans(10.5, color: Colors.white)),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: FloatingActionButton.small(
                        heroTag: 'reroll_meal_photo',
                        backgroundColor: AppColors.cardOf(context),
                        tooltip: 'Try another photo',
                        onPressed: onRerollPhoto,
                        child: Icon(Icons.refresh,
                            color: AppColors.textPrimaryOf(context)),
                      ),
                    ),
                  ]),
      ),
      const SizedBox(height: AppSpacing.md),
      TextFormField(
        initialValue: mealName,
        decoration: const InputDecoration(labelText: 'Meal Name'),
        onChanged: onNameChanged,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        initialValue: description,
        maxLines: 2,
        decoration: const InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'Short description visible to diners'),
        onChanged: onDescriptionChanged,
      ),
    ]);
  }
}

// ── Ingredients ───────────────────────────────────────────────────────────────

class _IngredientsStep extends StatefulWidget {
  final Map<String, double> selected;
  final MealNutritionSnapshot? nutrition;
  final bool fetching;
  final bool fromApi;
  final void Function(String crop, double qty) onAdd;
  final void Function(String crop) onRemove;

  const _IngredientsStep({
    required this.selected,
    required this.nutrition,
    required this.fetching,
    required this.fromApi,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_IngredientsStep> createState() => _IngredientsStepState();
}

class _IngredientsStepState extends State<_IngredientsStep> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = MockData.nutritionReference.keys.toList();
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all.where((c) => c.toLowerCase().contains(q)).toList();

    // Typing something that isn't in the known list at all? Offer to add
    // it as a free-text ingredient anyway — USDA's live lookup (see
    // NutritionApiService) can look up basically any food name, so the
    // chef isn't actually limited to these 9 crops, just guided by them.
    final exactMatch = all.any((c) => c.toLowerCase() == q);
    final showCustomOption = q.isNotEmpty && !exactMatch;
    final customLabel =
        q.isEmpty ? '' : q[0].toUpperCase() + q.substring(1);

    return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
      Text('Select Ingredients', style: AppTextStyles.h2),
      Text('From verified batches in your kitchen — or type any ingredient',
          style: AppTextStyles.bodyMuted),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search or type a crop name...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    _searchCtrl.clear();
                    _query = '';
                  }),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: AppColors.borderOf(context)),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      if (showCustomOption)
        ListTile(
          tileColor: AppColors.chefAccent.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              side: BorderSide(color: AppColors.chefAccent.withValues(alpha: 0.4))),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          leading: const Icon(Icons.add_circle_outline, color: AppColors.chefAccent),
          title: Text('Add "$customLabel"', style: AppTextStyles.body(14, weight: FontWeight.w600)),
          subtitle: const Text('Not in your batches — nutrition will be looked up live'),
          onTap: () {
            widget.onAdd(customLabel, 80);
            _searchCtrl.clear();
            setState(() => _query = '');
          },
        ),
      if (showCustomOption) const SizedBox(height: AppSpacing.sm),
      if (filtered.isEmpty && !showCustomOption)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('No matches — start typing to add a new ingredient',
              style: AppTextStyles.bodyMuted)),
        ),
      ...filtered.map((crop) {
        final qty = widget.selected[crop];
        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              side: BorderSide(
                  color: qty != null ? AppColors.chefAccent : AppColors.borderOf(context))),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 4),
          leading:
              Icon(Icons.eco, color: qty != null ? AppColors.chefAccent : AppColors.textSecondaryOf(context)),
          title: Text(crop, style: AppTextStyles.body(14)),
          subtitle: qty != null ? Text('${qty.toStringAsFixed(0)} g') : null,
          trailing: qty != null
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () => widget.onRemove(crop)),
                  const SizedBox(width: 4),
                  IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () => widget.onAdd(crop, qty + 25)),
                ])
              : TextButton(
                  child: const Text('Add'),
                  onPressed: () => widget.onAdd(crop, 80)),
        );
      }),
      if (widget.fetching) ...[
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
              color: AppColors.chefAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Row(children: [
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: AppSpacing.sm),
            Text('Looking up nutrition…', style: AppTextStyles.bodyMuted),
          ]),
        ),
      ] else if (widget.nutrition != null) ...[
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
              color: AppColors.chefAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Nutrition', style: AppTextStyles.label),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (widget.fromApi ? AppColors.leaf : Colors.grey)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.fromApi ? 'Sourced from USDA' : 'Estimated (offline)',
                  style: AppTextStyles.sans(10,
                      color: widget.fromApi ? AppColors.leaf : Colors.grey[700],
                      weight: FontWeight.w700),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              '${widget.nutrition!.calories.toStringAsFixed(0)} kcal · '
              '${widget.nutrition!.proteinG.toStringAsFixed(1)}g protein · '
              '${widget.nutrition!.carbsG.toStringAsFixed(1)}g carbs · '
              '${widget.nutrition!.fatG.toStringAsFixed(1)}g fat · '
              '${widget.nutrition!.fiberG.toStringAsFixed(1)}g fiber',
              style: AppTextStyles.body(14),
            ),
          ]),
        ),
      ],
    ]);
  }
}

// ── Allergens ─────────────────────────────────────────────────────────────────

class _AllergensStep extends StatelessWidget {
  final Map<AllergenType, _AllergenState> allergens;
  final String other;
  final void Function(AllergenType, _AllergenState) onAllergenChanged;
  final ValueChanged<String> onOtherChanged;

  const _AllergensStep({
    required this.allergens,
    required this.other,
    required this.onAllergenChanged,
    required this.onOtherChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = AllergenType.values.where((a) => a != AllergenType.none).toList();

    return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
      Text('Confirm Allergens', style: AppTextStyles.h2),
      Text('Select status for each of the 14 standard allergens',
          style: AppTextStyles.bodyMuted),
      const SizedBox(height: AppSpacing.sm),
      // None checkbox
      CheckboxListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
        value: allergens[AllergenType.none] == _AllergenState.contains,
        title: const Text('None'),
        onChanged: (v) => onAllergenChanged(
            AllergenType.none,
            v! ? _AllergenState.contains : _AllergenState.none),
      ),
      const Divider(),
      ...types.map((a) => _AllergenRow(
            label: a.label,
            state: allergens[a]!,
            onChanged: (s) => onAllergenChanged(a, s),
          )),
      const SizedBox(height: AppSpacing.md),
      Text('Other allergens (optional)', style: AppTextStyles.label),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: other,
        onChanged: onOtherChanged,
        decoration: const InputDecoration(
            hintText: 'e.g. Pine nuts, Kiwi...'),
      ),
    ]);
  }
}

class _AllergenRow extends StatelessWidget {
  final String label;
  final _AllergenState state;
  final ValueChanged<_AllergenState> onChanged;
  const _AllergenRow(
      {required this.label, required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: state != _AllergenState.none
              ? AppColors.error.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.body(14))),
            _StateChip(
              label: 'Contains',
              active: state == _AllergenState.contains,
              color: AppColors.error,
              onTap: () => onChanged(state == _AllergenState.contains
                  ? _AllergenState.none
                  : _AllergenState.contains),
            ),
            const SizedBox(width: 6),
            _StateChip(
              label: 'May contain',
              active: state == _AllergenState.mayContain,
              color: AppColors.amber,
              onTap: () => onChanged(state == _AllergenState.mayContain
                  ? _AllergenState.none
                  : _AllergenState.mayContain),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _StateChip(
      {required this.label,
      required this.active,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : AppColors.borderOf(context)),
        ),
        child: Text(label,
            style: AppTextStyles.label.copyWith(
                color: active ? color : AppColors.textSecondaryOf(context))),
      ),
    );
  }
}

// ── Review ────────────────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  final String mealName;
  final String description;
  final UnsplashPhoto? autoPhoto;
  final Map<String, double> ingredients;
  final MealNutritionSnapshot? nutrition;
  final bool nutritionFromApi;
  final Map<AllergenType, _AllergenState> allergens;
  final String other;

  const _ReviewStep({
    required this.mealName,
    required this.description,
    required this.autoPhoto,
    required this.ingredients,
    required this.nutrition,
    required this.nutritionFromApi,
    required this.allergens,
    required this.other,
  });

  @override
  Widget build(BuildContext context) {
    final confirmed = allergens.entries
        .where((e) => e.value == _AllergenState.contains)
        .map((e) => e.key.label)
        .toList();
    final mayContain = allergens.entries
        .where((e) => e.value == _AllergenState.mayContain)
        .map((e) => e.key.label)
        .toList();

    return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
      Text('Review Meal', style: AppTextStyles.h2),
      const SizedBox(height: AppSpacing.sm),
      if (autoPhoto != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(autoPhoto!.thumbUrl, height: 140,
              width: double.infinity, fit: BoxFit.cover),
        ),
      const SizedBox(height: AppSpacing.sm),
      Text(mealName.isEmpty ? '(Unnamed)' : mealName, style: AppTextStyles.h1),
      if (description.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description, style: AppTextStyles.bodyMuted),
        ),
      const SizedBox(height: AppSpacing.md),
      Text('INGREDIENTS', style: AppTextStyles.label),
      ...ingredients.entries.map((e) => Text(
          '• ${e.key} — ${e.value.toStringAsFixed(0)} g',
          style: AppTextStyles.body(14))),
      if (nutrition != null) ...[
        const SizedBox(height: AppSpacing.md),
        Text('NUTRITION', style: AppTextStyles.label),
        Text(
            '${nutrition!.calories.toStringAsFixed(0)} kcal · '
            '${nutrition!.proteinG.toStringAsFixed(1)}g protein',
            style: AppTextStyles.body(14)),
        Text(
            nutritionFromApi
                ? 'Sourced from USDA'
                : 'Estimated — offline/no API key configured',
            style: AppTextStyles.sans(11,
                color: nutritionFromApi ? AppColors.leaf : Colors.grey[600])),
      ],
      const SizedBox(height: AppSpacing.md),
      Text('ALLERGENS', style: AppTextStyles.label),
      if (confirmed.isNotEmpty)
        Text('Contains: ${confirmed.join(", ")}',
            style: AppTextStyles.body(14).copyWith(color: AppColors.error)),
      if (mayContain.isNotEmpty)
        Text('May contain: ${mayContain.join(", ")}',
            style: AppTextStyles.body(14).copyWith(color: AppColors.amber)),
      if (other.isNotEmpty)
        Text('Other: $other', style: AppTextStyles.bodyMuted),
      if (confirmed.isEmpty && mayContain.isEmpty)
        Text('No allergens declared', style: AppTextStyles.bodyMuted),
    ]);
  }
}
