import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/animated_emoji.dart';

class IrrigationScreen extends ConsumerStatefulWidget {
  const IrrigationScreen({super.key});
  @override
  ConsumerState<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends ConsumerState<IrrigationScreen> {
  CropBatch? _selectedBatch;
  IrrigationSource _source = IrrigationSource.borehole;
  String _method = 'Drip irrigation';
  DateTime _nextScheduled = DateTime.now().add(const Duration(days: 2));
  bool _loading = false;

  final _methods = [
    'Drip irrigation',
    'Sprinkler',
    'Hand watering',
    'Flood',
    'Furrow'
  ];

  @override
  Widget build(BuildContext context) {
    final batches = ref.watch(activeBatchesProvider);

    return Scaffold(
      backgroundColor: AppColors.farmerSurfaceOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Log Irrigation', style: AppTextStyles.poppins(20, weight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => context.pop()),
        actions: [
          TextButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.leaf))
                  : Text('Save',
                      style: AppTextStyles.sans(15,
                          color: AppColors.leaf, weight: FontWeight.w700))),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            AnimatedEmoji('💧', size: 22),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    'Log when a batch is watered. GreenTrack tracks conditions and lets you know when it\'s due — no need to measure or time it yourself.',
                    style: AppTextStyles.sans(12,
                        color: const Color(0xFF1565C0)))),
          ]),
        ),
        const SizedBox(height: 20),

        Text('Which batch?', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 10),
        SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: batches.length,
              itemBuilder: (ctx, i) {
                final b = batches[i];
                final sel = _selectedBatch?.id == b.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBatch = b),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: sel ? AppColors.mist : Colors.white,
                        border: Border.all(
                            color: sel ? AppColors.leaf : AppColors.borderOf(context),
                            width: sel ? 2 : 1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedEmoji('🌿', size: 22),
                          const SizedBox(height: 4),
                          Text(b.cropName,
                              style: AppTextStyles.sans(10,
                                  weight: FontWeight.w600),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ]),
                  ),
                );
              },
            )),
        const SizedBox(height: 20),

        Text('Water source', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        DropdownButtonFormField<IrrigationSource>(
            initialValue: _source,
            decoration: const InputDecoration(),
            items: IrrigationSource.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (v) => setState(() => _source = v!)),
        const SizedBox(height: 16),

        Text('Irrigation method',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(),
            items: _methods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _method = v!)),
        const SizedBox(height: 20),

        Text('Schedule next irrigation',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
                context: context,
                initialDate: _nextScheduled,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)));
            if (d != null) setState(() => _nextScheduled = d);
          },
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                  color: AppColors.cardOf(context),
                  border: Border.all(color: AppColors.borderOf(context)),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.schedule_outlined,
                    size: 18, color: AppColors.slateLight),
                const SizedBox(width: 10),
                Text(
                    '${_nextScheduled.day}/${_nextScheduled.month}/${_nextScheduled.year}',
                    style: AppTextStyles.sans(14)),
                const Spacer(),
                Text('Next irrigation',
                    style: AppTextStyles.sans(11, color: AppColors.slateLight)),
              ])),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Future<void> _save() async {
    if (_selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a batch.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(batchServiceProvider).logIrrigation(
          batchId: _selectedBatch!.id,
          source: _source,
          method: _method,
          nextScheduled: _nextScheduled);
      if (!mounted) return;
      setState(() => _loading = false);

      final batch = _selectedBatch!;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.water_drop, color: AppColors.consumerAccent, size: 40),
          title: const Text('Irrigated!'),
          content: Text('${batch.cropName} was watered via $_method. '
              'Next scheduled for ${_nextScheduled.day}/${_nextScheduled.month}.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (!mounted) return;
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
