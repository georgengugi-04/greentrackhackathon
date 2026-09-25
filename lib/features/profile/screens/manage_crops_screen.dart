import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';

class ManageCropsScreen extends ConsumerWidget {
  const ManageCropsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(farmerBatchesProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: const Text('Manage Crops')),
      body: batchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.leaf)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load your crops: $e', textAlign: TextAlign.center),
          ),
        ),
        data: (batches) {
          if (batches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.eco_outlined, size: 40, color: AppColors.slateLight),
                  const SizedBox(height: 10),
                  Text('You don\'t have any crop batches yet.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(13, color: AppColors.textSecondaryOf(context))),
                ]),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.red),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Deleting a crop batch is permanent — it also removes its '
                    'custody history and breaks any QR codes already printed for it.',
                    style: AppTextStyles.body(11.5, color: AppColors.red),
                  )),
                ]),
              ),
              ...batches.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CropDeleteTile(batch: b),
              )),
            ],
          );
        },
      ),
    );
  }
}

class _CropDeleteTile extends ConsumerStatefulWidget {
  final CropBatch batch;
  const _CropDeleteTile({required this.batch});

  @override
  ConsumerState<_CropDeleteTile> createState() => _CropDeleteTileState();
}

class _CropDeleteTileState extends ConsumerState<_CropDeleteTile> {
  bool _deleting = false;

  Future<void> _confirmDelete(BuildContext context) async {
    final batch = widget.batch;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${batch.cropName}?'),
        content: const Text(
            'This permanently removes the batch and its custody history. '
            'This can\'t be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(batchServiceProvider).deleteBatch(batch.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${batch.cropName} deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete this batch: $e')),
        );
      }
    }
    // On success this tile's batch disappears from farmerBatchesProvider's
    // stream on its own — no need to manually remove it from a local list.
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.batch;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppColors.leaf.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.eco_outlined, color: AppColors.leaf),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.cropName,
              style: AppTextStyles.body(14.5, weight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context))),
          const SizedBox(height: 2),
          Text('${b.plotName ?? 'Unplotted'} · ${b.stage.label}',
              style: AppTextStyles.body(11.5, color: AppColors.textSecondaryOf(context))),
        ])),
        _deleting
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.red))
            : IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                onPressed: () => _confirmDelete(context),
              ),
      ]),
    );
  }
}
