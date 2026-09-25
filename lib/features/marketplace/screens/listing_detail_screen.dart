import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/marketplace_providers.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/models/models.dart';

/// Public listing detail. Never shows the farmer's exact plot coordinates —
/// only [MarketplaceListing.generalLocation], which is set at publish time
/// (section 16: exact farm location stays private).
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});
  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listingAsync = ref.watch(listingByIdProvider(listingId));
    final user = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.listingTitle)),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(
            child: Text(l10n.listingErrorLoad, style: AppTextStyles.bodyMuted)),
        data: (listing) {
          if (listing == null) {
            return Center(
                child: Text(l10n.listingNoLongerAvailable,
                    style: AppTextStyles.bodyMuted));
          }
          final soon = listing.status == MarketplaceListingStatus.upcoming;
          final soldOut = listing.status == MarketplaceListingStatus.soldOut;
          final isFollowingAsync =
              ref.watch(isFollowingListingProvider(listing.id));

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(l10n.marketplaceFreshCropName(listing.cropName),
                    style: AppTextStyles.poppins(24, weight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  soon
                      ? l10n.marketplaceEstQuantity(
                          listing.quantity.toStringAsFixed(0), listing.unit)
                      : l10n.marketplaceAvailableQuantity(
                          listing.availableQuantity.toStringAsFixed(0), listing.unit),
                  style: AppTextStyles.sans(16, weight: FontWeight.w600),
                ),
                if (listing.pricePerUnit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        l10n.marketplacePriceLine(
                            listing.pricePerUnit!.toStringAsFixed(0), listing.unit),
                        style: AppTextStyles.sans(15,
                            weight: FontWeight.w700,
                            color: AppColors.premiumEmerald)),
                  ),
                const SizedBox(height: 16),
                if (soon)
                  _InfoBanner(
                    icon: Icons.info_outline_rounded,
                    text: l10n.listingNotHarvestedBanner,
                  ),
                const SizedBox(height: 8),
                _DetailRow(
                    label: soon ? l10n.listingExpectedHarvest : l10n.listingHarvested,
                    value: soon
                        ? (listing.expectedHarvestDate == null
                            ? l10n.listingDateTbd
                            : DateFormat('d MMMM yyyy')
                                .format(listing.expectedHarvestDate!))
                        : (listing.harvestedAt == null
                            ? l10n.listingDateUnknown
                            : DateFormat('d MMMM yyyy')
                                .format(listing.harvestedAt!))),
                _DetailRow(label: l10n.listingLocation, value: listing.generalLocation),
                _DetailRow(label: l10n.listingFarmer, value: listing.farmerName),
                _DetailRow(label: l10n.listingBatch, value: listing.batchId),
                _DetailRow(label: l10n.listingStatus, value: listing.status.label),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.push('/consumer/scan/${listing.batchId}'),
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: Text(l10n.listingTraceThisBatch),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                ),
                const SizedBox(height: 12),
                if (soon)
                  isFollowingAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, __) => const SizedBox.shrink(),
                    data: (following) => ElevatedButton.icon(
                      onPressed: user == null
                          ? null
                          : () async {
                              final service =
                                  ref.read(marketplaceServiceProvider);
                              if (following) {
                                await service.unfollow(listing.id, user.id);
                              } else {
                                await service.follow(listing.id, user.id);
                              }
                            },
                      icon: Icon(following
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded),
                      label: Text(following ? l10n.listingFollowingThis : l10n.listingNotifyMe),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: AppColors.premiumWarning),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: soldOut
                        ? null
                        : () => context.push('/marketplace/listing/${listing.id}/request'),
                    icon: const Icon(Icons.shopping_basket_outlined),
                    label: Text(soldOut ? l10n.listingSoldOut : l10n.listingRequestProduce),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: AppColors.premiumEmerald),
                  ),
                const SizedBox(height: 12),
                Text(
                  l10n.listingPaymentDisclaimer,
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.premiumWarning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: AppColors.premiumWarning, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.sans(12.5))),
        ]),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(
              width: 140,
              child: Text(label,
                  style: AppTextStyles.sans(13,
                      color: AppColors.textSecondaryOf(context)))),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.sans(13, weight: FontWeight.w600))),
        ]),
      );
}
