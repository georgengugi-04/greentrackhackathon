import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/supplier_providers.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/modern_components.dart';

/// "Become a Supplier" registration, or — once a SupplierProfile exists —
/// the supplier's own management view (My Listings + Requests), mirroring
/// FarmerMarketplaceScreen's shape (spec sections 19-22).
class MySupplierScreen extends ConsumerWidget {
  const MySupplierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final profileAsync = ref.watch(myMaybeSupplierProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, __) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.marketplaceTitleShort)),
        body: Center(
            child: Text("We couldn't load your supplier account.",
                style: AppTextStyles.bodyMuted)),
      ),
      data: (profile) => profile == null
          ? _SupplierRegistrationView(userId: user.id)
          : _SupplierManagementView(profile: profile),
    );
  }
}

// ── REGISTRATION ─────────────────────────────────────────────────────────

class _SupplierRegistrationView extends ConsumerStatefulWidget {
  const _SupplierRegistrationView({required this.userId});
  final String userId;

  @override
  ConsumerState<_SupplierRegistrationView> createState() =>
      _SupplierRegistrationViewState();
}

class _SupplierRegistrationViewState
    extends ConsumerState<_SupplierRegistrationView> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  SupplierCategory _category = SupplierCategory.seeds;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.mySupplierBecomeSupplier)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.mySupplierIntro, style: AppTextStyles.bodyMuted),
            const SizedBox(height: 20),
            Text(l10n.mySupplierBusinessName,
                style: AppTextStyles.sans(13, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Text(l10n.supplierProfileCategory,
                style: AppTextStyles.sans(13, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<SupplierCategory>(
              initialValue: _category,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: SupplierCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            Text(l10n.mySupplierGeneralLocation,
                style: AppTextStyles.sans(13, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                  hintText: l10n.marketplaceLocationHint, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Text(l10n.mySupplierDescription,
                style: AppTextStyles.sans(13, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Text(l10n.mySupplierContactPhone,
                style: AppTextStyles.sans(13, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Text(l10n.mySupplierContactEmail,
                style: AppTextStyles.sans(13, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppColors.leaf),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l10n.mySupplierRegisterButton),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.mySupplierPendingNotice,
              style: AppTextStyles.sans(12, color: AppColors.textSecondaryOf(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty || _locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.mySupplierErrorRequiredFields)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(supplierServiceProvider).createOrUpdateProfile(
            userId: widget.userId,
            businessName: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            category: _category,
            generalLocation: _locationCtrl.text.trim(),
            contactPhone:
                _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            contactEmail:
                _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.requestErrorGeneric(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── MANAGEMENT (listings + requests) ─────────────────────────────────────

class _SupplierManagementView extends ConsumerWidget {
  const _SupplierManagementView({required this.profile});
  final SupplierProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listingsAsync = ref.watch(mySupplierListingsProvider(profile.id));
    final requestsAsync = ref.watch(requestsForMySupplierProvider(profile.userId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surfaceOf(context),
        appBar: AppBar(
          title: Text(profile.businessName,
              style: AppTextStyles.poppins(18, weight: FontWeight.w700)),
          actions: [
            IconButton(
              tooltip: l10n.marketplaceMessages,
              onPressed: () => context.push('/messages'),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
            ),
          ],
          bottom: TabBar(tabs: [
            Tab(text: l10n.mySupplierMyListings),
            Tab(text: l10n.mySupplierRequests),
          ]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateListingSheet(context, ref, profile),
          icon: const Icon(Icons.add),
          label: Text(l10n.mySupplierAddListing),
          backgroundColor: AppColors.leaf,
        ),
        body: TabBarView(children: [
          Column(children: [
            if (!profile.isVerified) _VerificationBanner(status: profile.verificationStatus),
            Expanded(
              child: listingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Center(
                    child: Text(l10n.farmerMarketplaceErrorListings,
                        style: AppTextStyles.bodyMuted)),
                data: (listings) {
                  if (listings.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.inventory_2_outlined,
                      title: l10n.mySupplierNoListings,
                      message: l10n.mySupplierNoListingsMessage,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: listings.length,
                    itemBuilder: (_, i) =>
                        _MyListingCard(listing: listings[i], ref: ref),
                  );
                },
              ),
            ),
          ]),
          requestsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(
                child: Text(l10n.farmerMarketplaceErrorRequests,
                    style: AppTextStyles.bodyMuted)),
            data: (requests) {
              if (requests.isEmpty) {
                return EmptyStateView(
                  icon: Icons.inbox_outlined,
                  title: l10n.mySupplierNoRequests,
                  message: l10n.mySupplierNoRequestsMessage,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: requests.length,
                itemBuilder: (_, i) => _SupplierRequestCard(request: requests[i], ref: ref),
              );
            },
          ),
        ]),
      ),
    );
  }

  void _showCreateListingSheet(
      BuildContext context, WidgetRef ref, SupplierProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateListingSheet(profile: profile),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({required this.status});
  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rejected = status == VerificationStatus.rejected;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (rejected ? Colors.red : AppColors.premiumWarning).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(rejected ? Icons.error_outline_rounded : Icons.hourglass_top_rounded,
            color: rejected ? Colors.red : AppColors.premiumWarning, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            rejected
                ? l10n.mySupplierRejectedNotice
                : l10n.mySupplierPendingBanner,
            style: AppTextStyles.sans(12.5),
          ),
        ),
      ]),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  const _MyListingCard({required this.listing, required this.ref});
  final SupplierListing listing;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paused = listing.status == SupplierListingStatus.paused;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                Text(listing.name, style: AppTextStyles.sans(15, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(listing.category.label, style: AppTextStyles.bodyMuted),
                const SizedBox(height: 4),
                Text(paused ? l10n.mySupplierPaused : l10n.mySupplierActive,
                    style: AppTextStyles.sans(12,
                        weight: FontWeight.w600,
                        color: paused
                            ? AppColors.textSecondaryOf(context)
                            : AppColors.premiumEmerald)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.read(supplierServiceProvider).setListingStatus(
                listing.id,
                paused ? SupplierListingStatus.active : SupplierListingStatus.paused),
            child: Text(paused ? l10n.commonResume : l10n.commonPause),
          ),
        ]),
      ),
    );
  }
}

class _SupplierRequestCard extends StatelessWidget {
  const _SupplierRequestCard({required this.request, required this.ref});
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
          if (request.preferredDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                  l10n.requestPreferredLabel(
                      DateFormat('d MMM yyyy').format(request.preferredDate!)),
                  style: AppTextStyles.bodyMuted),
            ),
          if (request.message != null && request.message!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('"${request.message}"', style: AppTextStyles.sans(13, weight: FontWeight.w500)),
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
                      .read(supplierServiceProvider)
                      .updateRequestStatus(request.id, MarketplaceRequestStatus.declined),
                  child: Text(l10n.commonDecline),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(supplierServiceProvider)
                      .updateRequestStatus(request.id, MarketplaceRequestStatus.accepted),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.premiumEmerald),
                  child: Text(l10n.commonAccept),
                ),
              ),
            ]),
          ],
          if (request.status == MarketplaceRequestStatus.accepted) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref
                  .read(supplierServiceProvider)
                  .updateRequestStatus(request.id, MarketplaceRequestStatus.fulfilled),
              child: Text(l10n.commonMarkFulfilled),
            ),
          ],
        ]),
      ),
    );
  }
}

class _CreateListingSheet extends ConsumerStatefulWidget {
  const _CreateListingSheet({required this.profile});
  final SupplierProfile profile;

  @override
  ConsumerState<_CreateListingSheet> createState() => _CreateListingSheetState();
}

class _CreateListingSheetState extends ConsumerState<_CreateListingSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  SupplierCategory _category = SupplierCategory.seeds;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.mySupplierAddListing, style: AppTextStyles.poppins(18, weight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(labelText: l10n.mySupplierProductName, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SupplierCategory>(
            initialValue: _category,
            decoration: InputDecoration(labelText: l10n.supplierProfileCategory, border: const OutlineInputBorder()),
            items: SupplierCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: InputDecoration(labelText: l10n.mySupplierDescription, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.mySupplierPrice, border: const OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _unitCtrl,
                decoration: InputDecoration(labelText: l10n.mySupplierUnit, hintText: l10n.mySupplierUnitHint, border: const OutlineInputBorder()),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), backgroundColor: AppColors.leaf),
            child: _saving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(l10n.mySupplierPublishListing),
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.mySupplierErrorEnterName)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(supplierServiceProvider).createListing(
            supplierId: widget.profile.id,
            supplierName: widget.profile.businessName,
            category: _category,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            price: double.tryParse(_priceCtrl.text.trim()),
            unit: _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestErrorGeneric(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
