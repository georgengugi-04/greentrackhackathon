import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/animated_emoji.dart';

class PestScreen extends ConsumerStatefulWidget {
  const PestScreen({super.key});
  @override
  ConsumerState<PestScreen> createState() => _PestScreenState();
}

class _PestScreenState extends ConsumerState<PestScreen> {
  CropBatch? _selectedBatch;
  bool _diagnosing = false, _diagnosed = false, _loading = false;
  String? _pestName, _diagnosis, _pesticide, _applicationMethod;
  int _phiDays = 7;

  // Simulated pest database diagnoses
  final _pestDb = [
    {
      'pest': 'Aphids',
      'diagnosis':
          'Aphid infestation detected. Colonies visible on leaf undersides.',
      'pesticide': 'Neem Oil Spray (0.5%)',
      'method': 'Spray on affected leaves, morning application',
      'phi': 1
    },
    {
      'pest': 'Spider Mites',
      'diagnosis':
          'Spider mite damage detected. Fine webbing and stippling on leaves.',
      'pesticide': 'Abamectin 1.8% EC',
      'method': 'Full coverage spray, avoid high temperatures',
      'phi': 7
    },
    {
      'pest': 'Whitefly',
      'diagnosis':
          'Whitefly infestation confirmed. Adults visible on underside of leaves.',
      'pesticide': 'Imidacloprid 200SL',
      'method': 'Soil drench or spray application',
      'phi': 14
    },
  ];

  @override
  Widget build(BuildContext context) {
    final batches = ref.watch(activeBatchesProvider);

    return Scaffold(
      backgroundColor: AppColors.farmerSurfaceOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
          title: Text('Pest Diagnosis', style: AppTextStyles.poppins(20, weight: FontWeight.w700)),
          leading: IconButton(
              icon: const Icon(Icons.close), onPressed: () => context.pop())),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // Camera prompt
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1A2E1A), Color(0xFF2D5A27)]),
              borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            AnimatedEmoji('🔬', size: 40),
            const SizedBox(height: 12),
            Text('AI Pest Diagnosis',
                style: AppTextStyles.poppins(20, weight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 6),
            Text(
                'Take a photo of affected leaves. Our integrated database will identify the pest and recommend the right treatment.',
                style: AppTextStyles.sans(13, color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: _takeCameraPhoto,
                      icon: const Icon(Icons.camera_alt_outlined,
                          color: Colors.white),
                      label: const Text('Camera',
                          style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54)))),
              const SizedBox(width: 10),
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: _takeCameraPhoto,
                      icon: const Icon(Icons.photo_library_outlined,
                          color: Colors.white),
                      label: const Text('Gallery',
                          style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54)))),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        if (_diagnosing) ...[
          Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppColors.cardOf(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderOf(context))),
              child: Column(children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text('Analysing leaf sample...', style: AppTextStyles.sans(14)),
                Text('Matching against pest database',
                    style: AppTextStyles.sans(12, color: AppColors.slateLight)),
              ])),
          const SizedBox(height: 20),
        ],

        if (_diagnosed && _pestName != null) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: AppColors.alert.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.alert.withValues(alpha: 0.3))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AnimatedEmoji('🐛', size: 24),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('$_pestName Detected',
                          style: AppTextStyles.sans(16,
                              weight: FontWeight.w700, color: AppColors.alert)),
                      Text('Confidence: 94%',
                          style: AppTextStyles.sans(11,
                              color: AppColors.slateLight)),
                    ])),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.alert,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('URGENT',
                        style: AppTextStyles.sans(9,
                            color: Colors.white, weight: FontWeight.w700))),
              ]),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text('Diagnosis',
                  style: AppTextStyles.sans(12,
                      color: AppColors.slateLight, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('$_diagnosis', style: AppTextStyles.sans(13)),
              const SizedBox(height: 12),
              Text('Recommended Treatment',
                  style: AppTextStyles.sans(12,
                      color: AppColors.slateLight, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('🧪 $_pesticide',
                  style: AppTextStyles.sans(13, weight: FontWeight.w600)),
              Text('Application: $_applicationMethod',
                  style: AppTextStyles.sans(12, color: AppColors.slate)),
              const SizedBox(height: 12),
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.alert.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    AnimatedEmoji('⏱️', size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'PHI: $_phiDays days — Harvest will be locked until the pre-harvest interval completes. This ensures produce is safe for consumption.',
                            style:
                                AppTextStyles.sans(12, color: AppColors.bark))),
                  ])),
              const SizedBox(height: 16),
              Text('Apply treatment to which batch?',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<CropBatch>(
                  initialValue: _selectedBatch,
                  decoration: const InputDecoration(),
                  hint: const Text('Select batch'),
                  items: batches
                      .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text('${b.cropName} — ${b.plotName ?? '${b.plotLocation.lat.toStringAsFixed(3)}, ${b.plotLocation.lng.toStringAsFixed(3)}'}')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBatch = v)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loading ? null : _applyTreatment,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alert,
                      minimumSize: const Size(double.infinity, 48)),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Apply Treatment + Start PHI Countdown',
                          style: AppTextStyles.sans(14,
                              color: Colors.white, weight: FontWeight.w600))),
            ]),
          ),
        ],

        if (!_diagnosed && !_diagnosing) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.cardOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderOf(context))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Common Pests',
                  style: AppTextStyles.sans(14, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              ..._pestDb.map((p) => ListTile(
                    leading: AnimatedEmoji('🐛', size: 22),
                    title: Text(p['pest'] as String,
                        style: AppTextStyles.sans(13, weight: FontWeight.w600)),
                    subtitle: Text('PHI: ${p['phi']} days',
                        style: AppTextStyles.sans(11)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      setState(() {
                        _pestName = p['pest'] as String;
                        _diagnosis = p['diagnosis'] as String;
                        _pesticide = p['pesticide'] as String;
                        _applicationMethod = p['method'] as String;
                        _phiDays = p['phi'] as int;
                        _diagnosed = true;
                      });
                    },
                  )),
            ]),
          ),
        ],
        const SizedBox(height: 80),
      ]),
    );
  }

  Future<void> _takeCameraPhoto() async {
    setState(() => _diagnosing = true);
    await Future.delayed(const Duration(seconds: 2));
    final result = _pestDb[1]; // Simulate diagnosis
    setState(() {
      _diagnosing = false;
      _diagnosed = true;
      _pestName = result['pest'] as String;
      _diagnosis = result['diagnosis'] as String;
      _pesticide = result['pesticide'] as String;
      _applicationMethod = result['method'] as String;
      _phiDays = result['phi'] as int;
    });
  }

  Future<void> _applyTreatment() async {
    if (_selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a batch to apply treatment to.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(batchServiceProvider).logPestTreatment(
          batchId: _selectedBatch!.id,
          pestName: _pestName!,
          diagnosis: _diagnosis!,
          pesticide: _pesticide!,
          applicationMethod: _applicationMethod!,
          phiDays: _phiDays);
      if (!mounted) return;
      setState(() => _loading = false);

      final cropName = _selectedBatch!.cropName;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.leaf, size: 40),
          title: const Text('Treatment Logged'),
          content: Text('$cropName treated. Harvest locked for '
              '$_phiDays days (PHI countdown started).'),
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
