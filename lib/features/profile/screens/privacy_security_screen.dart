import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/models/models.dart';

class PrivacySecurityScreen extends ConsumerWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            icon: Icons.location_on_outlined,
            title: 'Location',
            body: 'Your plot\'s GPS coordinates power local weather, satellite '
                'soil moisture, and are pinned on your batch\'s public trace so '
                'buyers can see where produce came from.',
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.photo_camera_outlined,
            title: 'Photos',
            body: 'New crop photos are auto-fetched from Unsplash by crop name '
                '— not photos of your actual plot. Pest-scan photos you take go '
                'to Kindwise only when you use the scanner.',
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.visibility_outlined,
            title: 'Who Can See Your Batches',
            body: 'Anyone who scans a batch\'s QR code sees that batch\'s trace '
                '(crop, origin, harvest date, custody journey). They can\'t see '
                'your email, other batches, or account details.',
          ),
          const SizedBox(height: 20),
          Text('YOUR DATA',
              style: AppTextStyles.poppins(11.5, weight: FontWeight.w700,
                  color: AppColors.textSecondaryOf(context)).copyWith(letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
              boxShadow: AppShadows.card,
            ),
            child: Column(children: [
              if (user?.role == UserRole.farmer)
                ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.red),
                  ),
                  title: Text('Manage Crops',
                      style: AppTextStyles.poppins(14, weight: FontWeight.w600,
                          color: AppColors.textPrimaryOf(context))),
                  subtitle: Text('View or delete crop batches you\'ve planted',
                      style: AppTextStyles.body(11.5, color: AppColors.textSecondaryOf(context))),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondaryOf(context), size: 20),
                  onTap: () => context.push('/settings/manage-crops'),
                )
              else
                ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: AppColors.textSecondaryOf(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.info_outline, size: 18, color: AppColors.textSecondaryOf(context)),
                  ),
                  title: Text('Crop batch deletion',
                      style: AppTextStyles.poppins(14, weight: FontWeight.w600,
                          color: AppColors.textPrimaryOf(context))),
                  subtitle: Text('Only Farmer accounts own crop batches directly',
                      style: AppTextStyles.body(11.5, color: AppColors.textSecondaryOf(context))),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _InfoCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: AppColors.leaf),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyles.poppins(13.5, weight: FontWeight.w700,
              color: AppColors.textPrimaryOf(context))),
          const SizedBox(height: 4),
          Text(body, style: AppTextStyles.body(12, color: AppColors.textSecondaryOf(context), height: 1.4)),
        ])),
      ]),
    );
  }
}
