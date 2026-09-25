import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/marketplace_providers.dart';
import '../../../core/providers/supplier_providers.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/modern_components.dart';

/// The buyer-side counterpart to FarmerMarketplaceScreen's "Requests" tab
/// and MySupplierScreen's "Requests" tab — this is where a buyer (farmer
/// requesting a supplier product, or anyone requesting produce) sees the
/// status of requests *they sent*, and can message the seller.
class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final produceAsync = ref.watch(myRequestsProvider);
    final supplierAsync = ref.watch(myRequestsToSuppliersProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.myRequestsTitle)),
      body: SafeArea(
        child: produceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(
              child: Text(l10n.farmerMarketplaceErrorRequests,
                  style: AppTextStyles.bodyMuted)),
          data: (produceRequests) => supplierAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(
                child: Text(l10n.farmerMarketplaceErrorRequests,
                    style: AppTextStyles.bodyMuted)),
            data: (supplierRequests) {
              final all = [...produceRequests, ...supplierRequests]
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              if (all.isEmpty) {
                return EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.myRequestsNoneYet,
                  message: l10n.myRequestsNoneYetMessage,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: all.length,
                itemBuilder: (_, i) => _MyRequestCard(request: all[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MyRequestCard extends ConsumerWidget {
  const _MyRequestCard({required this.request});
  final MarketplaceRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSupplier = request.targetType == MarketplaceRequestTarget.supplier;
    final titleAsync = isSupplier
        ? ref.watch(supplierListingByIdProvider(request.listingId))
        : ref.watch(listingByIdProvider(request.listingId));

    String title = AppLocalizations.of(context)!.conversationRequestFallback;
    if (titleAsync.hasValue) {
      final v = titleAsync.value;
      if (v is SupplierListing) title = v.name;
      if (v is MarketplaceListing) title = v.cropName;
    }

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
              child: Text('$title · ${request.quantity.toStringAsFixed(0)} ${request.unit}',
                  style: AppTextStyles.sans(14, weight: FontWeight.w700)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.premiumWarning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(request.status.label,
                  style: AppTextStyles.sans(11,
                      weight: FontWeight.w700, color: AppColors.premiumWarning)),
            ),
          ]),
          Text(DateFormat('d MMM yyyy').format(request.createdAt),
              style: AppTextStyles.bodyMuted),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/messages/request/${request.id}'),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: Text(AppLocalizations.of(context)!.commonMessage),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ),
        ]),
      ),
    );
  }
}
