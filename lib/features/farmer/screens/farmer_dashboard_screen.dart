import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_vision_service.dart';
import '../../../core/services/soil_moisture_service.dart';
import '../../../core/services/irrigation_advisor.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/animated_emoji.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../shared/widgets/premium_widgets.dart';
import '../../shared/widgets/modern_components.dart';
import '../../shared/widgets/looping_background_video.dart';
import '../../shared/widgets/farmer_growing_illustration.dart';

// Crop image lookup — Unsplash free CDN, no API key needed
const _cropImages = {
  'Cherry Tomatoes': 'https://images.unsplash.com/photo-1546470427-f5dcc18e4b0d?w=600&q=80',
  'Tomatoes':        'https://images.unsplash.com/photo-1546470427-f5dcc18e4b0d?w=600&q=80',
  'Carrots':         'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=600&q=80',
  'Basil':           'https://images.unsplash.com/photo-1618375569909-3c8616cf7733?w=600&q=80',
  'Lettuce':         'https://images.unsplash.com/photo-1622205313162-be1d5712a43f?w=600&q=80',
  'Avocado':         'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=600&q=80',
  'Bell Pepper':     'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=600&q=80',
  'Cucumber':        'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?w=600&q=80',
  'Eggplant':        'https://images.unsplash.com/photo-1617692855027-33b14f061079?w=600&q=80',
  'Kale':            'https://images.unsplash.com/photo-1524179091875-bf99a9a6af57?w=600&q=80',
};

const _defaultCropImage =
    'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=600&q=80';


/// Real batches only — no demo/placeholder fallback. A brand-new account
/// (or the dev quick-access buttons, which don't create a real Firebase
/// user) genuinely shows an empty state until the farmer adds their own
/// first batch. See `_EmptyCropsState` for what renders instead.
/// Finds the farmer's real most-recently-harvested batch and its actual
/// pest-diagnosis history, then hands that real data to the crop-rotation
/// advisor — this used to always claim the last crop was "Tomatoes" and
/// perfectly healthy no matter what was actually grown, which made the
/// recommendation meaningless.
void _planNextCrop(BuildContext context, WidgetRef ref) {
  final allBatches = ref.read(farmerBatchesProvider).value ?? const <CropBatch>[];
  final harvested = allBatches.where((b) => b.stage == CropStage.harvested).toList()
    ..sort((a, b) => (b.harvestedAt ?? DateTime(0)).compareTo(a.harvestedAt ?? DateTime(0)));

  if (harvested.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Harvest a batch first — rotation planning needs to know '
            'what was actually grown here.')));
    return;
  }

  final lastBatch = harvested.first;

  // Use the most recent real pest diagnosis logged against this batch, if
  // any, instead of always assuming it was healthy.
  final diagnoses = [...lastBatch.pestDiagnoses]
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  final lastDiagnosis = diagnoses.isEmpty ? null : diagnoses.first;

  final diagnosis = lastDiagnosis == null
      ? const VisionDiagnosisResult(
          isHealthy: true,
          label: 'Healthy',
          confidence: 1,
          severity: PestSeverity.low,
          summary: 'No pest issues were logged on this batch.',
        )
      : VisionDiagnosisResult(
          isHealthy: false,
          label: lastDiagnosis.detectedPest,
          confidence: 1,
          severity: lastDiagnosis.severity,
          phiDays: lastDiagnosis.phiDays,
          summary: 'Detected during a pest scan on this batch.',
        );

  final phiClearDate = lastDiagnosis?.treatedAt != null
      ? lastDiagnosis!.treatedAt!.add(Duration(days: lastDiagnosis.phiDays))
      : null;

  context.push('/farmer/plan-crop', extra: {
    'previousCropName': lastBatch.cropName,
    'diagnosis': diagnosis,
    'phiClearDate': phiClearDate,
  });
}

List<_Crop> _visibleCrops(WidgetRef ref) {
  final batches = ref.watch(farmerBatchesProvider).value ?? const [];
  return batches.map(_Crop.fromBatch).toList();
}

class FarmerDashboardScreen extends ConsumerStatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  ConsumerState<FarmerDashboardScreen> createState() =>
      _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState
    extends ConsumerState<FarmerDashboardScreen> {
  int _navIndex = 0;
  bool _showQuickActions = false;
  String _chartPeriod = 'Month';

  /// Public on purpose — lets sibling widgets (e.g. the header's avatar
  /// tap) switch tabs without reaching in and calling setState directly,
  /// which Dart disallows on another class's @protected member.
  void goToProfileTab() => setState(() => _navIndex = 4);

  final _bars = const [
    _Bar('Jan', 0.3, 0.2), _Bar('Feb', 0.5, 0.4), _Bar('Mar', 0.4, 0.6),
    _Bar('Apr', 0.9, 0.5), _Bar('May', 0.7, 0.8), _Bar('Jun', 0.6, 0.7),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    final name = user?.name ?? 'Farmer';

    return Scaffold(
      backgroundColor: AppColors.farmerSurfaceOf(context),
      body: Stack(children: [
        IndexedStack(index: _navIndex, children: [
          _HomeTab(name: name, bars: _bars, period: _chartPeriod,
              onPeriod: (p) => setState(() => _chartPeriod = p),
              onViewAllCrops: () => setState(() => _navIndex = 1)),
          const _CropsTab(),
          const _DocumentsTab(),
          const _HarvestTab(),
          _ProfileTab(name: name),
        ]),
        if (_showQuickActions)
          _QuickActionsOverlay(
              onClose: () => setState(() => _showQuickActions = false)),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.forest,
        elevation: 6,
        onPressed: () =>
            setState(() => _showQuickActions = !_showQuickActions),
        child: AnimatedRotation(
          turns: _showQuickActions ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        index: _navIndex,
        onTap: (i) => setState(() {
          _navIndex = i;
          _showQuickActions = false;
        }),
      ),
    );
  }
}

// ── DOCUMENTS TAB ────────────────────────────────────────────────────────────

class _DocumentsTab extends ConsumerStatefulWidget {
  const _DocumentsTab();
  @override
  ConsumerState<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<_DocumentsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  FarmDocumentType? _filter; // null = All

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(farmerDocumentsProvider);

    return SafeArea(child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Documents', style: AppTextStyles.poppins(26, weight: FontWeight.w800,
                  color: AppColors.textPrimaryOf(context)))
                  .animate()
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .slideX(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 2),
              Text('Certificates, receipts, and records — all in one place',
                  style: AppTextStyles.poppins(12.5, color: AppColors.textSecondaryOf(context)))
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms),
            ]),
          ),
          ModernButton.icon(
            icon: Icons.add_rounded,
            onPressed: () => context.push('/farmer/documents/new?type=other'),
            color: AppColors.forest,
            height: 40,
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(color: AppColors.cardOf(context),
              borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.subtle),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search documents...',
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondaryOf(context)),
              suffixIcon: _query.isEmpty ? null : IconButton(
                  icon: Icon(Icons.close, size: 18, color: AppColors.textSecondaryOf(context)),
                  onPressed: () => setState(() { _searchCtrl.clear(); _query = ''; })),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _CategoryChip(label: 'All', selected: _filter == null,
                onTap: () => setState(() => _filter = null)),
            ...FarmDocumentType.values.map((t) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _CategoryChip(label: '${t.emoji} ${t.label}', selected: _filter == t,
                    onTap: () => setState(() => _filter = t)))),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: docsAsync.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(20), child: ShimmerList(count: 4)),
          error: (e, _) => Center(child: ErrorStateView(message: '$e')),
          data: (docs) {
            final filtered = docs.where((d) {
              final matchesType = _filter == null || d.type == _filter;
              final matchesQuery = _query.trim().isEmpty ||
                  d.itemName.toLowerCase().contains(_query.trim().toLowerCase());
              return matchesType && matchesQuery;
            }).toList();

            if (filtered.isEmpty) {
              return Center(
                child: EmptyStateView(
                  icon: Icons.folder_open_outlined,
                  title: docs.isEmpty ? 'No documents yet' : 'No matches',
                  message: docs.isEmpty
                      ? 'Certificates, receipts, and farm records you log will show up here.'
                      : 'Try a different search or category.',
                  actionLabel: docs.isEmpty ? 'Add a document' : null,
                  onAction: docs.isEmpty
                      ? () => context.push('/farmer/documents/new?type=other')
                      : null,
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _DocumentCard(document: filtered[i]),
            );
          },
        ),
      ),
    ]));
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [AppColors.forest, AppColors.leaf],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: selected ? null : AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : AppColors.borderOf(context)),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.forest.withValues(alpha: 0.28),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondaryOf(context))),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final FarmDocument document;
  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      radius: 20,
      child: Row(children: [
        if (document.photoUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: document.photoUrl!, width: 52, height: 52, fit: BoxFit.cover,
              placeholder: (_, __) => Container(width: 52, height: 52,
                  color: AppColors.forest.withValues(alpha: 0.08)),
              errorWidget: (_, __, ___) => Container(width: 52, height: 52,
                  color: AppColors.forest.withValues(alpha: 0.08),
                  child: Text(document.type.emoji, style: const TextStyle(fontSize: 22))),
            ),
          )
        else
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
                color: AppColors.forest.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(document.type.emoji, style: const TextStyle(fontSize: 24)),
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(document.itemName, style: AppTextStyles.body(14.5, weight: FontWeight.w700,
                color: AppColors.textPrimaryOf(context))),
            const SizedBox(height: 2),
            Text('${document.type.label} · ${_formatDate(document.createdAt)}',
                style: AppTextStyles.bodyMuted.copyWith(fontSize: 12)),
            if (document.notes != null && document.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(document.notes!, style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.leaf.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.cloud_done_outlined, size: 12, color: AppColors.leaf),
            SizedBox(width: 4),
            Text('Synced', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.leaf)),
          ]),
        ),
      ]),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}



/// Builds the four KPI cards from real batch data — no hardcoded demo
/// numbers. Everything reads zero/empty honestly until the farmer has
/// actually logged batches.
List<Widget> _kpiCards(List<_Crop> crops) {
  final nearHarvest = crops.where((c) =>
      c.stage == 'Ready to Harvest' ||
      (c.daysLabel.endsWith('d') &&
          (int.tryParse(c.daysLabel.replaceAll('d', '')) ?? 999) <= 5)).toList();
  final needAttention = crops.where((c) => c.stage == 'Needs Attention').toList();
  final totalYieldKg = crops.fold<double>(0, (sum, c) {
    final n = double.tryParse(c.yieldLabel.replaceAll(RegExp('[^0-9.]'), ''));
    return sum + (n ?? 0);
  });

  return [
    _KpiCard('🌱', crops.isEmpty ? '' : '${crops.length} total', crops.isNotEmpty,
        '${crops.length}', 'Active Crops', crops.isEmpty ? 'Add your first batch' : ''),
    _KpiCard('⚖️', '', true,
        '${totalYieldKg.toStringAsFixed(1)}kg', 'Season Yield',
        crops.isEmpty ? 'No harvests logged yet' : 'Estimated from active batches'),
    _KpiCard('🌾', nearHarvest.isEmpty ? '' : '${nearHarvest.length} soon', nearHarvest.isNotEmpty,
        '${nearHarvest.length}', 'Near Harvest',
        nearHarvest.isEmpty ? 'None yet' : 'Next: ${nearHarvest.first.name} in ${nearHarvest.first.daysLabel}'),
    _KpiCard('⚠️', needAttention.isEmpty ? 'all clear' : 'urgent', needAttention.isEmpty,
        '${needAttention.length}', 'Need Attention',
        needAttention.isEmpty ? 'Nothing flagged' : needAttention.map((c) => c.name).join(' · ')),
  ];
}

class _EmptyCropsBanner extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCropsBanner({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.leaf.withValues(alpha: 0.10),
            AppColors.mint.withValues(alpha: 0.14),
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.leaf.withValues(alpha: 0.18)),
      ),
      child: Column(children: [
        SizedBox(
          height: 90,
          child: const FarmerGrowingIllustration(size: 90)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -3, end: 3, duration: 2200.ms, curve: Curves.easeInOut),
        ),
        const SizedBox(height: 14),
        Text('Nothing planted yet',
            style: AppTextStyles.poppins(16.5, weight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context))),
        const SizedBox(height: 4),
        Text('Log your first batch and watch its whole journey unfold here.',
            style: AppTextStyles.poppins(12.5, color: AppColors.textSecondaryOf(context)),
            textAlign: TextAlign.center),
        const SizedBox(height: 18),
        _PressScale(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.forest, AppColors.leaf],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.leaf.withValues(alpha: 0.35),
                  blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onAdd,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text('New Crop Batch', style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PressScale extends StatefulWidget {
  final Widget child;
  const _PressScale({required this.child});
  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  final String name;
  final List<_Bar> bars;
  final String period;
  final ValueChanged<String> onPeriod;
  final VoidCallback onViewAllCrops;

  const _HomeTab(
      {required this.name,
      required this.bars,
      required this.period,
      required this.onPeriod,
      required this.onViewAllCrops});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crops = _visibleCrops(ref);
    return _HomeTabHeaderAndBody(
      name: name,
      bars: bars,
      period: period,
      onPeriod: onPeriod,
      onViewAllCrops: onViewAllCrops,
      crops: crops,
    );
  }
}

class _HomeTabHeaderAndBody extends ConsumerWidget {
  final String name;
  final List<_Bar> bars;
  final String period;
  final ValueChanged<String> onPeriod;
  final VoidCallback onViewAllCrops;
  final List<_Crop> crops;

  const _HomeTabHeaderAndBody({
    required this.name,
    required this.bars,
    required this.period,
    required this.onPeriod,
    required this.onViewAllCrops,
    required this.crops,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final allBatches = ref.watch(farmerBatchesProvider).value ?? const [];

    // Same real-data completion/level calc as the Profile tab, so the
    // header reads identically no matter which tab you're looking at it
    // from.
    final completionFields = [
      user?.name.isNotEmpty ?? false,
      user?.email.isNotEmpty ?? false,
      user?.photoUrl != null,
      user?.farmName != null,
      user?.organicCertificationUrl != null,
    ];
    final completion =
        completionFields.where((f) => f).length / completionFields.length;
    final levelLabel = allBatches.length >= 10
        ? 'Top Grower'
        : allBatches.length >= 3
            ? 'Grower'
            : 'New Grower';

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: PremiumProfileHeader(
          name: name,
          photoUrl: user?.photoUrl,
          subtitle: 'Growing sustainably every day 🌱',
          levelLabel: levelLabel,
          profileCompletion: completion,
          onSettingsTap: () => context.push('/settings'),
          onNotificationsTap: () => context.push('/notifications'),
        ),
      ),
      SliverToBoxAdapter(
          child: _WeatherCard().animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0)),
      SliverToBoxAdapter(
        child: Transform.translate(
          offset: const Offset(0, -22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _GreetingInsightRow(name: name),
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
      ),
      // Crop grid
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('My Crops', style: AppTextStyles.h2),
              const Spacer(),
              GestureDetector(
                onTap: onViewAllCrops,
                child: Text('View all', style: const TextStyle(color: AppColors.leaf,
                    fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ]).animate().fadeIn(delay: 80.ms, duration: 350.ms),
            const SizedBox(height: 12),
            crops.isEmpty
                ? _EmptyCropsBanner(onAdd: () => context.push('/farmer/batches/new'))
                    .animate().fadeIn(delay: 140.ms, duration: 400.ms)
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: crops.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => context.push('/farmer/batches/${crops[i].id}'),
                      child: _CropPhotoCard(crop: crops[i])
                          .animate()
                          .fadeIn(delay: (100 + i * 60).ms, duration: 350.ms)
                          .slideY(begin: 0.06, end: 0),
                    ),
                  ),
          ]),
        ),
      ),
      // KPI grid
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        sliver: SliverGrid(
          delegate: SliverChildListDelegate(
            _kpiCards(crops).asMap().entries.map((e) => e.value
                .animate()
                .fadeIn(delay: (180 + e.key * 60).ms, duration: 350.ms)
                .slideY(begin: 0.08, end: 0)).toList(),
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12,
              mainAxisSpacing: 12, childAspectRatio: 1.28),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _HarvestChart(bars: bars, period: period, onPeriod: onPeriod),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]);
  }
}

class _CropPhotoCard extends StatelessWidget {
  final _Crop crop;
  const _CropPhotoCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    final imgUrl = crop.photoUrl ?? _cropImages[crop.name] ?? _defaultCropImage;
    // Driven by the batch's REAL stage, not just whether the estimated
    // harvest date has passed — a freshly-planted batch can easily have
    // an estimate that's already elapsed (short growing crops, a planted
    // date logged late, etc.) without actually being ready. Showing
    // "Schedule Harvest" in that case sent farmers to a screen that
    // could never find the batch, since Log Harvest only lists batches
    // whose real stage is readyToHarvest.
    final ready = crop.stageEnum == CropStage.readyToHarvest;
    final overdueEstimate = !ready && crop.daysLabel == 'Ready!';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Photo, with the stage badge overlaid top-left
        AspectRatio(
          aspectRatio: 1.35,
          child: Stack(fit: StackFit.expand, children: [
            CachedNetworkImage(
              imageUrl: imgUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                  color: AppColors.mint.withValues(alpha: 0.3),
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))),
              errorWidget: (_, __, ___) => Container(
                  color: AppColors.mint.withValues(alpha: 0.3),
                  child: const Icon(Icons.eco, color: AppColors.leaf, size: 40)),
            ),
            Positioned(top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: crop.stageColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(crop.stage,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 9, fontWeight: FontWeight.w700)),
              )),
            if (crop.isFavorite)
              Positioned(top: 10, right: 10,
                child: Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(
                      color: Colors.black26, shape: BoxShape.circle),
                  child: const Center(
                      child: AnimatedEmoji('❤️', size: 12)),
                )),
          ]),
        ),
        // Info section — crop name, batch/plot line, then either an age
        // readout or a "Schedule Harvest" CTA once it's actually ready.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(crop.name,
                style: AppTextStyles.body(14, weight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(crop.variety,
                style: AppTextStyles.body(11, color: AppColors.textSecondaryOf(context)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            if (ready)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/farmer/batches/harvest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amberPale,
                    foregroundColor: AppColors.harvest,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Schedule Harvest',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
              )
            else if (overdueEstimate)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/farmer/batches/${crop.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest.withValues(alpha: 0.1),
                    foregroundColor: AppColors.forest,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Mark Ready to Harvest',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: crop.progress,
                  backgroundColor: AppColors.borderOf(context),
                  valueColor: AlwaysStoppedAnimation<Color>(crop.stageColor),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(crop.daysLabel,
                    style: TextStyle(color: crop.stageColor,
                        fontSize: 10.5, fontWeight: FontWeight.w700)),
                Text(crop.yieldLabel,
                    style: AppTextStyles.body(10.5,
                        color: AppColors.textSecondaryOf(context))),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── WEATHER CARD ─────────────────────────────────────────────────────────────

class _GreetingInsightRow extends ConsumerWidget {
  final String name;
  const _GreetingInsightRow({required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adviceAsync = ref.watch(irrigationAdviceProvider);
    final topAdvice = adviceAsync.maybeWhen(
        data: (list) => list.isNotEmpty ? list.first : null, orElse: () => null);
    final insightText = topAdvice == null
        ? 'All your batches look well watered today.'
        : '${topAdvice.batch.cropName} ${topAdvice.headline.toLowerCase()}.';

    // A single full-width banner — the greeting itself already lives in
    // the header right above this, so repeating "Good morning, name"
    // again here was pure duplication. Water-themed gradient + glow gives
    // it its own identity instead of looking like just another gray card.
    return GestureDetector(
      onTap: () => context.push('/farmer/irrigation-advisor'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F3D5C), Color(0xFF14507A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1976D2).withValues(alpha: 0.28),
                blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.08)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: const Text('💧', style: TextStyle(fontSize: 20)),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(duration: 1400.ms, begin: const Offset(1, 1), end: const Offset(1.08, 1.08)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(insightText, style: const TextStyle(color: Colors.white,
                  fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text('Log the action',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11.5, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
          ),
        ]),
      ),
    );
  }
}

class _WeatherCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final adviceAsync = ref.watch(irrigationAdviceProvider);
    final soilMoistureAsync = ref.watch(soilMoistureProvider);

    return GestureDetector(
      onTap: () => context.push('/farmer/irrigation-advisor'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.3),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          // Subtle moving backdrop — the generated growth clip, cropped to
          // a wide banner and dimmed, so it reads as texture rather than
          // competing with the weather numbers on top of it.
          const Positioned.fill(
            child: LoopingBackgroundVideo(
              assetPath: 'assets/videos/header_banner.mp4',
              fallbackColor: Color(0xFF1B4332),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1B4332).withValues(alpha: 0.82),
                      const Color(0xFF2D6A4F).withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: weatherAsync.when(
          loading: () => const SizedBox(
              height: 140,
              child: Center(child: CircularProgressIndicator(color: Colors.white))),
          error: (e, _) => _WeatherFallback(),
          data: (w) {
            final topAdvice = adviceAsync.maybeWhen(
                data: (list) => list.isNotEmpty ? list.first : null,
                orElse: () => null);
            final moisture = soilMoistureAsync.maybeWhen(
                data: (m) => m, orElse: () => null);
            return Column(children: [
              Row(children: [
                const Row(children: [
                  Icon(Icons.location_on, color: Colors.white70, size: 15),
                  SizedBox(width: 4),
                  Text('Farm Zone',
                      style: TextStyle(color: Colors.white,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/farmer/irrigation-advisor'),
                  child: Row(children: [
                    Text('Irrigation advice',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, color: Colors.white54, size: 14),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                AnimatedEmoji(w.emoji, size: 36),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${w.tempC.toStringAsFixed(0)}°C',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 32, fontWeight: FontWeight.w800)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(w.condition,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ]),
                const Spacer(),
              ]),
              const SizedBox(height: 14),
              Row(children: _statTiles(w, topAdvice, moisture)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  AnimatedEmoji('🌿', size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    _adviceText(topAdvice, moisture),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                  )),
                ]),
              ),
            ]);
          },
        ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _statTiles(
      WeatherSnapshot w, IrrigationAdvice? topAdvice, SoilMoistureReading? moisture) {
    final tiles = <_WStat>[
      _WStat('💧', '${w.humidityPct.toStringAsFixed(0)}%', 'Humidity'),
      _WStat('💨', '${w.windKph.toStringAsFixed(0)} kph', 'Wind'),
      _WStat('🌧️', '${w.rainfallLast24hMm.toStringAsFixed(1)} mm', 'Rainfall'),
      _WStat(topAdvice?.emoji ?? '✅',
          topAdvice == null ? 'Good' : topAdvice.urgency.name, 'Irrigation'),
      if (moisture != null)
        _WStat('🛰️', '${moisture.moisturePercent.toStringAsFixed(0)}%', 'Soil (Sat.)'),
    ];
    final widgets = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      widgets.add(Expanded(child: tiles[i]));
      if (i != tiles.length - 1) widgets.add(_WDiv());
    }
    return widgets;
  }

  String _adviceText(IrrigationAdvice? topAdvice, SoilMoistureReading? moisture) {
    final base = topAdvice == null
        ? 'No active batches to water right now.'
        : '${topAdvice.headline} — ${topAdvice.batch.cropName}. ${topAdvice.reason}';
    if (moisture == null) return base;
    final satNote = ' Satellite (${moisture.daysSinceObserved}d ago) shows '
        '${moisture.label.toLowerCase()} soil moisture (~${moisture.moisturePercent.toStringAsFixed(0)}%).';
    return base + satNote;
  }
}

class _WeatherFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 140,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, color: Colors.white70, size: 28),
            const SizedBox(height: 8),
            Text('Weather unavailable — check your connection',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
          ]),
        ),
      );
}

class _WStat extends StatelessWidget {
  final String emoji, value, label;
  const _WStat(this.emoji, this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    AnimatedEmoji(emoji, size: 18),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(
        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
    Text(label, style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
  ]);
}

class _WDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2));
}

// ── KPI CARD ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String emoji, badge, value, label, sub;
  final bool badgeGreen;
  const _KpiCard(this.emoji, this.badge, this.badgeGreen,
      this.value, this.label, this.sub);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context), borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: (badgeGreen ? AppColors.leaf : Colors.orange)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: AnimatedEmoji(emoji, size: 15),
          ),
          if (badge.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: badgeGreen
                    ? AppColors.mint.withValues(alpha: 0.3)
                    : const Color(0xFFFFEDE9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badge,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                      color: badgeGreen
                          ? AppColors.leaf
                          : Colors.orange.shade700)),
            ),
        ]),
        const SizedBox(height: 10),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context), letterSpacing: -0.3)),
        const SizedBox(height: 1),
        Text(label, style: AppTextStyles.poppins(12.5, weight: FontWeight.w600,
            color: AppColors.textPrimaryOf(context))),
        const SizedBox(height: 1),
        Text(sub, style: AppTextStyles.bodyMuted.copyWith(fontSize: 10.5),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ── HARVEST CHART ─────────────────────────────────────────────────────────────

class _HarvestChart extends StatelessWidget {
  final List<_Bar> bars;
  final String period;
  final ValueChanged<String> onPeriod;
  const _HarvestChart(
      {required this.bars, required this.period, required this.onPeriod});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context), borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Harvest Yield', style: AppTextStyles.h2),
            Text('Monthly kg comparison',
                style: AppTextStyles.bodyMuted.copyWith(fontSize: 12)),
          ])),
          _PeriodToggle(selected: period, onSelect: onPeriod),
        ]),
        const SizedBox(height: 14),
        const Row(children: [
          _Leg(AppColors.forest, '2026'),
          SizedBox(width: 16),
          _Leg(AppColors.amber, '2025'),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: CustomPaint(painter: _ChartPainter(bars), size: Size.infinite),
        ),
      ]),
    );
  }
}

class _Leg extends StatelessWidget {
  final Color color; final String label;
  const _Leg(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 12,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 6),
    Text(label, style: AppTextStyles.bodyMuted.copyWith(fontSize: 12)),
  ]);
}

class _PeriodToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _PeriodToggle({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.parchment,
          borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(3),
      child: Row(mainAxisSize: MainAxisSize.min,
        children: ['Week', 'Month', 'Year'].map((p) {
          final active = p == selected;
          return GestureDetector(
            onTap: () => onSelect(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: active ? AppColors.forest : Colors.transparent,
                  borderRadius: BorderRadius.circular(16)),
              child: Text(p,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.textSecondaryOf(context))),
            ),
          );
        }).toList()),
    );
  }
}

class _Bar {
  final String month;
  final double v1, v2;
  const _Bar(this.month, this.v1, this.v2);
}

class _ChartPainter extends CustomPainter {
  final List<_Bar> bars;
  const _ChartPainter(this.bars);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFFE8E4DC)..strokeWidth = 1;
    final p1 = Paint()..color = AppColors.forest;
    final p2 = Paint()..color = AppColors.amber;
    for (int i = 0; i <= 3; i++) {
      final y = size.height - size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final gw = size.width / bars.length;
    final bw = gw * 0.28;
    final gap = gw * 0.06;
    for (int i = 0; i < bars.length; i++) {
      final b = bars[i];
      final cx = gw * i + gw / 2;
      final h1 = size.height * 0.85 * b.v1;
      final h2 = size.height * 0.85 * b.v2;
      canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - bw - gap / 2, size.height - h1, bw, h1),
          topLeft: const Radius.circular(4), topRight: const Radius.circular(4)), p1);
      canvas.drawRRect(RRect.fromRectAndCorners(
          Rect.fromLTWH(cx + gap / 2, size.height - h2, bw, h2),
          topLeft: const Radius.circular(4), topRight: const Radius.circular(4)), p2);
      final tp = TextPainter(
          text: TextSpan(text: b.month,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, size.height + 4));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => false;
}

// ── CROPS TAB ────────────────────────────────────────────────────────────────

enum _CropSort {
  recentlyUpdated,
  nameAZ,
  stage;

  String get label => switch (this) {
        _CropSort.recentlyUpdated => 'Recently updated',
        _CropSort.nameAZ => 'Name (A–Z)',
        _CropSort.stage => 'Growth stage',
      };
}

class _CropsTab extends ConsumerStatefulWidget {
  const _CropsTab();
  @override
  ConsumerState<_CropsTab> createState() => _CropsTabState();
}

class _CropsTabState extends ConsumerState<_CropsTab> {
  int _filter = 0;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _growingStages = {
    CropStage.planned, CropStage.planted, CropStage.sprouting,
    CropStage.vegetative, CropStage.flowering, CropStage.fruiting,
  };
  static const _attentionStages = {CropStage.concern, CropStage.failed};
  _CropSort _sort = _CropSort.recentlyUpdated;

  bool _matchesFilter(_Crop c, int filter) => switch (filter) {
        1 => c.stageEnum == CropStage.readyToHarvest,
        2 => _growingStages.contains(c.stageEnum),
        3 => _attentionStages.contains(c.stageEnum),
        _ => true,
      };

  List<_Crop> _filteredCrops(WidgetRef ref) {
    final all = _visibleCrops(ref);
    final q = _query.trim().toLowerCase();
    final filtered = all.where((c) {
      if (!_matchesFilter(c, _filter)) return false;
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) || c.variety.toLowerCase().contains(q);
    }).toList();
    switch (_sort) {
      case _CropSort.nameAZ:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _CropSort.stage:
        filtered.sort((a, b) => a.stageEnum.index.compareTo(b.stageEnum.index));
      case _CropSort.recentlyUpdated:
        break; // already in the order _visibleCrops provides
    }
    return filtered;
  }

  Future<void> _openSortSheet(BuildContext context) async {
    final chosen = await showModalBottomSheet<_CropSort>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sort crops by', style: TextStyle(fontWeight: FontWeight.w700))),
          ),
          ...(_CropSort.values.map((s) => RadioListTile<_CropSort>(
                value: s,
                groupValue: _sort,
                title: Text(s.label),
                onChanged: (v) => Navigator.pop(sheetContext, v),
              ))),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (chosen != null) setState(() => _sort = chosen);
  }

  @override
  Widget build(BuildContext context) {
    // Counts reflect the farmer's actual batches — not hardcoded — so a
    // freshly planted crop shows up in "All" and "Growing" immediately,
    // and the totals never drift out of sync with the real data.
    final allCrops = _visibleCrops(ref);
    final harvestCount = allCrops.where((c) => c.stageEnum == CropStage.readyToHarvest).length;
    final growingCount = allCrops.where((c) => _growingStages.contains(c.stageEnum)).length;
    final attentionCount = allCrops.where((c) => _attentionStages.contains(c.stageEnum)).length;
    final filters = [
      'All (${allCrops.length})',
      '🌾 Harvest ($harvestCount)',
      '🌿 Growing ($growingCount)',
      '⚠️ Attention ($attentionCount)',
    ];
    return SafeArea(child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('My Crops', style: AppTextStyles.poppins(26, weight: FontWeight.w800,
                  color: AppColors.textPrimaryOf(context)))
                  .animate()
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .slideX(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 2),
              Text('Track every batch from seed to harvest',
                  style: AppTextStyles.poppins(12.5, color: AppColors.textSecondaryOf(context)))
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms),
            ]),
          ),
          ModernButton.icon(
            icon: Icons.tune_rounded,
            onPressed: () => _openSortSheet(context),
            color: AppColors.forest,
            height: 40,
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(color: AppColors.cardOf(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.subtle),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search crops, varieties...',
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondaryOf(context)),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, size: 18, color: AppColors.textSecondaryOf(context)),
                      onPressed: () => setState(() {
                        _searchCtrl.clear();
                        _query = '';
                      }),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final selected = _filter == i;
            return GestureDetector(
              onTap: () => setState(() => _filter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: [AppColors.forest, AppColors.leaf],
                          begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : null,
                  color: selected ? null : AppColors.cardOf(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected ? Colors.transparent : AppColors.borderOf(context)),
                  boxShadow: selected
                      ? [BoxShadow(color: AppColors.forest.withValues(alpha: 0.28),
                          blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(filters[i],
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textSecondaryOf(context))),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      Expanded(child: Builder(builder: (context) {
        final crops = _filteredCrops(ref);
        if (crops.isEmpty) {
          return Center(
            child: _query.isNotEmpty || _filter != 0
                ? EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: allCrops.isEmpty
                        ? 'No crops yet'
                        : 'No crops match "$_query"',
                    message: allCrops.isEmpty
                        ? 'Add your first batch to get started.'
                        : _filter != 0
                            ? 'Try a different filter or search term.'
                            : null,
                  )
                : _EmptyCropsBanner(onAdd: () => context.push('/farmer/batches/new')),
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: crops.map((c) => GestureDetector(
            onTap: () => context.push('/farmer/batches/${c.id}'),
            child: _CropListCard(crop: c),
          )).toList(),
        );
      })),
    ]));
  }
}

class _CropListCard extends StatelessWidget {
  final _Crop crop;
  const _CropListCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    final imgUrl = crop.photoUrl ?? _cropImages[crop.name] ?? _defaultCropImage;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: AppColors.cardOf(context), borderRadius: BorderRadius.circular(22),
          boxShadow: AppShadows.card),
      clipBehavior: Clip.hardEdge,
      child: Row(children: [
        // Small image on left
        SizedBox(
          width: 80, height: 90,
          child: CachedNetworkImage(
            imageUrl: imgUrl, fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.mint.withValues(alpha: 0.2)),
            errorWidget: (_, __, ___) =>
                Container(color: AppColors.mint.withValues(alpha: 0.2),
                    child: const Icon(Icons.eco, color: AppColors.leaf)),
          ),
        ),
        Expanded(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(crop.name,
                  style: AppTextStyles.h2.copyWith(fontSize: 15))),
              if (crop.isFavorite)
                AnimatedEmoji('❤️', size: 13),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: crop.stageColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(crop.stage,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: crop.stageColor)),
              ),
            ]),
            Text(crop.variety,
                style: AppTextStyles.bodyMuted.copyWith(fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: crop.progress,
                  backgroundColor: AppColors.borderOf(context),
                  valueColor: AlwaysStoppedAnimation<Color>(crop.stageColor),
                  minHeight: 7,
                ),
              )),
              const SizedBox(width: 8),
              Text('${(crop.progress * 100).toInt()}%',
                  style: AppTextStyles.label),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text(crop.daysLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: crop.stageColor)),
              const SizedBox(width: 12),
              Text(crop.yieldLabel,
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 12)),
            ]),
          ]),
        )),
      ]),
    );
  }
}

// ── HARVEST & PROFILE TABS ────────────────────────────────────────────────────

class _HarvestTab extends ConsumerWidget {
  const _HarvestTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(farmerBatchesProvider).value ?? const [];
    final harvested = batches.where((b) => b.stage == CropStage.harvested).toList()
      ..sort((a, b) => (b.harvestedAt ?? b.plantedDate ?? b.plannedDate)
          .compareTo(a.harvestedAt ?? a.plantedDate ?? a.plannedDate));

    // Batches that are planted/growing but not harvested yet — this is
    // what "Schedule Harvest" on the New Crop Batch form actually feeds.
    // Without this section, planting a crop today gave no visible
    // confirmation anywhere on the Harvest tab that a harvest was even
    // scheduled — only the Harvest Log (completed harvests) existed.
    final upcoming = batches
        .where((b) =>
            b.stage != CropStage.harvested &&
            b.stage != CropStage.failed &&
            b.estimatedHarvestDate != null)
        .toList()
      ..sort((a, b) => a.estimatedHarvestDate!.compareTo(b.estimatedHarvestDate!));

    return SafeArea(child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Harvests', style: AppTextStyles.poppins(26, weight: FontWeight.w800,
            color: AppColors.textPrimaryOf(context)))
            .animate()
            .fadeIn(duration: 400.ms, curve: Curves.easeOut)
            .slideX(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
        const SizedBox(height: 2),
        Text('What\'s coming up, and what you\'ve already brought in',
            style: AppTextStyles.poppins(12.5, color: AppColors.textSecondaryOf(context)))
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 20),
        SectionHeader(title: 'Upcoming Harvests'),
        if (upcoming.isEmpty)
          const EmptyStateView(
            icon: Icons.event_available_outlined,
            title: 'Nothing scheduled',
            message: 'Plant a batch to see its expected harvest date here.',
          )
        else
          ...upcoming.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _UpcomingHarvestRow(batch: b),
          )),
        const SizedBox(height: 24),
        SectionHeader(title: 'Harvest Log'),
        if (harvested.isEmpty)
          const EmptyStateView(
            icon: Icons.agriculture_outlined,
            title: 'No harvests logged yet',
            message: 'Tap the + button below to log your first harvest.',
          )
        else
          ...harvested.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HarvestEntry(
              b.cropName,
              b.plotName ?? 'Unplotted',
              '${(b.verifiedWeightKg ?? b.estimatedYieldKg ?? 0).toStringAsFixed(1)} kg',
              b.harvestedAt == null
                  ? '—'
                  : '${b.harvestedAt!.day}/${b.harvestedAt!.month}/${b.harvestedAt!.year}',
              b.photoUrl ?? _cropImages[b.cropName] ?? _defaultCropImage,
            ),
          )),
      ],
    ));
  }
}

class _UpcomingHarvestRow extends StatelessWidget {
  final CropBatch batch;
  const _UpcomingHarvestRow({required this.batch});

  @override
  Widget build(BuildContext context) {
    final expected = batch.estimatedHarvestDate!;
    final daysLeft = expected.difference(DateTime.now()).inDays;
    final ready = daysLeft <= 0;
    final imgUrl = batch.photoUrl ?? _cropImages[batch.cropName] ?? _defaultCropImage;

    return GestureDetector(
      onTap: () => context.push('/farmer/batches/${batch.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(children: [
          SizedBox(width: 56, height: 56,
            child: CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.mint.withValues(alpha: 0.2)),
                errorWidget: (_, __, ___) => Container(color: AppColors.mint.withValues(alpha: 0.2),
                    child: const Icon(Icons.eco, color: AppColors.leaf))),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(batch.cropName, style: AppTextStyles.poppins(14, weight: FontWeight.w700)),
              Text(batch.plotName ?? 'Unplotted',
                  style: AppTextStyles.poppins(11, color: AppColors.textSecondaryOf(context))),
              const SizedBox(height: 2),
              Text('Expected ${expected.day}/${expected.month}/${expected.year}',
                  style: AppTextStyles.poppins(11, color: AppColors.textSecondaryOf(context))),
            ]),
          )),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (ready ? AppColors.amber : AppColors.leaf).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(ready ? 'Ready!' : '${daysLeft}d',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: ready ? AppColors.amber : AppColors.leaf)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _HarvestEntry extends StatelessWidget {
  final String name, plot, weight, date, imgUrl;
  const _HarvestEntry(this.name, this.plot, this.weight, this.date, this.imgUrl);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppShadows.card),
      clipBehavior: Clip.hardEdge,
      child: Row(children: [
        SizedBox(width: 70, height: 70,
          child: CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.mint.withValues(alpha: 0.2)),
            errorWidget: (_, __, ___) => const Icon(Icons.eco))),
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTextStyles.poppins(14, weight: FontWeight.w700)),
            Text('$plot · $date', style: AppTextStyles.poppins(12, color: AppColors.textSecondaryOf(context))),
          ]),
        )),
        Padding(padding: const EdgeInsets.only(right: 14),
          child: Text(weight,
              style: AppTextStyles.poppins(16, weight: FontWeight.w800, color: AppColors.amber))),
      ]),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  final String name;
  const _ProfileTab({required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final batches = ref.watch(farmerBatchesProvider).value ?? const [];
    final totalYield = ref.watch(totalYieldProvider);
    final daysActive = batches.isEmpty
        ? 0
        : DateTime.now()
            .difference(batches
                .map((b) => b.plantedDate ?? b.plannedDate)
                .reduce((a, b) => a.isBefore(b) ? a : b))
            .inDays;

    // Real, derived values — not placeholders. Completion is counted from
    // actual profile fields; level is a simple tier off actual batch count.
    final completionFields = [
      user?.name.isNotEmpty ?? false,
      user?.email.isNotEmpty ?? false,
      user?.photoUrl != null,
      user?.farmName != null,
      user?.organicCertificationUrl != null,
    ];
    final completion =
        completionFields.where((f) => f).length / completionFields.length;
    final levelLabel = batches.length >= 10
        ? 'Top Grower'
        : batches.length >= 3
            ? 'Grower'
            : 'New Grower';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.premiumBackground),
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: PremiumProfileHeader(
            name: name,
            photoUrl: user?.photoUrl,
            subtitle: 'Growing sustainably every day 🌱',
            levelLabel: levelLabel,
            profileCompletion: completion,
            onSettingsTap: () => context.push('/settings'),
            onNotificationsTap: () => context.push('/notifications'),
          ),
        ),
        SliverToBoxAdapter(child: Transform.translate(
          offset: const Offset(0, -18),
          child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(children: [
            Row(children: [
              ModernStatCard(
                icon: Icons.eco_rounded,
                color: AppColors.premiumEmerald,
                label: 'Crops',
                value: batches.length,
                caption: 'Growing',
              ),
              const SizedBox(width: 12),
              ModernStatCard(
                icon: Icons.scale_rounded,
                color: AppColors.premiumWarning,
                label: 'Harvested',
                value: totalYield,
                suffix: 'kg',
                decimals: 1,
                caption: 'This season',
              ),
              const SizedBox(width: 12),
              ModernStatCard(
                icon: Icons.local_fire_department_rounded,
                color: AppColors.consumerAccent,
                label: 'Days Active',
                value: daysActive,
                caption: 'Current streak',
              ),
            ]),
            const SizedBox(height: 22),
            SectionHeader(title: 'Achievements'),
            SizedBox(height: 96, child: ListView(scrollDirection: Axis.horizontal, children: [
              AchievementBadge(
                  icon: Icons.emoji_events_rounded,
                  label: 'Top Farmer',
                  earned: levelLabel == 'Top Grower'),
              AchievementBadge(
                  icon: Icons.agriculture_rounded,
                  label: '50kg Club',
                  earned: totalYield >= 50,
                  progress: (totalYield / 50).clamp(0, 1)),
              const AchievementBadge(
                  icon: Icons.water_drop_rounded, label: 'Water Wise', earned: false, progress: 0.3),
              const AchievementBadge(
                  icon: Icons.photo_camera_rounded, label: 'Documented', earned: false, progress: 0.1),
              const AchievementBadge(
                  icon: Icons.recycling_rounded, label: 'Zero Waste', earned: false, progress: 0),
            ])),
            const SizedBox(height: 22),
            SectionHeader(title: 'Farm Tools'),
            QuickActionCard(
              icon: Icons.biotech_rounded,
              color: AppColors.premiumEmerald,
              title: 'AI Pest Scanner',
              subtitle: 'Identify diseases instantly using AI',
              description: 'Detect crop issues from photos in seconds.',
              onTap: () => context.push(
                  '/farmer/batches/batch-cherry-tomatoes/scan?crop=Cherry%20Tomatoes'),
            ),
            const SizedBox(height: 10),
            QuickActionCard(
              icon: Icons.water_drop_rounded,
              color: AppColors.consumerAccent,
              title: 'Irrigation Advisor',
              subtitle: 'Weather-aware watering guidance',
              description: 'Know when a batch actually needs water.',
              onTap: () => context.push('/farmer/irrigation-advisor'),
            ),
            const SizedBox(height: 10),
            QuickActionCard(
              icon: Icons.cloud_outlined,
              color: AppColors.forest,
              title: 'Climate Intelligence',
              subtitle: 'JHUB weather-station crop risk & advisory',
              description: 'Disease, heat, and field-work risk for your crop today.',
              onTap: () => context.push('/farmer/climate-intelligence'),
            ),
            const SizedBox(height: 10),
            QuickActionCard(
              icon: Icons.qr_code_2_rounded,
              color: AppColors.premiumWarning,
              title: 'Trace a Batch',
              subtitle: 'Look up any batch\'s full history',
              description: 'Scan or enter a batch ID to trace it.',
              onTap: () => context.push('/farmer/trace'),
            ),
            const SizedBox(height: 10),
            QuickActionCard(
              icon: Icons.storefront_rounded,
              color: AppColors.leaf,
              title: 'Marketplace',
              subtitle: 'Publish harvests, manage requests',
              description: 'Sell fresh produce and track buyer requests.',
              onTap: () => context.push('/farmer/marketplace'),
            ),
            const SizedBox(height: 22),
            SectionHeader(title: 'Planning'),
            QuickActionCard(
              icon: Icons.eco_rounded,
              color: AppColors.premiumEmerald,
              title: 'Plan Next Crop',
              subtitle: 'Get a rotation suggestion',
              onTap: () => _planNextCrop(context, ref),
            ),
            const SizedBox(height: 10),
            QuickActionCard(
              icon: Icons.add_circle_outline_rounded,
              color: AppColors.premiumEmerald,
              title: 'Log New Batch',
              subtitle: 'Register a new crop batch',
              onTap: () => context.push('/farmer/batches/new'),
            ),
            const SizedBox(height: 22),
            SectionHeader(title: 'Account'),
            GlassSectionCard(children: [
              PremiumSettingsTile(
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.premiumEmerald,
                title: 'Edit Profile',
                description: 'Update your information',
                onTap: () => context.push('/profile'),
              ),
              PremiumSettingsTile(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.premiumEmerald,
                title: 'Privacy & Security',
                description: 'Data, permissions, manage crops',
                onTap: () => context.push('/settings/privacy-security'),
              ),
              PremiumSettingsTile(
                icon: Icons.notifications_none_rounded,
                iconColor: AppColors.premiumWarning,
                title: 'Notifications',
                description: 'Manage alerts',
                onTap: () => context.push('/notifications'),
              ),
              PremiumSettingsTile(
                icon: Icons.help_outline_rounded,
                iconColor: AppColors.consumerAccent,
                title: 'Help & Support',
                description: 'Contact us',
                onTap: () => context.push('/settings/help-support'),
              ),
              PremiumSettingsTile(
                icon: Icons.logout_rounded,
                iconColor: AppColors.red,
                title: 'Sign Out',
                description: 'Sign out securely',
                onTap: () {
                  ref.read(sessionProvider.notifier).signOut();
                  context.go('/login');
                },
              ),
            ]),
            const SizedBox(height: 100),
          ]),
        ))),
      ]),
    );
  }
}


// ── QUICK ACTIONS ─────────────────────────────────────────────────────────────

class _QuickActionsOverlay extends StatelessWidget {
  final VoidCallback onClose;
  const _QuickActionsOverlay({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(onTap: () {},
          child: Container(
            decoration: BoxDecoration(color: AppColors.cardOf(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.borderOf(context),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Text('Quick Actions', style: AppTextStyles.h2)),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ]),
              Text('What would you like to record?', style: AppTextStyles.bodyMuted),
              const SizedBox(height: 16),
              GridView.count(shrinkWrap: true, crossAxisCount: 3,
                  crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.86,
                  children: [
                    _ABtn(Icons.grass_rounded, 'Add Crop', 'New planting',
                        const [Color(0xFF43A047), Color(0xFF1B5E20)],
                        onTap: () { onClose(); context.push('/farmer/batches/new'); }),
                    _ABtn(Icons.water_drop_rounded, 'Log Watering', 'Water applied',
                        const [Color(0xFF42A5F5), Color(0xFF1565C0)],
                        onTap: () { onClose(); context.push('/farmer/batches/irrigation'); }),
                    _ABtn(Icons.agriculture_rounded, 'Log Harvest', 'What you picked',
                        const [Color(0xFFFFB74D), Color(0xFFEF6C00)],
                        onTap: () { onClose(); context.push('/farmer/batches/harvest'); }),
                    _ABtn(Icons.bug_report_rounded, 'AI Pest Scan', 'Diagnose & treat',
                        const [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
                        onTap: () {
                          onClose();
                          context.push('/farmer/batches/batch-cherry-tomatoes/scan'
                              '?crop=Cherry%20Tomatoes');
                        }),
                    _ABtn(Icons.qr_code_scanner_rounded, 'Trace Batch', 'Look up a QR',
                        const [Color(0xFF26A69A), Color(0xFF00695C)],
                        onTap: () { onClose(); context.push('/farmer/trace'); }),
                    _ABtn(Icons.camera_alt_rounded, 'Documentation', 'Photo-log a record',
                        const [Color(0xFFFF7043), Color(0xFFD84315)],
                        onTap: () {
                          onClose();
                          context.push('/farmer/documents/new?type=other');
                        }),
                    _ABtn(Icons.science_rounded, 'Fertilizer', 'Product used',
                        const [Color(0xFF29B6F6), Color(0xFF0277BD)],
                        onTap: () {
                          onClose();
                          context.push('/farmer/documents/new?type=fertilizer');
                        }),
                    _ABtn(Icons.verified_rounded, 'Organic Cert', 'File a certificate',
                        const [Color(0xFF9575CD), Color(0xFF512DA8)],
                        onTap: () {
                          onClose();
                          context.push('/farmer/documents/new?type=organicCertificate');
                        }),
                  ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFEEF8F0),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  AnimatedEmoji('☀️', size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Good growing day today!',
                        style: AppTextStyles.body(14).copyWith(fontWeight: FontWeight.w600)),
                    Text('24°C · Humidity 68% · Light winds',
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 12)),
                  ])),
                ]),
              ),
            ]),
          )),
    ));
  }
}

class _ABtn extends StatefulWidget {
  final IconData icon;
  final String label, sub;
  final List<Color> gradient;
  final VoidCallback? onTap;
  const _ABtn(this.icon, this.label, this.sub, this.gradient, {this.onTap});

  @override
  State<_ABtn> createState() => _ABtnState();
}

class _ABtnState extends State<_ABtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardOf(context),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.subtle,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: widget.gradient,
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [
                  BoxShadow(color: widget.gradient.last.withValues(alpha: 0.4),
                      blurRadius: 14, spreadRadius: 1, offset: const Offset(0, 5)),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(widget.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(widget.label, style: AppTextStyles.label.copyWith(
                fontSize: 11.5, color: AppColors.textPrimaryOf(context)),
                textAlign: TextAlign.center),
            const SizedBox(height: 1),
            Text(widget.sub, style: AppTextStyles.bodyMuted.copyWith(fontSize: 9),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

// ── BOTTOM NAV ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int index; final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(), notchMargin: 8,
      color: AppColors.cardOf(context), elevation: 8,
      child: SizedBox(height: 60, child: Row(children: [
        Expanded(child: _NI(Icons.home_rounded, 'Home', 0, index, onTap)),
        Expanded(child: _NI(Icons.eco_outlined, 'Crops', 1, index, onTap)),
        Expanded(child: _NI(Icons.description_outlined, 'Documents', 2, index, onTap)),
        const Expanded(child: SizedBox()),
        Expanded(child: _NI(Icons.store_outlined, 'Harvest', 3, index, onTap)),
        Expanded(child: _NI(Icons.person_outline, 'Profile', 4, index, onTap)),
      ])),
    );
  }
}

class _NI extends StatelessWidget {
  final IconData icon; final String label;
  final int idx, cur; final ValueChanged<int> onTap;
  const _NI(this.icon, this.label, this.idx, this.cur, this.onTap);
  @override
  Widget build(BuildContext context) {
    final active = idx == cur;
    return GestureDetector(onTap: () => onTap(idx),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon,
            color: active ? AppColors.forest : AppColors.textSecondaryOf(context), size: 22),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? AppColors.forest : AppColors.textSecondaryOf(context))),
        if (active) Container(margin: const EdgeInsets.only(top: 2),
            width: 4, height: 4,
            decoration: const BoxDecoration(
                color: AppColors.forest, shape: BoxShape.circle)),
      ]),
    );
  }
}

// ── DATA MODELS ───────────────────────────────────────────────────────────────

class _Crop {
  final String id, name, variety, stage, daysLabel, yieldLabel;
  final Color stageColor;
  final CropStage stageEnum;
  final double progress;
  final bool isFavorite;
  final String? photoUrl;
  const _Crop(this.id, this.name, this.variety, this.stage, this.stageColor,
      this.stageEnum, this.progress, this.daysLabel, this.yieldLabel, this.isFavorite,
      [this.photoUrl]);

  /// Maps a real, Firestore-backed [CropBatch] onto this display shape so
  /// Home/Crops tabs can render actual batches (photo included) the same
  /// way they render the demo placeholder crops.
  factory _Crop.fromBatch(CropBatch b) {
    final (label, color) = switch (b.stage) {
      CropStage.planned => ('Planned', AppColors.slateLight),
      CropStage.planted => ('Just Planted', AppColors.consumerAccent),
      CropStage.sprouting => ('Sprouting', AppColors.leaf),
      CropStage.vegetative => ('Vegetative', AppColors.leaf),
      CropStage.flowering => ('Flowering', AppColors.consumerAccent),
      CropStage.fruiting => ('Fruiting', AppColors.consumerAccent),
      CropStage.readyToHarvest => ('Ready to Harvest', AppColors.amber),
      CropStage.harvested => ('Harvested', AppColors.slateLight),
      CropStage.concern => ('Needs Attention', AppColors.error),
      CropStage.failed => ('Failed', AppColors.error),
    };

    double progress = 0.1;
    String daysLabel = '—';
    final planted = b.plantedDate ?? b.plannedDate;
    final expected = b.estimatedHarvestDate;
    if (expected != null) {
      final total = expected.difference(planted).inDays;
      final elapsed = DateTime.now().difference(planted).inDays;
      progress = total <= 0 ? 1.0 : (elapsed / total).clamp(0.0, 1.0);
      final remaining = expected.difference(DateTime.now()).inDays;
      daysLabel = remaining <= 0 ? 'Ready!' : '${remaining}d';
    }
    if (b.stage == CropStage.readyToHarvest) {
      progress = 0.92;
      daysLabel = 'Ready!';
    }

    return _Crop(
      b.id,
      b.cropName,
      '${b.variety ?? 'Standard'} · ${b.plotName ?? 'Unplotted'}',
      label,
      color,
      b.stage,
      progress,
      daysLabel,
      b.estimatedYieldKg == null ? '—' : '~${b.estimatedYieldKg!.toStringAsFixed(1)}kg',
      false,
      b.photoUrl,
    );
  }
}