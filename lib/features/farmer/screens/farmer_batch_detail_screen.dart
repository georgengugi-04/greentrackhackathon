import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/marketplace_providers.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/models/models.dart';

class FarmerBatchDetailScreen extends ConsumerStatefulWidget {
  final String batchId;
  const FarmerBatchDetailScreen({required this.batchId, super.key});

  @override
  ConsumerState<FarmerBatchDetailScreen> createState() => _FarmerBatchDetailScreenState();
}

class _FarmerBatchDetailScreenState extends ConsumerState<FarmerBatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batchAsync = ref.watch(batchByIdProvider(widget.batchId));

    return batchAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.farmerSurfaceOf(context),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.farmerSurfaceOf(context),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Text('Could not load this batch.\n$e',
              textAlign: TextAlign.center, style: AppTextStyles.bodyMuted),
        ),
      ),
      data: (batch) {
        if (batch == null) {
          return Scaffold(
            backgroundColor: AppColors.farmerSurfaceOf(context),
            appBar: AppBar(backgroundColor: Colors.transparent),
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.search_off, size: 40, color: AppColors.slateLight),
                const SizedBox(height: 12),
                Text("This batch isn't in your list anymore.",
                    style: AppTextStyles.bodyMuted),
              ]),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.farmerSurfaceOf(context),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(batch.cropName),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: AppColors.farmerAccent,
              labelColor: AppColors.farmerAccent,
              unselectedLabelColor: AppColors.textSecondaryOf(context),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Irrigation'),
                Tab(text: 'Pests'),
                Tab(text: 'PHI'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _OverviewTab(batch: batch),
              _IrrigationTab(logs: batch.irrigationLogs),
              _PestTab(diagnoses: batch.pestDiagnoses, batchId: batch.id),
              _PHITab(batch: batch),
            ],
          ),
        );
      },
    );
  }
}

// ── Overview ─────────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final CropBatch batch;
  const _OverviewTab({required this.batch});

  // Stages where it makes sense to declare "this is ready" — before
  // planting there's nothing to assess yet, and harvested/failed/concern
  // batches have already moved past this decision. Includes `planted`
  // itself: there's currently no separate UI step that advances a batch
  // through sprouting/vegetative/flowering/fruiting, so in practice every
  // real batch sits at `planted` right up until harvest — excluding it
  // here left every batch with no path to "Ready to Harvest" at all.
  static const _readyEligibleStages = {
    CropStage.planted,
    CropStage.sprouting,
    CropStage.vegetative,
    CropStage.flowering,
    CropStage.fruiting,
  };

  // The natural forward order for the "still growing" stages — used to
  // build the "what's next" picker. Ready-to-harvest has its own
  // dedicated flow above (it also asks for an estimated yield), and
  // harvested/concern/failed are end states with their own screens.
  static const _growthOrder = [
    CropStage.planted,
    CropStage.sprouting,
    CropStage.vegetative,
    CropStage.flowering,
    CropStage.fruiting,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _InfoTile('Batch ID', batch.id),
        _InfoTile('Plot', batch.plotName ?? '—'),
        _InfoTile('Method', batch.farmingMethod.name),
        _InfoTile('Stage', batch.stage.name),
        _InfoTile('Sun', batch.sunExposure.name),
        _InfoTile('Planned', _fmt(batch.plannedDate)),
        if (batch.plantedDate != null) _InfoTile('Planted', _fmt(batch.plantedDate!)),
        if (batch.harvestedAt != null) _InfoTile('Harvested', _fmt(batch.harvestedAt!)),
        if (batch.verifiedWeightKg != null)
          _InfoTile('Weight', '${batch.verifiedWeightKg} kg'),
        if (batch.organicCertified) const _InfoTile('Organic', 'Certified ✓'),
        const SizedBox(height: AppSpacing.md),
        // Mid-cycle check-in — lets a farmer log real progress (sprouted,
        // now flowering, etc.) as it actually happens, instead of a batch
        // sitting frozen at "Just Planted" with no way to reflect growth
        // until the single jump straight to "ready to harvest."
        if (_growthOrder.contains(batch.stage) && batch.stage != CropStage.fruiting)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.eco_outlined),
              label: const Text('Update Growth Stage'),
              onPressed: () => _updateStage(context, ref),
            ),
          ),
        if (_readyEligibleStages.contains(batch.stage))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber, foregroundColor: Colors.white),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark Ready to Harvest'),
              onPressed: () => _markReady(context, ref),
            ),
          )
        else if (batch.stage == CropStage.readyToHarvest)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Row(children: [
              const Icon(Icons.check_circle, color: AppColors.amber, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                  'Ready to harvest — estimated ${batch.estimatedYieldKg ?? "—"} kg. '
                  'Log the harvest from the Harvest tab once it\'s picked.',
                  style: AppTextStyles.body(12.5))),
            ]),
          ),
        if (batch.stage == CropStage.readyToHarvest || batch.harvestedAt != null)
          _PublishToMarketplaceCard(batch: batch),
        ElevatedButton.icon(
          icon: const Icon(Icons.qr_code),
          label: const Text('View Batch QR Code'),
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(batch.cropName),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: batch.qrCodeData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Batch ID: ${batch.id}', style: AppTextStyles.bodyMuted),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateStage(BuildContext context, WidgetRef ref) async {
    final currentIndex = _growthOrder.indexOf(batch.stage);
    final options = _growthOrder.sublist(currentIndex + 1);

    final chosen = await showModalBottomSheet<CropStage>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('How far along is ${batch.cropName} now?',
                style: AppTextStyles.h2.copyWith(fontSize: 17)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Currently: ${batch.stage.emoji} ${batch.stage.label}',
                style: AppTextStyles.bodyMuted),
          ),
          const SizedBox(height: 8),
          ...options.map((s) => ListTile(
                leading: Text(s.emoji, style: const TextStyle(fontSize: 20)),
                title: Text(s.label),
                onTap: () => Navigator.pop(sheetContext, s),
              )),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (chosen == null || !context.mounted) return;

    try {
      await ref.read(batchServiceProvider).updateStage(batch.id, chosen);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${batch.cropName} is now ${chosen.label.toLowerCase()}.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not update this batch: $e')));
    }
  }

  Future<void> _markReady(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(
        text: batch.estimatedYieldKg?.toStringAsFixed(1) ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark ready to harvest?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('This moves ${batch.cropName} to "Ready to Harvest" so it shows up '
              'on the Harvest tab.', style: AppTextStyles.bodyMuted),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Estimated yield (kg)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Mark Ready')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final estimate = double.tryParse(ctrl.text.trim());
    if (estimate == null || estimate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a valid estimated weight in kg.')));
      return;
    }

    try {
      await ref.read(batchServiceProvider).markReadyToHarvest(
          batchId: batch.id, estimatedKg: estimate);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${batch.cropName} marked ready to harvest.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not update this batch: $e')));
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
          color: AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.borderOf(context))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMuted),
          Text(value,
              style: AppTextStyles.body(14).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Irrigation ────────────────────────────────────────────────────────────────

class _IrrigationTab extends StatelessWidget {
  final List<IrrigationLog> logs;
  const _IrrigationTab({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.farmerAccent,
        onPressed: () => context.push('/farmer/batches/irrigation'),
        child: const Icon(Icons.add),
      ),
      body: logs.isEmpty
          ? Center(
              child: Text('No irrigation logs yet', style: AppTextStyles.bodyMuted))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: logs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                final l = logs[i];
                return ListTile(
                  tileColor: AppColors.cardOf(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      side: BorderSide(color: AppColors.borderOf(context))),
                  leading: const Icon(Icons.water_drop,
                      color: AppColors.consumerAccent),
                  title: Text(l.method ?? l.source.label),
                  subtitle: Text(l.timestamp.toString().split(' ').first),
                );
              },
            ),
    );
  }
}

// ── Pests ─────────────────────────────────────────────────────────────────────

class _PestTab extends StatelessWidget {
  final List<PestDiagnosis> diagnoses;
  final String batchId;
  const _PestTab({required this.diagnoses, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.error,
        icon: const Icon(Icons.bug_report),
        label: const Text('New Diagnosis'),
        onPressed: () => context.push('/farmer/batches/$batchId/scan'),
      ),
      body: diagnoses.isEmpty
          ? Center(
              child: Text('No pest diagnoses recorded', style: AppTextStyles.bodyMuted))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: diagnoses.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                final d = diagnoses[i];
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.cardOf(context),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: d.isHarvestLocked
                          ? AppColors.error
                          : AppColors.borderOf(context),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.detectedPest, style: AppTextStyles.h2),
                      Text('Severity: ${d.severity.name}',
                          style: AppTextStyles.bodyMuted),
                      if (d.isHarvestLocked)
                        Text(
                          'PHI locked until ${d.phiClearDate.toString().split(' ').first}',
                          style: AppTextStyles.body(14)
                              .copyWith(color: AppColors.error),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ── PHI Countdown ─────────────────────────────────────────────────────────────

class _PHITab extends StatelessWidget {
  final CropBatch batch;
  const _PHITab({required this.batch});

  @override
  Widget build(BuildContext context) {
    final locked = batch.harvestLockedByPHI;
    final clearDate = batch.earliestPHIClearDate;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: locked
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.leaf.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Icon(
                  locked ? Icons.lock : Icons.lock_open,
                  size: 48,
                  color: locked ? AppColors.error : AppColors.leaf,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  locked ? 'Harvest Locked' : 'Harvest Cleared',
                  style: AppTextStyles.h1.copyWith(
                      color: locked ? AppColors.error : AppColors.leaf),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  locked && clearDate != null
                      ? 'Safe to harvest after\n${clearDate.toString().split(' ').first}'
                      : batch.pestDiagnoses.isEmpty
                          ? 'No pest treatments recorded'
                          : 'All PHI windows have passed',
                  style: AppTextStyles.bodyMuted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('PHI (Pre-Harvest Interval)', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'A PHI lockout is applied automatically when a pesticide treatment is logged. Harvest is blocked until all treatment windows have cleared.',
            style: AppTextStyles.body(14),
          ),
        ],
      ),
    );
  }
}

// ── Publish to Marketplace ──────────────────────────────────────────────────
// Section 4 of the marketplace spec: a batch never auto-publishes. This is
// the one place a farmer can turn a batch into a MarketplaceListing (via the
// existing MarketplaceService.publishBatch) or explicitly keep it private.
// Reads listingForBatchProvider first so a batch already listed shows its
// live status instead of the publish prompt again.
class _PublishToMarketplaceCard extends ConsumerStatefulWidget {
  final CropBatch batch;
  const _PublishToMarketplaceCard({required this.batch});

  @override
  ConsumerState<_PublishToMarketplaceCard> createState() =>
      _PublishToMarketplaceCardState();
}

class _PublishToMarketplaceCardState extends ConsumerState<_PublishToMarketplaceCard> {
  bool _publishing = false;

  CropBatch get batch => widget.batch;

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(listingForBatchProvider(batch.id));

    return existing.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (listing) {
        if (listing != null) {
          // Already listed — link through to the live listing instead of
          // offering to publish a second time for the same batch.
          return Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.leaf.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(children: [
              const Icon(Icons.storefront_rounded, color: AppColors.leaf, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  listing.status == MarketplaceListingStatus.upcoming
                      ? 'Listed on Marketplace — Harvesting Soon'
                      : listing.status == MarketplaceListingStatus.available
                          ? 'Listed on Marketplace — ${listing.availableQuantity.toStringAsFixed(0)} ${listing.unit} available'
                          : 'Listed on Marketplace — ${listing.status.name}',
                  style: AppTextStyles.body(12.5),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/marketplace/listing/${listing.id}'),
                child: const Text('View'),
              ),
            ]),
          );
        }

        // Nothing to publish yet if there's no quantity estimate at all.
        final quantity = batch.verifiedWeightKg ?? batch.estimatedYieldKg;
        if (quantity == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.leaf.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.leaf.withValues(alpha: 0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.storefront_rounded, color: AppColors.leaf, size: 18),
              const SizedBox(width: 8),
              const Text('Publish to Marketplace?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            ]),
            const SizedBox(height: 6),
            Text(
              '${batch.cropName} • Estimated quantity: ${quantity.toStringAsFixed(0)} kg'
              '${batch.estimatedHarvestDate != null ? ' • Expected harvest: ${_fmt(batch.estimatedHarvestDate!)}' : ''}',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 10),
            if (_publishing)
              // The Firestore write can take a moment — without this the
              // card just sits there looking frozen between tapping
              // Publish in the dialog and the confirmation appearing.
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.leaf)),
                const SizedBox(width: 10),
                Text('Publishing to Marketplace…',
                    style: AppTextStyles.body(12.5, weight: FontWeight.w600)),
              ])
            else
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Not a no-op: the farmer explicitly chose to keep
                      // this private, and should see that registered
                      // rather than wondering if the tap did anything.
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Kept private. You can publish this batch anytime.')));
                    },
                    child: const Text('Keep Private'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.leaf, foregroundColor: Colors.white),
                    onPressed: () => _publish(context, ref),
                    child: const Text('Publish'),
                  ),
                ),
              ]),
          ]),
        );
      },
    );
  }

  Future<void> _publish(BuildContext context, WidgetRef ref) async {
    final user = ref.read(sessionProvider);
    if (user == null) return;

    // General location only — never the batch's precise plotLocation
    // coordinates (section 16: public traceability must not expose exact
    // farm coordinates).
    final locationCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publish to Marketplace'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: locationCtrl,
            decoration: const InputDecoration(
              labelText: 'General location',
              hintText: 'e.g. Subukia, Nakuru',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price per kg (optional)',
              hintText: 'Leave blank to hide price',
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a general location to publish.')));
      return;
    }

    setState(() => _publishing = true);
    try {
      await ref.read(marketplaceServiceProvider).publishBatch(
            batch: batch,
            farmerName: user.name,
            generalLocation: locationCtrl.text.trim(),
            pricePerUnit: double.tryParse(priceCtrl.text.trim()),
          );
      ref.invalidate(listingForBatchProvider(batch.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✓ Published to Marketplace.'),
            backgroundColor: AppColors.leaf));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not publish: $e')));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
