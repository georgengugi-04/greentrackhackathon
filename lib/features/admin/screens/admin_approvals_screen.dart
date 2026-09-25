import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/supplier_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';

class AdminApprovalsScreen extends ConsumerWidget {
  const AdminApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isAdminAsync = ref.watch(isAdminProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surfaceOf(context),
        appBar: AppBar(
          title: Text(l10n.adminAccessRequestsTitle),
          bottom: TabBar(tabs: [
            Tab(text: l10n.adminRoleRequestsTab),
            Tab(text: l10n.adminSuppliersTab),
          ]),
        ),
        body: isAdminAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.leaf)),
          error: (e, _) => Center(child: Text(l10n.adminErrorVerifyAccess(e.toString()))),
          data: (isAdmin) {
            if (!isAdmin) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.lock_outline_rounded, size: 40, color: AppColors.slateLight),
                    const SizedBox(height: 12),
                    Text(l10n.adminNotAuthorized,
                        style: AppTextStyles.body(16, weight: FontWeight.w700,
                            color: AppColors.textPrimaryOf(context))),
                    const SizedBox(height: 6),
                    Text(l10n.adminNoAdminAccess,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(12.5, color: AppColors.textSecondaryOf(context))),
                  ]),
                ),
              );
            }
            return const TabBarView(children: [
              _RequestQueue(),
              _SupplierQueue(),
            ]);
          },
        ),
      ),
    );
  }
}

class _RequestQueue extends ConsumerWidget {
  const _RequestQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final requestsAsync = ref.watch(pendingRoleRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.leaf)),
      error: (e, _) => Center(child: Text(l10n.adminErrorLoadRequests(e.toString()))),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_outline, size: 40, color: AppColors.leaf),
                const SizedBox(height: 12),
                Text(l10n.adminNoPendingRequests,
                    style: AppTextStyles.body(14, color: AppColors.textSecondaryOf(context))),
              ]),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: requests.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RequestCard(request: r),
          )).toList(),
        );
      },
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final RoleRequest request;
  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final reviewer = FirebaseAuth.instance.currentUser?.uid;
    if (reviewer == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(verificationServiceProvider).reviewRequest(
            uid: widget.request.uid,
            approve: approve,
            reviewerUid: reviewer,
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(approve
                ? l10n.adminApproved(widget.request.name)
                : l10n.adminRejected(widget.request.name))));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.adminErrorSaveDecision(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Text(r.requestedRole.label,
                style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          Text('${r.requestedAt.day}/${r.requestedAt.month}/${r.requestedAt.year}',
              style: AppTextStyles.body(11, color: AppColors.textSecondaryOf(context))),
        ]),
        const SizedBox(height: 8),
        Text(r.name, style: AppTextStyles.body(14.5, weight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context))),
        Text(r.email, style: AppTextStyles.body(11.5, color: AppColors.textSecondaryOf(context))),
        if (r.organizationDetail != null) ...[
          const SizedBox(height: 4),
          Text(r.organizationDetail!,
              style: AppTextStyles.body(12.5, color: AppColors.textPrimaryOf(context))),
        ],
        const SizedBox(height: 12),
        if (_busy)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.leaf)),
          ))
        else
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => _decide(false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.redLight),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(AppLocalizations.of(context)!.commonReject, style: const TextStyle(color: AppColors.red)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => _decide(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leaf,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(AppLocalizations.of(context)!.commonApprove, style: const TextStyle(color: Colors.white)),
            )),
          ]),
      ]),
    );
  }
}

class _SupplierQueue extends ConsumerWidget {
  const _SupplierQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profilesAsync = ref.watch(pendingSupplierProfilesProvider);

    return profilesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.leaf)),
      error: (e, _) => Center(child: Text(l10n.adminErrorLoadSuppliers(e.toString()))),
      data: (profiles) {
        if (profiles.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_outline, size: 40, color: AppColors.leaf),
                const SizedBox(height: 12),
                Text(l10n.adminNoSuppliersAwaiting,
                    style: AppTextStyles.body(14, color: AppColors.textSecondaryOf(context))),
              ]),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: profiles.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SupplierCard(profile: p),
          )).toList(),
        );
      },
    );
  }
}

class _SupplierCard extends ConsumerStatefulWidget {
  final SupplierProfile profile;
  const _SupplierCard({required this.profile});

  @override
  ConsumerState<_SupplierCard> createState() => _SupplierCardState();
}

class _SupplierCardState extends ConsumerState<_SupplierCard> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    setState(() => _busy = true);
    try {
      await ref.read(supplierServiceProvider).setVerificationStatus(
            widget.profile.id,
            approve ? VerificationStatus.approved : VerificationStatus.rejected,
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(approve
                ? l10n.adminSupplierVerified(widget.profile.businessName)
                : l10n.adminRejected(widget.profile.businessName))));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.adminErrorSaveDecision(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Text(p.category.label,
                style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          Text('${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}',
              style: AppTextStyles.body(11, color: AppColors.textSecondaryOf(context))),
        ]),
        const SizedBox(height: 8),
        Text(p.businessName, style: AppTextStyles.body(14.5, weight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context))),
        Text(p.generalLocation, style: AppTextStyles.body(11.5, color: AppColors.textSecondaryOf(context))),
        if (p.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(p.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(12.5, color: AppColors.textPrimaryOf(context))),
        ],
        if (p.contactPhone != null || p.contactEmail != null) ...[
          const SizedBox(height: 4),
          Text([p.contactPhone, p.contactEmail].whereType<String>().join(' · '),
              style: AppTextStyles.body(11.5, color: AppColors.textSecondaryOf(context))),
        ],
        const SizedBox(height: 12),
        if (_busy)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.leaf)),
          ))
        else
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => _decide(false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.redLight),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(AppLocalizations.of(context)!.commonReject, style: const TextStyle(color: AppColors.red)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => _decide(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leaf,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(AppLocalizations.of(context)!.commonVerify, style: const TextStyle(color: Colors.white)),
            )),
          ]),
      ]),
    );
  }
}
