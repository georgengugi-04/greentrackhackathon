import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/supplier_providers.dart';
import '../../../data/models/models.dart';

/// Public supplier-listing detail. The "Verified Supplier" badge is looked
/// up live from the supplier's own profile (never cached on the listing)
/// so a verification change takes effect immediately everywhere it's shown.
class SupplierListingDetailScreen extends ConsumerWidget {
  const SupplierListingDetailScreen({super.key, required this.listingId});
  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listingAsync = ref.watch(supplierListingByIdProvider(listingId));

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.supplierListingTitle)),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(
            child: Text(l10n.supplierListingErrorLoad,
                style: AppTextStyles.bodyMuted)),
        data: (listing) {
          if (listing == null) {
            return Center(
                child: Text(l10n.supplierListingNoLongerAvailable,
                    style: AppTextStyles.bodyMuted));
          }
          final profileAsync =
              ref.watch(supplierProfileByIdProvider(listing.supplierId));

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(listing.name,
                    style: AppTextStyles.poppins(24, weight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(listing.category.label, style: AppTextStyles.bodyMuted),
                if (listing.price != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        l10n.suppliersPriceLine(listing.price!.toStringAsFixed(0)) +
                            (listing.unit == null ? '' : '/${listing.unit}'),
                        style: AppTextStyles.sans(15,
                            weight: FontWeight.w700,
                            color: AppColors.premiumEmerald)),
                  ),
                const SizedBox(height: 16),
                Text(listing.description, style: AppTextStyles.sans(14)),
                const SizedBox(height: 16),
                profileAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, __) => const SizedBox.shrink(),
                  data: (profile) {
                    if (profile == null) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => context
                          .push('/marketplace/suppliers/profile/${profile.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardOf(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderOf(context)),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.leaf.withValues(alpha: 0.15),
                            child: Text(
                                profile.businessName.isNotEmpty
                                    ? profile.businessName[0].toUpperCase()
                                    : '?',
                                style: AppTextStyles.sans(16,
                                    weight: FontWeight.w700, color: AppColors.leaf)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Flexible(
                                    child: Text(profile.businessName,
                                        style: AppTextStyles.sans(14,
                                            weight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  if (profile.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded,
                                        size: 16, color: AppColors.premiumEmerald),
                                  ],
                                ]),
                                Text(profile.generalLocation,
                                    style: AppTextStyles.sans(12,
                                        color: AppColors.textSecondaryOf(context))),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ]),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context
                      .push('/marketplace/suppliers/listing/${listing.id}/request'),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(l10n.supplierListingRequestProduct),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: AppColors.premiumEmerald),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.supplierListingPaymentDisclaimer,
                  style: AppTextStyles.sans(12,
                      color: AppColors.textSecondaryOf(context)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
