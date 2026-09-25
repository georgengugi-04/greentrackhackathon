import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/animated_emoji.dart';

class HarvestLogScreen extends ConsumerStatefulWidget {
  const HarvestLogScreen({super.key});
  @override
  ConsumerState<HarvestLogScreen> createState() => _HarvestLogScreenState();
}

class _HarvestLogScreenState extends ConsumerState<HarvestLogScreen> {
  CropBatch? _selectedBatch;
  double _actualKg = 10;
  bool _loading = false, _harvested = false;
  String? _batchId, _qrData;

  @override
  Widget build(BuildContext context) {
    final readyBatches = ref.watch(readyToHarvestProvider);
    final phiLocked = ref.watch(phiLockedBatchesProvider);

    if (_harvested && _qrData != null) {
      return _QrSuccess(
          qrData: _qrData!,
          batchId: _batchId!,
          cropName: _selectedBatch?.cropName ?? '',
          actualKg: _actualKg,
          onDone: () => context.pop());
    }

    return Scaffold(
      backgroundColor: AppColors.farmerSurfaceOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
          title: Text('Log Harvest', style: AppTextStyles.poppins(20, weight: FontWeight.w700)),
          leading: IconButton(
              icon: const Icon(Icons.close), onPressed: () => context.pop())),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // PHI locked warning
        if (phiLocked.isNotEmpty) ...[
          Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.alert.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.alert.withValues(alpha: 0.3))),
              child: Row(children: [
                AnimatedEmoji('🔒', size: 22),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        '${phiLocked.length} batch${phiLocked.length > 1 ? 'es' : ''} locked due to active PHI: '
                        '${phiLocked.map((b) => '${b.cropName} (${b.phiDaysRemaining}d remaining)').join(', ')}',
                        style: AppTextStyles.sans(12, color: AppColors.alert))),
              ])),
          const SizedBox(height: 16),
        ],

        Text('Select batch to harvest',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 10),
        if (readyBatches.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.mist, borderRadius: BorderRadius.circular(12)),
            child: Text(
                'No batches are ready to harvest yet. A batch shows up here once '
                'its stage reaches "Ready to Harvest" and any pest-treatment PHI '
                'window has cleared.',
                style: AppTextStyles.sans(12, color: AppColors.slate)),
          ),
        ...readyBatches.map((batch) {
          final locked = batch.harvestLockedByPHI;
          final selected = _selectedBatch?.id == batch.id;
          return GestureDetector(
            onTap: locked ? null : () => setState(() => _selectedBatch = batch),
            child: Opacity(
              opacity: locked ? 0.5 : 1,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: selected ? AppColors.mist : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? AppColors.leaf : AppColors.borderOf(context),
                        width: selected ? 2 : 1)),
                child: Row(children: [
                  // Crop photo — falls back to the stage emoji when the
                  // batch has no photo attached.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: batch.photoUrl == null
                        ? Container(
                            width: 44, height: 44,
                            color: AppColors.mist,
                            alignment: Alignment.center,
                            child: Text(batch.stage.emoji,
                                style: const TextStyle(fontSize: 22)),
                          )
                        : CachedNetworkImage(
                            imageUrl: batch.photoUrl!,
                            width: 44, height: 44, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                width: 44, height: 44, color: AppColors.mist),
                            errorWidget: (_, __, ___) => Container(
                                width: 44, height: 44, color: AppColors.mist,
                                alignment: Alignment.center,
                                child: Text(batch.stage.emoji,
                                    style: const TextStyle(fontSize: 22))),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(batch.cropName,
                            style: AppTextStyles.sans(14,
                                weight: FontWeight.w700)),
                        Text(
                            '${batch.plotName ?? '${batch.plotLocation.lat.toStringAsFixed(3)}, ${batch.plotLocation.lng.toStringAsFixed(3)}'} · ${batch.farmingMethod.label}',
                            style: AppTextStyles.sans(11,
                                color: AppColors.slateLight)),
                        Text('Expected: ${batch.estimatedYieldKg}kg',
                            style:
                                AppTextStyles.sans(11, color: AppColors.slate)),
                      ])),
                  if (locked)
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.alert,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('LOCKED\n${batch.phiDaysRemaining}d',
                            style: AppTextStyles.sans(9,
                                color: Colors.white, weight: FontWeight.w700),
                            textAlign: TextAlign.center))
                  else if (selected)
                    const Icon(Icons.check_circle, color: AppColors.leaf),
                ]),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        if (_selectedBatch != null) ...[
          Text('Actual yield harvested',
              style: Theme.of(context).textTheme.labelMedium),
          Slider(
              value: _actualKg,
              min: 0.5,
              max: 500,
              divisions: 99,
              label: '${_actualKg.toStringAsFixed(1)}kg',
              activeColor: AppColors.leaf,
              onChanged: (v) => setState(() => _actualKg = v)),
          Center(
              child: Text('${_actualKg.toStringAsFixed(1)} kg',
                  style: AppTextStyles.mono(26))),
          const SizedBox(height: 8),
          Center(
              child: Text('Estimated was ${_selectedBatch!.estimatedYieldKg}kg',
                  style: AppTextStyles.sans(12, color: AppColors.slateLight))),
          const SizedBox(height: 28),

          // QR explanation
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                AnimatedEmoji('📱', size: 28),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('QR Code Generated',
                          style: AppTextStyles.sans(13,
                              weight: FontWeight.w700,
                              color: AppColors.canopy)),
                      Text(
                          'Tapping "Log Harvest" will finalise this batch and generate a unique QR code. Print and attach it to your delivery crates.',
                          style:
                              AppTextStyles.sans(12, color: AppColors.slate)),
                    ])),
              ])),
          const SizedBox(height: 20),

          ElevatedButton(
              onPressed: _loading ? null : _logHarvest,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppColors.canopy),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedEmoji('🌾 ', size: 20),
                      Text('Log Harvest & Generate QR',
                          style: AppTextStyles.sans(15,
                              color: Colors.white, weight: FontWeight.w600)),
                    ])),
        ],
        const SizedBox(height: 80),
      ]),
    );
  }

  Future<void> _logHarvest() async {
    if (_selectedBatch == null) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(batchServiceProvider)
          .logHarvest(batchId: _selectedBatch!.id, actualYieldKg: _actualKg);
      setState(() {
        _harvested = true;
        _batchId = _selectedBatch!.id;
        _qrData = _selectedBatch!.qrCodeData;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _QrSuccess extends StatefulWidget {
  final String qrData, batchId, cropName;
  final double actualKg;
  final VoidCallback onDone;

  const _QrSuccess(
      {required this.qrData,
      required this.batchId,
      required this.cropName,
      required this.actualKg,
      required this.onDone});

  @override
  State<_QrSuccess> createState() => _QrSuccessState();
}

class _QrSuccessState extends State<_QrSuccess> {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.farmerSurfaceOf(context),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              const Spacer(),
              AnimatedEmoji('✅', size: 64),
              const SizedBox(height: 20),
              Text('Harvest Logged!',
                  style: AppTextStyles.poppins(28, weight: FontWeight.w700, color: AppColors.soil)),
              const SizedBox(height: 8),
              Text('${widget.cropName} · ${widget.actualKg.toStringAsFixed(1)}kg',
                  style: AppTextStyles.sans(15, color: AppColors.slate)),
              const SizedBox(height: 36),

              // QR Code
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: AppColors.cardOf(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderOf(context)),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.soil.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4))
                      ]),
                  child: Column(children: [
                    QrImageView(
                        data: widget.qrData,
                        version: QrVersions.auto,
                        size: 200,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF1A2E1A)),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF1A2E1A))),
                    const SizedBox(height: 12),
                    Text('BATCH ID',
                        style: AppTextStyles.sans(10,
                            color: AppColors.slateLight,
                            weight: FontWeight.w700)),
                    Text(widget.batchId.substring(0, 8).toUpperCase(),
                        style: AppTextStyles.mono(14)),
                    const SizedBox(height: 8),
                    Text(
                        DateFormat('d MMM yyyy · HH:mm').format(DateTime.now()),
                        style: AppTextStyles.sans(11,
                            color: AppColors.slateLight)),
                  ])),
              const SizedBox(height: 24),

              Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                      '📦 Print this QR code and stick it directly onto your delivery crates or packages. '
                      'Buyers, chefs, and diners can scan it to verify origin, freshness, and organic certification.',
                      style: AppTextStyles.sans(12, color: AppColors.slate),
                      textAlign: TextAlign.center)),
              const Spacer(),

              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: _shareQrDetails,
                        child: const Text('Share QR Code'))),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                        onPressed: widget.onDone, child: const Text('Done'))),
              ]),
            ]),
          ),
        ),
      );

  Future<void> _shareQrDetails() async {
    // No share_plus/printing dependency in this project yet, so this
    // copies a shareable summary to the clipboard rather than silently
    // doing nothing (the previous onPressed was an empty no-op — tapping
    // the button never did anything at all, with no feedback either way).
    final summary = '${widget.cropName} — ${widget.actualKg.toStringAsFixed(1)}kg\n'
        'Batch ${widget.batchId.substring(0, 8).toUpperCase()}\n'
        '${widget.qrData}';
    await Clipboard.setData(ClipboardData(text: summary));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Batch details copied — paste them anywhere to share.')));
    }
  }
}
