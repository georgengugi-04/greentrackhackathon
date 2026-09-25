import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/unsplash_service.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/branded_loading_indicator.dart';

class NewBatchScreen extends ConsumerStatefulWidget {
  const NewBatchScreen({super.key});
  @override
  ConsumerState<NewBatchScreen> createState() => _NewBatchScreenState();
}

class _NewBatchScreenState extends ConsumerState<NewBatchScreen> {
  final _nameCtrl = TextEditingController();
  final _varietyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  FarmingMethod _method = FarmingMethod.conventional;
  DateTime _plantDate = DateTime.now();
  DateTime _harvestDate = DateTime.now().add(const Duration(days: 60));
  double _estYield = 10;
  int _quantity = 100;
  bool _loading = false;

  // Safety floor, not a real agronomic figure for any specific crop — just
  // enough to make "planted today, harvested today" (or tomorrow)
  // impossible to enter. Even the fastest microgreens take a couple of
  // weeks; this exists to catch fat-finger/rushed-form-fill mistakes, not
  // to model actual crop growth durations.
  static const _minGrowingDays = 14;

  void _onPlantDateChanged(DateTime newPlantDate) {
    setState(() {
      _plantDate = newPlantDate;
      // Keep the harvest date valid relative to the new plant date instead
      // of silently leaving an impossible combination (e.g. plant date
      // moved forward past the existing harvest date) for the farmer to
      // discover only when they try to submit.
      final earliestHarvest = _plantDate.add(const Duration(days: _minGrowingDays));
      if (_harvestDate.isBefore(earliestHarvest)) {
        _harvestDate = earliestHarvest;
      }
    });
  }
  double _lat = 0, _lng = 0;

  // Auto-fetched crop photo — no manual picker. Debounced on crop-name
  // changes so we're not firing an Unsplash request per keystroke.
  UnsplashPhoto? _autoPhoto;
  bool _photoLoading = false;
  Timer? _photoDebounce;
  String _lastQueried = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onCropNameChanged);
  }

  @override
  void dispose() {
    _photoDebounce?.cancel();
    _nameCtrl.removeListener(_onCropNameChanged);
    super.dispose();
  }

  void _onCropNameChanged() {
    _photoDebounce?.cancel();
    final query = _nameCtrl.text.trim();
    if (query.isEmpty || query == _lastQueried) return;
    _photoDebounce = Timer(const Duration(milliseconds: 700), () => _fetchPhoto(query));
  }

  Future<void> _fetchPhoto(String query) async {
    if (!mounted) return;
    setState(() => _photoLoading = true);
    final photo = await UnsplashService.instance.photoFor(query);
    _lastQueried = query;
    if (!mounted) return;
    setState(() {
      _autoPhoto = photo;
      _photoLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.farmerSurfaceOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('New Crop Batch', style: AppTextStyles.poppins(20, weight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => context.pop()),
        actions: [
          TextButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.leaf))
                  : Text('Plant',
                      style: AppTextStyles.sans(15,
                          color: AppColors.leaf, weight: FontWeight.w700))),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(children: [
        ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Crop photo — auto-fetched from Unsplash as soon as a crop name
          // is typed, no manual upload needed.
          Container(
            height: 160,
            width: double.infinity,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.cardOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: _photoLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.leaf, strokeWidth: 2.4))
                : _autoPhoto == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_search_outlined,
                              size: 34, color: AppColors.leaf),
                          const SizedBox(height: 8),
                          Text(
                              _nameCtrl.text.trim().isEmpty
                                  ? 'Type a crop name to auto-fetch a photo'
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
                        Image.network(_autoPhoto!.thumbUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported_outlined, color: AppColors.leaf)),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('Photo: ${_autoPhoto!.photographerName} / Unsplash',
                                style: AppTextStyles.sans(10.5, color: Colors.white)),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: FloatingActionButton.small(
                            heroTag: 'reroll_batch_photo',
                            backgroundColor: AppColors.cardOf(context),
                            tooltip: 'Try another photo',
                            onPressed: _nameCtrl.text.trim().isEmpty
                                ? null
                                : () {
                                    _lastQueried = ''; // force a re-fetch of the same query
                                    _fetchPhoto(_nameCtrl.text.trim());
                                  },
                            child: Icon(Icons.refresh, color: AppColors.textPrimaryOf(context)),
                          ),
                        ),
                      ]),
          ),
          const SizedBox(height: 20),

          // GPS location banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.leaf.withValues(alpha: 0.3))),
            child: Row(children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.leaf, size: 22),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('GPS Location',
                        style: AppTextStyles.sans(13,
                            weight: FontWeight.w600, color: AppColors.canopy)),
                    Text(
                        _lat == 0
                            ? 'Tap to pin your plot location'
                            : '${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}',
                        style: AppTextStyles.sans(12, color: AppColors.slate)),
                  ])),
              TextButton(onPressed: _getLocation, child: const Text('Pin')),
            ]),
          ),
          const SizedBox(height: 20),

          _label('Plot Location Name *'),
          const SizedBox(height: 6),
          TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                  hintText: 'e.g. North Field, Greenhouse B',
                  prefixIcon: Icon(Icons.terrain_outlined, size: 20))),
          const SizedBox(height: 16),

          _label('Crop Name *'),
          const SizedBox(height: 6),
          TextField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(hintText: 'e.g. Spinach, Tomatoes')),
          const SizedBox(height: 16),

          _label('Variety'),
          const SizedBox(height: 6),
          TextField(
              controller: _varietyCtrl,
              decoration:
                  const InputDecoration(hintText: 'e.g. Baby Spinach, Cherry')),
          const SizedBox(height: 16),

          _label('Farming Method *'),
          const SizedBox(height: 6),
          DropdownButtonFormField<FarmingMethod>(
              initialValue: _method,
              decoration: const InputDecoration(),
              items: FarmingMethod.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                  .toList(),
              onChanged: (v) => setState(() => _method = v!)),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _label('Date Planted'),
                  const SizedBox(height: 6),
                  _DatePicker(
                      date: _plantDate,
                      // Can't be in the future — this field records a
                      // planting that has already happened, not a plan.
                      firstDate: DateTime.now().subtract(const Duration(days: 730)),
                      lastDate: DateTime.now(),
                      onChanged: _onPlantDateChanged),
                ])),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _label('Expected Harvest'),
                  const SizedBox(height: 6),
                  _DatePicker(
                      date: _harvestDate,
                      // Can never be on/before the planting date — the
                      // picker itself won't offer those days, rather than
                      // letting the farmer pick an impossible date and
                      // catching it only at submit time.
                      firstDate: _plantDate.add(const Duration(days: _minGrowingDays)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onChanged: (d) => setState(() => _harvestDate = d)),
                ])),
          ]),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _label('Est. Yield (kg)'),
                  Slider(
                      value: _estYield,
                      min: 1,
                      max: 500,
                      divisions: 499,
                      label: '${_estYield.round()}kg',
                      activeColor: AppColors.leaf,
                      onChanged: (v) => setState(() => _estYield = v)),
                  Center(
                      child: Text('${_estYield.round()} kg',
                          style: AppTextStyles.mono(14))),
                ])),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _label('Plants / Units'),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null),
                    Text('$_quantity', style: AppTextStyles.mono(20)),
                    IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _quantity++)),
                  ]),
                ])),
          ]),
          const SizedBox(height: 16),

          _label('Notes'),
          const SizedBox(height: 6),
          TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Seed source, soil conditions, observations...')),
          const SizedBox(height: 32),
        ],
        ),
        if (_loading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cardOf(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const BrandedLoadingIndicator(
                      message: 'Planting your crop…',
                      asset: 'assets/lottie/produce_loading.json'),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _label(String t) =>
      Text(t, style: Theme.of(context).textTheme.labelMedium);

  Future<void> _getLocation() async {
    // Mock GPS for demo — in production use geolocator package
    setState(() {
      _lat = -1.2921;
      _lng = 36.8219;
    });
    if (mounted) {
      _locationCtrl.text.isEmpty
          ? _locationCtrl.text = 'Nairobi County Plot'
          : null;
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill in crop name and plot location.')));
      return;
    }
    // Backstop, not the primary defense — the date pickers themselves
    // already refuse to offer an invalid harvest date, but this catches
    // it regardless of how the values got set.
    if (!_harvestDate.isAfter(_plantDate.add(const Duration(days: _minGrowingDays - 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Expected harvest must be at least $_minGrowingDays days '
              'after the planting date.')));
      return;
    }
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You need to be signed in with a real account to add a batch — '
              'the "Quick access" dev buttons don\'t create one.')));
      return;
    }

    setState(() => _loading = true);
    try {
      // Keep the branded loading animation on screen for a minimum stretch
      // so it reads as an intentional moment rather than a flicker on fast
      // connections — but never adds delay beyond however long the actual
      // save takes.
      final saveFuture = ref.read(batchServiceProvider).createBatch(
            farmerId: uid,
            cropName: _nameCtrl.text.trim(),
            variety: _varietyCtrl.text.trim().isEmpty
                ? 'Standard'
                : _varietyCtrl.text.trim(),
            plotLocation: _locationCtrl.text.trim(),
            latitude: _lat,
            longitude: _lng,
            farmingMethod: _method,
            plantedDate: _plantDate,
            expectedHarvestDate: _harvestDate,
            estimatedYieldKg: _estYield.roundToDouble(),
            quantityPlanted: _quantity,
            notes:
                _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            photoUrl: _autoPhoto?.url,
          );
      final minDelay = Future.delayed(const Duration(milliseconds: 1100));
      final batch = await saveFuture;
      await minDelay;
      // Confirm actual use of the photo, per Unsplash API guidelines —
      // best-effort, never blocks the save flow if it fails.
      if (_autoPhoto != null) {
        unawaited(UnsplashService.instance.trackDownload(_autoPhoto!));
      }
      if (!mounted) return;
      setState(() => _loading = false);

      // A dialog the farmer must acknowledge is far more reliable than a
      // SnackBar fired right before popping the screen — a SnackBar tied
      // to a Scaffold that's mid-navigation can silently never appear,
      // which is exactly what "stuck with no message" looked like before.
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.leaf, size: 40),
          title: const Text('Planted!'),
          content: Text('${batch.cropName} was added to your farm. QR code will be '
              'ready once it\'s harvested.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      // Guaranteed navigation home regardless of how this screen was
      // reached — pop() can silently no-op if there's nothing to pop to.
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/farmer');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime date;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;
  const _DatePicker({
    required this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          // initialDate must fall within [firstDate, lastDate] or
          // showDatePicker throws — clamp rather than assume the current
          // value is still valid (it won't be, right after the plant date
          // moves forward past the old harvest date, for example).
          final clampedInitial = date.isBefore(firstDate)
              ? firstDate
              : date.isAfter(lastDate)
                  ? lastDate
                  : date;
          final d = await showDatePicker(
              context: context,
              initialDate: clampedInitial,
              firstDate: firstDate,
              lastDate: lastDate);
          if (d != null) onChanged(d);
        },
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
                color: AppColors.cardOf(context),
                border: Border.all(color: AppColors.borderOf(context)),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppColors.slateLight),
              const SizedBox(width: 8),
              Text('${date.day}/${date.month}/${date.year}',
                  style: AppTextStyles.sans(13)),
            ])),
      );
}
