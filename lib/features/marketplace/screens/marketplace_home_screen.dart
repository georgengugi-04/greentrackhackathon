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

/// Marketplace landing screen — Fresh Produce, Harvesting Soon, and a way
/// into the existing batch-trace flow. Deliberately does not duplicate the
/// QR/trace system (section 17): "Trace a Batch" pushes the same scanner
/// route every other role already uses.
class MarketplaceHomeScreen extends ConsumerStatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  ConsumerState<MarketplaceHomeScreen> createState() =>
      _MarketplaceHomeScreenState();
}

enum _ProduceView { all, availableNow, harvestingSoon }

class _MarketplaceHomeScreenState extends ConsumerState<MarketplaceHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _ProduceView _view = _ProduceView.all;
  String _locationFilter = '';
  double? _minQuantity;
  double? _maxPrice;

  bool get _hasActiveFilters =>
      _locationFilter.isNotEmpty || _minQuantity != null || _maxPrice != null;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final freshAsync = ref.watch(freshProduceProvider);
    final soonAsync = ref.watch(harvestingSoonProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(l10n.marketplaceTitle,
            style: AppTextStyles.poppins(20, weight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: l10n.marketplaceMyRequests,
            onPressed: () => context.push('/marketplace/my-requests'),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: l10n.marketplaceMessages,
            onPressed: () => context.push('/messages'),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.marketplaceTagline, style: AppTextStyles.bodyMuted),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: l10n.marketplaceSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.cardOf(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.borderOf(context))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Stack(children: [
                IconButton.filledTonal(
                  tooltip: l10n.marketplaceFilters,
                  onPressed: () => _openFilterSheet(context),
                  icon: const Icon(Icons.tune_rounded),
                ),
                if (_hasActiveFilters)
                  Positioned(
                    right: 6, top: 6,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.premiumEmerald, shape: BoxShape.circle),
                    ),
                  ),
              ]),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _ViewChip(
                    label: l10n.marketplaceViewAll,
                    selected: _view == _ProduceView.all,
                    onTap: () => setState(() => _view = _ProduceView.all),
                  ),
                  _ViewChip(
                    label: l10n.marketplaceViewAvailableNow,
                    selected: _view == _ProduceView.availableNow,
                    onTap: () => setState(() => _view = _ProduceView.availableNow),
                  ),
                  _ViewChip(
                    label: l10n.marketplaceViewHarvestingSoon,
                    selected: _view == _ProduceView.harvestingSoon,
                    onTap: () => setState(() => _view = _ProduceView.harvestingSoon),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/scan'),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: Text(l10n.marketplaceTraceABatch),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
            if (_view != _ProduceView.harvestingSoon) ...[
              const SizedBox(height: 24),
              SectionHeader(title: l10n.marketplaceFreshProduce),
              freshAsync.when(
                loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator())),
                error: (e, __) => _ErrorState(message: l10n.marketplaceErrorLoadListings),
                data: (listings) {
                  final filtered = _filter(listings);
                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.shopping_basket_outlined,
                      title: _hasActiveFilters || _query.isNotEmpty
                          ? l10n.marketplaceNoProduceMatch
                          : l10n.marketplaceNoProduceAvailable,
                      message: _hasActiveFilters || _query.isNotEmpty
                          ? l10n.marketplaceTryWideningFilters
                          : l10n.marketplaceCheckBackSoon,
                    );
                  }
                  return Column(
                    children: filtered
                        .map((l) => _ListingCard(
                            listing: l,
                            onTap: () =>
                                context.push('/marketplace/listing/${l.id}')))
                        .toList(),
                  );
                },
              ),
            ],
            if (_view != _ProduceView.availableNow) ...[
              const SizedBox(height: 24),
              SectionHeader(title: l10n.marketplaceViewHarvestingSoon),
              soonAsync.when(
                loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator())),
                error: (e, __) => _ErrorState(message: l10n.marketplaceErrorLoadHarvests),
                data: (listings) {
                  final filtered = _filter(listings);
                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.event_available_outlined,
                      title: _hasActiveFilters || _query.isNotEmpty
                          ? l10n.marketplaceNoHarvestsMatch
                          : l10n.marketplaceNoHarvestsYet,
                    );
                  }
                  return Column(
                    children: filtered
                        .map((l) => _ListingCard(
                            listing: l,
                            onTap: () =>
                                context.push('/marketplace/listing/${l.id}')))
                        .toList(),
                  );
                },
              ),
            ],
            if (_view == _ProduceView.all) ...[
              const SizedBox(height: 24),
              SectionHeader(
                title: l10n.marketplaceAgriSuppliers,
                action: l10n.marketplaceViewAllLink,
                onActionTap: () => context.push('/marketplace/suppliers'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/marketplace/suppliers'),
                icon: const Icon(Icons.storefront_outlined),
                label: Text(l10n.marketplaceSuppliersBlurb),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    alignment: Alignment.centerLeft),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationCtrl = TextEditingController(text: _locationFilter);
    final qtyCtrl = TextEditingController(
        text: _minQuantity == null ? '' : _minQuantity!.toStringAsFixed(0));
    final priceCtrl = TextEditingController(
        text: _maxPrice == null ? '' : _maxPrice!.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.marketplaceFilterProduce, style: AppTextStyles.poppins(18, weight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: locationCtrl,
            decoration: InputDecoration(
                labelText: l10n.marketplaceLocation, hintText: l10n.marketplaceLocationHint,
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: l10n.marketplaceMinQuantity, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: l10n.marketplaceMaxPrice, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _locationFilter = '';
                    _minQuantity = null;
                    _maxPrice = null;
                  });
                  Navigator.pop(sheetContext);
                },
                child: Text(l10n.commonClear),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _locationFilter = locationCtrl.text.trim();
                    _minQuantity = double.tryParse(qtyCtrl.text.trim());
                    _maxPrice = double.tryParse(priceCtrl.text.trim());
                  });
                  Navigator.pop(sheetContext);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.leaf),
                child: Text(l10n.commonApply),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  List<MarketplaceListing> _filter(List<MarketplaceListing> listings) {
    return listings.where((l) {
      if (_query.isNotEmpty && !l.cropName.toLowerCase().contains(_query)) {
        return false;
      }
      if (_locationFilter.isNotEmpty &&
          !l.generalLocation.toLowerCase().contains(_locationFilter.toLowerCase())) {
        return false;
      }
      if (_minQuantity != null) {
        final available = l.status == MarketplaceListingStatus.upcoming
            ? l.quantity
            : l.availableQuantity;
        if (available < _minQuantity!) return false;
      }
      if (_maxPrice != null && l.pricePerUnit != null && l.pricePerUnit! > _maxPrice!) {
        return false;
      }
      return true;
    }).toList();
  }
}

class _ViewChip extends StatelessWidget {
  const _ViewChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.leaf.withValues(alpha: 0.18),
          labelStyle: AppTextStyles.sans(12.5,
              weight: FontWeight.w600,
              color: selected ? AppColors.leaf : AppColors.textSecondaryOf(context)),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(message, style: AppTextStyles.bodyMuted),
      );
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.onTap});
  final MarketplaceListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final soon = listing.status == MarketplaceListingStatus.upcoming;
    final dateLabel = soon
        ? (listing.expectedHarvestDate == null
            ? null
            : DateFormat('d MMM').format(listing.expectedHarvestDate!))
        : (listing.harvestedAt == null
            ? null
            : DateFormat('d MMM yyyy').format(listing.harvestedAt!));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
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
                  Row(children: [
                    Expanded(
                      child: Text(l10n.marketplaceFreshCropName(listing.cropName),
                          style: AppTextStyles.sans(16, weight: FontWeight.w700)),
                    ),
                    _StatusBadge(status: listing.status),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    (soon
                            ? l10n.marketplaceEstQuantity(
                                listing.quantity.toStringAsFixed(0), listing.unit)
                            : l10n.marketplaceAvailableQuantity(
                                listing.availableQuantity.toStringAsFixed(0), listing.unit)) +
                        (dateLabel == null
                            ? ''
                            : (soon
                                ? l10n.marketplaceExpectedDate(dateLabel)
                                : l10n.marketplaceHarvestedDate(dateLabel))),
                    style: AppTextStyles.bodyMuted,
                  ),
                  const SizedBox(height: 4),
                  Text('${listing.generalLocation} · ${listing.farmerName}',
                      style: AppTextStyles.sans(12,
                          color: AppColors.textSecondaryOf(context))),
                  if (listing.pricePerUnit != null) ...[
                    const SizedBox(height: 4),
                    Text(
                        l10n.marketplacePriceLine(
                            listing.pricePerUnit!.toStringAsFixed(0), listing.unit),
                        style: AppTextStyles.sans(13,
                            weight: FontWeight.w700,
                            color: AppColors.premiumEmerald)),
                  ],
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final MarketplaceListingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MarketplaceListingStatus.available => AppColors.premiumEmerald,
      MarketplaceListingStatus.upcoming => AppColors.premiumWarning,
      MarketplaceListingStatus.soldOut => AppColors.textSecondaryOf(context),
      _ => AppColors.textSecondaryOf(context),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status.label,
          style: AppTextStyles.sans(10, weight: FontWeight.w700, color: color)),
    );
  }
}
