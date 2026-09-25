import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';

class ChefVerifyBatchScreen extends StatefulWidget {
  const ChefVerifyBatchScreen({super.key});

  @override
  State<ChefVerifyBatchScreen> createState() => _ChefVerifyBatchScreenState();
}

class _ChefVerifyBatchScreenState extends State<ChefVerifyBatchScreen> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Incoming Batch')),
      body: _scanned
          ? _VerificationResult(batch: MockData.sampleBatch)
          : _ScanPrompt(onSimulate: () => setState(() => _scanned = true)),
    );
  }
}

class _ScanPrompt extends StatelessWidget {
  final VoidCallback onSimulate;
  const _ScanPrompt({required this.onSimulate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                color: AppColors.chefAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.chefAccent.withValues(alpha: 0.3), width: 2),
              ),
              child: const Center(child: Icon(Icons.qr_code_scanner, size: 80, color: AppColors.chefAccent)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Scan the crate QR code', style: AppTextStyles.h2),
            Text('to verify farm origin and certification', style: AppTextStyles.bodyMuted),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              icon: const Icon(Icons.flash_on),
              label: const Text('Simulate Scan'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.chefAccent),
              onPressed: onSimulate,
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationResult extends StatelessWidget {
  final CropBatch batch;
  const _VerificationResult({required this.batch});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.leaf.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Row(children: [
            const Icon(Icons.verified, color: AppColors.leaf, size: 32),
            const SizedBox(width: AppSpacing.md),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Batch Verified', style: AppTextStyles.h2),
              Text('Authentic GreenTrack batch', style: AppTextStyles.bodyMuted),
            ]),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        _Field('Crop', batch.cropName),
        _Field('Batch ID', batch.id),
        _Field('Farm Plot', batch.plotName ?? '—'),
        _Field('Harvested', batch.harvestedAt != null ? batch.harvestedAt.toString().split(' ').first : '—'),
        _Field('Weight', '${batch.verifiedWeightKg ?? "—"} kg'),
        _Field('Method', batch.farmingMethod.name),
        _Field('Organic', batch.organicCertified ? 'Certified ✓' : 'No'),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton.icon(
          icon: const Icon(Icons.inventory_2),
          label: const Text('Accept into Kitchen Inventory'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.chefAccent),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Flag this batch?'),
              content: const Text(
                  'This will mark the batch for review by the farm team before it can be accepted into inventory.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Batch flagged for review')),
                    );
                  },
                  child: const Text('Flag Issue',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ),
          child: const Text('Flag Issue'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label, value;
  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: AppColors.cardOf(context), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: AppColors.borderOf(context))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMuted),
          Text(value, style: AppTextStyles.body(14).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
