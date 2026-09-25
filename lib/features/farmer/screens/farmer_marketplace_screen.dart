import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/marketplace_providers.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/modern_components.dart';
import '../../shared/widgets/premium_widgets.dart';

/// Farmer's "My Marketplace" — own listings and the requests against them.
/// Everything here reads from the same MarketplaceListing/Request Firestore
/// collections the public Marketplace screens use — no separate farmer-only
/// copy of the data (section 44: single source of truth).
class FarmerMarketplaceScreen extends ConsumerWidget {
  const FarmerMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listingsAsync = ref.watch(myListingsProvider);
    final requestsAsync = ref.watch(requestsForMyListingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surfaceOf(context),
        appBar: AppBar(
          title: Text(l10n.farmerMarketplaceTitle,
              style: AppTextStyles.poppins(20, weight: FontWeight.w700)),
          actions: [
            IconButton(
              tooltip: l10n.marketplaceMessages,
              onPressed: () => context.push('/messages'),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
            ),
          ],
          bottom: TabBar(tabs: [
            Tab(text: l10n.farmerMarketplaceMyListings),
            Tab(text: l10n.farmerMarketplaceRequests),
          ]),
        ),
        body: TabBarView(children: [
          listingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(
                child: Text(l10n.farmerMarketplaceErrorListings,
                    style: AppTextStyles.bodyMuted)),
            data: (listings) {
              if (listings.isEmpty) {
                return EmptyStateView(
                  icon: Icons.storefront_outlined,
                  title: l10n.farmerMarketplaceNoListings,
                  message: l10n.farmerMarketplaceNoListingsMessage,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: listings.length,
                itemBuilder: (context, i) =>
                    _FarmerListingCard(listing: listings[i]),
              );
            },
          ),
          requestsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(
                child: Text(l10n.farmerMarketplaceErrorRequests,
                    style: AppTextStyles.bodyMuted)),
            data: (requests) {
              if (requests.isEmpty) {
                return EmptyStateView(
                  icon: Icons.inbox_outlined,
                  title: l10n.farmerMarketplaceNoRequests,
                  message: l10n.farmerMarketplaceNoRequestsMessage,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: requests.length,
                itemBuilder: (context, i) =>
                    _RequestCard(request: requests[i], ref: ref),
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _FarmerListingCard extends StatelessWidget {
  const _FarmerListingCard({required this.listing});
  final MarketplaceListing listing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.push('/marketplace/listing/${listing.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.cropName,
                      style: AppTextStyles.sans(15, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                      l10n.farmerMarketplaceRemaining(
                          listing.availableQuantity.toStringAsFixed(0),
                          listing.quantity.toStringAsFixed(0),
                          listing.unit),
                      style: AppTextStyles.bodyMuted),
                  const SizedBox(height: 4),
                  Text(listing.status.label,
                      style: AppTextStyles.sans(12,
                          weight: FontWeight.w600,
                          color: AppColors.premiumEmerald)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.ref});
  final MarketplaceRequest request;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = request.status == MarketplaceRequestStatus.pending;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                  l10n.requestBuyerQuantity(request.buyerName,
                      request.quantity.toStringAsFixed(0), request.unit),
                  style: AppTextStyles.sans(14, weight: FontWeight.w700)),
            ),
            Text(request.status.label,
                style: AppTextStyles.sans(12,
                    weight: FontWeight.w600, color: AppColors.premiumWarning)),
          ]),
          const SizedBox(height: 4),
          Text(request.intendedUse.label, style: AppTextStyles.bodyMuted),
          if (request.preferredDate != null)
            Text(
                l10n.requestPreferredLabel(
                    DateFormat('d MMM yyyy').format(request.preferredDate!)),
                style: AppTextStyles.bodyMuted),
          if (request.message != null && request.message!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('"${request.message}"',
                style: AppTextStyles.sans(13, weight: FontWeight.w500)),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/messages/request/${request.id}'),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: Text(l10n.commonMessage),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ),
          if (pending) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(marketplaceServiceProvider)
                      .updateRequestStatus(
                          request.id, MarketplaceRequestStatus.declined),
                  child: Text(l10n.commonDecline),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(marketplaceServiceProvider)
                      .acceptRequest(request.id),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.premiumEmerald),
                  child: Text(l10n.commonAccept),
                ),
              ),
            ]),
          ],
          if (request.status == MarketplaceRequestStatus.accepted) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref
                  .read(marketplaceServiceProvider)
                  .updateRequestStatus(
                      request.id, MarketplaceRequestStatus.fulfilled),
              child: Text(l10n.commonMarkFulfilled),
            ),
          ],
        ]),
      ),
    );
  }
}
