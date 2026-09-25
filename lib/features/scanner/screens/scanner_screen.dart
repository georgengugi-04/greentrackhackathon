import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/scan_history_provider.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/scan_frame.dart';
import '../../shared/widgets/qr_camera_view.dart';
import '../../shared/widgets/animated_emoji.dart';

// ── QR SCANNER SCREEN ─────────────────────────────────
// Used by shoppers, chefs, and diners

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _scanning = false;
  String? _scannedId;
  String? _scannedMealId;
  MobileScannerController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_scannedMealId != null) {
      return MealTraceResultScreen(
          mealId: _scannedMealId!,
          onReset: () => setState(() {
                _scannedMealId = null;
                _scanning = false;
                _controller?.dispose();
                _controller = null;
              }));
    }
    if (_scannedId != null) {
      return TraceResultScreen(
          batchId: _scannedId!,
          onReset: () => setState(() {
                _scannedId = null;
                _scanning = false;
                _controller?.dispose();
                _controller = null;
              }));
    }

    return Scaffold(
      backgroundColor: AppColors.night,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('GreenTrack',
                          style: AppTextStyles.poppins(28, weight: FontWeight.w700, color: Colors.white)),
                      const Spacer(),
                      const TraceModeBadge(label: 'Trace mode', accent: AppColors.glow),
                    ]),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.charcoal,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white12)),
                      child: Row(children: [
                        const Icon(Icons.search_rounded, color: Colors.white38),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text('Search farm, meal, batch code...',
                                style: AppTextStyles.sans(14,
                                    color: Colors.white54))),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    Text('Choose Your Trace',
                        style: AppTextStyles.poppins(22, weight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 112,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _TraceRoleCard(
                              icon: Icons.shopping_bag_outlined,
                              title: 'Shopper',
                              subtitle: 'Package origin'),
                          _TraceRoleCard(
                              icon: Icons.restaurant_outlined,
                              title: 'Chef',
                              subtitle: 'Kitchen freshness'),
                          _TraceRoleCard(
                              icon: Icons.local_dining_outlined,
                              title: 'Diner',
                              subtitle: 'Meal nutrients'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                child: Column(children: [
                  const Spacer(),
                  _scanning && _controller != null
                      ? QrDetector(
                          controller: _controller!,
                          onCode: _onCodeDetected,
                          child: LiveScanFrame(
                              controller: _controller!, accent: AppColors.glow),
                        )
                      : const DarkScanFrame(accent: AppColors.glow),
                  const SizedBox(height: 26),
                  Text(_scanning ? 'Point the camera at a QR code' : 'Scan the produce QR',
                      style: AppTextStyles.poppins(24, weight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                      'Open farm source, safety interval, transit timeline, and nutrition details from one code.',
                      style: AppTextStyles.sans(13,
                          color: Colors.white54, height: 1.35),
                      textAlign: TextAlign.center),
                  const Spacer(),
                  ElevatedButton.icon(
                      onPressed: _scanning ? _stopScan : _startScan,
                      icon: Icon(_scanning
                          ? Icons.close_rounded
                          : Icons.qr_code_scanner_rounded),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.glow,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18))),
                      label: Text(_scanning ? 'Stop Scanning' : 'Scan QR Code',
                          style: AppTextStyles.sans(16,
                              weight: FontWeight.w800, color: Colors.white))),
                  const SizedBox(height: 12),
                  OutlinedButton(
                      onPressed: _demoScan,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48)),
                      child: Text('Use demo trace',
                          style:
                              AppTextStyles.sans(14, color: Colors.white70))),
                  const SizedBox(height: 10),
                  TextButton.icon(
                      onPressed: _enterCodeManually,
                      icon: const Icon(Icons.keyboard_alt_outlined,
                          color: Colors.white54, size: 18),
                      label: Text('Enter batch ID manually',
                          style:
                              AppTextStyles.sans(13, color: Colors.white54))),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startScan() {
    setState(() {
      _scanning = true;
      _controller = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates);
    });
  }

  void _stopScan() {
    setState(() {
      _scanning = false;
      _controller?.dispose();
      _controller = null;
    });
  }

  void _onCodeDetected(String raw) {
    // Codes are printed as 'greentrack://batch/<id>' (see CropBatch.qrCodeData)
    // or 'greentrack://meal/<id>' (see Meal.qrCodeData) — fall back to
    // treating it as a batch id if it isn't one of ours, so a plain batch
    // id still resolves.
    _controller?.stop();
    if (raw.startsWith('greentrack://meal/')) {
      setState(() => _scannedMealId = raw.substring('greentrack://meal/'.length));
      return;
    }
    final id = raw.startsWith('greentrack://batch/')
        ? raw.substring('greentrack://batch/'.length)
        : raw;
    setState(() => _scannedId = id);
  }

  void _demoScan() {
    _controller?.dispose();
    setState(() {
      _scanning = false;
      _controller = null;
      _scannedId = 'demo-batch-001';
    });
  }

  Future<void> _enterCodeManually() async {
    final ctrl = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: const Text('Enter batch or meal ID', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. batch_001 or a code from the label',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.glow)),
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(ctrl.text.trim()),
              style: FilledButton.styleFrom(backgroundColor: AppColors.glow),
              child: const Text('Look up')),
        ],
      ),
    );
    if (id == null || id.isEmpty || !mounted) return;
    _controller?.dispose();
    setState(() {
      _scanning = false;
      _controller = null;
    });
    // A manually-typed ID could be either — try batch first (the more
    // common case), then meal, before falling back to the batch "not
    // found" screen.
    final batchResult =
        await ref.read(batchServiceProvider).traceByQr(id);
    if (!mounted) return;
    if (batchResult != null) {
      setState(() => _scannedId = id);
      return;
    }
    final meal = await ref.read(mealServiceProvider).getMeal(id);
    if (!mounted) return;
    if (meal != null) {
      setState(() => _scannedMealId = id);
    } else {
      setState(() => _scannedId = id); // shows the "not found" state
    }
  }
}

class _TraceRoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TraceRoleCard(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glow.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: AppColors.glow.withValues(alpha: 0.14), blurRadius: 18)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.sprout),
          const Spacer(),
          Text(title,
              style: AppTextStyles.sans(13,
                  color: Colors.white, weight: FontWeight.w800)),
          Text(subtitle, style: AppTextStyles.sans(10, color: Colors.white54)),
        ],
      ),
    );
  }
}

// ── TRACE RESULT SCREEN ───────────────────────────────
// Shown after successful QR scan — works for shopper, chef, diner

class TraceResultScreen extends ConsumerWidget {
  final String batchId;
  final VoidCallback onReset;

  const TraceResultScreen(
      {super.key, required this.batchId, required this.onReset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(traceResultProvider(batchId));

    // Save this as a real scan the moment it resolves — this is what
    // "Recent Scans" on the shopper/diner dashboard reads from, so it only
    // ever shows things the user actually scanned.
    ref.listen(traceResultProvider(batchId), (previous, next) {
      final result = next.value;
      if (result != null) {
        ref.read(scanHistoryProvider.notifier).recordBatch(result);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.clay,
      body: resultAsync.when(
        loading: () => Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Tracing batch...', style: AppTextStyles.sans(14)),
        ])),
        error: (e, _) => _NotFound(onReset: onReset),
        data: (result) => result == null
            ? _NotFound(onReset: onReset)
            : _TraceView(result: result, onReset: onReset),
      ),
    );
  }
}

// No share_plus/health-tracker integration exists in this project — these
// give real, honest feedback (a working clipboard copy, and a clear "not
// available yet" message) instead of a silent no-op button that looks
// broken when tapped.
Future<void> _shareTraceSummary(BuildContext context, BatchTraceResult result) async {
  final summary = '${result.cropName} (${result.variety})\n'
      'Farm: ${result.farmName} — ${result.farmerName}\n'
      'Harvested: ${result.harvestedAt.toLocal()}\n'
      'Batch: ${result.batchId}';
  await Clipboard.setData(ClipboardData(text: summary));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trace details copied — paste them anywhere to share.')));
  }
}

void _notifyFitnessTrackerUnavailable(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Fitness tracker logging isn\'t available yet.')));
}

class _TraceView extends StatelessWidget {
  final BatchTraceResult result;
  final VoidCallback onReset;
  const _TraceView({required this.result, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final hoursAgo = DateTime.now().difference(result.harvestedAt).inHours;
    final freshLabel = hoursAgo < 24
        ? 'Harvested ${hoursAgo}h ago'
        : 'Harvested ${DateTime.now().difference(result.harvestedAt).inDays} days ago';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 200,
          backgroundColor: AppColors.canopy,
          leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onReset),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: result.isOrganicCertified
                                ? AppColors.harvest.withValues(alpha: 0.25)
                                : Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: result.isOrganicCertified
                                    ? AppColors.harvest
                                    : Colors.white30)),
                        child: Row(children: [
                          Text(result.isOrganicCertified ? '🌿 ' : '🌱 ',
                              style: const TextStyle(fontSize: 12)),
                          Text(
                              result.isOrganicCertified
                                  ? 'Certified Organic'
                                  : result.farmingMethod.label,
                              style: AppTextStyles.sans(11,
                                  color: result.isOrganicCertified
                                      ? AppColors.harvest
                                      : Colors.white70,
                                  weight: FontWeight.w700)),
                        ])),
                    const SizedBox(width: 8),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: result.phiCompliant
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                            result.phiCompliant
                                ? '✅ PHI Safe'
                                : '⚠️ PHI Warning',
                            style: AppTextStyles.sans(11,
                                color: Colors.white, weight: FontWeight.w700))),
                  ]),
                  const SizedBox(height: 10),
                  Text(result.cropName,
                      style: AppTextStyles.poppins(28, weight: FontWeight.w700, color: Colors.white)),
                  Text('${result.variety} · ${result.farmName}',
                      style: AppTextStyles.sans(13, color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Freshness card
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: hoursAgo < 48
                          ? AppColors.harvest.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: hoursAgo < 48
                              ? AppColors.harvest.withValues(alpha: 0.3)
                              : AppColors.border)),
                  child: Row(children: [
                    Text(
                        hoursAgo < 24
                            ? '🟢'
                            : hoursAgo < 72
                                ? '🟡'
                                : '🔴',
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Freshness Verified',
                              style: AppTextStyles.sans(14,
                                  weight: FontWeight.w700,
                                  color: AppColors.soil)),
                          Text(freshLabel,
                              style: AppTextStyles.sans(13,
                                  color: hoursAgo < 24
                                      ? AppColors.canopy
                                      : AppColors.slate)),
                          Text(
                              DateFormat('d MMM yyyy · HH:mm')
                                  .format(result.harvestedAt),
                              style: AppTextStyles.sans(11,
                                  color: AppColors.slateLight)),
                        ])),
                  ])),
              const SizedBox(height: 14),

              // Farm info card
              _InfoCard(icon: '🏡', title: 'Source Farm', children: [
                _InfoRow('Farm', result.farmName),
                _InfoRow('Farmer', result.farmerName),
                _InfoRow('Location', result.farmLocation),
                _InfoRow('Method', result.farmingMethod.label),
                if (result.certificationNumber != null)
                  _InfoRow('Cert #', result.certificationNumber!),
              ]),
              const SizedBox(height: 14),

              // Yield card
              _InfoCard(icon: '⚖️', title: 'Batch Details', children: [
                _InfoRow('Batch ID', batchId.substring(0, 8).toUpperCase()),
                _InfoRow(
                    'Yield', '${result.actualYieldKg.toStringAsFixed(1)} kg'),
                _InfoRow('PHI Compliance',
                    result.phiCompliant ? 'Compliant ✅' : 'Warning ⚠️'),
              ]),
              const SizedBox(height: 14),

              // Transit chain — the signature element
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Farm-to-Table Journey',
                          style: AppTextStyles.poppins(18, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Full chain of custody',
                          style: AppTextStyles.sans(12,
                              color: AppColors.slateLight)),
                      const SizedBox(height: 16),
                      ...result.transitEvents.asMap().entries.map((e) {
                        final isLast = e.key == result.transitEvents.length - 1;
                        return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(children: [
                                Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                        color: isLast
                                            ? AppColors.canopy
                                            : AppColors.mist,
                                        shape: BoxShape.circle),
                                    child: Center(
                                        child: Text(e.value.emoji,
                                            style: const TextStyle(
                                                fontSize: 16)))),
                                if (!isLast)
                                  Container(
                                      width: 2,
                                      height: 36,
                                      color: AppColors.border),
                              ]),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Padding(
                                padding:
                                    EdgeInsets.only(bottom: isLast ? 0 : 24),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(e.value.description,
                                          style: AppTextStyles.sans(13,
                                              weight: FontWeight.w600,
                                              color: AppColors.soil)),
                                      Text(e.value.location,
                                          style: AppTextStyles.sans(11,
                                              color: AppColors.slate)),
                                      Text(
                                          DateFormat('d MMM yyyy · HH:mm')
                                              .format(e.value.timestamp),
                                          style: AppTextStyles.sans(10,
                                              color: AppColors.slateLight)),
                                    ]),
                              )),
                            ]);
                      }),
                    ]),
              ),
              const SizedBox(height: 14),

              // Nutrition (if available)
              if (result.nutrition != null) ...[
                _NutritionCard(nutrition: result.nutrition!),
                const SizedBox(height: 14),
              ],

              // Actions
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => _shareTraceSummary(context, result),
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Share'))),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: () => _notifyFitnessTrackerUnavailable(context),
                        icon: const Icon(Icons.fitness_center,
                            size: 18, color: Colors.white),
                        label: const Text('Log Nutrients'))),
              ]),
              const SizedBox(height: 20),

              TextButton(
                  onPressed: onReset, child: const Text('← Scan another code')),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  String get batchId => result.batchId;
}

class _InfoCard extends StatelessWidget {
  final String icon, title;
  final List<Widget> children;
  const _InfoCard(
      {required this.icon, required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(title,
                style: AppTextStyles.sans(14,
                    weight: FontWeight.w700, color: AppColors.soil)),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: AppTextStyles.sans(12, color: AppColors.slateLight))),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.sans(13,
                      weight: FontWeight.w600, color: AppColors.soil))),
        ]),
      );
}

class _NutritionCard extends StatelessWidget {
  final NutritionInfo nutrition;
  const _NutritionCard({required this.nutrition});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            AnimatedEmoji('🥗', size: 18),
            const SizedBox(width: 8),
            Text('Nutritional Info',
                style: AppTextStyles.sans(14,
                    weight: FontWeight.w700, color: AppColors.soil)),
            const Spacer(),
            Text('per 100g',
                style: AppTextStyles.sans(11, color: AppColors.slateLight)),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _NutriBadge('Calories', '${nutrition.caloriesPer100g.toInt()} kcal',
                AppColors.harvest),
            _NutriBadge('Protein', '${nutrition.proteinG.toStringAsFixed(1)}g',
                AppColors.canopy),
            _NutriBadge('Carbs', '${nutrition.carbsG.toStringAsFixed(1)}g',
                AppColors.leaf),
            _NutriBadge('Fibre', '${nutrition.fibreG.toStringAsFixed(1)}g',
                AppColors.sprout),
            _NutriBadge(
                'Fat', '${nutrition.fatG.toStringAsFixed(1)}g', AppColors.bark),
            ...nutrition.vitamins.entries.map((e) => _NutriBadge(e.key,
                '${e.value.toStringAsFixed(1)}mg', const Color(0xFF6B3FA0))),
          ]),
          const SizedBox(height: 12),
          ElevatedButton.icon(
              onPressed: () => _notifyFitnessTrackerUnavailable(context),
              icon: const Icon(Icons.fitness_center,
                  size: 16, color: Colors.white),
              label: const Text('Log to Fitness Tracker'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44))),
        ]),
      );
}

class _NutriBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _NutriBadge(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: AppTextStyles.mono(13, color: color)),
          Text(label,
              style: AppTextStyles.sans(10, color: AppColors.slateLight)),
        ]),
      );
}

class _NotFound extends StatelessWidget {
  final VoidCallback onReset;
  const _NotFound({required this.onReset});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.clay,
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedEmoji('❓', size: 56),
            const SizedBox(height: 20),
            Text('Batch Not Found', style: AppTextStyles.poppins(24, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
                'This QR code doesn\'t match any GreenTrack batch. '
                'Make sure the produce has been registered on the platform.',
                style: AppTextStyles.sans(14, color: AppColors.slate),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: onReset, child: const Text('Scan Again')),
          ]),
        )),
      );
}

// ── MEAL TRACE RESULT SCREEN ─────────────────────────
// Shown after scanning a chef-built meal's QR code (printed from the
// Chef's meal detail screen) — mirrors TraceResultScreen's structure but
// for a Meal instead of a CropBatch.

class MealTraceResultScreen extends ConsumerWidget {
  final String mealId;
  final VoidCallback onReset;

  const MealTraceResultScreen(
      {super.key, required this.mealId, required this.onReset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealAsync = ref.watch(mealTraceResultProvider(mealId));

    // Same principle as the batch trace screen: a real scan gets recorded
    // into "Recent Scans" the moment it actually resolves.
    ref.listen(mealTraceResultProvider(mealId), (previous, next) {
      final meal = next.value;
      if (meal != null) {
        ref.read(scanHistoryProvider.notifier).recordMeal(meal);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.clay,
      body: mealAsync.when(
        loading: () => Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Tracing meal...', style: AppTextStyles.sans(14)),
        ])),
        error: (e, _) => _MealNotFound(onReset: onReset),
        data: (meal) => meal == null
            ? _MealNotFound(onReset: onReset)
            : _MealTraceView(meal: meal, onReset: onReset),
      ),
    );
  }
}

class _MealTraceView extends StatelessWidget {
  final Meal meal;
  final VoidCallback onReset;
  const _MealTraceView({required this.meal, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final confirmed = meal.allergens.where((a) => a.contains).toList();
    final mayContain = meal.allergens.where((a) => a.mayContain).toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 220,
          backgroundColor: AppColors.canopy,
          leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onReset),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              if (meal.photoUrl != null)
                Image.network(meal.photoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                            gradient: AppColors.heroGradient)))
              else
                Container(
                    decoration:
                        const BoxDecoration(gradient: AppColors.heroGradient)),
              // Scrim so the title stays legible over a photo
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white30)),
                        child: Text('🍽️ ${meal.restaurantName}',
                            style: AppTextStyles.sans(11,
                                color: Colors.white70,
                                weight: FontWeight.w700))),
                    const SizedBox(height: 10),
                    Text(meal.name,
                        style: AppTextStyles.poppins(28, weight: FontWeight.w700, color: Colors.white)),
                    if (meal.description != null &&
                        meal.description!.isNotEmpty)
                      Text(meal.description!,
                          style: AppTextStyles.sans(13, color: Colors.white70)),
                  ],
                ),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Ingredients / sourcing card — the actual traceability part
              _InfoCard(icon: '🌱', title: 'Sourced From', children: [
                if (meal.ingredients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('No ingredients listed for this meal.',
                        style: AppTextStyles.sans(13,
                            color: AppColors.slateLight)),
                  )
                else
                  ...meal.ingredients.map((i) => _InfoRow(
                      i.cropName, '${i.quantityGrams.toStringAsFixed(0)} g')),
              ]),
              const SizedBox(height: 14),

              _MealNutritionCard(nutrition: meal.nutrition),
              const SizedBox(height: 14),

              // Allergens — always shown, even when there are none, since
              // "nothing declared" is itself food-safety-relevant info.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('⚠️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('Allergens',
                        style: AppTextStyles.sans(14,
                            weight: FontWeight.w700, color: AppColors.soil)),
                  ]),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (confirmed.isEmpty && mayContain.isEmpty)
                    Text('No allergens declared',
                        style: AppTextStyles.sans(13,
                            color: AppColors.slateLight)),
                  if (confirmed.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                          'Contains: ${confirmed.map((a) => a.allergenId.label).join(", ")}',
                          style: AppTextStyles.sans(13,
                              weight: FontWeight.w600, color: Colors.red[700])),
                    ),
                  if (mayContain.isNotEmpty)
                    Text(
                        'May contain: ${mayContain.map((a) => a.allergenId.label).join(", ")}',
                        style: AppTextStyles.sans(13,
                            weight: FontWeight.w600,
                            color: Colors.orange[800])),
                  if (meal.otherAllergenNote != null &&
                      meal.otherAllergenNote!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Note: ${meal.otherAllergenNote}',
                        style: AppTextStyles.sans(12,
                            color: AppColors.slateLight)),
                  ],
                ]),
              ),
              const SizedBox(height: 20),

              TextButton(
                  onPressed: onReset, child: const Text('← Scan another code')),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }
}

class _MealNutritionCard extends StatelessWidget {
  final MealNutritionSnapshot nutrition;
  const _MealNutritionCard({required this.nutrition});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const AnimatedEmoji('🥗', size: 18),
            const SizedBox(width: 8),
            Text('Nutrition (whole meal)',
                style: AppTextStyles.sans(14,
                    weight: FontWeight.w700, color: AppColors.soil)),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _NutriBadge('Calories', '${nutrition.calories.toStringAsFixed(0)} kcal',
                AppColors.harvest),
            _NutriBadge('Protein', '${nutrition.proteinG.toStringAsFixed(1)}g',
                AppColors.canopy),
            _NutriBadge(
                'Carbs', '${nutrition.carbsG.toStringAsFixed(1)}g', AppColors.leaf),
            _NutriBadge(
                'Fat', '${nutrition.fatG.toStringAsFixed(1)}g', AppColors.bark),
            _NutriBadge('Fibre', '${nutrition.fiberG.toStringAsFixed(1)}g',
                AppColors.sprout),
          ]),
        ]),
      );
}

class _MealNotFound extends StatelessWidget {
  final VoidCallback onReset;
  const _MealNotFound({required this.onReset});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.clay,
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const AnimatedEmoji('❓', size: 56),
            const SizedBox(height: 20),
            Text('Meal Not Found', style: AppTextStyles.poppins(24, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
                'This QR code doesn\'t match any GreenTrack meal. '
                'Make sure the dish has been added to the menu on the platform.',
                style: AppTextStyles.sans(14, color: AppColors.slate),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: onReset, child: const Text('Scan Again')),
          ]),
        )),
      );
}
