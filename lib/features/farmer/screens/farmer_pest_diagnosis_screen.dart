import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_vision_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/models.dart';

class FarmerPestDiagnosisScreen extends ConsumerStatefulWidget {
  final String batchId;
  final String cropName;
  const FarmerPestDiagnosisScreen({
    required this.batchId,
    this.cropName = 'Tomatoes',
    super.key,
  });

  @override
  ConsumerState<FarmerPestDiagnosisScreen> createState() =>
      _FarmerPestDiagnosisScreenState();
}

enum _Stage { capture, analyzing, result, error }

class _FarmerPestDiagnosisScreenState extends ConsumerState<FarmerPestDiagnosisScreen> {
  _Stage _stage = _Stage.capture;
  Uint8List? _imageBytes;
  VisionDiagnosisResult? _result;
  String? _errorMessage;

  PestSeverity _severity = PestSeverity.low;
  bool _treated = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1280);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _stage = _Stage.analyzing;
      });
      await _runDiagnosis(bytes);
    } catch (e) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Could not access the camera/gallery on this device. '
            'You can still log a diagnosis manually below.';
      });
    }
  }

  Future<void> _saveDiagnosis(VisionDiagnosisResult result) async {
    if (result.isHealthy || !_treated) {
      // Nothing to persist for a healthy read, or an unhealthy one the
      // farmer hasn't actually treated yet — just confirm and leave.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
            result.isHealthy
                ? '✅ Diagnosis saved — no treatment needed.'
                : '📋 Diagnosis noted. Log treatment once applied to start the PHI countdown.')));
        Navigator.pop(context, result);
      }
      return;
    }

    try {
      await ref.read(batchServiceProvider).logPestTreatment(
            batchId: widget.batchId,
            pestName: result.label,
            diagnosis: result.summary,
            pesticide: result.recommendedTreatment ?? 'Not specified',
            applicationMethod: result.applicationInstructions ?? '',
            phiDays: result.phiDays,
            severity: _severity,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          '🐛 Logged to this batch — ${result.phiDays}-day PHI countdown started.')));
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save to this batch: $e')));
    }
  }

  Future<void> _runDiagnosis(Uint8List bytes) async {
    try {
      final result =
          await AiVisionService.instance.diagnose(bytes, cropName: widget.cropName);
      if (!mounted) return;
      setState(() {
        _result = result;
        _severity = result.severity;
        _stage = _Stage.result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = e is AiVisionException
            ? e.message
            : 'Diagnosis failed unexpectedly. Please try again.';
      });
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardOf(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.farmerAccent),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.farmerAccent),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.farmerSurfaceOf(context),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('AI Pest & Disease Scan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildCaptureArea(),
          const SizedBox(height: AppSpacing.md),
          if (_stage == _Stage.analyzing) _buildAnalyzing(),
          if (_stage == _Stage.error) _buildError(),
          if (_stage == _Stage.result && _result != null) _buildResult(_result!),
        ],
      ),
    );
  }

  Widget _buildCaptureArea() {
    return GestureDetector(
      onTap: _stage == _Stage.analyzing ? null : _showSourceSheet,
      child: Container(
        height: 200,
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: _imageBytes == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 40, color: AppColors.textSecondaryOf(context)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Tap to photograph the affected plant',
                        style: AppTextStyles.bodyMuted),
                    Text('AI will identify the pest or disease automatically',
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 11)),
                  ],
                ),
              )
            : Stack(fit: StackFit.expand, children: [
                Image.memory(_imageBytes!, fit: BoxFit.cover),
                if (_stage != _Stage.analyzing)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: FloatingActionButton.small(
                      heroTag: 'retake',
                      backgroundColor: AppColors.cardOf(context),
                      onPressed: _showSourceSheet,
                      child: Icon(Icons.refresh, color: AppColors.textPrimaryOf(context)),
                    ),
                  ),
              ]),
      ),
    );
  }

  Widget _buildAnalyzing() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.farmerAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(children: [
        const SizedBox(
            width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
        const SizedBox(height: AppSpacing.sm),
        Text('Analyzing photo for pests and disease…', style: AppTextStyles.body(14)),
        const SizedBox(height: 4),
        Text('Comparing leaf pattern, color, and texture against known conditions',
            style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Diagnosis unavailable', style: AppTextStyles.h2)),
        ]),
        const SizedBox(height: 4),
        Text(_errorMessage ?? 'Something went wrong.', style: AppTextStyles.bodyMuted),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(onPressed: _showSourceSheet, child: const Text('Try again')),
      ]),
    );
  }

  Widget _buildResult(VisionDiagnosisResult result) {
    final color = result.isHealthy ? AppColors.success : AppColors.error;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(result.isHealthy ? Icons.eco : Icons.bug_report, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(result.label, style: AppTextStyles.h2)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${(result.confidence * 100).toStringAsFixed(0)}% confident',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(result.summary, style: AppTextStyles.bodyMuted),
            if (!result.isHealthy) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Recommended Treatment', style: AppTextStyles.label),
              Text(result.recommendedTreatment ?? '—',
                  style: AppTextStyles.body(14).copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(result.applicationInstructions ?? '', style: AppTextStyles.bodyMuted),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                const Icon(Icons.timer, size: 16, color: AppColors.amber),
                const SizedBox(width: 4),
                Text('PHI: ${result.phiDays} days after treatment',
                    style: AppTextStyles.body(14).copyWith(color: AppColors.amber)),
              ]),
            ],
            if (result.usedOfflineModel) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Diagnosed on-device — no internet required.',
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 11)),
            ],
          ],
        ),
      ),
      if (!result.isHealthy) ...[
        const SizedBox(height: AppSpacing.md),
        Text('Confirm Severity', style: AppTextStyles.label),
        RadioGroup<PestSeverity>(
          groupValue: _severity,
          onChanged: (v) => setState(() => _severity = v!),
          child: Column(children: [
            ...PestSeverity.values.map(
              (s) => RadioListTile<PestSeverity>(
                value: s,
                title: Text(s.name, style: AppTextStyles.body(14)),
                activeColor: AppColors.error,
              ),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.sm),
        CheckboxListTile(
          value: _treated,
          onChanged: (v) => setState(() => _treated = v!),
          title: Text('Treatment applied now', style: AppTextStyles.body(14)),
          subtitle: Text(
              'Logging treatment will start the ${result.phiDays}-day PHI countdown',
              style: AppTextStyles.bodyMuted),
          activeColor: AppColors.farmerAccent,
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      ElevatedButton.icon(
        icon: const Icon(Icons.save),
        label: const Text('Save Diagnosis'),
        onPressed: () => _saveDiagnosis(result),
      ),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton.icon(
        icon: const Icon(Icons.eco_outlined),
        label: const Text('Plan Next Crop for This Plot'),
        onPressed: () {
          final phiClear = _treated
              ? DateTime.now().add(Duration(days: result.phiDays))
              : null;
          context.push(
            '/farmer/plan-crop',
            extra: {
              'previousCropName': widget.cropName,
              'diagnosis': result,
              'phiClearDate': phiClear,
            },
          );
        },
      ),
    ]);
  }
}
