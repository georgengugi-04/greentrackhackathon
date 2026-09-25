import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/supplier_providers.dart';
import '../../../data/models/models.dart';

/// Public supplier profile (spec section 22). Only ever shows what the
/// supplier put in generalLocation/description/contact — never anything
/// beyond what SupplierProfile itself stores.
class SupplierProfileScreen extends ConsumerWidget {
  const SupplierProfileScreen({super.key, required this.supplierId});
  final String supplierId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(supplierProfileByIdProvider(supplierId));

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.supplierProfileTitle)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(
            child: Text(l10n.supplierProfileErrorLoad,
                style: AppTextStyles.bodyMuted)),
        data: (profile) {
          if (profile == null) {
            return Center(
                child: Text(l10n.supplierProfileUnavailable,
                    style: AppTextStyles.bodyMuted));
          }
          final listingsAsync = ref.watch(mySupplierListingsProvider(profile.id));

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.leaf.withValues(alpha: 0.15),
                    child: Text(
                        profile.businessName.isNotEmpty
                            ? profile.businessName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.poppins(22,
                            weight: FontWeight.w700, color: AppColors.leaf)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(profile.businessName,
                                style: AppTextStyles.poppins(18,
                                    weight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (profile.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded,
                                size: 18, color: AppColors.premiumEmerald),
                          ],
                        ]),
                        Text(
                            profile.isVerified
                                ? l10n.supplierProfileVerified
                                : profile.verificationStatus.label,
                            style: AppTextStyles.sans(12,
                                weight: FontWeight.w600,
                                color: profile.isVerified
                                    ? AppColors.premiumEmerald
                                    : AppColors.textSecondaryOf(context))),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _DetailRow(label: l10n.supplierProfileCategory, value: profile.category.label),
                _DetailRow(label: l10n.supplierProfileLocation, value: profile.generalLocation),
                if (profile.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(profile.description, style: AppTextStyles.sans(14)),
                ],
                const SizedBox(height: 24),
                Text(l10n.supplierProfileProductsServices,
                    style: AppTextStyles.sans(14, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                listingsAsync.when(
                  loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator())),
                  error: (e, __) => Text(
                      l10n.supplierProfileErrorListings,
                      style: AppTextStyles.bodyMuted),
                  data: (listings) {
                    final active = listings
                        .where((l) => l.status == SupplierListingStatus.active)
                        .toList();
                    if (active.isEmpty) {
                      return Text(l10n.supplierProfileNoActiveListings,
                          style: AppTextStyles.bodyMuted);
                    }
                    return Column(
                      children: active
                          .map((l) => Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(l.name),
                                  subtitle: Text(l.category.label),
                                  trailing: l.price == null
                                      ? null
                                      : Text(
                                          l10n.suppliersPriceLine(l.price!.toStringAsFixed(0)) +
                                              (l.unit == null ? '' : '/${l.unit}'),
                                          style: AppTextStyles.sans(13,
                                              weight: FontWeight.w700,
                                              color: AppColors.premiumEmerald)),
                                  onTap: () => context
                                      .push('/marketplace/suppliers/listing/${l.id}'),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: AppTextStyles.sans(13,
                      color: AppColors.textSecondaryOf(context)))),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.sans(13, weight: FontWeight.w600))),
        ]),
      );
}
