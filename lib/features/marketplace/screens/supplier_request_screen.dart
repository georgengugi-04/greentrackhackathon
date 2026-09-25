import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/supplier_providers.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/models/models.dart';

/// Farmer -> supplier request (spec section 21). Simpler than the produce
/// request form — no available-quantity ceiling to validate against, since
/// suppliers don't track stock in v1 (see SupplierListing's doc comment).
class SupplierRequestScreen extends ConsumerStatefulWidget {
  const SupplierRequestScreen({super.key, required this.listingId});
  final String listingId;

  @override
  ConsumerState<SupplierRequestScreen> createState() => _SupplierRequestScreenState();
}

class _SupplierRequestScreenState extends ConsumerState<SupplierRequestScreen> {
  final _qtyCtrl = TextEditingController(text: '1');
  final _unitCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  DateTime? _preferredDate;
  bool _sending = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listingAsync = ref.watch(supplierListingByIdProvider(widget.listingId));

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
          // Pre-fill the unit from the listing if the supplier set one
          // (e.g. "bags", "litres") — a farmer requesting fertiliser
          // shouldn't have to guess the unit the supplier already uses.
          if (_unitCtrl.text.isEmpty && listing.unit != null) {
            _unitCtrl.text = listing.unit!;
          }
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(listing.name,
                    style: AppTextStyles.poppins(20, weight: FontWeight.w700)),
                Text(listing.supplierName, style: AppTextStyles.bodyMuted),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.supplierRequestQuantity,
                            style: AppTextStyles.sans(13, weight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _qtyCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration:
                              const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.supplierRequestUnit,
                            style: AppTextStyles.sans(13, weight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _unitCtrl,
                          decoration: InputDecoration(
                              hintText: l10n.supplierRequestUnitHint, border: const OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                Text(l10n.requestPreferredDate,
                    style: AppTextStyles.sans(13, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 2)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 180)),
                    );
                    if (picked != null) setState(() => _preferredDate = picked);
                  },
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      alignment: Alignment.centerLeft),
                  child: Text(_preferredDate == null
                      ? l10n.requestChooseDate
                      : DateFormat('d MMMM yyyy').format(_preferredDate!)),
                ),
                const SizedBox(height: 18),
                Text(l10n.requestMessage,
                    style: AppTextStyles.sans(13, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                      hintText: l10n.supplierRequestMessageHint,
                      border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _sending ? null : () => _send(listing),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: AppColors.premiumEmerald),
                  child: _sending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.requestSend),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _send(SupplierListing listing) async {
    final user = ref.read(sessionProvider);
    if (user == null) return;
    final l10n = AppLocalizations.of(context)!;
    final qty = double.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.requestErrorInvalidQuantity)));
      return;
    }
    final profile = await ref.read(supplierServiceProvider).getProfile(listing.supplierId);
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.supplierRequestSupplierUnavailable)));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(supplierServiceProvider).createRequest(
            listing: listing,
            supplierUserId: profile.userId,
            buyerId: user.id,
            buyerName: user.name,
            quantity: qty,
            unit: _unitCtrl.text.trim().isEmpty ? l10n.supplierRequestDefaultUnit : _unitCtrl.text.trim(),
            preferredDate: _preferredDate,
            message:
                _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.supplierRequestSentToSupplier)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.requestErrorGeneric(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
