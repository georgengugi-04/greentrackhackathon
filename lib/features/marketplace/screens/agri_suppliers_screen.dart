import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/supplier_providers.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/modern_components.dart';

/// Agri Suppliers directory (spec section 18) — separate from Fresh
/// Produce, category-filterable. Only shows active listings; verification
/// is checked per-card via the supplier's own profile so a badge never has
/// to be self-claimed.
class AgriSuppliersScreen extends ConsumerStatefulWidget {
  const AgriSuppliersScreen({super.key});

  @override
  ConsumerState<AgriSuppliersScreen> createState() => _AgriSuppliersScreenState();
}

class _AgriSuppliersScreenState extends ConsumerState<AgriSuppliersScreen> {
  SupplierCategory? _category;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listingsAsync = ref.watch(supplierDirectoryProvider(_category));

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(l10n.suppliersTitle),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/marketplace/my-supplier'),
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: Text(l10n.suppliersSellHere),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: l10n.suppliersSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.cardOf(context),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.borderOf(context))),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: l10n.suppliersAll,
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                ...SupplierCategory.values.map((c) => _CategoryChip(
                      label: c.label,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: listingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(
                  child: Text(l10n.suppliersErrorLoad, style: AppTextStyles.bodyMuted)),
              data: (listings) {
                final filtered = _query.isEmpty
                    ? listings
                    : listings
                        .where((l) =>
                            l.name.toLowerCase().contains(_query) ||
                            l.supplierName.toLowerCase().contains(_query))
                        .toList();
                if (filtered.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.suppliersNoneYet,
                    message: l10n.suppliersNoneYetMessage,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _SupplierListingCard(
                    listing: filtered[i],
                    onTap: () => context
                        .push('/marketplace/suppliers/listing/${filtered[i].id}'),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});
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

class _SupplierListingCard extends StatelessWidget {
  const _SupplierListingCard({required this.listing, required this.onTap});
  final SupplierListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      child: Text(listing.name,
                          style: AppTextStyles.sans(16, weight: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.leaf.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(listing.category.label,
                          style: AppTextStyles.sans(10,
                              weight: FontWeight.w700, color: AppColors.leaf)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(listing.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMuted),
                  const SizedBox(height: 4),
                  Text(listing.supplierName,
                      style: AppTextStyles.sans(12,
                          color: AppColors.textSecondaryOf(context))),
                  if (listing.price != null) ...[
                    const SizedBox(height: 4),
                    Text(
                        l10n.suppliersPriceLine(listing.price!.toStringAsFixed(0)) +
                            (listing.unit == null ? '' : '/${listing.unit}'),
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
